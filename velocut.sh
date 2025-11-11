#!/usr/bin/env bash

# === velocut.sh — découpe rapide de segments vidéo (GoPro friendly) ===
# Usage: ./velocut.sh <video.mp4>
# - Demande le nombre de segments puis start/end pour chacun (UI identique)
# - EXÉCUTION OPTIMISÉE: lance les exports en PARALLÈLE (jusqu'au nb de CPU)
# - Pas de ré-encodage: ultra rapide, qualité identique (-c copy)

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
  hh="${hh//[^0-9]/}"; mm="${mm//[^0-9]/}"; ss="${ss//[^0-9]/}"
  echo $((10#$hh*3600 + 10#$mm*60 + 10#$ss))
}

safe_time_for_name() { echo "$1" | tr ':' '-'; }

# ----- Checks -----
banner
have ffmpeg || die "ffmpeg introuvable. Installe-le avec: ${YELLOW}brew install ffmpeg${RESET}"

INPUT="$1"
[[ -n "$INPUT" ]] || die "Usage: ${CYAN}$0 <video.mp4>${RESET}"
[[ -f "$INPUT" ]] || die "Fichier introuvable: ${YELLOW}$INPUT${RESET}"

INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
STEM="$(basename "${INPUT_ABS%.*}")"
OUTDIR="$(dirname "$INPUT_ABS")/${STEM}_cuts"
LOGDIR="${OUTDIR}/_logs"
mkdir -p "$OUTDIR" "$LOGDIR"

# Concurrence auto: utilise 100% des CPU dispo
MAXJOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
(( MAXJOBS < 1 )) && MAXJOBS=1

echo "📄 Fichier source : ${CYAN}$INPUT_ABS${RESET}"
echo "📂 Dossier sortie : ${CYAN}$OUTDIR${RESET}"
echo "🧠 Concurrence    : ${CYAN}${MAXJOBS} job(s) en parallèle${RESET}"
echo ""

# Nombre de segments
while true; do
  read -rp "✂️  Nombre de segments à extraire : " NUM
  [[ "$NUM" =~ ^[0-9]+$ ]] && (( NUM > 0 )) && break
  echo "${YELLOW}⚠️  Entre un entier > 0${RESET}"
done
echo ""
echo "${BOLD}OK, on prépare ${NUM} segment(s).${RESET}"

# On collecte d'abord tous les segments (UI identique), puis on lance en parallèle
declare -a STARTS ENDS OUTFILES
i=1
while (( i <= NUM )); do
  echo ""
  echo "${BOLD}— Segment #$i —${RESET}"
  read -rp "  ⏱️  Début (ex 0:12 ou 00:00:12) : " START
  read -rp "  ⏱️  Fin    (ex 0:17 ou 00:00:17) : " END

  SSEC="$(time_to_seconds "$START")" || SSEC=-1
  ESEC="$(time_to_seconds "$END")"   || ESEC=-1
  if (( SSEC < 0 || ESEC < 0 || ESEC <= SSEC )); then
    echo "${RED}❌ Temps invalides (fin doit être > début). On recommence ce segment.${RESET}"
    continue
  fi

  START_TAG="$(safe_time_for_name "$START")"
  END_TAG="$(safe_time_for_name "$END")"
  OUTFILE="${OUTDIR}/${STEM}_part$(printf '%02d' "$i")__${START_TAG}-${END_TAG}.mp4"

  STARTS+=("$START")
  ENDS+=("$END")
  OUTFILES+=("$OUTFILE")
  i=$((i+1))
done

echo ""
echo "${BOLD}🚀 Lancement des exports en parallèle…${RESET}"

# Attendre un créneau dans le pool
wait_for_slot() {
  while (( $(jobs -pr | wc -l | tr -d ' ') >= MAXJOBS )); do
    sleep 0.1
  done
}

CREATED=()
for idx in "${!OUTFILES[@]}"; do
  START="${STARTS[$idx]}"
  END="${ENDS[$idx]}"
  OUTFILE="${OUTFILES[$idx]}"
  LOG="${LOGDIR}/$(basename "$OUTFILE").log"

  wait_for_slot
  {
    echo "▶️  $(date)  $START → $END  → $(basename "$OUTFILE")"
    if ffmpeg -nostdin -hide_banner -loglevel error -y -ss "$START" -to "$END" -i "$INPUT_ABS" -c copy "$OUTFILE" 2>>"$LOG"; then
      echo "✅ FIN $(date) $(basename "$OUTFILE")" >>"$LOG"
      printf "%s\0" "$OUTFILE" >> "${LOGDIR}/__created.list"
    else
      echo "❌ ÉCHEC $(date) $(basename "$OUTFILE")" >>"$LOG"
    fi
  } &

  echo "🧵 Job lancé: ${CYAN}$START → $END${RESET} → ${GREEN}$(basename "$OUTFILE")${RESET}"
done

wait  # attend la fin de tous les jobs

# Récup liste des fichiers créés
if [[ -f "${LOGDIR}/__created.list" ]]; then
  while IFS= read -r -d '' f; do CREATED+=("$f"); done < "${LOGDIR}/__created.list"
fi

echo ""
echo "${BOLD}🎉 Terminé ! Segments créés :${RESET}"
if ((${#CREATED[@]}==0)); then
  echo "  ${RED}Aucun segment généré. Consulte les logs: ${LOGDIR}${RESET}"
else
  for f in "${CREATED[@]}"; do
    echo "  • ${GREEN}$f${RESET}"
  done
fi

echo ""
echo "${DIM}Glisse ces clips dans Final Cut (import « laisser à l’emplacement actuel »).${RESET}"
