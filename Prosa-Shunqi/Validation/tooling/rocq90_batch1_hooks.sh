#!/usr/bin/env bash

# Formal Rocq 9.0 Batch 1 hooks. All inputs are declared below or in the
# associated descriptor.

VALIDATION_PREPARE_INPUTS=(
  "$VALIDATION_ROOT/tooling/rocq90_batch1_descriptor.json"
  "$VALIDATION_ROOT/tooling/rocq90_batch1_hooks.sh"
  "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py"
  "$VALIDATION_ROOT/fixtures/rocq90_batch1/Batch1ArtifactAudit.lean"
)
VALIDATION_CHECK_INPUTS=(
  "$VALIDATION_ROOT/scripts/audit_assumptions.py"
  "$VALIDATION_ROOT/scripts/audit_foundation_slice_1_assumptions.py"
)
while IFS= read -r certificate_input; do
  VALIDATION_CHECK_INPUTS+=("$certificate_input")
done < <(find \
  "$VALIDATION_ROOT/certificates/common" \
  "$VALIDATION_ROOT/certificates/foundation_slice_1" \
  "$VALIDATION_ROOT/certificates/foundation_slice_2" \
  "$VALIDATION_ROOT/certificates/foundation_slice_2_closure" \
  "$VALIDATION_ROOT/certificates/utility_foundation" \
  -type f \( -name '*.v' -o -name '*assumption_config.json' \) | sort)

batch_modules=(
  Time Tactics Notation Rel Seqset Subadditivity Supremum Nat UnitGrowth SearchArg
)
batch_counts=(2 2 1 3 3 6 7 2 12 8)
batch_lean_paths=(
  Prosa/Behavior/Time Prosa/Util/Tactics Prosa/Util/Notation Prosa/Util/Rel
  Prosa/Util/Seqset Prosa/Util/Subadditivity Prosa/Util/Supremum Prosa/Util/Nat
  Prosa/Util/UnitGrowth Prosa/Util/SearchArg
)
batch_source_paths=(
  behavior/time.v util/tactics.v util/notation.v util/rel.v util/seqset.v
  util/subadditivity.v util/supremum.v util/nat.v util/unit_growth.v util/search_arg.v
)
batch_targets=(
  $'Prosa.Behavior.Time.duration\nProsa.Behavior.Time.instant'
  $'Prosa.Util.Tactics.neqP\nProsa.Util.Tactics.modusponens'
  'Prosa.Util.Notation.constant'
  $'Prosa.Util.Rel.monotone\nProsa.Util.Rel.total_over_list\nProsa.Util.Rel.antisymmetric_over_list'
  $'Prosa.Util.Seqset.set\nProsa.Util.Seqset.set_of\nProsa.Util.Seqset.set_uniq'
  $'Prosa.Util.Subadditivity.subadditive_at\nProsa.Util.Subadditivity.subadditive_until\nProsa.Util.Subadditivity.subadditive\nProsa.Util.Subadditivity.subadditive_standard\nProsa.Util.Subadditivity.subadditive_standard_equivalence\nProsa.Util.Subadditivity.subadditive_leq_mul'
  $'Prosa.Util.Supremum.choose_superior\nProsa.Util.Supremum.supremum\nProsa.Util.Supremum.supremum_unfold\nProsa.Util.Supremum.supremum_exists\nProsa.Util.Supremum.supremum_none\nProsa.Util.Supremum.supremum_in\nProsa.Util.Supremum.supremum_spec'
  $'Nat.sub\nNat.pred\nNat.add\ninstSubNat\ninstAddNat\ninstLENat\nLE.le'
  $'Prosa.Util.UnitGrowth.unit_growth_function\nProsa.Util.UnitGrowth.slowed\nProsa.Util.UnitGrowth.slowed.eq_1\nProsa.Util.UnitGrowth.slowed.eq_2\nProsa.Util.Rel.monotone\nHSub.hSub\ninstHSub\nNat.sub\nNat.pred\ninstSubNat\nLT.lt\ninstLTNat\nDecidable.decide\nExists\nExists.intro'
  $'Prosa.Util.SearchArg.search_arg\nProsa.Util.SearchArg.search_arg.eq_1\nProsa.Util.SearchArg.search_arg.eq_2\nProsa.Util.SearchArg.prop_on_ex_minn\nIff\nIff.intro\nIff.mp\nIff.mpr'
)

batch_rocq_compile() {
  local work=$1 directory=$2 source_file=$3
  shift 3
  (
    ulimit -s 65520
    cd "$directory"
    validation_rocq90_exec rocq c \
      -R "$work/source" prosa \
      -Q "$IMPORTER_ROOT/src" LeanImport -I "$IMPORTER_ROOT/src" \
      -Q "$work/imported" FoundationImported \
      "$@" "$source_file"
  )
}

validation_prepare_lean_build() {
  mkdir -p "$VALIDATION_PREPARED/olean/Prosa/Behavior" \
    "$VALIDATION_PREPARED/olean/Prosa/Util" \
    "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch1"
  local path stem
  for path in "${batch_lean_paths[@]}"; do
    if rg -n '\b(sorry|axiom|unsafe)\b' "$PROJECT_ROOT/$path.lean"; then
      echo "forbidden production proof escape: $path.lean" >&2
      return 1
    fi
    stem=${path##*/}
    validation_compile_lean_module "$VALIDATION_PREPARED" "$path" \
      >"$VALIDATION_RUN_LOG/fresh_${stem}.log" 2>&1
  done
  lean -DautoImplicit=false -R "$PROJECT_ROOT" \
    -o "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch1/Batch1ArtifactAudit.olean" \
    "$VALIDATION_ROOT/fixtures/rocq90_batch1/Batch1ArtifactAudit.lean" \
    >"$VALIDATION_PREPARED/lean_artifact_audit.log" 2>&1
  [[ $(rg -c 'TYPE_DEF_EQ_OK target=' \
      "$VALIDATION_PREPARED/lean_artifact_audit.log") == 46 ]]
  rg -q 'BATCH1_ACTUAL_ARTIFACT_GUARDS_OK count=46' \
    "$VALIDATION_PREPARED/lean_artifact_audit.log"

  local fixture label config
  while IFS='|' read -r label fixture config; do
    lean -DautoImplicit=false "$fixture" \
      >"$VALIDATION_PREPARED/lean_${label}_audit.log" 2>&1
    if [[ -n "$config" ]]; then
      python3 "$VALIDATION_ROOT/scripts/audit_lean_axioms.py" \
        --config "$config" \
        --log "$VALIDATION_PREPARED/lean_${label}_audit.log" \
        --output "$VALIDATION_PREPARED/lean_${label}_axioms.json" \
        >"$VALIDATION_RUN_LOG/lean_${label}_classifier.log" 2>&1
    fi
  done <<EOF
time|$VALIDATION_ROOT/fixtures/foundation_slice_1/LeanDeclarationAudit.lean|
slice2|$VALIDATION_ROOT/fixtures/foundation_slice_2/ProductionDeclarationAudit.lean|$VALIDATION_ROOT/fixtures/foundation_slice_2/production_axiom_config.json
nat|$VALIDATION_ROOT/fixtures/utility_foundation/LeanNatAudit.lean|$VALIDATION_ROOT/fixtures/utility_foundation/nat_axiom_config.json
unit_growth|$VALIDATION_ROOT/fixtures/utility_foundation/LeanUnitGrowthAudit.lean|$VALIDATION_ROOT/fixtures/utility_foundation/unit_growth_axiom_config.json
search_arg|$VALIDATION_ROOT/fixtures/utility_foundation/LeanSearchArgAudit.lean|$VALIDATION_ROOT/fixtures/utility_foundation/search_arg_axiom_config.json
EOF
  VALIDATION_STAGE_OUTPUTS=(
    "artifact_audit=$VALIDATION_PREPARED/lean_artifact_audit.log"
    "artifact_audit_olean=$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch1/Batch1ArtifactAudit.olean"
  )
  for path in "${batch_lean_paths[@]}"; do
    stem=${path##*/}
    VALIDATION_STAGE_OUTPUTS+=(
      "${stem}_olean=$VALIDATION_PREPARED/olean/$path.olean")
  done
  for label in slice2 nat unit_growth search_arg; do
    VALIDATION_STAGE_OUTPUTS+=(
      "${label}_lean_axioms=$VALIDATION_PREPARED/lean_${label}_axioms.json")
  done
}

validation_prepare_source_acquisition() {
  mkdir -p "$VALIDATION_PREPARED/source/behavior" "$VALIDATION_PREPARED/source/util"
  local source_path
  for source_path in "${batch_source_paths[@]}"; do
    cp "$SOURCE_ROOT/$source_path" "$VALIDATION_PREPARED/source/$source_path"
    cmp -s "$SOURCE_ROOT/$source_path" "$VALIDATION_PREPARED/source/$source_path"
  done
  for source_path in "${batch_source_paths[@]}"; do
    (
      ulimit -s 65520
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$source_path"
    ) >"$VALIDATION_RUN_LOG/official_${source_path//\//_}.log" 2>&1
  done

  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/unit_growth.v \
    --module GeneratedUnitGrowthSource \
    --declarations unit_growth_function,unit_growth_function_k_steps_bounded,exists_intermediate_point,exists_intermediate_point_leq,exists_first_intermediate_point,slowed,slowed_respects_pointwise_leq,slowed_is_unit_step,slowed_respects_monotone,slowed_never_exceeds,bound_preserved_under_slowed,slowed_subtraction_value_preservation \
    --computational unit_growth_function,slowed \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.unit_growth \
    --output "$VALIDATION_PREPARED/source/GeneratedUnitGrowthSource.v" \
    --metadata "$VALIDATION_PREPARED/source/unit_growth_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/unit_growth_source_extraction.log" 2>&1
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/search_arg.v \
    --module GeneratedSearchArgSource \
    --declarations earliest_pred_element_exists_case,search_arg,search_arg_none,search_arg_not_none,search_arg_pred,search_arg_in_range,search_arg_extremum,prop_on_ex_minn \
    --computational search_arg \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.search_arg \
    --output "$VALIDATION_PREPARED/source/GeneratedSearchArgSource.v" \
    --metadata "$VALIDATION_PREPARED/source/search_arg_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/search_arg_source_extraction.log" 2>&1
  for source_path in GeneratedUnitGrowthSource GeneratedSearchArgSource; do
    (
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$source_path.v"
    ) >"$VALIDATION_RUN_LOG/generated_${source_path}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "unit_growth_generated_vo=$VALIDATION_PREPARED/source/GeneratedUnitGrowthSource.vo"
    "search_arg_generated_vo=$VALIDATION_PREPARED/source/GeneratedSearchArgSource.vo"
    "unit_growth_source_metadata=$VALIDATION_PREPARED/source/unit_growth_source_extraction.json"
    "search_arg_source_metadata=$VALIDATION_PREPARED/source/search_arg_source_extraction.json"
  )
  for source_path in "${batch_source_paths[@]}"; do
    stem=${source_path##*/}
    stem=${stem%.v}
    VALIDATION_STAGE_OUTPUTS+=(
      "${stem}_source_vo=$VALIDATION_PREPARED/source/${source_path%.v}.vo")
  done
}

validation_prepare_export() {
  mkdir -p "$VALIDATION_PREPARED/imported"
  unset LEAN4EXPORT_STATEMENT_ONLY LEAN4EXPORT_NORMALIZE_THEOREM_TYPES \
    LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS \
    LEAN4EXPORT_NORMALIZE_DEFINITION_BODIES \
    LEAN4EXPORT_DEFINITION_BODY_PROJECTIONS || true
  local i module module_path targets target
  local -a target_args
  for i in "${!batch_modules[@]}"; do
    module=${batch_modules[$i]}
    module_path=${batch_lean_paths[$i]//\//.}
    targets=${batch_targets[$i]}
    export LEAN4EXPORT_BODY_THEOREMS="$targets"
    target_args=()
    while IFS= read -r target; do
      target_args+=("$target")
    done <<<"$targets"
    "$EXPORTER_ROOT/.lake/build/bin/lean4export" "$module_path" -- \
      "${target_args[@]}" >"$VALIDATION_PREPARED/imported/$module.out" \
      2>"$VALIDATION_RUN_LOG/export_${module}.log"
    [[ -s "$VALIDATION_PREPARED/imported/$module.out" ]]
  done
  ! rg -q '#NS [0-9]+ (Acc|WellFounded|Acc_rec|Acc_rect|find|findX)$' \
    "$VALIDATION_PREPARED/imported/SearchArg.out"
  python3 - "$VALIDATION_PREPARED" "${batch_modules[@]}" <<'PY'
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
rows = {}
expected = {
    'Time': [],
    'Tactics': ['propext'],
    'Notation': [],
    'Rel': [],
    'Seqset': [],
    'Subadditivity': ['propext'],
    'Supremum': ['propext'],
    'Nat': [],
    'UnitGrowth': [],
    'SearchArg': [],
}
for name in sys.argv[2:]:
    p = root / 'imported' / f'{name}.out'
    lines = p.read_text().splitlines()
    namespace = {}
    for line in lines:
        fields = line.split()
        if len(fields) == 4 and fields[1] == '#NS':
            namespace[fields[0]] = (fields[2], fields[3])
    def qualified_name(index):
        parts = []
        while index in namespace:
            index, part = namespace[index]
            parts.append(part)
        return '.'.join(reversed(parts))
    foundations = sorted(
        qualified_name(line.split()[1])
        for line in lines if line.startswith('#AX ')
    )
    unexpected = sorted(set(foundations) - set(expected[name]))
    missing = sorted(set(expected[name]) - set(foundations))
    rows[name] = {
        'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
        'lean_foundation_records': foundations,
        'expected_lean_foundation_records': expected[name],
        'unexpected_axiom_records': unexpected,
        'missing_expected_foundation_records': missing,
        'statement_only': False,
    }
    assert not unexpected, f'{name}: unexpected #AX records: {unexpected}'
    assert not missing, f'{name}: missing expected foundation records: {missing}'
(root / 'export_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "export_manifest=$VALIDATION_PREPARED/export_manifest.json"
  )
  for module in "${batch_modules[@]}"; do
    VALIDATION_STAGE_OUTPUTS+=(
      "${module}_export=$VALIDATION_PREPARED/imported/$module.out")
  done
}

validation_prepare_rocq_import() {
  local i module
  for i in "${!batch_modules[@]}"; do
    module=${batch_modules[$i]}
    printf 'From LeanImport Require Import Lean.\n\nLean Import "%s.out".\n' \
      "$module" >"$VALIDATION_PREPARED/imported/Imported${module}.v"
    batch_rocq_compile "$VALIDATION_PREPARED" "$VALIDATION_PREPARED/imported" \
      "Imported${module}.v" >"$VALIDATION_RUN_LOG/import_${module}.log" 2>&1
  done
  python3 - "$VALIDATION_PREPARED" "${batch_modules[@]}" <<'PY'
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
rows = {}
for name in sys.argv[2:]:
    p = root / 'imported' / f'Imported{name}.vo'
    rows[name] = {'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
(root / 'import_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "import_manifest=$VALIDATION_PREPARED/import_manifest.json"
  )
  for module in "${batch_modules[@]}"; do
    VALIDATION_STAGE_OUTPUTS+=(
      "${module}_import=$VALIDATION_PREPARED/imported/Imported${module}.vo")
  done
}

validation_check_setup() {
  cp -R "$VALIDATION_PREPARED/olean/." "$VALIDATION_PHASE_WORK/olean/"
  cp -R "$VALIDATION_PREPARED/source/." "$VALIDATION_PHASE_WORK/source/"
  cp -R "$VALIDATION_PREPARED/imported/." "$VALIDATION_PHASE_WORK/imported/"
  mkdir -p "$VALIDATION_PHASE_WORK/certificates/"{common,fs1,fs2,closure,utility}
  cp "$VALIDATION_ROOT/certificates/common/"{PropSPropFoundation,LogicalRelation,EqTypeCorrespondence,RelListCorrespondence,SeqsetCorrespondence,SubadditivityNatCorrespondence,SupremumTheoremCorrespondence,NatSubCorrespondence,UnitGrowthCorrespondence}.v \
    "$VALIDATION_PHASE_WORK/certificates/common/"
  cp "$VALIDATION_ROOT/certificates/foundation_slice_1/"*.v \
    "$VALIDATION_PHASE_WORK/certificates/fs1/"
  cp "$VALIDATION_ROOT/certificates/foundation_slice_2/"*.v \
    "$VALIDATION_PHASE_WORK/certificates/fs2/"
  cp "$VALIDATION_ROOT/certificates/foundation_slice_2_closure/"*.v \
    "$VALIDATION_PHASE_WORK/certificates/closure/"
  cp "$VALIDATION_ROOT/certificates/utility_foundation/"{Nat,UnitGrowth,SearchArg}*.v \
    "$VALIDATION_PHASE_WORK/certificates/utility/"
  if rg -n '\b(Admitted|admit|Axiom)\b|\bsorry\b' \
      "$VALIDATION_PHASE_WORK/certificates" --glob '*.v' \
      --glob '!PropSPropFoundation.v'; then
    echo 'forbidden certificate proof escape' >&2
    return 1
  fi
  local foundation_axioms
  foundation_axioms=$(rg -n '^Axiom ' \
    "$VALIDATION_PHASE_WORK/certificates/common/PropSPropFoundation.v")
  [[ "$foundation_axioms" == *'Axiom interpret_strict'* ]]
  [[ $(printf '%s\n' "$foundation_axioms" | sed '/^$/d' | wc -l | tr -d ' ') == 1 ]]
}

batch_certificate_compile() {
  local directory=$1 module=$2
  batch_rocq_compile "$VALIDATION_PHASE_WORK" "$directory" "$module.v" \
    -Q "$VALIDATION_PHASE_WORK/certificates/common" FoundationCertificates \
    -Q "$VALIDATION_PHASE_WORK/certificates/fs1" FoundationCertificates \
    -Q "$VALIDATION_PHASE_WORK/certificates/fs2" FoundationCertificates \
    -Q "$VALIDATION_PHASE_WORK/certificates/closure" FoundationCertificates \
    -Q "$VALIDATION_PHASE_WORK/certificates/utility" FoundationCertificates
}

validation_check_certificate_compile() {
  local common="$VALIDATION_PHASE_WORK/certificates/common"
  local fs1="$VALIDATION_PHASE_WORK/certificates/fs1"
  local fs2="$VALIDATION_PHASE_WORK/certificates/fs2"
  local closure="$VALIDATION_PHASE_WORK/certificates/closure"
  local utility="$VALIDATION_PHASE_WORK/certificates/utility"
  local module
  for module in PropSPropFoundation LogicalRelation EqTypeCorrespondence \
    RelListCorrespondence SeqsetCorrespondence SubadditivityNatCorrespondence; do
    batch_certificate_compile "$common" "$module" \
      >"$VALIDATION_RUN_LOG/certificate_${module}.log" 2>&1
  done
  for module in SourceTypeAudit FoundationTimeCertificate AssumptionAudit; do
    batch_certificate_compile "$fs1" "$module" \
      >"$VALIDATION_RUN_LOG/fs1_${module}.log" 2>&1
  done
  for module in SourceTypeAudit NotationCertificate TacticsCertificate \
    RelCertificate SupremumCertificate AssumptionAudit; do
    batch_certificate_compile "$fs2" "$module" \
      >"$VALIDATION_RUN_LOG/fs2_${module}.log" 2>&1
  done
  batch_certificate_compile "$common" SupremumTheoremCorrespondence \
    >"$VALIDATION_RUN_LOG/certificate_SupremumTheoremCorrespondence.log" 2>&1
  for module in TacticsClosureCertificate RelClosureCertificate \
    SeqsetClosureCertificate SubadditivityClosureCertificate \
    SupremumClosureCertificate ClosureAssumptionAudit; do
    batch_certificate_compile "$closure" "$module" \
      >"$VALIDATION_RUN_LOG/closure_${module}.log" 2>&1
  done
  for module in NatSubCorrespondence UnitGrowthCorrespondence; do
    batch_certificate_compile "$common" "$module" \
      >"$VALIDATION_RUN_LOG/certificate_${module}.log" 2>&1
  done
  for module in NatCertificate NatAssumptionAudit UnitGrowthCertificate \
    UnitGrowthAssumptionAudit SearchArgDefinitionCertificate \
    SearchArgStatementCertificate SearchArgNatFindFreeTypeAudit \
    SearchArgAssumptionAudit; do
    batch_certificate_compile "$utility" "$module" \
      >"$VALIDATION_RUN_LOG/utility_${module}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "time_certificate=$fs1/FoundationTimeCertificate.vo"
    "closure_certificate=$closure/ClosureAssumptionAudit.vo"
    "nat_certificate=$utility/NatCertificate.vo"
    "unit_growth_certificate=$utility/UnitGrowthCertificate.vo"
    "search_arg_definition_certificate=$utility/SearchArgDefinitionCertificate.vo"
    "search_arg_statement_certificate=$utility/SearchArgStatementCertificate.vo"
  )
}

validation_check_assumption_audit() {
  local output="$VALIDATION_RUN_LOG/assumption_fs1.json"
  python3 "$VALIDATION_ROOT/scripts/audit_foundation_slice_1_assumptions.py" \
    --log "$VALIDATION_RUN_LOG/fs1_AssumptionAudit.log" --output "$output" \
    >"$VALIDATION_RUN_LOG/assumption_fs1_classifier.log" 2>&1
  local label config log
  while IFS='|' read -r label config log; do
    python3 "$VALIDATION_ROOT/scripts/audit_assumptions.py" \
      --config "$config" --log "$log" \
      --output "$VALIDATION_RUN_LOG/assumption_${label}.json" \
      >"$VALIDATION_RUN_LOG/assumption_${label}_classifier.log" 2>&1
  done <<EOF
slice2|$VALIDATION_ROOT/certificates/foundation_slice_2/assumption_config.json|$VALIDATION_RUN_LOG/fs2_AssumptionAudit.log
closure|$VALIDATION_ROOT/certificates/foundation_slice_2_closure/assumption_config.json|$VALIDATION_RUN_LOG/closure_ClosureAssumptionAudit.log
nat|$VALIDATION_ROOT/certificates/utility_foundation/nat_assumption_config.json|$VALIDATION_RUN_LOG/utility_NatAssumptionAudit.log
unit_growth|$VALIDATION_ROOT/certificates/utility_foundation/unit_growth_assumption_config.json|$VALIDATION_RUN_LOG/utility_UnitGrowthAssumptionAudit.log
search_arg|$VALIDATION_ROOT/certificates/utility_foundation/search_arg_assumption_config.json|$VALIDATION_RUN_LOG/utility_SearchArgAssumptionAudit.log
EOF
  python3 - "$VALIDATION_RUN_LOG" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
fs1 = json.loads((root / 'assumption_fs1.json').read_text())
assert fs1['status'] == 'CERTIFIED'
assert fs1['semantic_premises'] == []
for label in ('slice2', 'closure', 'nat', 'unit_growth', 'search_arg'):
    report = json.loads((root / f'assumption_{label}.json').read_text())
    for name, row in report['certificates'].items():
        assert row['semantic_premises'] == [], (label, name)
        assert row['source_theorem_dependency'] is False, (label, name)
        assert row['target_theorem_dependency'] is False, (label, name)
        assert row['unexpected'] == [], (label, name)
        assert row['status'] in ('CERTIFIED', 'CERTIFIED_WITH_PROP_SPROP_FOUNDATION'), (label, name)
PY

  validation_rocq90_exec rocqchk -silent -o \
    -Q "$IMPORTER_ROOT/src" LeanImport LeanImport.Lean \
    >"$VALIDATION_RUN_LOG/rocqchk_foundation.log" 2>&1
  local module
  for module in "${batch_modules[@]}"; do
    validation_rocq90_exec rocqchk -silent -o \
      -Q "$IMPORTER_ROOT/src" LeanImport \
      -Q "$VALIDATION_PHASE_WORK/imported" FoundationImported \
      "FoundationImported.Imported${module}" \
      >"$VALIDATION_RUN_LOG/rocqchk_${module}.log" 2>&1
    rg -q 'Constants/Inductives relying on type-in-type: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
    rg -q 'Constants/Inductives relying on unsafe \(co\)fixpoints: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
    rg -q 'Inductives whose positivity is assumed: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
  done
  python3 - "$VALIDATION_RUN_LOG" "${batch_modules[@]}" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
modules = sys.argv[2:]
def axioms(path):
    inside = False
    result = set()
    for line in path.read_text().splitlines():
        if line.startswith('* Axioms:'):
            inside = True
            continue
        if inside and line.startswith('* Constants/Inductives'):
            break
        if inside and line.startswith('    '):
            item = line.strip()
            if item and item != '<none>': result.add(item)
    return result
foundation = axioms(root / 'rocqchk_foundation.log')
rows = {}
for module in modules:
    additional = axioms(root / f'rocqchk_{module}.log') - foundation
    expected = {x for x in additional if x.endswith(('.propext', '.Quot_sound', '.Classical_choice'))}
    unexpected = sorted(additional - expected)
    if unexpected:
        raise SystemExit(f'unexpected Rocq axioms for {module}: {unexpected}')
    rows[module] = {
        'type_in_type': [], 'unsafe_fixpoints': [], 'assumed_positivity': [],
        'lean_foundation_axioms': sorted(expected),
        'unexpected_custom_rocq_axioms': unexpected,
    }
(root / 'rocqchk_trust_summary.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "assumption_slice2=$VALIDATION_RUN_LOG/assumption_slice2.json"
    "assumption_closure=$VALIDATION_RUN_LOG/assumption_closure.json"
    "assumption_nat=$VALIDATION_RUN_LOG/assumption_nat.json"
    "assumption_unit_growth=$VALIDATION_RUN_LOG/assumption_unit_growth.json"
    "assumption_search_arg=$VALIDATION_RUN_LOG/assumption_search_arg.json"
    "rocqchk_trust=$VALIDATION_RUN_LOG/rocqchk_trust_summary.json"
  )
}

validation_finalize_publication() {
  local publish="$VALIDATION_ROOT/imported/rocq90_batch1"
  local pipeline="$VALIDATION_ROOT/planning/v06_pipeline"
  mkdir -p "$publish" "$pipeline"
  local i module
  for i in "${!batch_modules[@]}"; do
    module=${batch_modules[$i]}
    cp "$VALIDATION_PREPARED/imported/$module.out" "$publish/$module.out"
    cp "$VALIDATION_PREPARED/imported/Imported${module}.v" "$publish/Imported${module}.v"
    cp "$VALIDATION_PREPARED/imported/Imported${module}.vo" "$publish/Imported${module}.vo"
  done
  python3 - "$PROJECT_ROOT" "$SOURCE_ROOT" "$VALIDATION_PREPARED" \
    "$VALIDATION_RUN_LOG" "$publish/artifact_manifest.json" \
    "$pipeline/rocq90_batch1_status.json" "$VALIDATION_SNAPSHOT_ID" <<'PY'
import hashlib, json, subprocess, sys
from pathlib import Path
project, source, prepared, logs, manifest_out, status_out = map(Path, sys.argv[1:7])
snapshot = sys.argv[7]
names = ['Time','Tactics','Notation','Rel','Seqset','Subadditivity','Supremum','Nat','UnitGrowth','SearchArg']
files = ['behavior/time.v','util/tactics.v','util/notation.v','util/rel.v','util/seqset.v','util/subadditivity.v','util/supremum.v','util/nat.v','util/unit_growth.v','util/search_arg.v']
lean = ['Prosa/Behavior/Time.lean','Prosa/Util/Tactics.lean','Prosa/Util/Notation.lean','Prosa/Util/Rel.lean','Prosa/Util/Seqset.lean','Prosa/Util/Subadditivity.lean','Prosa/Util/Supremum.lean','Prosa/Util/Nat.lean','Prosa/Util/UnitGrowth.lean','Prosa/Util/SearchArg.lean']
counts = [2,2,1,3,3,6,7,2,12,8]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
rows = []
for rank, (name, source_file, lean_file, count) in enumerate(zip(names, files, lean, counts), 1):
    olean = prepared / 'olean' / lean_file.replace('.lean','.olean')
    rows.append({
        'rank': rank, 'file': source_file, 'module': name,
        'authoritative_declarations': count,
        'source_sha256': sha(source / source_file),
        'lean_source_sha256': sha(project / lean_file),
        'fresh_olean_sha256': sha(olean),
        'out_sha256': sha(prepared / 'imported' / f'{name}.out'),
        'vo_sha256': sha(prepared / 'imported' / f'Imported{name}.vo'),
        'import': 'PASS', 'certificates': 'PASS', 'assumption_audit': 'PASS',
        'rocqchk': 'PASS', 'acceptance': 'ACCEPTED_V06_FILE_ROCQ90',
        'semantic_premises': [], 'source_theorem_dependency': False,
        'target_theorem_dependency': False, 'unexpected_assumptions': [],
    })
manifest = {
    'schema_version': 1, 'snapshot_id': snapshot,
    'authoritative_prosa_commit': subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'], text=True).strip(),
    'mathlib_commit': subprocess.check_output(['git','-C',str(project/'.lake/packages/mathlib'),'rev-parse','HEAD'], text=True).strip(),
    'files': rows,
}
manifest_out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
status = {
    'schema_version': 1,
    'classification': 'ROCQ90_FULL_MIGRATION_BATCH1_ACCEPTED',
    'active_validation_baseline': 'Rocq 9.0.0',
    'snapshot_id': snapshot, 'files_accepted': 10,
    'files_total': 10, 'declarations_accepted': 46,
    'declarations_total': 46, 'translated_but_not_certified': 0,
    'unexpected_assumptions': 0, 'unexpected_custom_rocq_axioms': 0,
    'normal_universe_checking': True, 'normal_elimination_checking': True,
    'type_in_type': 0, 'unsafe_fixpoints': 0, 'assumed_positivity': 0,
    'files': rows,
}
status_out.write_text(json.dumps(status, indent=2, sort_keys=True) + '\n')
PY
  cp "$publish/artifact_manifest.json" "$VALIDATION_RUN_LOG/artifact_manifest.json"
  cp "$pipeline/rocq90_batch1_status.json" "$VALIDATION_RUN_LOG/rocq90_batch1_status.json"
  VALIDATION_STAGE_OUTPUTS=(
    "artifact_manifest=$VALIDATION_RUN_LOG/artifact_manifest.json"
    "batch_status=$VALIDATION_RUN_LOG/rocq90_batch1_status.json"
  )
}
