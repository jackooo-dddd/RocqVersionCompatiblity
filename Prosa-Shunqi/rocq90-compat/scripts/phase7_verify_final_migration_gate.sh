#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(cd "$EXPERIMENT_ROOT/.." && pwd)
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase7/final/certification"
IMPORT_DIR="$WORK_ROOT/imported"
COMMON_DIR="$WORK_ROOT/common"
CERT_DIR="$WORK_ROOT/certificates"
GENERATED_DIR="$WORK_ROOT/generated"
SOURCE_DIR="$WORK_ROOT/source"
AUDIT_DIR="$WORK_ROOT/audit"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase7/final"
RESULT_ROOT="$EXPERIMENT_ROOT/results/phase7"
ARTIFACT_ROOT="$RESULT_ROOT/artifacts"
IMPORTER="$EXPERIMENT_ROOT/.work/phase2/importer-baseline"
SUBADDITIVITY_OUT="$VALIDATION_ROOT/imported/Subadditivity.out"

"$SCRIPT_DIR/phase2_check_environment.sh" >"$LOG_ROOT/environment.log" 2>&1
[[ -x "$IMPORTER/src/lean_import.cmxs" ]]
[[ $(rg -c '^let with_unsafe_univs f \(\) = f \(\)$' "$IMPORTER/src/lean.ml") == 1 ]]
! rg -q 'check_universes[[:space:]]*=[[:space:]]*false' "$IMPORTER/src"
! rg -q 'check_eliminations[[:space:]]*=[[:space:]]*false' "$IMPORTER/src"
[[ $(sha256_file "$SUBADDITIVITY_OUT") == \
  9ca38bbffc3c1b052bb60aa3a2a091fd15aeb531f195124c604f970ca8243b50 ]]

for artifact in ListLast Bigcat; do
  [[ -s "$ARTIFACT_ROOT/$artifact.phase7.out" ]]
  ! rg -q '#NS [0-9]+ (Acc|WellFounded|Acc_rec|Acc_rect|find|findX)$' \
    "$ARTIFACT_ROOT/$artifact.phase7.out"
done

if [[ -e "$WORK_ROOT" ]]; then
  find "$WORK_ROOT" -depth -delete
fi
mkdir -p "$IMPORT_DIR" "$COMMON_DIR" "$CERT_DIR" "$GENERATED_DIR" \
  "$SOURCE_DIR/util" "$AUDIT_DIR" "$LOG_ROOT" "$RESULT_ROOT"

cp "$ARTIFACT_ROOT/ListLast.phase7.out" "$IMPORT_DIR/ListLast.out"
cp "$ARTIFACT_ROOT/Bigcat.phase7.out" "$IMPORT_DIR/Bigcat.out"
cp "$SUBADDITIVITY_OUT" "$IMPORT_DIR/Subadditivity.out"
cp "$PROJECT_ROOT/Validation/fixtures/utility_foundation/ImportedListLast.v" \
  "$IMPORT_DIR/"
cp "$PROJECT_ROOT/Validation/fixtures/translation_order/ImportedBigcat.v" \
  "$IMPORT_DIR/"
cp "$VALIDATION_ROOT/imported/ImportedSubadditivity.v" "$IMPORT_DIR/"

cp "$VALIDATION_ROOT/certificates/common/PropSPropFoundation.v" "$COMMON_DIR/"
cp "$VALIDATION_ROOT/certificates/common/LogicalRelation.v" "$COMMON_DIR/"
cp "$VALIDATION_ROOT/certificates/common/SubadditivityNatCorrespondence.v" \
  "$COMMON_DIR/"
cp "$VALIDATION_ROOT/certificates/common/BigcatCorrespondence.v" "$COMMON_DIR/"

cp "$VALIDATION_ROOT/generated-source/GeneratedListLastSource.v" "$GENERATED_DIR/"
cp "$EXPERIMENT_ROOT/source/util/tactics.v" "$SOURCE_DIR/util/"
cp "$EXPERIMENT_ROOT/source/util/notation.v" "$SOURCE_DIR/util/"
cp "$EXPERIMENT_ROOT/source/util/supremum.v" "$SOURCE_DIR/util/"

declarations='mem_bigcat_nat,mem_bigcat_nat_exists,mem_bigcat_ord,bigcat_nat_uniq,bigcat_nat_filter_eq_filter_bigcat_nat,size_big_nat,mem_bigcat,mem_bigcat_exists,bigcat_filter_eq_filter_bigcat,bigcat_uniq,seq_different_elements_nil,bigcat_seq_uniqK,bigcat_partitions'
python3 "$PROJECT_ROOT/Validation/scripts/extract_v06_semantic_source.py" \
  --source-root "$EXPERIMENT_ROOT/source" --source-file util/bigcat.v \
  --module GeneratedBigcatSource --declarations "$declarations" \
  --elaborated-evidence \
    "$PROJECT_ROOT/Validation/planning/v06_dependency/declaration_type_evidence.json" \
  --qualified-prefix prosa.util.bigcat \
  --drop-import 'Require Export prosa.util.tactics prosa.util.list.' \
  --output "$GENERATED_DIR/GeneratedBigcatSource.v" \
  --metadata "$GENERATED_DIR/bigcat_source_extraction.json" \
  >"$LOG_ROOT/bigcat-source-extraction.log"

cp "$VALIDATION_ROOT/certificates/smoke/ListLastCertificate.v" "$CERT_DIR/"
(cd "$CERT_DIR" && patch --batch --forward -p0 < \
  "$EXPERIMENT_ROOT/tests/phase7/listlast_certificate_rocq90.patch") \
  >"$LOG_ROOT/listlast-certificate-patch.log" 2>&1
cp "$EXPERIMENT_ROOT/tests/phase7/ListLastTypeAudit.v" "$CERT_DIR/"
cp "$EXPERIMENT_ROOT/tests/phase7/ListLastAssumptionAudit.v" "$CERT_DIR/"
cp "$PROJECT_ROOT/Validation/certificates/utility_foundation/BigcatCertificate.v" \
  "$CERT_DIR/"
cp "$PROJECT_ROOT/Validation/certificates/utility_foundation/BigcatTypeAudit.v" \
  "$CERT_DIR/"
cp "$PROJECT_ROOT/Validation/certificates/utility_foundation/BigcatAssumptionAudit.v" \
  "$CERT_DIR/"
cp "$EXPERIMENT_ROOT/tests/phase7/RocqSafetyAudit.v" "$AUDIT_DIR/"

rocq_flags=(
  -R "$SOURCE_DIR" prosa
  -R "$GENERATED_DIR" prosa
  -Q "$IMPORTER/src" LeanImport
  -I "$IMPORTER/src"
  -Q "$IMPORT_DIR" FoundationImported
  -Q "$COMMON_DIR" FoundationCertificates
  -Q "$CERT_DIR" FoundationCertificates
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
compile_one "$SOURCE_DIR/util" notation
compile_one "$SOURCE_DIR/util" supremum
compile_one "$IMPORT_DIR" ImportedSubadditivity
compile_one "$IMPORT_DIR" ImportedListLast
compile_one "$IMPORT_DIR" ImportedBigcat
compile_one "$GENERATED_DIR" GeneratedListLastSource
compile_one "$GENERATED_DIR" GeneratedBigcatSource
compile_one "$COMMON_DIR" PropSPropFoundation
compile_one "$COMMON_DIR" LogicalRelation
compile_one "$COMMON_DIR" SubadditivityNatCorrespondence
compile_one "$COMMON_DIR" BigcatCorrespondence
compile_one "$CERT_DIR" ListLastCertificate
compile_one "$CERT_DIR" ListLastTypeAudit
compile_one "$CERT_DIR" ListLastAssumptionAudit
compile_one "$CERT_DIR" BigcatCertificate
compile_one "$CERT_DIR" BigcatTypeAudit
compile_one "$CERT_DIR" BigcatAssumptionAudit
compile_one "$AUDIT_DIR" RocqSafetyAudit

python3 "$SCRIPT_DIR/audit_assumptions.py" \
  --config "$EXPERIMENT_ROOT/tests/phase7/listlast_assumption_config.json" \
  --log "$LOG_ROOT/ListLastAssumptionAudit.log" \
  --output "$RESULT_ROOT/listlast_assumption_audit.json" \
  >"$LOG_ROOT/listlast-assumption-classifier.log" 2>&1
python3 "$SCRIPT_DIR/audit_assumptions.py" \
  --config "$PROJECT_ROOT/Validation/certificates/utility_foundation/bigcat_assumption_config.json" \
  --log "$LOG_ROOT/BigcatAssumptionAudit.log" \
  --output "$RESULT_ROOT/bigcat_assumption_audit.json" \
  >"$LOG_ROOT/bigcat-assumption-classifier.log" 2>&1

python3 - "$RESULT_ROOT/listlast_assumption_audit.json" \
  "$RESULT_ROOT/bigcat_assumption_audit.json" <<'PY'
import json
import sys
from pathlib import Path

for path in sys.argv[1:]:
    report = json.loads(Path(path).read_text())
    for name, result in report["certificates"].items():
        assert result["semantic_premises"] == [], (path, name)
        assert result["source_theorem_dependency"] is False, (path, name)
        assert result["target_theorem_dependency"] is False, (path, name)
        assert result["unexpected"] == [], (path, name)
PY

rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
  LeanImport.Lean >"$LOG_ROOT/rocqchk-foundation.log" 2>&1
for artifact in ListLast Bigcat; do
  case "$artifact" in
    ListLast) artifact_label=listlast ;;
    Bigcat) artifact_label=bigcat ;;
  esac
  rocq_exec rocqchk -silent -o -Q "$IMPORTER/src" LeanImport \
    -Q "$IMPORT_DIR" FoundationImported \
    "FoundationImported.Imported$artifact" \
    >"$LOG_ROOT/rocqchk-imported-$artifact_label.log" 2>&1
  rg -q 'Constants/Inductives relying on type-in-type: <none>' \
    "$LOG_ROOT/rocqchk-imported-$artifact_label.log"
  rg -q 'Constants/Inductives relying on unsafe \(co\)fixpoints: <none>' \
    "$LOG_ROOT/rocqchk-imported-$artifact_label.log"
  rg -q 'Inductives whose positivity is assumed: <none>' \
    "$LOG_ROOT/rocqchk-imported-$artifact_label.log"
done

python3 - "$LOG_ROOT/rocqchk-foundation.log" \
  "$LOG_ROOT/rocqchk-imported-listlast.log" \
  "$LOG_ROOT/rocqchk-imported-bigcat.log" \
  >"$LOG_ROOT/rocqchk-axiom-delta.log" <<'PY'
import sys
from pathlib import Path

def axioms(path):
    inside = False
    result = set()
    for line in Path(path).read_text().splitlines():
        if line.startswith("* Axioms:"):
            inside = True
            continue
        if inside and line.startswith("* Constants/Inductives"):
            break
        if inside and line.startswith("    "):
            item = line.strip()
            if item and item != "<none>":
                result.add(item)
    return result

foundation = axioms(sys.argv[1])
expected = {
    "listlast": {"FoundationImported.ImportedListLast.propext"},
    "bigcat": {
        "FoundationImported.ImportedBigcat.propext",
        "FoundationImported.ImportedBigcat.Quot_sound",
        "FoundationImported.ImportedBigcat.Classical_choice",
    },
}
for label, path in zip(("listlast", "bigcat"), sys.argv[2:]):
    additional = axioms(path) - foundation
    unexpected = additional - expected[label]
    missing = expected[label] - additional
    print(f"{label}_expected_foundation_axioms={len(expected[label])}")
    print(f"{label}_unexpected_additional_axioms={len(unexpected)}")
    for item in sorted(additional):
        print(f"{label}: {item}")
    if unexpected or missing:
        raise SystemExit(f"axiom delta mismatch for {label}: unexpected={unexpected}, missing={missing}")
PY

"$SCRIPT_DIR/phase6_verify_searcharg_natfind_free.sh" \
  >"$LOG_ROOT/searcharg-phase6-recheck.log" 2>&1
rg -q $'full_searcharg_certification\tPASS\t0\tSEARCHARG_ROCQ90_FULLY_CERTIFIED' \
  "$EXPERIMENT_ROOT/results/phase6/status.tsv"

{
  printf 'artifact\tsha256\n'
  printf 'ImportedListLast.vo\t%s\n' "$(sha256_file "$IMPORT_DIR/ImportedListLast.vo")"
  printf 'ListLastCertificate.vo\t%s\n' "$(sha256_file "$CERT_DIR/ListLastCertificate.vo")"
  printf 'ImportedBigcat.vo\t%s\n' "$(sha256_file "$IMPORT_DIR/ImportedBigcat.vo")"
  printf 'BigcatCertificate.vo\t%s\n' "$(sha256_file "$CERT_DIR/BigcatCertificate.vo")"
} >"$RESULT_ROOT/verification_hashes.tsv"

{
  printf 'case\tcheck\tstatus\tevidence\n'
  printf 'SearchArg\tPhase6 full certification recheck\tPASS\tlogs/phase7/final/searcharg-phase6-recheck.log\n'
  printf 'ListLast\tfresh proof-complete import\tPASS\tlogs/phase7/final/ImportedListLast.log\n'
  printf 'ListLast\tall 15 certificates\tPASS\tlogs/phase7/final/ListLastCertificate.log\n'
  printf 'ListLast\ttype and boundary audit\tPASS\tlogs/phase7/final/ListLastTypeAudit.log\n'
  printf 'ListLast\tassumption audit\tPASS\tresults/phase7/listlast_assumption_audit.json\n'
  printf 'ListLast\trocqchk trust audit\tPASS\tlogs/phase7/final/rocqchk-imported-listlast.log\n'
  printf 'Bigcat\tfresh proof-complete import\tPASS\tlogs/phase7/final/ImportedBigcat.log\n'
  printf 'Bigcat\tall 13 certificates\tPASS\tlogs/phase7/final/BigcatCertificate.log\n'
  printf 'Bigcat\ttype audit\tPASS\tlogs/phase7/final/BigcatTypeAudit.log\n'
  printf 'Bigcat\tassumption audit\tPASS\tresults/phase7/bigcat_assumption_audit.json\n'
  printf 'Bigcat\trocqchk trust audit\tPASS\tlogs/phase7/final/rocqchk-imported-bigcat.log\n'
  printf 'gate\tnormal universe/elimination negative tests\tPASS\tlogs/phase7/final/RocqSafetyAudit.log\n'
  printf 'gate\tunexpected additional Rocq axioms\tPASS_NONE\tlogs/phase7/final/rocqchk-axiom-delta.log\n'
  printf 'gate\tfinal classification\tPASS\tROCQ90_MIGRATION_GATE_PASSED\n'
} >"$RESULT_ROOT/status.tsv"

echo 'phase7 stock Rocq 9.0 representative migration gate: PASS'
