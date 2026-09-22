#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

LOG_ROOT="$EXPERIMENT_ROOT/logs/certificates"
COMMON_ROOT="$VALIDATION_ROOT/certificates/common"
SMOKE_ROOT="$VALIDATION_ROOT/certificates/smoke"
GENERATED_ROOT="$VALIDATION_ROOT/generated-source"
mkdir -p "$LOG_ROOT"
overall=0

rocq_flags=(
  -R "$SOURCE_ROOT" prosa
  -R "$GENERATED_ROOT" prosa
  -Q "$IMPORTER_ROOT/src" LeanImport
  -I "$IMPORTER_ROOT/src"
  -Q "$VALIDATION_ROOT/imported" FoundationImported
  -Q "$COMMON_ROOT" FoundationCertificates
  -Q "$SMOKE_ROOT" FoundationCertificates
)

compile_one() {
  local directory=$1
  local module=$2
  local log="$LOG_ROOT/${module}.log"
  local exit_file="$LOG_ROOT/${module}.exit"
  set +e
  (
    cd "$directory"
    rocq_exec rocq c "${rocq_flags[@]}" "${module}.v"
  ) >"$log" 2>&1
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$exit_file"
  printf '%-38s exit=%s\n' "$module" "$rc"
  printf '%s\n' "$rc" >"$LOG_ROOT/${module}.state"
  if (( rc != 0 )); then
    overall=1
  fi
}

blocked() {
  local module=$1
  local dependency=$2
  printf 'BLOCKED: dependency %s did not pass\n' "$dependency" \
    >"$LOG_ROOT/${module}.log"
  printf '%s\n' BLOCKED >"$LOG_ROOT/${module}.exit"
  printf '%-38s BLOCKED (%s)\n' "$module" "$dependency"
  printf '%s\n' BLOCKED >"$LOG_ROOT/${module}.state"
  overall=1
}

compile_after() {
  local dependency=$1
  local directory=$2
  local module=$3
  local dependency_state=BLOCKED
  if [[ -f "$LOG_ROOT/${dependency}.state" ]]; then
    dependency_state=$(<"$LOG_ROOT/${dependency}.state")
  fi
  if [[ $dependency_state == 0 ]]; then
    compile_one "$directory" "$module"
  else
    blocked "$module" "$dependency"
  fi
}

# Generated source interfaces are reused verbatim; no extraction occurs here.
compile_one "$GENERATED_ROOT" GeneratedSearchArgSource
compile_one "$GENERATED_ROOT" GeneratedListSimpleSource
compile_one "$GENERATED_ROOT" GeneratedListLastSource

# The time certificate imports the tiny official source module directly.
compile_one "$SOURCE_ROOT/behavior" time

# Shared correspondence foundation needed by the selected certificates.
compile_one "$COMMON_ROOT" PropSPropFoundation
compile_one "$COMMON_ROOT" LogicalRelation
compile_one "$COMMON_ROOT" SubadditivityNatCorrespondence

# Smoke tests whose imported artifacts succeed on Rocq 9.0.
compile_after time "$SMOKE_ROOT" FoundationTimeCertificate
compile_after FoundationTimeCertificate "$SMOKE_ROOT" FoundationTimeAssumptionAudit
compile_one "$SMOKE_ROOT" TacticsCertificate
compile_after TacticsCertificate "$SMOKE_ROOT" TacticsAssumptionAudit
compile_after SubadditivityNatCorrespondence "$SMOKE_ROOT" ListSimpleCertificate
compile_after ListSimpleCertificate "$SMOKE_ROOT" ListSimpleAssumptionAudit

# These are intentionally attempted and expected to fail closed when their
# prerequisite imported .vo is unavailable because of the Acc blocker.
if [[ -f "$VALIDATION_ROOT/imported/ImportedSearchArg.vo" ]]; then
  compile_one "$SMOKE_ROOT" SearchArgDefinitionCertificate
  compile_after SearchArgDefinitionCertificate "$SMOKE_ROOT" SearchArgStatementCertificate
  compile_after SearchArgStatementCertificate "$SMOKE_ROOT" SearchArgAssumptionAudit
else
  blocked SearchArgDefinitionCertificate ImportedSearchArg.vo
  blocked SearchArgStatementCertificate SearchArgDefinitionCertificate
  blocked SearchArgAssumptionAudit SearchArgStatementCertificate
fi

if [[ -f "$VALIDATION_ROOT/imported/ImportedListLast.vo" ]]; then
  compile_one "$SMOKE_ROOT" ListLastCertificate
  compile_after ListLastCertificate "$SMOKE_ROOT" ListLast0ConsAudit
else
  blocked ListLastCertificate ImportedListLast.vo
  blocked ListLast0ConsAudit ListLastCertificate
fi

exit "$overall"
