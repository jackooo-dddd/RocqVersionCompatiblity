#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

WORK_ROOT="$EXPERIMENT_ROOT/.work/phase3"
IMPORTER="$EXPERIMENT_ROOT/.work/phase2/importer-baseline"
ARTIFACT="$EXPERIMENT_ROOT/results/phase3/artifacts/SearchArg.acc-free.out"
CASE_ROOT="$WORK_ROOT/verified-import"
AUDIT_ROOT="$WORK_ROOT/verified-audit"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase3"
STATUS="$EXPERIMENT_ROOT/results/phase3/searcharg_acc_free_status.tsv"

"$SCRIPT_DIR/phase2_check_environment.sh" >/dev/null
[[ -x "$IMPORTER/src/lean_import.cmxs" ]]
[[ $(rg -c '^let with_unsafe_univs f \(\) = f \(\)$' "$IMPORTER/src/lean.ml") == 1 ]]
! rg -q 'check_universes = false' "$IMPORTER/src/lean.ml"
[[ $(sha256_file "$ARTIFACT") == \
  4568d291048e5f9bf14678b6012c0633b4fb16e84d04bb7c495823a4934cc3be ]]
! rg -q '^#AX ' "$ARTIFACT"
! rg -q '(^|[^A-Za-z])(Acc|WellFounded|Acc_rec|Acc_rect)([^A-Za-z]|$)' "$ARTIFACT"

for path in "$CASE_ROOT" "$AUDIT_ROOT"; do
  if [[ -e "$path" ]]; then find "$path" -depth -delete; fi
  mkdir -p "$path"
done
cp "$ARTIFACT" "$CASE_ROOT/SearchArg.out"
cp "$EXPERIMENT_ROOT/validation/imported/ImportedSearchArg.v" "$CASE_ROOT/"
cp "$EXPERIMENT_ROOT/tests/phase3/SearchArgRocqAudit.v" "$AUDIT_ROOT/"

(
  ulimit -s 65520
  cd "$CASE_ROOT"
  rocq_exec rocq c -Q "$IMPORTER/src" LeanImport -I "$IMPORTER/src" \
    -Q "$CASE_ROOT" Phase3Imported ImportedSearchArg.v
) >"$LOG_ROOT/stock-import.log" 2>&1

rocq_exec rocq c -Q "$IMPORTER/src" LeanImport -I "$IMPORTER/src" \
  -Q "$CASE_ROOT" Phase3Imported -Q "$AUDIT_ROOT" Phase3Audit \
  "$AUDIT_ROOT/SearchArgRocqAudit.v" >"$LOG_ROOT/rocq-interface-audit.log" 2>&1

rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
  LeanImport.Lean >"$LOG_ROOT/rocqchk-foundation.log" 2>&1
rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
  -Q "$CASE_ROOT" Phase3Imported Phase3Imported.ImportedSearchArg \
  >"$LOG_ROOT/rocqchk-proof-complete.log" 2>&1

rg -q 'Constants/Inductives relying on type-in-type: <none>' \
  "$LOG_ROOT/rocqchk-proof-complete.log"
rg -q 'Constants/Inductives relying on unsafe \(co\)fixpoints: <none>' \
  "$LOG_ROOT/rocqchk-proof-complete.log"
rg -q 'Inductives whose positivity is assumed: <none>' \
  "$LOG_ROOT/rocqchk-proof-complete.log"

python3 - "$LOG_ROOT/rocqchk-foundation.log" \
  "$LOG_ROOT/rocqchk-proof-complete.log" >"$LOG_ROOT/rocqchk-axiom-delta.log" <<'PY'
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

{
  printf 'check\tstatus\n'
  printf 'acc_dependency_absent\tPASS\n'
  printf 'stock_rocq90_import\tPASS\n'
  printf 'lean_type_defeq_and_refl_guards\tPASS\n'
  printf 'rocq_interface_audit\tPASS\n'
  printf 'rocqchk_type_in_type\tPASS_NONE\n'
  printf 'rocqchk_unsafe_fixpoints\tPASS_NONE\n'
  printf 'rocqchk_assumed_positivity\tPASS_NONE\n'
  printf 'rocqchk_additional_axioms\tPASS_NONE\n'
  printf 'existing_searcharg_certificates\tBLOCKED\n'
} >"$STATUS"

echo 'phase3 SearchArg Acc-free stock Rocq verification: PASS'
