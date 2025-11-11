# 🎬 QuickCut CLI

> **QuickCut CLI** est un utilitaire en ligne de commande rapide et minimaliste, écrit en **Bash**, permettant de découper des vidéos **sans ré-encodage** grâce à **FFmpeg**.  
> Idéal pour extraire des passages précis (GoPro, iPhone, drone, etc.) tout en **préservant la qualité et les métadonnées d’origine** (dates de création, modification…).

---

## 🧭 Sommaire

1. [🚀 Fonctionnalités](#-fonctionnalités)
2. [⚙️ Prérequis](#️-prérequis)
3. [📦 Installation](#-installation)
4. [💻 Utilisation](#-utilisation)
5. [🧩 Exemple complet](#-exemple-complet)
6. [🧠 Détails techniques](#-détails-techniques)
7. [🛠️ Structure du projet](#️-structure-du-projet)
8. [📜 Licence](#-licence)

---

## 🚀 Fonctionnalités

✅ Découpe ultra-rapide sans ré-encodage (`-c copy`)  
✅ Conservation de la qualité **originale**  
✅ Préservation des **métadonnées temporelles** (date/heure réelles du tournage)  
✅ Exploite **tous les cœurs CPU** du Mac pour accélérer le traitement  
✅ Interface CLI simple, lisible et colorée  
✅ Aucune dépendance exotique (seulement Bash + FFmpeg)  
✅ Compatible macOS, Linux, et WSL  

---

## ⚙️ Prérequis

Avant toute utilisation, assurez-vous que **FFmpeg** est installé :

```bash
brew install ffmpeg
````

ou sous Linux :

```bash
sudo apt install ffmpeg
```

---

## 📦 Installation

Clonez simplement le dépôt :

```bash
git clone https://github.com/<votre-utilisateur>/quickcut-cli.git
cd quickcut-cli
chmod +x quickcut.sh
```

> 💡 Vous pouvez aussi créer un lien symbolique pour l’utiliser partout :

```bash
sudo ln -s ~/quickcut-cli/quickcut.sh /usr/local/bin/quickcut
```

Ensuite, exécutez-le depuis n’importe où :

```bash
quickcut ma_video.mp4
```

---

## 💻 Utilisation

```bash
./quickcut.sh <fichier_video>
```

Le script :

1. Vous demande combien de segments extraire
2. Vous invite à entrer les horodatages de début et de fin
3. Découpe les segments instantanément
4. Conserve les métadonnées de la vidéo d’origine (dates et heures)

---

### 🧩 Exemple complet

```bash
./quickcut.sh GOPR1649.MP4
```

```
🎬  QuickCut — Cutter express (ffmpeg)
Astuce : formats temps acceptés mm:ss ou hh:mm:ss (ex: 0:12, 01:12:03)

📄 Fichier source : /Volumes/NO NAME/DCIM/113GOPRO/GOPR1649.MP4
📂 Dossier sortie (si >1 segment) : /Volumes/NO NAME/DCIM/113GOPRO/GOPR1649_cuts/
🧠 Concurrence : 12 job(s) en parallèle
===================================================

✂️  Nombre de segments à extraire : 3
===================================================
— Segment #1 —
  ⏱️  Début  (ex 0:12 ou 00:00:12) : 01:01
  ⏱️  Fin    (ex 0:17 ou 00:00:17) : 04:16
...
🚀 Lancement des exports en parallèle…
✅ Créé → GOPR1649_part01__01-01-04-16.mp4
```

> Les fichiers sont enregistrés dans le même dossier que la vidéo source, dans un sous-dossier `*_cuts` (sauf si un seul segment).

---

## 🧠 Détails techniques

* **Langage** : Bash (POSIX-compatible)
* **Découpe** : `ffmpeg -ss start -to end -c copy` → pas de recompression
* **Horodatage** : synchronisation automatique des dates Finder et des métadonnées MP4
* **Concurrence** : utilisation automatique de tous les cœurs CPU (`sysctl -n hw.ncpu`)
* **Compatibilité** :

  * macOS (Intel & Apple Silicon)
  * Linux (Debian, Ubuntu, Arch…)
  * Windows via WSL

---

## 🛠️ Structure du projet

```
quickcut-cli/
├── quickcut.sh       # Script principal
├── README.md         # Documentation
└── LICENSE           # Licence libre (MIT)
```

---

## 📜 Licence

Ce projet est distribué sous licence **MIT** — vous êtes libre de l’utiliser, modifier et redistribuer tant que les mentions d’origine sont conservées.

```
MIT License © 2025 Lukas Mauffré
```

---

> 🧡 Si ce projet vous est utile, ⭐️ mettez une étoile sur GitHub pour le soutenir !
