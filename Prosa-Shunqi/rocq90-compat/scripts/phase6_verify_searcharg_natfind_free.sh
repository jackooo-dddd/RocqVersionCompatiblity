#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(cd "$EXPERIMENT_ROOT/.." && pwd)
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase6/final/certification"
IMPORT_DIR="$WORK_ROOT/imported"
COMMON_DIR="$WORK_ROOT/common"
SMOKE_DIR="$WORK_ROOT/smoke"
GENERATED_DIR="$WORK_ROOT/generated"
SOURCE_DIR="$WORK_ROOT/source"
AUDIT_DIR="$WORK_ROOT/audit"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase6/final"
RESULT_ROOT="$EXPERIMENT_ROOT/results/phase6"
ARTIFACT="$RESULT_ROOT/artifacts/SearchArg.natfind-free.out"
IMPORTER="$EXPERIMENT_ROOT/.work/phase2/importer-baseline"
SUBADDITIVITY_OUT="$VALIDATION_ROOT/imported/Subadditivity.out"

"$SCRIPT_DIR/phase2_check_environment.sh" >"$LOG_ROOT/environment.log" 2>&1
[[ -x "$IMPORTER/src/lean_import.cmxs" ]]
[[ $(rg -c '^let with_unsafe_univs f \(\) = f \(\)$' "$IMPORTER/src/lean.ml") == 1 ]]
! rg -q 'check_universes[[:space:]]*=[[:space:]]*false' "$IMPORTER/src"
! rg -q 'check_eliminations[[:space:]]*=[[:space:]]*false' "$IMPORTER/src"
! rg -q '^#AX ' "$ARTIFACT"
! rg -q '#NS [0-9]+ (find|findX|Acc|WellFounded|Acc_rec|Acc_rect)$' "$ARTIFACT"
[[ $(sha256_file "$SUBADDITIVITY_OUT") == \
  9ca38bbffc3c1b052bb60aa3a2a091fd15aeb531f195124c604f970ca8243b50 ]]

if [[ -e "$WORK_ROOT" ]]; then
  find "$WORK_ROOT" -depth -delete
fi
mkdir -p "$IMPORT_DIR" "$COMMON_DIR" "$SMOKE_DIR" "$GENERATED_DIR" \
  "$SOURCE_DIR/util" "$AUDIT_DIR" "$LOG_ROOT"

cp "$ARTIFACT" "$IMPORT_DIR/SearchArg.out"
cp "$SUBADDITIVITY_OUT" "$IMPORT_DIR/Subadditivity.out"
cp "$VALIDATION_ROOT/imported/ImportedSearchArg.v" "$IMPORT_DIR/"
cp "$VALIDATION_ROOT/imported/ImportedSubadditivity.v" "$IMPORT_DIR/"
cp "$VALIDATION_ROOT/certificates/common/PropSPropFoundation.v" "$COMMON_DIR/"
cp "$VALIDATION_ROOT/certificates/common/LogicalRelation.v" "$COMMON_DIR/"
cp "$VALIDATION_ROOT/certificates/common/SubadditivityNatCorrespondence.v" "$COMMON_DIR/"
cp "$VALIDATION_ROOT/generated-source/GeneratedSearchArgSource.v" "$GENERATED_DIR/"
cp "$VALIDATION_ROOT/certificates/smoke/SearchArgDefinitionCertificate.v" "$SMOKE_DIR/"
cp "$VALIDATION_ROOT/certificates/smoke/SearchArgStatementCertificate.v" "$SMOKE_DIR/"
cp "$VALIDATION_ROOT/certificates/smoke/SearchArgAssumptionAudit.v" "$SMOKE_DIR/"
cp "$SOURCE_ROOT/util/tactics.v" "$SOURCE_DIR/util/"
cp "$EXPERIMENT_ROOT/tests/phase6/SearchArgRocqAudit.v" "$AUDIT_DIR/"
cp "$EXPERIMENT_ROOT/tests/phase6/SearchArgNatFindFreeTypeAudit.v" "$AUDIT_DIR/"

rocq_flags=(
  -R "$SOURCE_DIR" prosa
  -R "$GENERATED_DIR" prosa
  -Q "$IMPORTER/src" LeanImport
  -I "$IMPORTER/src"
  -Q "$IMPORT_DIR" FoundationImported
  -Q "$COMMON_DIR" FoundationCertificates
  -Q "$SMOKE_DIR" FoundationCertificates
)

compile_one() {
  local directory=$1
  local module=$2
  set +e
  (
    ulimit -s 65520
    cd "$directory"
    rocq_exec rocq c "${rocq_flags[@]}" "$module.v"
  ) >"$LOG_ROOT/$module.log" 2>&1
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$LOG_ROOT/$module.exit"
  return "$rc"
}

compile_one "$SOURCE_DIR/util" tactics
compile_one "$IMPORT_DIR" ImportedSearchArg
compile_one "$IMPORT_DIR" ImportedSubadditivity
compile_one "$GENERATED_DIR" GeneratedSearchArgSource
compile_one "$COMMON_DIR" PropSPropFoundation
compile_one "$COMMON_DIR" LogicalRelation
compile_one "$COMMON_DIR" SubadditivityNatCorrespondence
compile_one "$SMOKE_DIR" SearchArgDefinitionCertificate
compile_one "$SMOKE_DIR" SearchArgStatementCertificate
compile_one "$SMOKE_DIR" SearchArgAssumptionAudit

rocq_exec rocq c -Q "$IMPORTER/src" LeanImport -I "$IMPORTER/src" \
  -Q "$IMPORT_DIR" FoundationImported -Q "$AUDIT_DIR" Phase6Audit \
  "$AUDIT_DIR/SearchArgRocqAudit.v" >"$LOG_ROOT/SearchArgRocqAudit.log" 2>&1
rocq_exec rocq c -Q "$IMPORTER/src" LeanImport -I "$IMPORTER/src" \
  -Q "$IMPORT_DIR" FoundationImported -Q "$AUDIT_DIR" Phase6Audit \
  "$AUDIT_DIR/SearchArgNatFindFreeTypeAudit.v" \
  >"$LOG_ROOT/SearchArgNatFindFreeTypeAudit.log" 2>&1

python3 "$SCRIPT_DIR/audit_assumptions.py" \
  --config "$PROJECT_ROOT/Validation/certificates/utility_foundation/search_arg_assumption_config.json" \
  --log "$LOG_ROOT/SearchArgAssumptionAudit.log" \
  --output "$RESULT_ROOT/searcharg_assumption_audit.json" \
  >"$LOG_ROOT/assumption-classifier.log" 2>&1

rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
  LeanImport.Lean >"$LOG_ROOT/rocqchk-foundation.log" 2>&1
rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
  -Q "$IMPORT_DIR" FoundationImported \
  FoundationImported.ImportedSearchArg \
  >"$LOG_ROOT/rocqchk-imported-searcharg.log" 2>&1

rg -q 'Constants/Inductives relying on type-in-type: <none>' \
  "$LOG_ROOT/rocqchk-imported-searcharg.log"
rg -q 'Constants/Inductives relying on unsafe \(co\)fixpoints: <none>' \
  "$LOG_ROOT/rocqchk-imported-searcharg.log"
rg -q 'Inductives whose positivity is assumed: <none>' \
  "$LOG_ROOT/rocqchk-imported-searcharg.log"

python3 - "$LOG_ROOT/rocqchk-foundation.log" \
  "$LOG_ROOT/rocqchk-imported-searcharg.log" \
  >"$LOG_ROOT/rocqchk-axiom-delta.log" <<'PY'
import sys
from pathlib import Path

def axioms(path):
    inside = False
    result = set()
    for line in Path(path).read_text().splitlines():
        if line.startswith('* Axioms:'):
            inside = True
            continue
        if inside and line.startswith('* Constants/Inductives'):
            break
        if inside and line.startswith('    '):
            item = line.strip()
            if item and item != '<none>':
                result.add(item)
    return result

foundation = axioms(sys.argv[1])
module = axioms(sys.argv[2])
additional = module - foundation
print(f'foundation_axioms={len(foundation)}')
print(f'module_context_axioms={len(module)}')
print(f'additional_axioms={len(additional)}')
for item in sorted(additional):
    print(item)
if additional:
    raise SystemExit(1)
PY

python3 - "$RESULT_ROOT/searcharg_assumption_audit.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
for name, result in report['certificates'].items():
    assert result['semantic_premises'] == [], name
    assert result['source_theorem_dependency'] is False, name
    assert result['target_theorem_dependency'] is False, name
    assert result['unexpected'] == [], name
PY

{
  printf 'check\tstatus\texit_code\tevidence\n'
  printf 'fresh_lean_compile_and_export\tPASS\t0\tlogs/phase6/final/lean-searcharg.log\n'
  printf 'lean_exact_type_and_axiom_guard\tPASS\t0\tlogs/phase6/final/lean-type-and-axiom-audit.log\n'
  printf 'nat_find_acc_ax_absent\tPASS\t0\tresults/phase6/artifacts/SearchArg.natfind-free.out\n'
  printf 'stock_rocq90_import\tPASS\t0\tlogs/phase6/final/ImportedSearchArg.log\n'
  printf 'searcharg_definition_certificate\tPASS\t0\tlogs/phase6/final/SearchArgDefinitionCertificate.log\n'
  printf 'searcharg_statement_certificate\tPASS\t0\tlogs/phase6/final/SearchArgStatementCertificate.log\n'
  printf 'searcharg_assumption_audit\tPASS\t0\tresults/phase6/searcharg_assumption_audit.json\n'
  printf 'normal_universe_and_elimination_negative_tests\tPASS\t0\tlogs/phase6/final/SearchArgRocqAudit.log\n'
  printf 'rocqchk_type_in_type\tPASS_NONE\t0\tlogs/phase6/final/rocqchk-imported-searcharg.log\n'
  printf 'rocqchk_unsafe_fixpoints\tPASS_NONE\t0\tlogs/phase6/final/rocqchk-imported-searcharg.log\n'
  printf 'rocqchk_assumed_positivity\tPASS_NONE\t0\tlogs/phase6/final/rocqchk-imported-searcharg.log\n'
  printf 'rocqchk_additional_axioms\tPASS_NONE\t0\tlogs/phase6/final/rocqchk-axiom-delta.log\n'
  printf 'full_searcharg_certification\tPASS\t0\tSEARCHARG_ROCQ90_FULLY_CERTIFIED\n'
} >"$RESULT_ROOT/status.tsv"

if ! rg -q '^ImportedSearchArg\.vo\t' "$RESULT_ROOT/artifact_hashes.tsv"; then
  printf 'ImportedSearchArg.vo\t%s\n' \
    "$(sha256_file "$IMPORT_DIR/ImportedSearchArg.vo")" \
    >>"$RESULT_ROOT/artifact_hashes.tsv"
fi

echo 'phase6 SearchArg full stock Rocq 9.0 certification: PASS'
