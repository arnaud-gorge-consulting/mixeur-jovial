#!/usr/bin/env bash
# Compile le moteur LGPL de Mixeur Jovial (FFmpeg + LAME en WebAssembly, sans composant GPL).
#
# Usage : bash moteur-build/build.sh [leger|complet] [version-ffmpeg.wasm|auto]
# Prérequis : Linux (ou WSL sous Windows), git, python3, node/npm, Docker avec buildx.
# Durée : 20 à 60 min selon la machine. Sur GitHub, le workflow « Moteur LGPL » le fait pour vous.
#
# Résultat :
#   _sortie/<profil>/moteur/         dossier à copier dans app/moteur/
#   _sortie/<profil>/sources-moteur-<profil>.tar.gz   sources exactes (obligation LGPL)
set -euo pipefail

PROFIL="${1:-leger}"
REF="${2:-auto}"
PILOTE="${PILOTE:-0.12}"            # @ffmpeg/ffmpeg 0.12.x (MIT)
ICI="$(cd "$(dirname "$0")" && pwd)"
TRAVAIL="$ICI/_travail/$PROFIL"
SORTIE="$ICI/_sortie/$PROFIL"
rm -rf "$TRAVAIL" "$SORTIE"; mkdir -p "$TRAVAIL" "$SORTIE/moteur/core" "$SORTIE/moteur/ffmpeg" "$SORTIE/moteur/LICENCES"

etape() { echo; echo "=== $* ==="; }

etape "1/6 Récupération de ffmpeg.wasm"
git clone --quiet "${FFMPEGWASM_URL:-https://github.com/ffmpegwasm/ffmpeg.wasm}" "$TRAVAIL/ffmpeg.wasm"
cd "$TRAVAIL/ffmpeg.wasm"
if [ "$REF" = auto ]; then
  REF="$(git tag -l 'v0.12.*' --sort=-v:refname | head -1)"
  [ -z "$REF" ] && REF="$(git tag -l '*core*0.12*' --sort=-v:refname | head -1)"
  [ -z "$REF" ] && REF="main"
fi
echo "Version utilisée : $REF   (étiquettes disponibles : $(git tag -l | tail -8 | tr '\n' ' '))"
git checkout --quiet "$REF"
COMMIT="$(git rev-parse HEAD)"

etape "2/6 Retrait des composants GPL (profil $PROFIL)"
python3 "$ICI/patch_ffmpegwasm.py" . "$PROFIL"
git diff --stat
git diff > "$SORTIE/modifications-ffmpeg.wasm.patch"

etape "3/6 Compilation (longue)"
export DOCKER_BUILDKIT=1
docker buildx build \
  --build-arg EXTRA_CFLAGS="-O3" \
  --build-arg EXTRA_LDFLAGS="-O3" \
  --build-arg FFMPEG_ST=yes \
  -o "$TRAVAIL/dist" .
CORE_JS="$(find "$TRAVAIL/dist" -path '*esm*' -name 'ffmpeg-core.js' | head -1)"
CORE_WASM="$(find "$TRAVAIL/dist" -path '*esm*' -name 'ffmpeg-core.wasm' | head -1)"
[ -f "$CORE_JS" ] && [ -f "$CORE_WASM" ] || { echo "ERREUR : cœur ESM introuvable dans $TRAVAIL/dist"; find "$TRAVAIL/dist"; exit 1; }
cp "$CORE_JS" "$CORE_WASM" "$SORTIE/moteur/core/"

etape "4/6 Pilote @ffmpeg/ffmpeg (MIT)"
cd "$TRAVAIL"
npm pack --silent "@ffmpeg/ffmpeg@$PILOTE" > /dev/null
tar -xzf ffmpeg-ffmpeg-*.tgz
cp -r package/dist/esm/. "$SORTIE/moteur/ffmpeg/"
cp package/LICENSE "$SORTIE/moteur/LICENCES/ffmpeg.wasm-pilote-MIT.txt" 2>/dev/null || true
PILOTE_V="$(node -p "require('./package/package.json').version")"

etape "5/6 Sources et licences (obligation LGPL)"
mkdir -p "$TRAVAIL/sources"
python3 - "$TRAVAIL/ffmpeg.wasm/moteur-config.json" > "$TRAVAIL/depots.txt" <<'EOF'
import json, sys
for s in json.load(open(sys.argv[1]))["sources"]:
    print(s["depot"], s["version"])
EOF
while read -r depot version; do
  nom="$(basename "$depot" .git)"
  git clone --quiet --depth 1 --branch "$version" "$depot" "$TRAVAIL/sources/$nom" \
    || git clone --quiet "$depot" "$TRAVAIL/sources/$nom"
  (cd "$TRAVAIL/sources/$nom" && git checkout --quiet "$version" 2>/dev/null || true)
  for f in COPYING COPYING.LGPLv2.1 COPYING.LGPLv3 LICENSE LICENSE.md; do
    [ -f "$TRAVAIL/sources/$nom/$f" ] && cp "$TRAVAIL/sources/$nom/$f" "$SORTIE/moteur/LICENCES/$nom-$f.txt"
  done
done < "$TRAVAIL/depots.txt"
cp "$TRAVAIL/ffmpeg.wasm/LICENSE" "$SORTIE/moteur/LICENCES/ffmpeg.wasm-MIT.txt" 2>/dev/null || true
(cd "$TRAVAIL/ffmpeg.wasm" && git archive --format=tar.gz --prefix=ffmpeg.wasm/ -o "$TRAVAIL/sources/ffmpeg.wasm-$REF.tar.gz" HEAD)
cp "$TRAVAIL/ffmpeg.wasm/moteur-config.json" "$SORTIE/moteur-config.json"
cp "$ICI/patch_ffmpegwasm.py" "$ICI/build.sh" "$SORTIE/modifications-ffmpeg.wasm.patch" "$TRAVAIL/sources/"
tar --exclude=.git -czf "$SORTIE/sources-moteur-$PROFIL.tar.gz" -C "$TRAVAIL" sources

etape "6/6 Fiche d'identité du moteur"
SHA="$(sha256sum "$SORTIE/moteur/core/ffmpeg-core.wasm" | cut -d' ' -f1)"
TAILLE="$(du -h "$SORTIE/moteur/core/ffmpeg-core.wasm" | cut -f1)"
python3 - "$SORTIE" "$PROFIL" "$REF" "$COMMIT" "$PILOTE_V" "$SHA" <<'EOF'
import json, sys, datetime
sortie, profil, ref, commit, pilote, sha = sys.argv[1:]
cfg = json.load(open(f"{sortie}/moteur-config.json"))
info = {
  "nom": "Moteur Mixeur Jovial", "profil": profil, "licence": "LGPL-2.1-or-later (FFmpeg, LAME) + MIT (pilote ffmpeg.wasm)",
  "date": datetime.date.today().isoformat(), "ffmpeg.wasm": {"version": ref, "commit": commit},
  "ffmpeg": cfg.get("ffmpeg_version"), "pilote_@ffmpeg/ffmpeg": pilote, "sha256_wasm": sha,
  "options_retirees": cfg["options_retirees"], "options_ajoutees": cfg["options_ajoutees"], "sources": cfg["sources"],
}
json.dump(info, open(f"{sortie}/moteur/INFOS.json", "w"), indent=2, ensure_ascii=False)
open(f"{sortie}/moteur/SOURCES.md", "w").write(
"""# Sources du moteur (LGPL)

Ce dossier contient FFmpeg et LAME compilés en WebAssembly, sous licence GNU LGPL 2.1 ou ultérieure.
Aucun composant GPL n'est inclus (pas de --enable-gpl, ni x264, x265, postproc).

Le code source exact, les modifications apportées et le script de compilation sont fournis dans
l'archive « sources-moteur-%s.tar.gz » remise avec ce logiciel, et sur demande auprès de l'auteur.

Vous pouvez remplacer ce moteur par votre propre compilation : remplacez les fichiers du dossier core/
par un ffmpeg-core.js / ffmpeg-core.wasm (format ESM de ffmpeg.wasm 0.12) de votre choix.

Composants et versions : voir INFOS.json. Textes des licences : dossier LICENCES/.
""" % profil)
EOF
echo
echo "Terminé : moteur $PROFIL, $TAILLE, dans $SORTIE/moteur"
ls -la "$SORTIE" "$SORTIE/moteur" "$SORTIE/moteur/core"
