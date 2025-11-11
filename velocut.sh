#!/usr/bin/env bash

# === velocut.sh — découpe rapide de segments vidéo (GoPro friendly) ===
# Usage: ./velocut.sh <video.mp4>
# - Demande le nombre de segments
# - Pour chaque segment: start → end (ex: 0:12, 1:02:03)
# - Exporte des fichiers sans ré-encodage (ultra rapide, qualité identique)

# ----- Couleurs & UI -----
BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RESET="$(printf '\033[0m')"
RED="$(printf '\033[31m')"; GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; CYAN="$(printf '\033[36m')"

banner() {
  echo ""
  echo "${BOLD}🎬  VELOCUT — Cutter express (ffmpeg)${RESET}"
  echo "${DIM}Astuce: formats temps acceptés  mm:ss  ou  hh:mm:ss (ex: 0:12, 01:12:03)${RESET}"
  echo ""
}

die() { echo "${RED}❌ $*${RESET}"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

time_to_seconds() {
  # Supporte "SS", "MM:SS", "HH:MM:SS"
  local t="$1" hh=0 mm=0 ss=0 IFS=:
  read -r a b c <<<"$t"
  if [[ -z "$b" && -z "$c" ]]; then
    ss="$a"
  elif [[ -z "$c" ]]; then
    mm="$a"; ss="$b"
  else
    hh="$a"; mm="$b"; ss="$c"
  fi
  # Nettoyage chiffres
  hh="${hh//[^0-9]/}"; mm="${mm//[^0-9]/}"; ss="${ss//[^0-9]/}"
  echo $((10#$hh*3600 + 10#$mm*60 + 10#$ss))
}

safe_time_for_name() {
  # Remplace ":" par "-" pour un nom de fichier clean
  echo "$1" | tr ':' '-'
}

# ----- Checks -----
banner
have ffmpeg || die "ffmpeg introuvable. Installe-le avec: ${YELLOW}brew install ffmpeg${RESET}"

INPUT="$1"
[[ -n "$INPUT" ]] || die "Usage: ${CYAN}$0 <video.mp4>${RESET}"
[[ -f "$INPUT" ]] || die "Fichier introuvable: ${YELLOW}$INPUT${RESET}"

# Infos chemin
INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
STEM="$(basename "${INPUT_ABS%.*}")"
OUTDIR="$(dirname "$INPUT_ABS")/${STEM}_cuts"
mkdir -p "$OUTDIR"

echo "📄 Fichier source : ${CYAN}$INPUT_ABS${RESET}"
echo "📂 Dossier sortie : ${CYAN}$OUTDIR${RESET}"
echo ""

# Nombre de segments
while true; do
  read -rp "✂️  Nombre de segments à extraire : " NUM
  [[ "$NUM" =~ ^[0-9]+$ ]] && (( NUM > 0 )) && break
  echo "${YELLOW}⚠️  Entre un entier > 0${RESET}"
done

echo ""
echo "${BOLD}OK, on découpe ${NUM} segment(s).${RESET}"

i=1
CREATED=()

while (( i <= NUM )); do
  echo ""
  echo "${BOLD}— Segment #$i —${RESET}"
  read -rp "  ⏱️  Début (ex 0:12 ou 00:00:12) : " START
  read -rp "  ⏱️  Fin    (ex 0:17 ou 00:00:17) : " END

  # Validations simples
  SSEC="$(time_to_seconds "$START")" || SSEC=-1
  ESEC="$(time_to_seconds "$END")"   || ESEC=-1
  if (( SSEC < 0 || ESEC < 0 || ESEC <= SSEC )); then
    echo "${RED}❌ Temps invalides (fin doit être > début). On recommence ce segment.${RESET}"
    continue
  fi

  START_TAG="$(safe_time_for_name "$START")"
  END_TAG="$(safe_time_for_name "$END")"
  OUTFILE="${OUTDIR}/${STEM}_part$(printf '%02d' "$i")__${START_TAG}-${END_TAG}.mp4"

  echo "🚀 Extraction ${CYAN}$START → $END${RESET} → ${GREEN}$(basename "$OUTFILE")${RESET}"
  # -c copy = pas de ré-encodage (rapide, sans perte). -ss/-to AVANT -i = découpe rapide.
  if ffmpeg -hide_banner -loglevel error -y -ss "$START" -to "$END" -i "$INPUT_ABS" -c copy "$OUTFILE"; then
    echo "${GREEN}✅ OK : ${OUTFILE}${RESET}"
    CREATED+=("$OUTFILE")
    i=$((i+1))
  else
    echo "${RED}❌ Échec ffmpeg pour ce segment. Vérifie les temps et réessaie.${RESET}"
  fi
done

echo ""
echo "${BOLD}🎉 Terminé ! Segments créés :${RESET}"
for f in "${CREATED[@]}"; do
  echo "  • ${GREEN}$f${RESET}"
done

echo ""
echo "${DIM}Astuce: glisse ces clips dans Final Cut (import en « laisser à l’emplacement actuel »).${RESET}"
