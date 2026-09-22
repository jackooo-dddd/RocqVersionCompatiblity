#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

LOG_ROOT="$EXPERIMENT_ROOT/logs/certificates"
COMMON_ROOT="$VALIDATION_ROOT/certificates/common"
SMOKE_ROOT="$VALIDATION_ROOT/certificates/smoke"
GENERATED_ROOT="$VALIDATION_ROOT/generated-source"
mkdir -p "$LOG_ROOT"

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
compile_one "$SMOKE_ROOT" FoundationTimeCertificate
compile_one "$SMOKE_ROOT" FoundationTimeAssumptionAudit
compile_one "$SMOKE_ROOT" TacticsCertificate
compile_one "$SMOKE_ROOT" TacticsAssumptionAudit
compile_one "$SMOKE_ROOT" ListSimpleCertificate
compile_one "$SMOKE_ROOT" ListSimpleAssumptionAudit

# These are intentionally attempted and expected to fail closed when their
# prerequisite imported .vo is unavailable because of the Acc blocker.
compile_one "$SMOKE_ROOT" SearchArgDefinitionCertificate
compile_one "$SMOKE_ROOT" SearchArgStatementCertificate
compile_one "$SMOKE_ROOT" SearchArgAssumptionAudit
compile_one "$SMOKE_ROOT" ListLastCertificate
compile_one "$SMOKE_ROOT" ListLast0ConsAudit
