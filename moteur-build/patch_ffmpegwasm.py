#!/usr/bin/env python3
"""
Adapte le dépôt officiel ffmpeg.wasm pour produire un moteur SANS composant GPL.

Ce que fait ce script, dans le dossier du dépôt ffmpeg.wasm passé en argument :
  1. Dockerfile : supprime les étapes qui compilent des bibliothèques GPL ou inutiles
     (x264, x265, libvpx, theora…), retire --enable-gpl / --enable-nonfree et les
     --enable-lib* sauf libmp3lame (LAME, LGPL), retire les -l<lib> correspondants.
  2. Profil « leger » : ajoute --disable-everything puis réactive uniquement ce dont
     Mixeur Jovial a besoin (liste ci-dessous, relevée en rejouant ses commandes).
  3. build/*.sh : retire libpostproc (GPL) de l'édition de liens.
  4. Écrit moteur-config.json : configuration retenue et sources exactes (pour la LGPL).

Usage : python3 patch_ffmpegwasm.py <dossier-ffmpeg.wasm> <complet|leger>
"""
import json, re, sys
from pathlib import Path

# ---------- Ce dont Mixeur Jovial a besoin (profil « leger ») ----------
LEGER = {
    "protocol": ["file"],
    "demuxer": ["mp3", "wav", "aac", "aiff", "asf", "flac", "matroska", "mov", "ogg", "caf", "w64"],
    "decoder": ["mp3", "mp3float", "aac", "aac_latm", "alac", "flac", "vorbis", "opus",
                "wmav1", "wmav2", "mjpeg", "png",
                "pcm_s16le", "pcm_s16be", "pcm_s24le", "pcm_s24be", "pcm_s32le", "pcm_s32be",
                "pcm_f32le", "pcm_f32be", "pcm_f64le", "pcm_u8", "pcm_alaw", "pcm_mulaw"],
    "parser": ["mpegaudio", "aac", "aac_latm", "flac", "vorbis", "opus", "mjpeg", "png"],
    "encoder": ["libmp3lame", "pcm_s16le"],
    "muxer": ["mp3", "wav", "null"],
    "filter": ["aresample", "aformat", "anull", "null", "format", "highpass", "lowpass",
               "asetnsamples", "astats", "ametadata", "ebur128", "volume", "afftdn",
               "aselect", "asetpts", "equalizer", "deesser", "acompressor", "alimiter",
               "loudnorm", "silencedetect", "atrim", "afade", "apad", "amix", "pan"],
}
LEGER_FLAGS = ["--disable-everything"] + [
    f"--enable-{kind}={','.join(names)}" for kind, names in LEGER.items()
]

KEEP_STAGES = {"lame-builder", "zlib-builder"}
KEEP_LIBS = {"mp3lame", "z", "m", "pthread"}
DROP_FLAG = re.compile(r"(?<!\S)--enable-(gpl|nonfree|version3|postproc|lib(?!mp3lame\b)[\w-]+)(?!\S)")
DROP_LINK = re.compile(r"(?<!\S)-l(?!(?:%s)(?!\S))[\w+-]+(?!\S)" % "|".join(map(re.escape, KEEP_LIBS)))


def instructions(text):
    """Découpe un Dockerfile en instructions (listes de lignes physiques)."""
    out, cur = [], []
    for line in text.splitlines():
        if not cur and (not line.strip() or line.lstrip().startswith("#")):
            out.append([line]); continue
        cur.append(line)
        if not line.rstrip().endswith("\\"):
            out.append(cur); cur = []
    if cur: out.append(cur)
    return out


def rejoin(lines):
    """Supprime les lignes vides et répare les « \\ » de continuation."""
    body = [l.rstrip().rstrip("\\").rstrip() for l in lines]
    body = [l for l in body if l.strip()]
    return [l + " \\" for l in body[:-1]] + body[-1:]


def patch_dockerfile(path, profil, report):
    text = path.read_text()
    blocks = instructions(text)
    out, stage, removed = [], None, set()
    # 1er passage : repérer les étapes à supprimer
    for b in blocks:
        m = re.match(r"\s*FROM\s+\S+\s+AS\s+([\w.-]+)", b[0], re.I)
        if m:
            name = m.group(1)
            if name.endswith("-builder") and not name.startswith("ffmpeg") and name not in KEEP_STAGES:
                removed.add(name)
    # 2e passage : réécrire
    for b in blocks:
        first = b[0]
        m = re.match(r"\s*FROM\s+\S+\s+AS\s+([\w.-]+)", first, re.I)
        if m: stage = m.group(1)
        elif re.match(r"\s*FROM\s", first, re.I): stage = None
        if stage in removed:
            continue
        if re.match(r"\s*COPY\s+--from=([\w.-]+)", first, re.I):
            src = re.match(r"\s*COPY\s+--from=([\w.-]+)", first, re.I).group(1)
            if src in removed:
                report["copies_retirees"].append(src); continue
        joined = "\n".join(b)
        if "--enable-" in joined or re.search(r"(?<!\S)-lmp3lame(?!\S)", joined):
            new = []
            for line in b:
                l = DROP_FLAG.sub("", line)
                if re.search(r"(?<!\S)-lmp3lame(?!\S)", joined):
                    l = DROP_LINK.sub("", l)
                if l != line: report["options_retirees"].append(line.strip().rstrip("\\").strip())
                new.append(l)
                if profil == "leger" and re.search(r"(?<!\S)--enable-libmp3lame(?!\S)", line):
                    indent = re.match(r"\s*", line).group(0) or "      "
                    new += [indent + f + " \\" for f in LEGER_FLAGS]
                    report["profil_leger_ajoute"] = True
            b = rejoin(new)
        out.extend(b)
    path.write_text("\n".join(out) + "\n")
    report["etapes_supprimees"] = sorted(removed)
    return text


def patch_scripts(repo, report):
    for sh in sorted((repo / "build").glob("*.sh")):
        txt = sh.read_text()
        new = "\n".join(l for l in txt.splitlines() if "postproc" not in l) + "\n"
        new = DROP_FLAG.sub("", new)
        if new != txt:
            sh.write_text(new)
            report["scripts_modifies"].append(sh.name)


def sources(dockerfile_text):
    """Relève les dépôts et versions exactes compilés (obligation LGPL : fournir les sources)."""
    env = dict(re.findall(r"^\s*ENV\s+(\w+)[= ]([^\s\\]+)", dockerfile_text, re.M))
    found = []
    for url in re.findall(r"^\s*ADD\s+(https://\S+?\.git#\S+)", dockerfile_text, re.M):
        url = re.sub(r"\$\{?(\w+)\}?", lambda m: env.get(m.group(1), m.group(0)), url)
        repo, ref = url.split("#", 1)
        found.append({"depot": repo, "version": ref})
    return found, env


def main():
    repo, profil = Path(sys.argv[1]), sys.argv[2]
    assert profil in ("complet", "leger"), "profil : complet ou leger"
    df = repo / "Dockerfile"
    if not df.exists():
        sys.exit("ERREUR : pas de Dockerfile dans " + str(repo))
    report = {"profil": profil, "copies_retirees": [], "options_retirees": [], "scripts_modifies": [],
              "profil_leger_ajoute": False}
    original = patch_dockerfile(df, profil, report)
    patch_scripts(repo, report)
    patched = df.read_text()

    # Vérifications : on préfère échouer tôt avec un message clair
    errors = []
    if "--enable-libmp3lame" not in patched: errors.append("--enable-libmp3lame introuvable : structure du dépôt inattendue")
    if re.search(r"(?<!\S)--enable-gpl(?!\S)", patched): errors.append("--enable-gpl encore présent")
    if profil == "leger" and not report["profil_leger_ajoute"]: errors.append("profil léger non appliqué")
    for sh in (repo / "build").glob("*.sh"):
        if "postproc" in sh.read_text(): errors.append(f"postproc encore présent dans {sh.name}")

    srcs, _ = sources(patched)
    _, env = sources(original)
    report["sources"] = srcs
    report["ffmpeg_version"] = env.get("FFMPEG_VERSION")
    report["options_ajoutees"] = LEGER_FLAGS if profil == "leger" else []
    (repo / "moteur-config.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(json.dumps(report, indent=2, ensure_ascii=False))
    if errors:
        sys.exit("ERREUR : " + " ; ".join(errors))
    print("OK : Dockerfile adapté (profil " + profil + ").")


if __name__ == "__main__":
    main()
