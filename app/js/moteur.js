/* Mixeur Jovial : moteur de traitement audio.
 *
 * Ce module pilote FFmpeg compilé en WebAssembly (version LGPL, sans composant GPL),
 * servi depuis le dossier ./moteur/ à côté de l'application :
 *   moteur/ffmpeg/index.js       pilote @ffmpeg/ffmpeg (MIT)
 *   moteur/core/ffmpeg-core.js   cœur FFmpeg + LAME (LGPL), remplaçable par l'utilisateur
 *   moteur/core/ffmpeg-core.wasm
 *
 * Il ne touche pas à la page : il reçoit des octets et des réglages, il rend un MP3.
 */

export const SR = 16000;                // fréquence de la boîte
const WIN = 0.2;                        // fenêtre d'analyse (s)
const TARGET_PRE = -20;                 // niveau de travail de la voix (LUFS)
const EDGE_KEEP = 0.3, GATE_MIN = 0.4;  // blanc gardé en début / fin ; durée mini d'atténuation du bruit
export const BASE = ['aresample=16000', 'aformat=channel_layouts=mono', 'highpass=f=90'];
export const VOICE = [
  'equalizer=f=250:t=q:w=1.2:g=-2',     // moins de « carton »
  'equalizer=f=3000:t=q:w=1:g=3',       // présence, intelligibilité
  'deesser=i=0.3',                      // « s » moins sifflants
  'acompressor=threshold=-26dB:ratio=3:attack=8:release=150:knee=4',
  'volume=14.5dB',
  'alimiter=limit=0.6:attack=5:release=60:level=0',
];
export const OUT = ['-ac', '1', '-ar', '16000', '-b:a', '64k', '-abr', '0'];

let ffmpeg = null, logSink = null, onProg = null;
const sec = (x) => (Math.round(x * 10) / 10).toFixed(1).replace('.', ',');

/* Télécharge un fichier en signalant la progression */
async function fetchBlobURL(url, mime, onPct) {
  const resp = await fetch(url);
  if (!resp.ok) throw new Error('fichier introuvable : ' + url + ' (' + resp.status + ')');
  const total = +(resp.headers.get('Content-Length') || 0);
  if (!resp.body || !total) return URL.createObjectURL(new Blob([await resp.arrayBuffer()], { type: mime }));
  const reader = resp.body.getReader(), chunks = [];
  let received = 0, last = -1;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value); received += value.length;
    const pct = Math.round(received / total * 100);
    if (pct !== last && onPct) { onPct(pct); last = pct; }
  }
  return URL.createObjectURL(new Blob(chunks, { type: mime }));
}

/* Charge le moteur une seule fois. base = URL du dossier « moteur/ » */
export async function chargerMoteur(base, { onPct } = {}) {
  if (ffmpeg) return ffmpeg;
  const u = (p) => new URL(p, base).href;
  const { FFmpeg } = await import(u('ffmpeg/index.js'));
  const ff = new FFmpeg();
  ff.on('log', ({ message }) => { if (logSink) logSink.push(message); });
  ff.on('progress', ({ progress }) => { if (onProg) onProg(progress); });
  await ff.load({
    coreURL: u('core/ffmpeg-core.js'),
    wasmURL: await fetchBlobURL(u('core/ffmpeg-core.wasm'), 'application/wasm', onPct),
  });
  ffmpeg = ff;
  return ffmpeg;
}
export const moteurPret = () => !!ffmpeg;

/* Lance ffmpeg ; renvoie le journal, lève une erreur si la commande échoue */
export async function run(args, prog) {
  const lines = [];
  logSink = lines; onProg = prog || null;
  let code;
  try { code = await ffmpeg.exec(args); }
  finally { logSink = null; onProg = null; }
  if (code !== 0) {
    const err = lines.filter(l => /error|invalid|no such|not found|unable/i.test(l)).slice(-2).join(' / ');
    const e = new Error('code ' + code + (err ? ' — ' + err : ''));
    e.journal = lines;
    throw e;
  }
  return lines;
}

/* Passe 1 : mesure du niveau de la voix (sonie) et du niveau toutes les 0,2 s */
export async function analyse(inName, prog, cfg) {
  const lines = await run(['-i', inName, '-vn', '-af', [...BASE,
    `asetnsamples=n=${Math.round(16000 * WIN)}`, 'astats=metadata=1:reset=1',
    'ametadata=mode=print:key=lavfi.astats.Overall.RMS_level', 'ebur128=framelog=verbose'].join(','),
    '-f', 'null', '-'], prog);
  const win = []; let t = null;
  for (const l of lines) {
    const m1 = l.match(/pts_time:([\d.]+)/);
    if (m1) t = +m1[1];
    const m2 = l.match(/RMS_level=(-?[\d.]+|-?inf|nan)/);
    if (m2 && t !== null) { win.push([t, /inf|nan/.test(m2[1]) ? -120 : +m2[1]]); t = null; }
  }
  const Ims = [...lines.join('\n').matchAll(/I:\s+(-?[\d.]+) LUFS/g)];
  const I = Ims.length ? +Ims[Ims.length - 1][1] : null;
  if (I === null || I < -70 || win.length < 5) return null;

  const lv = win.map(w => w[1]).sort((a, b) => a - b);
  const noise = lv[Math.floor(lv.length * 0.1)];
  const thr = Math.min(noise + 0.4 * (I - noise), I - 12);   // « blanc » = entre bruit et voix
  const end = win[win.length - 1][0] + WIN;
  const runs = []; let cur = null;
  for (const [tt, v] of win) {
    if (v < thr) cur = cur ? [cur[0], tt + WIN] : [tt, tt + WIN];
    else if (cur) { runs.push(cur); cur = null; }
  }
  if (cur) runs.push(cur);
  const cuts = [], gates = [];
  for (const [a, b] of runs) {
    if (b - a >= cfg.min) {                       // pause trop longue : on garde cfg.keep au total
      const edge = Math.min(EDGE_KEEP, cfg.keep), half = cfg.keep / 2;
      if (a <= 0.01) cuts.push([0, b - edge]);
      else if (b >= end - 0.01) cuts.push([a + edge, 1e9]);
      else cuts.push([a + half, b - half]);
    }
    if (b - a >= GATE_MIN) gates.push([a + 0.08, b - 0.08]);
  }
  return { I, noise, thr, gain: Math.max(-10, Math.min(35, TARGET_PRE - I)), cuts, gates, end };
}

export function buildFilters(plan, o, level) {
  // level 0 : complet ; 1 : sans les filtres récents (sécurité) ; 2 : conversion seule
  const f = [...BASE];
  if (level === 2) return f;
  if (o.voice && plan) f.push(`volume=${plan.gain.toFixed(2)}dB`);
  if (o.noise) f.push('afftdn=nr=12:tn=1');
  if (o.noise && plan && plan.gates.length && level === 0) {
    const ex = plan.gates.map(([a, b]) => `clip(min(t-${a.toFixed(2)},${b.toFixed(2)}-t)/0.06,0,1)`).join('+');
    f.push('asetnsamples=n=320', `volume='1-0.8*(${ex})':eval=frame`);
  }
  if (o.pauses && plan && plan.cuts.length) {
    const ex = plan.cuts.map(([a, b]) => `between(t,${a.toFixed(2)},${b.toFixed(2)})`).join('+');
    f.push(`aselect='not(${ex})'`, 'asetpts=N/SR/TB');
  }
  if (o.voice && plan) f.push(...(level === 0 ? VOICE : VOICE.filter(x => !x.startsWith('deesser'))));
  else if (o.voice) f.push(...VOICE.slice(0, 2), 'loudnorm=I=-15:TP=-2:LRA=7', 'aresample=16000'); // analyse indisponible
  return f;
}

/* Traite un fichier : octets en entrée, MP3 (Uint8Array) en sortie.
 * o = { voice, noise, pauses, min, keep } ; cb = { prog(0..1), status(texte), log(texte) } */
export async function traiter(bytes, inName, o, cb = {}) {
  const prog = cb.prog || (() => {}), status = cb.status || (() => {}), log = cb.log || (() => {});
  await ffmpeg.writeFile(inName, bytes);
  try {
    let plan = null;
    if (o.voice || o.noise || o.pauses) {
      status('analyse…');
      try { plan = await analyse(inName, p => prog(p * 0.3), { min: o.min, keep: o.keep }); }
      catch (e) { log('Analyse impossible (' + e.message + ') : traitement simplifié.'); }
      if (plan) {
        const removed = plan.cuts.reduce((t, [a, b]) => t + Math.max(0, Math.min(b, plan.end) - a), 0);
        log('voix ' + plan.I.toFixed(0) + ' LUFS, bruit ' + plan.noise.toFixed(0) + ' dB' +
            (o.pauses && plan.cuts.length ? ', ' + plan.cuts.length + ' pause(s) de plus de ' + sec(o.min) +
             ' s ramenée(s) à ' + sec(o.keep) + ' s (−' + sec(removed) + ' s)' : ''));
      }
    }
    status((o.voice || o.noise) ? 'nettoyage…' : 'conversion…');
    const base = (o.voice || o.noise || o.pauses) ? 0.3 : 0;
    for (let level = 0; level <= 2; level++) {
      try {
        await run(['-i', inName, '-vn', '-map_metadata', '-1', '-af', buildFilters(plan, o, level).join(','),
                   ...OUT, '-y', 'out.mp3'], p => prog(base + p * (1 - base)));
        if (level > 0) log('(version simplifiée du traitement utilisée pour ce fichier)');
        break;
      } catch (e) {
        if (level === 2) throw e;
        log('Traitement complet impossible (' + e.message + '), nouvel essai simplifié…');
      }
    }
    const data = await ffmpeg.readFile('out.mp3');
    await ffmpeg.deleteFile('out.mp3').catch(() => {});
    return { data: data instanceof Uint8Array ? data.slice() : new Uint8Array(data), plan };
  } finally {
    await ffmpeg.deleteFile(inName).catch(() => {});
  }
}
