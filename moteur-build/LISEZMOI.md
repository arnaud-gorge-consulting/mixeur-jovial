# Compiler le moteur LGPL de Mixeur Jovial

Le moteur, c'est FFmpeg et l'encodeur MP3 LAME, compilés en WebAssembly pour tourner dans le navigateur.
La version publique (`@ffmpeg/core`) est sous **GPL**, car elle contient x264 et x265.
Ce kit recompile FFmpeg **sans aucun composant GPL** : le résultat est sous **LGPL**.
Mixeur Jovial peut alors être vendu ou cédé sans publier son propre code.

## Ce que fait le kit

1. Il récupère le projet officiel [ffmpeg.wasm](https://github.com/ffmpegwasm/ffmpeg.wasm) (dernière version 0.12).
2. `patch_ffmpegwasm.py` retire de sa recette de compilation :
   - `--enable-gpl` et `--enable-nonfree` ;
   - x264, x265, libvpx, theora et les autres bibliothèques inutiles ;
   - libpostproc (GPL).
   Il garde LAME (LGPL) et zlib.
3. Il compile ensuite FFmpeg dans un conteneur Docker. Deux versions sont proposées :
   - **leger** : seulement ce qu'utilise Mixeur Jovial (formats, décodeurs, filtres). C'est la version la plus petite, donc le chargement le plus rapide.
   - **complet** : tout FFmpeg hors GPL. C'est la solution de secours si la version légère manque d'un composant.
4. Il assemble le dossier `moteur/` : cœur FFmpeg, pilote ffmpeg.wasm (MIT), licences, fiche `INFOS.json`.
5. Il archive les **sources exactes** compilées (`sources-moteur-*.tar.gz`). La LGPL oblige à les fournir avec le logiciel.

## Méthode 1 : sur GitHub (rien à installer, recommandé)

1. Envoie ce dépôt sur GitHub (dépôt privé).
2. Ouvre l'onglet **Actions**, puis le workflow **Moteur LGPL**, puis **Run workflow**.
3. Attends 30 à 60 minutes. Les deux profils se compilent en parallèle.
4. En bas de la page de l'exécution, rubrique **Artifacts**, télécharge :
   - `moteur-leger` (ou `moteur-complet`) : décompresse son contenu dans `app/moteur/` ;
   - `sources-moteur-leger` : à conserver et à remettre avec le logiciel.

## Méthode 2 : sur ton PC (Linux, ou WSL sous Windows)

Prérequis : Docker avec buildx, git, python3, node et npm.

```bash
bash moteur-build/build.sh leger      # ou : complet
# résultat : moteur-build/_sortie/leger/moteur  → à copier dans app/moteur
```

## Vérifier le moteur obtenu

1. Double-clique sur `app/Lancer Mixeur Jovial.bat`.
2. Dans l'outil, clique sur le lien **Vérifier le moteur**, en bas de la page.
3. Clique sur **Lancer la vérification**.

La page contrôle :
- la licence déclarée par FFmpeg ;
- l'absence de composant GPL ;
- la présence de chaque filtre, format et décodeur utilisé ;
- un traitement réel, qui doit produire un MP3 mono, 16 kHz, 64 kbps, avec le blanc raccourci.

Tout doit être vert avant de distribuer l'outil.

## Obligations LGPL, en résumé (à faire valider par un juriste)

- Garder le moteur dans un **fichier séparé et remplaçable** (`app/moteur/core/`). C'est le cas ici.
- Fournir les **textes de licence** (`moteur/LICENCES/`) et les **sources exactes** (`sources-moteur-*.tar.gz`).
- Mentionner l'usage de FFmpeg et LAME : c'est fait en bas de page de l'outil et dans `moteur/SOURCES.md`.
- Ne pas interdire, par contrat, la modification du moteur ni l'ingénierie inverse nécessaire pour le remplacer.
