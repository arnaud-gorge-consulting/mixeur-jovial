# Mixeur Jovial

Outil web pour **enregistrer, monter et exporter des histoires lues** au format des boîtes à histoires
(MP3 mono, 16 kHz, 64 kbps). Tout se passe sur l'ordinateur de l'utilisateur : aucun serveur,
aucun envoi de fichier, aucune connexion nécessaire.

## Fonctions

- **Enregistrer** au micro : choix du micro à tout moment, jauge de niveau avec conseils en direct.
- **Monter** : couper les loupés sur la forme d'onde, avec annuler, rétablir et retour à l'original.
- **Exporter**, avec trois traitements :
  - voix optimisée (volume régulier vers −16 LUFS, égalisation, dé-esseur, limiteur) ;
  - réduction du bruit de fond ;
  - raccourcissement automatique des longues pauses, avec seuils réglables (par défaut : plus de 1,5 s → 0,8 s).
- Un fichier est téléchargé directement en MP3 ; plusieurs sont regroupés dans un ZIP. Les noms sont nettoyés (35 caractères maximum).

## Utilisation

**Le plus simple : télécharger le paquet prêt à l'emploi dans [Releases](../../releases) et suivre [PRISE-EN-MAIN.md](PRISE-EN-MAIN.md).**


- **Windows** : double-cliquer sur `app/Lancer Mixeur Jovial.bat`. Un petit serveur local démarre (`lancer.ps1`, PowerShell inclus dans Windows, accessible uniquement depuis cet ordinateur) et l'outil s'ouvre dans le navigateur.
- **Mac** : clic droit sur `app/Lancer Mixeur Jovial (Mac).command`, puis **Ouvrir** (la première fois seulement : macOS bloque les scripts téléchargés). Le serveur utilise Python 3 ; s'il manque, macOS propose de l'installer.
- **Sur un site web** (par exemple chez un éditeur) : déposer le dossier `app/` tel quel sur un serveur en HTTPS. Aucun lanceur n'est alors nécessaire.

Apparence : deux thèmes, « Nature » (par défaut) et « Conteuse », au choix en bas de page ou par l'adresse `?theme=conteuse`.

Le micro n'est accessible qu'en HTTPS ou sur `localhost`. C'est pourquoi l'outil ne s'ouvre pas par un simple double-clic sur `index.html`.

## Navigateurs

| | Enregistrement et montage | Export (moteur) |
|---|---|---|
| Chrome, Edge (Windows, Mac) | ✓ | ✓ |
| Firefox (Windows, Mac) | ✓ | ✓ |
| Safari 15 ou plus récent (Mac) | ✓ | ✓ |
| Navigateurs mobiles | ✓ (écran allumé) | possible, plus lent |

Versions minimales visées : celles qui gèrent les modules JavaScript dans les Web Workers (Safari 15, Chrome 80, Firefox 114).
Le montage ne peut pas ouvrir un fichier dans un format que le navigateur ne sait pas lire (OGG sous un ancien Safari, par exemple). Ce fichier peut quand même être exporté.

## Structure

```
app/                      l'application (front end uniquement)
├── index.html            interface : HTML, CSS, logique d'enregistrement et de montage
├── js/moteur.js          traitement audio : pilote FFmpeg, analyse, chaîne de filtres
├── js/zip.js             création d'archives ZIP sans dépendance
├── test-moteur.html      vérification du moteur (licence, composants, traitement réel)
├── moteur/               moteur FFmpeg LGPL compilé (produit par moteur-build/, non versionné)
├── lancer.ps1            serveur local Windows
└── Lancer Mixeur Jovial.bat
moteur-build/             kit de compilation du moteur sans GPL (voir LISEZMOI.md)
.github/workflows/        compilation automatique du moteur sur GitHub
```

## Architecture en bref

- **Pas de back end ni de base de données.** L'état vit en mémoire, dans le navigateur. Seuls les réglages (micro choisi, seuils des pauses, options) sont gardés dans le `localStorage`.
- **Enregistrement** : Web Audio API (`getUserMedia`, `ScriptProcessor`), en WAV 16 bits.
- **Montage non destructif** : l'original n'est jamais modifié. Le montage est une liste de segments conservés ; chaque coupe en retire une partie. Les piles annuler / rétablir gardent les listes successives, et un fondu de 5 ms adoucit chaque raccord.
- **Traitement** : FFmpeg en WebAssembly, exécuté dans un Web Worker. Deux passes : une analyse (niveau de la voix, niveau du bruit, repérage des blancs), puis la chaîne de filtres et l'encodage MP3. Si un filtre échoue, l'outil réessaie avec une version simplifiée.

## Marques

« Joyeuse » et « Conteuse merveilleuse » sont des marques de leurs propriétaires respectifs. Mixeur Jovial est un
outil indépendant : il n'est ni affilié à Joyeuse, ni approuvé par elle. Il produit des fichiers au format
des boîtes à histoires qui lisent des MP3, sans utiliser de logo, de visuel ni de contenu de Joyeuse.

## Licences

- Code de Mixeur Jovial : voir `LICENSE` (tous droits réservés).
- Composants tiers : voir `THIRD_PARTY_NOTICES.md`.
