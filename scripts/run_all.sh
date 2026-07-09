#!/usr/bin/env bash
# run_all.sh — run the Rate-F0 pipeline end to end, in CLAUDE.md order:
#   0. src/diagnose_data.py        pre-extraction health check
#   1. src/build_dataset.py        extract -> filter -> features -> master_csv
#   2. src/analysis/02_effect_size.R   effect-size diagnosis (1st milestone)
#   3. src/analysis/01_fit_models.R    GAMM fits (DV = landmark excursion)
#   4. src/analysis/03_figures.R       paper figures
#   5. src/analysis/04_robustness.R    excursion-definition robustness
#   6. src/analysis/05_language_test.R  cross-linguistic difference test
#   7. src/analysis/06_accent_nucleus.R accent-nucleus (pitch-target) sub-analysis
#   8. src/analysis/07_language_register.R  Dialogue-vs-Buckeye register-matched test
#   9. src/analysis/08_mundlak.R        within/between decomposition + mechanism
#  10. src/analysis/11_intensity_check.R  intensity-confound control
#  11. src/analysis/12_peak_delay_check.R  ososagari / peak-delay check (CSJ)
#  12. src/analysis/13_mechanism_robustness.R  F0min/F0max robustness (3 checks)
#  13. src/analysis/09_artifact_check.R + 10_landmark_validate.R
#      + src/artifact_gate_lm.py + src/artifact_resample.py  frame-count artifact
#  14. src/analysis/bootstrap_ci.R  speaker-cluster 95% CIs + leave-one-speaker-out
#
# Usage:
#   scripts/run_all.sh                 # full real run
#   scripts/run_all.sh --dummy         # fast smoke: synthetic data through 1->5
#   scripts/run_all.sh --skip-diagnose # skip step 0
#   scripts/run_all.sh --from build    # start at build|effect|...|mechrobust|artifact|bootstrap
#
# Every step must succeed or the script stops (set -e). All console output is
# also teed to results/supplement/run_all.log.

set -euo pipefail

# --- locate repo root (this script lives in scripts/) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO"

# --- ensure toolchain is on PATH (Homebrew installs uv/Rscript here) ---
command -v uv      >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"
command -v Rscript >/dev/null 2>&1 || export PATH="/opt/homebrew/bin:$PATH"
for tool in uv Rscript; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: '$tool' not found on PATH" >&2; exit 127; }
done

# --- args ---
DUMMY=""; SKIP_DIAGNOSE=0; FROM="diagnose"
while [ $# -gt 0 ]; do
  case "$1" in
    --dummy)         DUMMY="--dummy" ;;
    --skip-diagnose) SKIP_DIAGNOSE=1 ;;
    --from)          FROM="${2:-}"; shift ;;
    -h|--help)       awk 'NR>1 && /^#/{sub(/^# ?/,""); print; next} NR>1{exit}' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# step ordering so --from can pick a start point
declare -a ORDER=(diagnose build effect models figures robust lang accent langreg mundlak intensity peakdelay mechrobust artifact bootstrap)
start_idx=0
for i in "${!ORDER[@]}"; do [ "${ORDER[$i]}" = "$FROM" ] && start_idx=$i; done
should_run() {  # $1 = step name
  local idx=-1; for i in "${!ORDER[@]}"; do [ "${ORDER[$i]}" = "$1" ] && idx=$i; done
  [ "$idx" -ge "$start_idx" ]
}

LOG_DIR="$REPO/results/supplement"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/run_all.log"
exec > >(tee "$LOG") 2>&1

banner() { echo; echo "============================================================"; echo ">>> $*"; echo "============================================================"; }

echo "Rate-F0 pipeline | repo=$REPO | dummy=${DUMMY:-no} | from=$FROM"
START=$(date +%s)

if [ "$SKIP_DIAGNOSE" -eq 0 ] && [ -z "$DUMMY" ] && should_run diagnose; then
  banner "0/14 diagnose_data.py"
  uv run python src/diagnose_data.py
fi

if should_run build; then
  banner "1/14 build_dataset.py ${DUMMY}"
  [ -n "$DUMMY" ] && echo "WARNING: --dummy overwrites ${REPO}/$(grep -m1 master_csv config/config.yaml | sed 's/.*: *//;s/\"//g') with synthetic data"
  uv run python src/build_dataset.py ${DUMMY}
fi

if should_run effect; then
  banner "2/14 02_effect_size.R"
  Rscript src/analysis/02_effect_size.R
fi

if should_run models; then
  banner "3/14 01_fit_models.R (DV=landmark excursion)"
  Rscript src/analysis/01_fit_models.R
fi

if should_run figures; then
  banner "4/14 03_figures.R"
  Rscript src/analysis/03_figures.R
fi

if should_run robust; then
  banner "5/14 04_robustness.R"
  Rscript src/analysis/04_robustness.R
fi

if should_run lang; then
  banner "6/14 05_language_test.R"
  Rscript src/analysis/05_language_test.R
fi

if should_run accent && [ -z "$DUMMY" ]; then
  banner "7/14 06_accent_nucleus.R"
  Rscript src/analysis/06_accent_nucleus.R
fi

if should_run langreg; then
  banner "8/14 07_language_register.R"
  Rscript src/analysis/07_language_register.R
fi

if should_run mundlak; then
  banner "9/14 08_mundlak.R"
  Rscript src/analysis/08_mundlak.R
fi

if should_run intensity; then
  banner "10/14 11_intensity_check.R"
  Rscript src/analysis/11_intensity_check.R
fi

if should_run peakdelay && [ -z "$DUMMY" ]; then
  banner "11/14 peak_delay (extract + 12_peak_delay_check.R)"
  uv run python src/peak_delay_extract.py
  Rscript src/analysis/12_peak_delay_check.R
fi

if should_run mechrobust && [ -z "$DUMMY" ]; then
  banner "12/14 13_mechanism_robustness.R"
  Rscript src/analysis/13_mechanism_robustness.R
fi

if should_run artifact && [ -z "$DUMMY" ]; then
  banner "13/14 frame-count artifact diagnostics (09/10 + gate/resample)"
  Rscript src/analysis/09_artifact_check.R
  Rscript src/analysis/10_landmark_validate.R
  uv run python src/artifact_gate_lm.py
  uv run python src/artifact_resample.py
fi

if should_run bootstrap && [ -z "$DUMMY" ]; then
  banner "14/14 bootstrap_ci.R (speaker-cluster CIs + leave-one-speaker-out)"
  Rscript src/analysis/bootstrap_ci.R
fi

END=$(date +%s)
banner "DONE in $((END - START))s — outputs in results/ (log: $LOG)"
