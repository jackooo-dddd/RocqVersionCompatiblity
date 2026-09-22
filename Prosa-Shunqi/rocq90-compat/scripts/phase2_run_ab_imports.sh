#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

WORK_ROOT="$EXPERIMENT_ROOT/.work/phase2"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase2/imports"
RESULT_ROOT="$EXPERIMENT_ROOT/results/phase2"
STATUS="$RESULT_ROOT/ab_import_status.tsv"
RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)-$$
RUN_ROOT="$WORK_ROOT/runs/$RUN_ID"
mkdir -p "$LOG_ROOT" "$RESULT_ROOT"

if [[ ${PHASE2_SELF_TEST:-0} == 1 ]]; then
  set +e
  false
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$LOG_ROOT/failure-injection.exit"
  (( rc == 0 )) && exit 0
  exit 97
fi

"$(dirname "$0")/phase2_check_environment.sh"
"$(dirname "$0")/phase2_build_importers.sh"

expected_hash() {
  case "$1" in
    Time) echo 8b2354769dc908175b0386f4fb1b2113be48db89164e384fe34b5539264e115a ;;
    Tactics) echo 34140e14c5508cedba1b3e5849c89b51e5ce81c8152f3a161d065bfcfaeafadb ;;
    Subadditivity) echo 9ca38bbffc3c1b052bb60aa3a2a091fd15aeb531f195124c604f970ca8243b50 ;;
    SearchArg) echo 7fb1c0ab15569ef46c73490f847f6cbd393e7bc52d3ab7abc5933cfc762926dd ;;
    ListSimple) echo 033db5ef70e40a66f0547a6af76392d1e7fe64214cff8356029e07a94ba8dd8e ;;
    ListLast) echo 5ab36259a8ad0a8b75ae649da3e01bbb7d6e88a5d34d657f8a12fe70c50f836f ;;
    Bigcat) echo 016cb75c76633ef8b5173867ea87e7019717ffbd23b88aa9f469e126241deedd ;;
    *) return 1 ;;
  esac
}

for module in Time Tactics Subadditivity SearchArg ListSimple ListLast Bigcat; do
  actual=$(sha256_file "$VALIDATION_ROOT/imported/$module.out")
  if [[ $actual != "$(expected_hash "$module")" ]]; then
    echo "$module.out hash mismatch: $actual" >&2
    exit 1
  fi
done

printf 'variant\tmodule\tstatus\texit_code\tout_sha256\tlog\n' >"$STATUS"

record_status() {
  local variant=$1 module=$2 status=$3 rc=$4 log=$5
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$variant" "$module" "$status" "$rc" "$(expected_hash "$module")" \
    "${log#"$EXPERIMENT_ROOT/"}" >>"$STATUS"
}

record_blocked() {
  local variant=$1 module=$2 reason=$3
  local log="$LOG_ROOT/$variant/$module.log"
  mkdir -p "$(dirname "$log")"
  printf 'BLOCKED: %s\n' "$reason" >"$log"
  record_status "$variant" "$module" BLOCKED BLOCKED "$log"
}

run_import() {
  local variant=$1 module=$2
  local importer="$WORK_ROOT/importer-$variant"
  local case_root="$RUN_ROOT/$variant/$module"
  local log="$LOG_ROOT/$variant/$module.log"
  local exit_file="$LOG_ROOT/$variant/$module.exit"
  local rc

  mkdir -p "$case_root" "$(dirname "$log")"
  cp "$VALIDATION_ROOT/imported/Imported$module.v" "$case_root/"
  ln -sf "$VALIDATION_ROOT/imported/$module.out" "$case_root/$module.out"

  set +e
  (
    # Large exports recurse deeply in the importer. Keep this process-local;
    # macOS otherwise defaults to an 8 MiB stack and reports SIGSEGV on guard.
    ulimit -s 65520
    cd "$case_root"
    rocq_exec rocq c \
      -Q "$importer/src" LeanImport \
      -I "$importer/src" \
      -Q "$case_root" Phase2Imported \
      "Imported$module.v"
  ) >"$log" 2>&1
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  return "$rc"
}

overall=0

if run_import baseline Time; then
  record_status baseline Time PASS 0 "$LOG_ROOT/baseline/Time.log"
else
  rc=$?
  record_status baseline Time FAIL "$rc" "$LOG_ROOT/baseline/Time.log"
  overall=1
fi

if run_import baseline SearchArg; then
  record_status baseline SearchArg UNEXPECTED_PASS 0 "$LOG_ROOT/baseline/SearchArg.log"
  overall=1
else
  rc=$?
  if rg -q 'Acc|squash|Assertion failed' "$LOG_ROOT/baseline/SearchArg.log"; then
    record_status baseline SearchArg EXPECTED_FAILURE "$rc" "$LOG_ROOT/baseline/SearchArg.log"
  else
    record_status baseline SearchArg FAIL_DIFFERENTLY "$rc" "$LOG_ROOT/baseline/SearchArg.log"
    overall=1
  fi
fi

if run_import candidate SearchArg; then
  record_status candidate SearchArg PASS 0 "$LOG_ROOT/candidate/SearchArg.log"
  for module in ListLast Bigcat Time Tactics Subadditivity ListSimple; do
    if run_import candidate "$module"; then
      record_status candidate "$module" PASS 0 "$LOG_ROOT/candidate/$module.log"
    else
      rc=$?
      record_status candidate "$module" FAIL "$rc" "$LOG_ROOT/candidate/$module.log"
      overall=1
    fi
  done
else
  rc=$?
  record_status candidate SearchArg FAIL "$rc" "$LOG_ROOT/candidate/SearchArg.log"
  overall=1
  for module in ListLast Bigcat Time Tactics Subadditivity ListSimple; do
    record_blocked candidate "$module" 'SearchArg candidate import did not pass'
  done
fi

printf '%s\n' "$RUN_ID" >"$RESULT_ROOT/latest_run_dir.txt"
exit "$overall"
