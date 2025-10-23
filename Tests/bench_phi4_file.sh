#!/usr/bin/env bash
set -euo pipefail

# ========== Paramètres utilisateur ==========
PORT=5001
HOST="0.0.0.0"
MODEL_FILE="phi-4-Q8_0.gguf"
RUNS=5

KOBOLD_CMD=(koboldcpp "$MODEL_FILE" "$PORT"
  --host "$HOST"
  --threads "$(sysctl -n hw.ncpu)"
  --usemmap
  --gpulayers 28
  --contextsize 12000
  --quantkv 1
)

# ========== Lecture des arguments ==========
# Modes acceptés :
#  - bench_phi4.sh PROMPT_FILE
#  - bench_phi4.sh BENCH_NAME PROMPT_FILE
#  - (sinon le script demandera interactivement)

ARG1="${1-}"
ARG2="${2-}"
BENCH_NAME=""
PROMPT_FILE=""

if [[ -n "${ARG1}" && -z "${ARG2-}" ]]; then
  # 1 seul argument
  if [[ -f "${ARG1}" ]]; then
    PROMPT_FILE="${ARG1}"
    # bench = nom de fichier sans extension
    fname="$(basename -- "${PROMPT_FILE}")"
    BENCH_NAME="${fname%.*}"
  else
    echo "Argument fourni mais ce n'est pas un fichier lisible : ${ARG1}"
    echo "Usage: bash $(basename "$0") [BENCH_NAME] PROMPT_FILE.txt"
    exit 1
  fi
elif [[ -n "${ARG1}" && -n "${ARG2}" ]]; then
  BENCH_NAME="${ARG1}"
  PROMPT_FILE="${ARG2}"
  if [[ ! -f "${PROMPT_FILE}" ]]; then
    echo "Fichier prompt introuvable : ${PROMPT_FILE}"
    exit 1
  fi
fi

# Si non fournis, demander interactivement
if [[ -z "${PROMPT_FILE}" ]]; then
  read -r -p "Chemin du fichier prompt (.txt) : " PROMPT_FILE
fi
if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "Fichier prompt introuvable : ${PROMPT_FILE}"
  exit 1
fi

if [[ -z "${BENCH_NAME}" ]]; then
  # propose le nom de base du fichier
  fname="$(basename -- "${PROMPT_FILE}")"
  default_name="${fname%.*}"
  read -r -p "Nom du bench (suffixe du fichier .md) [${default_name}] : " BENCH_NAME
  BENCH_NAME="${BENCH_NAME:-$default_name}"
fi

# Nettoyage du nom
BENCH_NAME="$(echo "$BENCH_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g')"

TS="$(date +"%Y%m%d_%H%M%S")"
REPORT="${BENCH_NAME}_${TS}.md"

# ========== Dossier temporaire (sera supprimé) ==========
TMPDIR="$(mktemp -d -t koboldbench.XXXXXXXX)"
LOGFILE="${TMPDIR}/kobold.log"

# ========== Démarrage de KoboldCpp ==========
echo "Démarrage de KoboldCpp…"
( "${KOBOLD_CMD[@]}" ) >"$LOGFILE" 2>&1 &
KPID=$!

cleanup() {
  echo "Arrêt de KoboldCpp (pid=$KPID)…"
  kill "$KPID" >/dev/null 2>&1 || true
  rm -rf "$TMPDIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT

# ========== Attente de l’API ==========
echo -n "Attente de http://${HOST}:${PORT}/v1/ "
for i in {1..60}; do
  if curl -s "http://${HOST}:${PORT}/v1/models" >/dev/null 2>&1; then
    break
  fi
  echo -n "."
  sleep 0.5
done
echo ""
echo "API détectée (ou prête)."

# ========== Lecture du prompt depuis fichier ==========
USER_PROMPT="$(cat -- "${PROMPT_FILE}")"

# ========== Utilitaires ==========
ns_time() { date +%s%N; }                                 # nanosecondes
safe_len_chars() { printf "%s" "$1" | wc -m | tr -d ' '; }
safe_len_bytes() { LC_ALL=C printf "%s" "$1" | wc -c | tr -d ' '; }
sha256_text() { printf "%s" "$1" | shasum -a 256 | awk '{print $1}'; }

# ========== Stockage en RAM ==========
declare -a RESPONSES
declare -a HASHES
declare -a ELAPSED_S
declare -a CHARS
declare -a BYTES
declare -a CPS
declare -a BPS

# ========== Appel unique ==========
call_once() {
  local idx="$1"

  local START_NS END_NS ELAPSED
  START_NS="$(ns_time)"

  local JSON
  JSON="$(curl -sS -X POST "http://${HOST}:${PORT}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "model": "local",
  "messages": [
    {"role": "user", "content": $(jq -Rn --arg s "$USER_PROMPT" '$s')}
  ],
  "temperature": 0.75,
  "max_tokens": 10000
}
EOF
)"

  END_NS="$(ns_time)"
  ELAPSED="$(awk -v start="$START_NS" -v end="$END_NS" 'BEGIN { printf "%.6f", (end-start)/1000000000 }')"

  local TEXT
  TEXT="$(printf "%s" "$JSON" | jq -r '.choices[0].message.content // ""')"

  local N_CHARS N_BYTES
  N_CHARS="$(safe_len_chars "$TEXT")"
  N_BYTES="$(safe_len_bytes "$TEXT")"

  local VC VB
  VC="$(awk -v c="$N_CHARS" -v t="$ELAPSED" 'BEGIN { if (t>0) printf "%.2f", c/t; else print "NA"}')"
  VB="$(awk -v b="$N_BYTES" -v t="$ELAPSED" 'BEGIN { if (t>0) printf "%.2f", b/t; else print "NA"}')"

  local H
  H="$(sha256_text "$TEXT")"

  RESPONSES[$idx]="$TEXT"
  HASHES[$idx]="$H"
  ELAPSED_S[$idx]="$ELAPSED"
  CHARS[$idx]="$N_CHARS"
  BYTES[$idx]="$N_BYTES"
  CPS[$idx]="$VC"
  BPS[$idx]="$VB"
}

echo "Exécution de ${RUNS} conversations indépendantes…"
for i in $(seq 1 "$RUNS"); do
  echo "• Run #$i"
  call_once "$i"
done

# ========== Identité des réponses ==========
hash_list=""
for i in $(seq 1 "$RUNS"); do
  hash_list+="${HASHES[$i]}"$'\n'
done
UNIQ_HASHES="$(printf "%s" "$hash_list" | sort -u | wc -l | tr -d ' ')"
ALL_IDENTICAL="NO"
if [[ "$UNIQ_HASHES" -eq 1 ]]; then
  ALL_IDENTICAL="YES"
fi

# ========== Construction du rapport ==========
REPORT_BUF=""
append() {
  local s="${1-}"
  REPORT_BUF+="${s}"$'\n'
}

append "# Rapport Bench KoboldCpp – ${BENCH_NAME} (${TS})"
append
append "**Commande :** \`$(printf "%q " "${KOBOLD_CMD[@]}")\`"
append
append "**Endpoint :** http://${HOST}:${PORT}/v1/chat/completions"
append
append "## Prompt (depuis fichier)"
append
append "**Fichier :** \`${PROMPT_FILE}\`"
append
append '```'
append "$USER_PROMPT"
append '```'
append
append "## Résumé"
append
append "- Runs : **${RUNS}**"
append "- Réponses toutes identiques : **${ALL_IDENTICAL}** (hashs uniques : ${UNIQ_HASHES})"
append "- Mesure du temps : **client-side** (durée réelle de l’appel HTTP) ; vitesses **chars/s** et **bytes/s**"
append
append "## Statistiques par run"
append
append "| Run | Durée (s) | Chars | Bytes | Chars/s | Bytes/s | SHA256 |"
append "|---:|----------:|------:|------:|-------:|--------:|:------|"
for i in $(seq 1 "$RUNS"); do
  append "| ${i} | ${ELAPSED_S[$i]} | ${CHARS[$i]} | ${BYTES[$i]} | ${CPS[$i]} | ${BPS[$i]} | \`${HASHES[$i]}\` |"
done

append
append "## Réponses"
for i in $(seq 1 "$RUNS"); do
  append
  append "### Run ${i}"
  append
  append '```'
  append "${RESPONSES[$i]}"
  append '```'
done

if [[ "$ALL_IDENTICAL" != "YES" ]]; then
  append
  append "## Diffs rapides (Run 1 vs autres)"
  for i in $(seq 2 "$RUNS"); do
    append
    append "### diff: Run 1 vs Run ${i}"
    DIFF_OUT="$(diff -u <(printf "%s" "${RESPONSES[1]}") <(printf "%s" "${RESPONSES[$i]}") || true)"
    append
    append '```diff'
    append "$DIFF_OUT"
    append '```'
  done
fi

append
append "## Notes"
append "- Aucun fichier intermédiaire conservé. Ce rapport est autosuffisant."
append "- Pour tokens/s : activer des logs KoboldCpp utilisables, ou tokenizer local pour post-traiter."

printf "%s" "$REPORT_BUF" > "$REPORT"
echo
echo "Rapport enregistré : $REPORT"
echo "(Suppression des temporaires…)"
# cleanup via trap
exit 0
