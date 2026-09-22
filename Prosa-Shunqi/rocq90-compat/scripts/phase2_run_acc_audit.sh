#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

WORK_ROOT="$EXPERIMENT_ROOT/.work/phase2"
RESULT_ROOT="$EXPERIMENT_ROOT/results/phase2"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase2/audit"
STATUS="$RESULT_ROOT/acc_audit_status.tsv"
LATEST="$RESULT_ROOT/latest_run_dir.txt"
CANDIDATE_IMPORTER="$WORK_ROOT/importer-candidate"

mkdir -p "$LOG_ROOT" "$RESULT_ROOT"
"$(dirname "$0")/phase2_check_environment.sh"

if [[ ! -f $LATEST ]]; then
  echo "missing $LATEST; run phase2_run_ab_imports.sh first" >&2
  exit 1
fi

RUN_ID=$(cat "$LATEST")
if [[ $RUN_ID == */* ]]; then
  echo "invalid phase2 run id: $RUN_ID" >&2
  exit 1
fi
RUN_ROOT="$WORK_ROOT/runs/$RUN_ID"
SEARCH_ROOT="$RUN_ROOT/candidate/SearchArg"
if [[ ! -f $SEARCH_ROOT/ImportedSearchArg.vo ]]; then
  echo "missing candidate SearchArg result: $SEARCH_ROOT/ImportedSearchArg.vo" >&2
  exit 1
fi

printf 'check\tstatus\texit_code\tlog\n' >"$STATUS"
overall=0

run_check() {
  local name=$1
  shift
  local log="$LOG_ROOT/$name.log"
  local exit_file="$LOG_ROOT/$name.exit"
  local rc
  set +e
  "$@" >"$log" 2>&1
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  if (( rc == 0 )); then
    printf '%s\tPASS\t0\t%s\n' "$name" "${log#"$EXPERIMENT_ROOT/"}" >>"$STATUS"
  else
    printf '%s\tFAIL\t%s\t%s\n' "$name" "$rc" "${log#"$EXPERIMENT_ROOT/"}" >>"$STATUS"
    overall=1
  fi
}

AUDIT_ROOT="$WORK_ROOT/audit"
rm -rf "$AUDIT_ROOT"
mkdir -p "$AUDIT_ROOT"
cp "$EXPERIMENT_ROOT/tests/phase2/SearchArgAccAudit.v" "$AUDIT_ROOT/"

run_check acc_types_and_computation \
  rocq_exec rocq c \
    -Q "$CANDIDATE_IMPORTER/src" LeanImport \
    -I "$CANDIDATE_IMPORTER/src" \
    -Q "$SEARCH_ROOT" Phase2Imported \
    -Q "$AUDIT_ROOT" Phase2Audit \
    "$AUDIT_ROOT/SearchArgAccAudit.v"

run_check typing_flags \
  rocq_exec rocqchk -silent -o \
    -Q "$CANDIDATE_IMPORTER/src" LeanImport \
    -Q "$SEARCH_ROOT" Phase2Imported \
    Phase2Imported.ImportedSearchArg

run_check candidate_patch_scope \
  "$EXPERIMENT_ROOT/tests/phase2/test_candidate_patch_scope.sh"

exit "$overall"
