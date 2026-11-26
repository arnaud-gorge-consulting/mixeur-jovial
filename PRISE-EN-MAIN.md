# Mixeur Jovial : prise en main pas à pas

Ce guide part de zéro : rien à installer, tout se passe sur ton ordinateur.

---

## 1. Télécharger l'outil (une seule fois)

1. Ouvre la page **Releases** du dépôt :
   https://github.com/arnaud-gorge-consulting/mixeur-jovial/releases
   (connecte-toi à GitHub, le dépôt est privé).
2. Dans la version la plus récente (étiquette verte **Latest**), clique sur **Mixeur-Jovial.zip** pour le télécharger.
3. Range-le dans un dossier durable, par exemple **Documents**. Évite de le laisser dans Téléchargements, qu'on vide souvent.

## 2. Décompresser

**Windows**

1. **D'abord, débloque le ZIP.** Sans cette étape, Windows bloquera le lanceur (« les fichiers provenant d'Internet peuvent être dangereux »), parfois sans proposer « Exécuter quand même ».
   - Clic droit sur **Mixeur-Jovial.zip**, puis **Propriétés**.
   - Dans l'onglet **Général**, tout en bas, coche **Débloquer**, puis **OK**.
   - Si la case n'apparaît pas, le fichier est déjà débloqué : passe à la suite.
2. Fais un clic droit sur **Mixeur-Jovial.zip**, puis **Extraire tout…**, puis **Extraire**.
3. Tu obtiens un dossier **Mixeur-Jovial**. Vérifie qu'il contient bien :
   - `Lancer Mixeur Jovial.bat`
   - `index.html`
   - un dossier `moteur` (avec dedans un dossier `core`)

> ⚠️ N'ouvre pas l'outil depuis l'intérieur du ZIP sans l'avoir extrait : Windows n'y donne qu'un accès temporaire, et le lanceur ne fonctionnerait pas.

**Mac** : double-clique sur le ZIP. Le dossier **Mixeur-Jovial** apparaît à côté.

## 3. Lancer l'outil

**Windows**

1. Double-clique sur **Lancer Mixeur Jovial.bat**.
2. Si Windows affiche « Windows a protégé votre ordinateur », clique sur **Informations complémentaires**, puis sur **Exécuter quand même**. Le message ne revient pas ensuite.
3. Une fenêtre noire s'ouvre, puis ton navigateur s'ouvre sur `http://localhost:8765`.
4. **Laisse la fenêtre noire ouverte** tant que tu utilises l'outil. La fermer arrête l'outil.

**Mac**

1. La première fois, fais un **clic droit** sur **Lancer Mixeur Jovial (Mac).command**, puis **Ouvrir**, puis à nouveau **Ouvrir**. Ensuite, un double-clic suffit.
2. Si macOS propose d'installer les « outils de développement en ligne de commande », accepte (quelques minutes), puis relance.
3. Une fenêtre Terminal s'ouvre, puis le navigateur. Laisse le Terminal ouvert pendant l'utilisation.

> Astuce : ajoute `http://localhost:8765` à tes favoris. Il ne fonctionne que lorsque le lanceur est ouvert.

## 4. Premier lancement : vérifier que tout va bien

1. En bas de la page de l'outil, clique sur **Vérifier le moteur**, puis sur **Lancer la vérification**.
2. Toutes les lignes doivent être vertes, avec le message « Moteur conforme ».
3. Reviens à l'outil avec le lien **← Retour à l'outil**.

## 5. Enregistrer une histoire

1. **Titre** : tape le titre de l'histoire. Le nom du fichier final s'affiche dessous : 35 caractères maximum, sans accents.
2. **Micro** : clique sur **Tester le micro**. Le navigateur demande l'autorisation : clique sur **Autoriser**.
   - Choisis ton micro dans la liste s'il y en a plusieurs.
   - Parle normalement : la jauge doit monter dans la **zone du milieu** (« bon niveau »). Si elle reste dans la zone jaune, rapproche-toi. Si elle passe dans le rouge, recule.
3. Clique sur **Enregistrer** et lis ton histoire. Clique sur **Arrêter l'enregistrement** à la fin.
4. En cas de loupé, ne t'arrête pas : marque une pause, reprends la phrase et continue. Tu couperas le raccord à l'étape suivante.

> **Sur Mac**, si le micro est refusé : ouvre Réglages Système > Confidentialité et sécurité > Micro, active ton navigateur, puis recharge la page.

## 6. Couper les loupés (montage)

Le montage s'ouvre tout seul après l'enregistrement.

1. **Écouter** : clique sur ▶ Écouter, ou appuie sur la barre Espace. Clique sur l'onde pour te placer à un endroit.
2. **Sélectionner** le passage raté : appuie sur le bouton de la souris au début du loupé, glisse jusqu'à la fin, puis relâche.
3. **Vérifier** : « Écouter la sélection » rejoue uniquement le passage sélectionné.
4. **Couper** : clique sur ✂ Couper la sélection, ou appuie sur Suppr. « Écouter » rejoue ensuite le raccord.
5. Une erreur ? **Annuler** (Ctrl+Z) remet le passage coupé. **Revenir à l'original** retrouve l'enregistrement complet.
6. Pour zoomer, utilise la molette de la souris sur l'onde, ou les boutons − / + / Tout.
7. Quand tout est bon, clique sur **Passer à l'export ↓**.

## 7. Exporter en MP3

1. Laisse les trois traitements activés, sauf besoin particulier :
   - **Optimiser la voix** : volume fort et régulier, voix claire.
   - **Nettoyer le bruit de fond.**
   - **Raccourcir les longues pauses** : par défaut, un blanc de plus de 1,5 s est ramené à 0,8 s. Les deux curseurs permettent d'ajuster ces durées.
2. Clique sur **Exporter en MP3**.
3. Le MP3 arrive dans ton dossier **Téléchargements**. Avec plusieurs histoires, tu obtiens un fichier **mixeur-jovial.zip** à décompresser.
4. Écoute le résultat directement dans la liste, avant de le copier sur la boîte.

> Tu peux aussi **importer** des fichiers existants (MP3, WAV, M4A…) avec la zone « Importer des fichiers audio », à l'étape 1. Ils passent par le même montage et le même export.

## 8. Copier sur la boîte à histoires

1. Branche la boîte à l'ordinateur avec son câble USB d'origine.
2. Elle apparaît comme une **clé USB** : dans l'Explorateur sous Windows, dans le Finder sous Mac.
3. Ouvre-la : il y a un dossier par face du cube. Copie tes MP3 dans le dossier de la face voulue.
4. **Éjecte** la boîte avant de la débrancher : sous Windows, clic droit sur le lecteur puis Éjecter ; sous Mac, bouton ⏏ dans le Finder.

## 9. Changer d'apparence

En bas de page, **Apparence : Nature / Conteuse** change les couleurs de l'outil. Ton choix est mémorisé.

## 10. Mettre à jour l'outil

Quand une nouvelle version paraît dans **Releases** :

1. Télécharge le nouveau **Mixeur-Jovial.zip** et décompresse-le.
2. Supprime l'ancien dossier.

Tes réglages (micro, seuils des pauses, apparence) sont conservés par le navigateur.

---

## En cas de problème

| Ce que tu vois | Cause probable | Solution |
|---|---|---|
| Bandeau « Ouvrez Mixeur Jovial avec Lancer Mixeur Jovial » | Tu as double-cliqué sur `index.html` | Ferme l'onglet et utilise le lanceur (étape 3) |
| Bandeau « Moteur absent » | Le dossier `moteur` manque ou est mal placé | Retélécharge le ZIP de la page Releases et extrais-le en entier |
| « Micro refusé » | Autorisation refusée dans le navigateur ou, sur Mac, dans le système | Clique sur le cadenas à gauche de l'adresse, puis Micro, puis Autoriser ; sur Mac, voir l'encadré de l'étape 5 |
| « Le micro est déjà utilisé… » | Une visio ou Audacity occupe le micro | Ferme l'autre application |
| « Les fichiers provenant d'Internet peuvent être dangereux », lanceur bloqué | Le ZIP n'a pas été débloqué avant l'extraction | Supprime le dossier extrait, débloque le ZIP (étape 2), puis extrais-le à nouveau |
| La page ne s'ouvre plus | La fenêtre noire (ou le Terminal) a été fermée | Relance le lanceur |
| Le navigateur ne s'ouvre pas tout seul | Navigateur par défaut non défini | Ouvre-le et va sur `http://localhost:8765` (l'adresse s'affiche dans la fenêtre noire) |
| Export très long | Fichier très long, ordinateur lent | Patiente (la barre avance) ou découpe l'histoire en plusieurs fichiers |

**Navigateurs conseillés** : Chrome, Edge ou Firefox récents. Sur Mac, Safari 15 ou plus récent.
