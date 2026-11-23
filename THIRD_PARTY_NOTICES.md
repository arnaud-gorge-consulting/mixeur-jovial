# Composants tiers

Mixeur Jovial utilise les composants suivants. Ils restent sous leur propre licence ; ils ne sont pas
couverts par la licence de Mixeur Jovial.

| Composant | Rôle | Licence | Où |
|---|---|---|---|
| [FFmpeg](https://ffmpeg.org) | Décodage, filtres audio | GNU LGPL 2.1 ou ultérieure (compilé sans `--enable-gpl`) | `app/moteur/core/` |
| [LAME](https://lame.sourceforge.io) | Encodage MP3 | GNU LGPL 2 ou ultérieure | `app/moteur/core/` |
| [zlib](https://zlib.net) | Décompression | Licence zlib | `app/moteur/core/` |
| [ffmpeg.wasm](https://github.com/ffmpegwasm/ffmpeg.wasm) (@ffmpeg/ffmpeg, recette de compilation) | Pilote du moteur dans le navigateur | MIT | `app/moteur/ffmpeg/`, `moteur-build/` |

Le moteur (`app/moteur/core/ffmpeg-core.js` et `ffmpeg-core.wasm`) est un fichier séparé que l'utilisateur
peut remplacer par sa propre compilation. Les textes complets des licences se trouvent dans
`app/moteur/LICENCES/`, et les sources exactes compilées dans l'archive `sources-moteur-*.tar.gz`
produite par `moteur-build/build.sh`.

This software uses code of FFmpeg (http://ffmpeg.org) licensed under the LGPLv2.1
(http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html); its source can be obtained as described above.
