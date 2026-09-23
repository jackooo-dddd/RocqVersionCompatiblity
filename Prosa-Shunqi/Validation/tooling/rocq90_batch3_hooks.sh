#!/usr/bin/env bash

# Formal stock-Rocq-9.0 migration hooks for authoritative ranks 12--19.
# All runtime evidence is rebuilt under Validation; compatibility experiment
# work directories are never read.

batch3_boundary="$VALIDATION_ROOT/tooling/rocq90_batch3_boundary.json"
batch3_fixture="$VALIDATION_ROOT/fixtures/rocq90_batch3"
batch3_utility_fixture="$VALIDATION_ROOT/fixtures/utility_foundation"
batch3_translation_fixture="$VALIDATION_ROOT/fixtures/translation_order"
batch3_cert_src="$VALIDATION_ROOT/certificates/utility_foundation"
batch3_common_src="$VALIDATION_ROOT/certificates/common"

batch3_modules=(
  SumSequence SumInterval Epsilon Bigop Setoid Poet Bigcat Minmax DivMod
)
batch3_files=(
  util/sum.v util/epsilon.v util/bigop.v util/setoid.v util/poet.v
  util/bigcat.v util/minmax.v util/div_mod.v
)
batch3_lean_modules=(
  Prosa/Util/Sum Prosa/Util/Epsilon Prosa/Util/Bigop Prosa/Util/Setoid
  Prosa/Util/Poet Prosa/Util/Bigcat Prosa/Util/Minmax Prosa/Util/Div_mod
)
batch3_lean_build_modules=(
  Prosa/Behavior/Time Prosa/Util/Tactics Prosa/Util/Notation Prosa/Util/Rel
  Prosa/Util/Seqset Prosa/Util/Subadditivity Prosa/Util/Supremum Prosa/Util/Nat
  Prosa/Util/UnitGrowth Prosa/Util/SearchArg Prosa/Util/List
  Prosa/Util/Sum Prosa/Util/Epsilon Prosa/Util/Bigop Prosa/Util/Setoid
  Prosa/Util/Poet Prosa/Util/Bigcat Prosa/Util/Minmax Prosa/Util/Div_mod
)
batch3_interfaces=(
  Validation/fixtures/utility_foundation/SumSequenceComputationInterface
  Validation/fixtures/utility_foundation/EpsilonInterface
  Validation/fixtures/translation_order/BigopComputationInterface
  Validation/fixtures/translation_order/SetoidComputationInterface
  Validation/fixtures/translation_order/PoetComputationInterface
  Validation/fixtures/translation_order/BigcatComputationInterface
  Validation/fixtures/translation_order/MinmaxComputationInterface
  Validation/fixtures/translation_order/DivModComputationInterface
  Validation/fixtures/rocq90_batch3/Batch3SemanticInterface
)
batch3_assumption_labels=(
  sum_sequence sum_interval epsilon bigop setoid poet bigcat minmax div_mod
)
batch3_assumption_modules=(
  SumSequenceAssumptionAudit SumIntervalAssumptionAudit EpsilonAssumptionAudit
  BigopAssumptionAudit SetoidAssumptionAudit PoetAssumptionAudit
  BigcatAssumptionAudit MinmaxAssumptionAudit DivModAssumptionAudit
)
batch3_compile_order=(
  PropSPropFoundation LogicalRelation TypeSPropRelation
  SubadditivityNatCorrespondence NatSubCorrespondence
  SumSequenceCorrespondence SumIntervalCorrespondence BigopCorrespondence
  SetoidCorrespondence PoetCorrespondence BigcatCorrespondence
  MinmaxCorrespondence SubadditivityClosureCertificate DivModCorrespondence
  SumSequenceCertificate SumIntervalCertificate EpsilonCertificate
  BigopCertificate SetoidCertificate PoetCertificate BigcatCertificate
  MinmaxCertificate DivModCertificate
  SumSequenceTypeAudit SumIntervalTypeAudit BigopTypeAudit SetoidTypeAudit
  PoetTypeAudit BigcatTypeAudit MinmaxTypeAudit DivModTypeAudit
  SumSequenceAssumptionAudit SumIntervalAssumptionAudit EpsilonAssumptionAudit
  BigopAssumptionAudit SetoidAssumptionAudit PoetAssumptionAudit
  BigcatAssumptionAudit MinmaxAssumptionAudit DivModAssumptionAudit
)

VALIDATION_PREPARE_INPUTS=(
  "$VALIDATION_ROOT/tooling/rocq90_batch3_descriptor.json"
  "$VALIDATION_ROOT/tooling/rocq90_batch3_hooks.sh"
  "$batch3_boundary"
  "$batch3_fixture/Batch3SemanticInterface.lean"
  "$VALIDATION_ROOT/scripts/generate_batch3_artifact_audit.py"
  "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py"
)
while IFS= read -r input; do VALIDATION_PREPARE_INPUTS+=("$input"); done < <(
  find "$batch3_utility_fixture" "$batch3_translation_fixture" -type f \
    \( -name '*ComputationInterface.lean' -o -name 'EpsilonInterface.lean' \
       -o -name '*_lean_axiom_config.json' -o -name 'sum_full_axiom_config.json' \
       -o -name 'Lean*Audit.lean' \) | sort
)
for input in "${batch3_lean_build_modules[@]}"; do
  VALIDATION_PREPARE_INPUTS+=("$PROJECT_ROOT/$input.lean")
done
VALIDATION_CHECK_INPUTS=(
  "$VALIDATION_ROOT/scripts/audit_assumptions.py"
  "$VALIDATION_ROOT/scripts/generate_batch3_rocq_type_audits.py"
  "$batch3_fixture/sum_unit_acc_free.patch"
  "$VALIDATION_ROOT/certificates/foundation_slice_2_closure/SubadditivityClosureCertificate.v"
)
while IFS= read -r input; do VALIDATION_CHECK_INPUTS+=("$input"); done < <(
  find "$batch3_common_src" "$batch3_cert_src" -type f \
    \( -name '*.v' -o -name '*assumption_config.json' \
       -o -name '*cluster_config.json' \) | sort
)

batch3_rocq_compile() {
  local directory=$1 source_file=$2
  (
    ulimit -s 65520
    cd "$directory"
    validation_rocq90_exec rocq c \
      -R "$VALIDATION_PHASE_WORK/source" prosa \
      -Q "$IMPORTER_ROOT/src" LeanImport -I "$IMPORTER_ROOT/src" \
      -Q "$VALIDATION_PHASE_WORK/imported" FoundationImported \
      -Q "$VALIDATION_PHASE_WORK/certificates" FoundationCertificates \
      "$source_file"
  )
}

batch3_prepared_rocq_compile() {
  local directory=$1 source_file=$2
  (
    ulimit -s 65520
    cd "$directory"
    validation_rocq90_exec rocq c \
      -R "$VALIDATION_PREPARED/source" prosa \
      -Q "$IMPORTER_ROOT/src" LeanImport -I "$IMPORTER_ROOT/src" \
      -Q "$VALIDATION_PREPARED/imported" FoundationImported \
      "$source_file"
  )
}

validation_prepare_lean_build() {
  local module label fixture config manifest
  for module in "${batch3_lean_build_modules[@]}"; do
    if rg -n '\b(sorry|axiom|unsafe)\b' "$PROJECT_ROOT/$module.lean"; then
      echo "forbidden production proof escape: $module.lean" >&2
      return 1
    fi
    label=${module##*/}
    validation_compile_lean_module "$VALIDATION_PREPARED" "$module" \
      >"$VALIDATION_RUN_LOG/fresh_${label}.log" 2>&1
  done
  for module in "${batch3_interfaces[@]}"; do
    label=${module##*/}
    validation_compile_lean_module "$VALIDATION_PREPARED" "$module" \
      >"$VALIDATION_RUN_LOG/fresh_${label}.log" 2>&1
  done
  rg -q 'NORMALIZED_SEMANTIC_STATEMENT target=' \
    "$VALIDATION_RUN_LOG/fresh_Batch3SemanticInterface.log"
  rg -q 'sumUnit_matches_compiled' \
    "$VALIDATION_RUN_LOG/fresh_Batch3SemanticInterface.log"
  rg -q 'sumUnitStatement_iff_compiled' \
    "$VALIDATION_RUN_LOG/fresh_Batch3SemanticInterface.log"
  if rg -n 'sorryAx|declaration uses .*(sorry|axiom)' \
      "$VALIDATION_RUN_LOG/fresh_Batch3SemanticInterface.log"; then
    echo 'Batch 3 semantic interface introduced an unsupported Lean axiom' >&2
    return 1
  fi

  local generated="$VALIDATION_PREPARED/generated"
  mkdir -p "$generated" \
    "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch3"
  local -a guard_args=()
  for manifest in \
    "$VALIDATION_ROOT/planning/v06_pipeline/utility_foundation_expansion_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/bigop_module_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/setoid_module_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/poet_module_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/bigcat_module_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/minmax_module_manifest.json" \
    "$VALIDATION_ROOT/planning/v06_pipeline/div_mod_module_manifest.json"; do
    guard_args+=(--manifest "$manifest")
  done
  python3 "$VALIDATION_ROOT/scripts/generate_batch3_artifact_audit.py" \
    --inventory "$VALIDATION_ROOT/planning/v06_dependency/declaration_inventory.csv" \
    "${guard_args[@]}" \
    --output "$generated/Batch3ArtifactAudit.lean" \
    --metadata "$generated/type_guard_metadata.json" \
    >"$VALIDATION_RUN_LOG/artifact_audit_generation.log" 2>&1
  lean -DautoImplicit=false -R "$PROJECT_ROOT" \
    -o "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch3/Batch3ArtifactAudit.olean" \
    "$generated/Batch3ArtifactAudit.lean" \
    >"$VALIDATION_PREPARED/lean_artifact_audit.log" 2>&1
  [[ $(rg -c 'TYPE_DEF_EQ_OK target=' \
      "$VALIDATION_PREPARED/lean_artifact_audit.log") == 68 ]]
  rg -q 'BATCH3_ACTUAL_ARTIFACT_GUARDS_OK count=68' \
    "$VALIDATION_PREPARED/lean_artifact_audit.log"

  python3 - "$VALIDATION_ROOT/planning/v06_dependency/declaration_inventory.csv" \
    "$batch3_cert_src" "$VALIDATION_PREPARED/inventory_check.json" <<'PY'
import csv, json, sys
from pathlib import Path
inventory, cert_root, output = map(Path, sys.argv[1:])
scope = {
    'util/sum.v': 25, 'util/epsilon.v': 0, 'util/bigop.v': 1,
    'util/setoid.v': 3, 'util/poet.v': 1, 'util/bigcat.v': 13,
    'util/minmax.v': 10, 'util/div_mod.v': 15,
}
with inventory.open(newline='') as handle:
    rows = list(csv.DictReader(handle))
actual = {name: [r['declaration_name'] for r in rows if r['source_file'] == name]
          for name in scope}
if {k: len(v) for k, v in actual.items()} != scope:
    raise SystemExit('authoritative Batch 3 count mismatch: ' + repr({k: len(v) for k,v in actual.items()}))
covered = {}
for label in ('sum_sequence','sum_interval','bigop','setoid','poet','bigcat','minmax','div_mod'):
    data = json.loads((cert_root / f'{label}_cluster_config.json').read_text())
    for name, spec in data['declarations'].items():
        key = (data['source_file'], name)
        if key in covered: raise SystemExit('duplicate cluster declaration: ' + repr(key))
        covered[key] = {'cluster': label, **spec}
expected = {(file, name) for file, names in actual.items() for name in names}
if len(expected) != 68 or set(covered) != expected:
    raise SystemExit('fail-closed coverage mismatch: missing=' + repr(sorted(expected-set(covered))) +
                     ' extra=' + repr(sorted(set(covered)-expected)))
output.write_text(json.dumps({'schema_version': 1, 'counts': scope,
    'authoritative_count': 68, 'certificate_cluster_count': len(covered),
    'authoritative_order': actual}, indent=2, sort_keys=True) + '\n')
PY

  python3 - "$batch3_utility_fixture" "$batch3_translation_fixture" \
    "$VALIDATION_RUN_LOG/combined_lean_axiom_config.json" <<'PY'
import json, sys
from pathlib import Path
utility, translation, output = map(Path, sys.argv[1:])
paths = [utility / 'sum_full_axiom_config.json'] + [
    translation / f'{label}_lean_axiom_config.json'
    for label in ('bigop','setoid','poet','bigcat','minmax','div_mod')]
combined = {'declarations': {}}
for path in paths:
    for name, spec in json.loads(path.read_text())['declarations'].items():
        if name in combined['declarations']:
            raise SystemExit('duplicate Lean axiom target: ' + name)
        combined['declarations'][name] = spec
if len(combined['declarations']) != 68:
    raise SystemExit(f'expected 68 Lean axiom targets, got {len(combined["declarations"])}')
output.write_text(json.dumps(combined, indent=2, sort_keys=True) + '\n')
PY
  : >"$VALIDATION_RUN_LOG/lean_axioms.log"
  for fixture in \
    "$batch3_utility_fixture/LeanSumFullAudit.lean" \
    "$batch3_translation_fixture/LeanBigopAudit.lean" \
    "$batch3_translation_fixture/LeanSetoidAudit.lean" \
    "$batch3_translation_fixture/LeanPoetAudit.lean" \
    "$batch3_translation_fixture/LeanBigcatAudit.lean" \
    "$batch3_translation_fixture/LeanMinmaxAudit.lean" \
    "$batch3_translation_fixture/LeanDivModAudit.lean"; do
    lean -DautoImplicit=false -R "$PROJECT_ROOT" "$fixture" \
      >>"$VALIDATION_RUN_LOG/lean_axioms.log" 2>&1
  done
  python3 "$VALIDATION_ROOT/scripts/audit_lean_axioms.py" \
    --config "$VALIDATION_RUN_LOG/combined_lean_axiom_config.json" \
    --log "$VALIDATION_RUN_LOG/lean_axioms.log" \
    --output "$VALIDATION_PREPARED/lean_axiom_summary.json" \
    >"$VALIDATION_RUN_LOG/lean_axiom_classifier.log" 2>&1

  VALIDATION_STAGE_OUTPUTS=(
    "artifact_audit=$VALIDATION_PREPARED/lean_artifact_audit.log"
    "artifact_metadata=$generated/type_guard_metadata.json"
    "lean_axioms=$VALIDATION_PREPARED/lean_axiom_summary.json"
    "inventory_check=$VALIDATION_PREPARED/inventory_check.json"
  )
  for module in "${batch3_lean_modules[@]}"; do
    label=${module##*/}
    VALIDATION_STAGE_OUTPUTS+=("${label}_olean=$VALIDATION_PREPARED/olean/$module.olean")
  done
}

validation_prepare_source_acquisition() {
  mkdir -p "$VALIDATION_PREPARED/source/util"
  local source_file
  local source_order=(
    util/tactics.v util/notation.v util/rel.v util/seqset.v
    util/subadditivity.v util/supremum.v util/nat.v util/unit_growth.v
    util/search_arg.v util/list.v util/sum.v util/epsilon.v util/bigop.v
    util/setoid.v util/poet.v util/bigcat.v util/minmax.v util/div_mod.v
  )
  for source_file in "${source_order[@]}"; do
    cp "$SOURCE_ROOT/$source_file" "$VALIDATION_PREPARED/source/$source_file"
    cmp -s "$SOURCE_ROOT/$source_file" "$VALIDATION_PREPARED/source/$source_file"
    (
      ulimit -s 65520
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$source_file"
    ) >"$VALIDATION_RUN_LOG/official_${source_file//\//_}.log" 2>&1
  done

  local declarations
  declarations=$(jq -r '.declarations | keys | join(",")' \
    "$batch3_cert_src/sum_sequence_cluster_config.json")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/sum.v \
    --module GeneratedSumSequenceSource --declarations "$declarations" \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.sum \
    --output "$VALIDATION_PREPARED/source/GeneratedSumSequenceSource.v" \
    --metadata "$VALIDATION_PREPARED/source/sum_sequence_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_SumSequence.log" 2>&1
  declarations=$(jq -r '.declarations | keys | join(",")' \
    "$batch3_cert_src/sum_interval_cluster_config.json")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/sum.v \
    --module GeneratedSumIntervalSource --declarations "$declarations" \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.sum \
    --output "$VALIDATION_PREPARED/source/GeneratedSumIntervalSource.v" \
    --metadata "$VALIDATION_PREPARED/source/sum_interval_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_SumInterval.log" 2>&1
  cp "$batch3_utility_fixture/EpsilonSourceInterface.v" \
    "$VALIDATION_PREPARED/source/EpsilonSourceInterface.v"
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/bigop.v \
    --module GeneratedBigopSource --declarations big_pred1_seq \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.bigop \
    --output "$VALIDATION_PREPARED/source/GeneratedBigopSource.v" \
    --metadata "$VALIDATION_PREPARED/source/bigop_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_Bigop.log" 2>&1
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/poet.v \
    --module GeneratedPoetSource --declarations forall_exists_implied_by_forall_in_zip \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.poet \
    --drop-import 'Require Export prosa.util.list.' \
    --output "$VALIDATION_PREPARED/source/GeneratedPoetSource.v" \
    --metadata "$VALIDATION_PREPARED/source/poet_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_Poet.log" 2>&1
  declarations=$(jq -r '.declarations | keys | join(",")' \
    "$batch3_cert_src/bigcat_cluster_config.json")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/bigcat.v \
    --module GeneratedBigcatSource --declarations "$declarations" \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.bigcat \
    --drop-import 'Require Export prosa.util.tactics prosa.util.list.' \
    --output "$VALIDATION_PREPARED/source/GeneratedBigcatSource.v" \
    --metadata "$VALIDATION_PREPARED/source/bigcat_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_Bigcat.log" 2>&1
  declarations=$(jq -r '.declarations | keys | join(",")' \
    "$batch3_cert_src/minmax_cluster_config.json")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/minmax.v \
    --module GeneratedMinmaxSource --declarations "$declarations" \
    --type-valued bigmax_leq_seqP \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.minmax \
    --drop-import 'Require Export prosa.util.notation prosa.util.nat prosa.util.list prosa.util.setoid.' \
    --output "$VALIDATION_PREPARED/source/GeneratedMinmaxSource.v" \
    --metadata "$VALIDATION_PREPARED/source/minmax_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_Minmax.log" 2>&1
  declarations=$(jq -r '.declarations | keys | join(",")' \
    "$batch3_cert_src/div_mod_cluster_config.json")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/div_mod.v \
    --module GeneratedDivModSource --declarations "$declarations" \
    --computational div_floor,div_ceil \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.div_mod \
    --output "$VALIDATION_PREPARED/source/GeneratedDivModSource.v" \
    --metadata "$VALIDATION_PREPARED/source/div_mod_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/source_extract_DivMod.log" 2>&1

  local generated_module
  for generated_module in GeneratedSumSequenceSource GeneratedSumIntervalSource \
    EpsilonSourceInterface GeneratedBigopSource GeneratedPoetSource \
    GeneratedBigcatSource GeneratedMinmaxSource GeneratedDivModSource; do
    (
      ulimit -s 65520
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$generated_module.v"
    ) >"$VALIDATION_RUN_LOG/generated_${generated_module}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "official_sum=$VALIDATION_PREPARED/source/util/sum.vo"
    "official_epsilon=$VALIDATION_PREPARED/source/util/epsilon.vo"
    "official_bigop=$VALIDATION_PREPARED/source/util/bigop.vo"
    "official_setoid=$VALIDATION_PREPARED/source/util/setoid.vo"
    "official_poet=$VALIDATION_PREPARED/source/util/poet.vo"
    "official_bigcat=$VALIDATION_PREPARED/source/util/bigcat.vo"
    "official_minmax=$VALIDATION_PREPARED/source/util/minmax.vo"
    "official_div_mod=$VALIDATION_PREPARED/source/util/div_mod.vo"
  )
}

validation_prepare_export() {
  mkdir -p "$VALIDATION_PREPARED/imported"
  unset LEAN4EXPORT_STATEMENT_ONLY LEAN4EXPORT_NORMALIZE_THEOREM_TYPES \
    LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS \
    LEAN4EXPORT_NORMALIZE_DEFINITION_BODIES \
    LEAN4EXPORT_DEFINITION_BODY_PROJECTIONS || true
  local module target body_targets
  local -a targets=()
  for module in SumSequence SumInterval Bigop Setoid Poet Bigcat Minmax DivMod; do
    targets=()
    while IFS= read -r target; do [[ -n "$target" ]] && targets+=("$target"); done < <(
      python3 - "$batch3_boundary" "$module" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))['modules'][sys.argv[2]]
print('\n'.join(m['definitions'] + m['body_theorems'] + m['semantic_adapters']))
PY
    )
    body_targets=$(python3 - "$batch3_boundary" "$module" <<'PY'
import json, sys
print('\n'.join(json.load(open(sys.argv[1]))['modules'][sys.argv[2]]['body_theorems']))
PY
    )
    export LEAN4EXPORT_BODY_THEOREMS="$body_targets"
    "$EXPORTER_ROOT/.lake/build/bin/lean4export" \
      Validation.fixtures.rocq90_batch3.Batch3SemanticInterface -- \
      "${targets[@]}" >"$VALIDATION_PREPARED/imported/$module.out" \
      2>"$VALIDATION_RUN_LOG/export_${module}.log"
    [[ -s "$VALIDATION_PREPARED/imported/$module.out" ]]
  done
  unset LEAN4EXPORT_BODY_THEOREMS
  "$EXPORTER_ROOT/.lake/build/bin/lean4export" \
    Validation.fixtures.utility_foundation.EpsilonInterface -- \
    Prosa.Validation.EpsilonInterface.epsilonNatValue \
    >"$VALIDATION_PREPARED/imported/Epsilon.out" \
    2>"$VALIDATION_RUN_LOG/export_Epsilon.log"
  [[ -s "$VALIDATION_PREPARED/imported/Epsilon.out" ]]

  python3 - "$VALIDATION_PREPARED" "$batch3_boundary" <<'PY'
import hashlib, json, sys
from pathlib import Path
root, boundary_path = map(Path, sys.argv[1:])
boundary = json.loads(boundary_path.read_text())
rows = {}
for module in ('SumSequence','SumInterval','Epsilon','Bigop','Setoid','Poet','Bigcat','Minmax','DivMod'):
    path = root / 'imported' / f'{module}.out'
    lines = path.read_text().splitlines()
    namespace = {}
    for line in lines:
        fields = line.split()
        if len(fields) == 4 and fields[1] == '#NS':
            namespace[fields[0]] = (fields[2], fields[3])
    def qualified(index):
        parts = []
        while index in namespace:
            index, part = namespace[index]
            parts.append(part)
        return '.'.join(reversed(parts))
    names, foundations = set(), []
    for line in lines:
        parts = line.split()
        if len(parts) >= 2 and parts[0] in ('#DEF','#AX'):
            name = qualified(parts[1]); names.add(name)
            if parts[0] == '#AX': foundations.append(name)
        elif len(parts) >= 3 and parts[0] == '#IND':
            names.add(qualified(parts[2]))
    forbidden = set(boundary['forbidden_export_names'])
    leaked = sorted(n for n in names if n.rsplit('.', 1)[-1] in forbidden)
    if leaked: raise SystemExit(f'{module}: forbidden implementation graph leaked: {leaked}')
    unexpected = sorted(n for n in foundations
        if not n.endswith(('propext','Quot.sound','Classical.choice')))
    if unexpected: raise SystemExit(f'{module}: unexpected #AX records: {unexpected}')
    spec = boundary['modules'].get(module, {'definitions': [], 'body_theorems': [], 'semantic_adapters': []})
    rows[module] = {
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'target_count': sum(len(spec[k]) for k in ('definitions','body_theorems','semantic_adapters')) if module != 'Epsilon' else 1,
        'semantic_adapter_count': len(spec.get('semantic_adapters', [])),
        'lean_foundation_records': sorted(foundations),
        'unexpected_axiom_records': unexpected,
        'forbidden_implementation_graph': leaked,
        'statement_only': False,
        'normal_universe_checking': True,
        'normal_elimination_checking': True,
    }
(root / 'export_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=("export_manifest=$VALIDATION_PREPARED/export_manifest.json")
  for module in "${batch3_modules[@]}"; do
    VALIDATION_STAGE_OUTPUTS+=("${module}_out=$VALIDATION_PREPARED/imported/$module.out")
  done
}

validation_prepare_rocq_import() {
  cp "$VALIDATION_ROOT/imported/utility_foundation/ImportedSumSequence.v" \
    "$VALIDATION_PREPARED/imported/ImportedSumSequence.v"
  cp "$VALIDATION_ROOT/fixtures/utility_foundation/ImportedSumInterval.v" \
    "$VALIDATION_PREPARED/imported/ImportedSumInterval.v"
  local module lower wrapper dependency expected
  for module in Epsilon Bigop Setoid Poet Bigcat Minmax DivMod; do
    lower=$(printf '%s' "$module" | tr '[:upper:]' '[:lower:]')
    [[ "$module" == DivMod ]] && lower=div_mod
    wrapper="$VALIDATION_ROOT/imported/translation_order/$lower/Imported$module.v"
    cp "$wrapper" "$VALIDATION_PREPARED/imported/Imported$module.v"
  done
  for module in Subadditivity Nat; do
    dependency="$VALIDATION_ROOT/imported/rocq90_batch1/Imported$module.vo"
    expected=$(jq -r --arg file "util/$(printf '%s' "$module" | tr '[:upper:]' '[:lower:]').v" \
      '.files[] | select(.file==$file) | .vo_sha256' \
      "$VALIDATION_ROOT/imported/rocq90_batch1/artifact_manifest.json")
    [[ -n "$expected" && $(validation_sha256 "$dependency") == "$expected" ]]
    cp "$dependency" "$VALIDATION_PREPARED/imported/Imported$module.vo"
  done
  for module in "${batch3_modules[@]}"; do
    batch3_prepared_rocq_compile "$VALIDATION_PREPARED/imported" \
      "Imported$module.v" >"$VALIDATION_RUN_LOG/import_${module}.log" 2>&1
  done
  python3 - "$VALIDATION_PREPARED" <<'PY'
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
modules = ('Subadditivity','Nat','SumSequence','SumInterval','Epsilon','Bigop','Setoid','Poet','Bigcat','Minmax','DivMod')
rows = {m: {'sha256': sha(root / 'imported' / f'Imported{m}.vo')} for m in modules}
(root / 'import_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=("import_manifest=$VALIDATION_PREPARED/import_manifest.json")
  for module in "${batch3_modules[@]}"; do
    VALIDATION_STAGE_OUTPUTS+=("${module}_vo=$VALIDATION_PREPARED/imported/Imported$module.vo")
  done
}

validation_check_setup() {
  cp -R "$VALIDATION_PREPARED/olean/." "$VALIDATION_PHASE_WORK/olean/"
  cp -R "$VALIDATION_PREPARED/source/." "$VALIDATION_PHASE_WORK/source/"
  cp -R "$VALIDATION_PREPARED/imported/." "$VALIDATION_PHASE_WORK/imported/"
  mkdir -p "$VALIDATION_PHASE_WORK/certificates" \
    "$VALIDATION_PHASE_WORK/generated_type_audits"
  local module
  for module in PropSPropFoundation LogicalRelation TypeSPropRelation \
    SubadditivityNatCorrespondence NatSubCorrespondence \
    SumSequenceCorrespondence SumIntervalCorrespondence BigopCorrespondence \
    SetoidCorrespondence PoetCorrespondence BigcatCorrespondence \
    MinmaxCorrespondence DivModCorrespondence; do
    cp "$batch3_common_src/$module.v" "$VALIDATION_PHASE_WORK/certificates/$module.v"
  done
  cp "$VALIDATION_ROOT/certificates/foundation_slice_2_closure/SubadditivityClosureCertificate.v" \
    "$VALIDATION_PHASE_WORK/certificates/SubadditivityClosureCertificate.v"
  patch --batch --forward -d "$VALIDATION_PHASE_WORK/certificates" -p1 \
    <"$batch3_fixture/sum_unit_acc_free.patch" \
    >"$VALIDATION_RUN_LOG/sum_sequence_rocq90_patch.log" 2>&1
  for module in SumSequenceCertificate SumIntervalCertificate EpsilonCertificate \
    BigopCertificate SetoidCertificate PoetCertificate BigcatCertificate \
    MinmaxCertificate DivModCertificate \
    SumSequenceAssumptionAudit SumIntervalAssumptionAudit EpsilonAssumptionAudit \
    BigopAssumptionAudit SetoidAssumptionAudit PoetAssumptionAudit \
    BigcatAssumptionAudit MinmaxAssumptionAudit DivModAssumptionAudit; do
    cp "$batch3_cert_src/$module.v" "$VALIDATION_PHASE_WORK/certificates/$module.v"
  done
  python3 "$VALIDATION_ROOT/scripts/generate_batch3_rocq_type_audits.py" \
    --source-root "$batch3_cert_src" \
    --output-root "$VALIDATION_PHASE_WORK/generated_type_audits" \
    >"$VALIDATION_RUN_LOG/type_audit_generation.log" 2>&1
  rg -q 'BATCH3_ROCQ_TYPE_AUDITS_OK declarations=64' \
    "$VALIDATION_RUN_LOG/type_audit_generation.log"
  for module in SumSequenceTypeAudit SumIntervalTypeAudit BigopTypeAudit \
    SetoidTypeAudit PoetTypeAudit BigcatTypeAudit MinmaxTypeAudit DivModTypeAudit; do
    cp "$VALIDATION_PHASE_WORK/generated_type_audits/$module.v" \
      "$VALIDATION_PHASE_WORK/certificates/$module.v"
  done
  if rg -n '\b(Admitted|admit|Axiom)\b|\bsorry\b' \
      "$VALIDATION_PHASE_WORK/certificates" --glob '*.v' \
      --glob '!PropSPropFoundation.v'; then
    echo 'forbidden certificate proof escape' >&2
    return 1
  fi
  local foundation_axioms
  foundation_axioms=$(rg -n '^Axiom ' \
    "$VALIDATION_PHASE_WORK/certificates/PropSPropFoundation.v")
  [[ "$foundation_axioms" == *'Axiom interpret_strict'* ]]
  [[ $(printf '%s\n' "$foundation_axioms" | sed '/^$/d' | wc -l | tr -d ' ') == 1 ]]
}

validation_check_certificate_compile() {
  local module
  for module in "${batch3_compile_order[@]}"; do
    batch3_rocq_compile "$VALIDATION_PHASE_WORK/certificates" "$module.v" \
      >"$VALIDATION_RUN_LOG/certificate_${module}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "sum_certificate=$VALIDATION_PHASE_WORK/certificates/SumIntervalCertificate.vo"
    "epsilon_certificate=$VALIDATION_PHASE_WORK/certificates/EpsilonCertificate.vo"
    "bigcat_certificate=$VALIDATION_PHASE_WORK/certificates/BigcatCertificate.vo"
    "div_mod_certificate=$VALIDATION_PHASE_WORK/certificates/DivModCertificate.vo"
    "type_audit=$VALIDATION_PHASE_WORK/certificates/DivModTypeAudit.vo"
  )
}

validation_check_assumption_audit() {
  local combined="$VALIDATION_RUN_LOG/combined_assumption_config.json"
  python3 - "$batch3_cert_src" "$combined" <<'PY'
import json, sys
from pathlib import Path
root, output = map(Path, sys.argv[1:])
labels = ('sum_sequence','sum_interval','epsilon','bigop','setoid','poet','bigcat','minmax','div_mod')
configs = [json.loads((root / f'{label}_assumption_config.json').read_text()) for label in labels]
out = {
  'prop_sprop_foundation': sorted(set().union(*(set(c.get('prop_sprop_foundation', [])) for c in configs))),
  'importer_foundation': sorted(set().union(*(set(c.get('importer_foundation', [])) for c in configs))),
  'rocq_sprop_uip': sorted(set().union(*(set(c.get('rocq_sprop_uip', [])) for c in configs))),
  'certificates': {},
}
for config in configs:
    for key, spec in config['certificates'].items():
        if key in out['certificates']: raise SystemExit('duplicate assumption audit target: ' + key)
        out['certificates'][key] = spec
if len(out['certificates']) != 70:
    raise SystemExit(f'expected 68 declarations plus two module/operation gates, got {len(out["certificates"])}')
output.write_text(json.dumps(out, indent=2, sort_keys=True) + '\n')
PY
  : >"$VALIDATION_RUN_LOG/assumptions.log"
  local module
  for module in "${batch3_assumption_modules[@]}"; do
    cat "$VALIDATION_RUN_LOG/certificate_${module}.log" \
      >>"$VALIDATION_RUN_LOG/assumptions.log"
  done
  python3 "$VALIDATION_ROOT/scripts/audit_assumptions.py" \
    --config "$combined" --log "$VALIDATION_RUN_LOG/assumptions.log" \
    --output "$VALIDATION_RUN_LOG/assumption_summary.json" \
    >"$VALIDATION_RUN_LOG/assumption_classifier.log" 2>&1
  python3 - "$VALIDATION_RUN_LOG/assumption_summary.json" <<'PY'
import json, sys
report = json.load(open(sys.argv[1]))
assert len(report['certificates']) == 70
for name, row in report['certificates'].items():
    assert row['semantic_premises'] == [], name
    assert row['source_theorem_dependency'] is False, name
    assert row['target_theorem_dependency'] is False, name
    assert row['unexpected'] == [], name
    assert row['status'] in ('CERTIFIED','CERTIFIED_WITH_PROP_SPROP_FOUNDATION'), (name, row['status'])
PY

  validation_rocq90_exec rocqchk -silent -o \
    -Q "$IMPORTER_ROOT/src" LeanImport LeanImport.Lean \
    >"$VALIDATION_RUN_LOG/rocqchk_foundation.log" 2>&1
  for module in "${batch3_modules[@]}"; do
    validation_rocq90_exec rocqchk -silent -o \
      -Q "$IMPORTER_ROOT/src" LeanImport \
      -Q "$VALIDATION_PHASE_WORK/imported" FoundationImported \
      "FoundationImported.Imported$module" \
      >"$VALIDATION_RUN_LOG/rocqchk_${module}.log" 2>&1
    rg -q 'Constants/Inductives relying on type-in-type: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
    rg -q 'Constants/Inductives relying on unsafe \(co\)fixpoints: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
    rg -q 'Inductives whose positivity is assumed: <none>' \
      "$VALIDATION_RUN_LOG/rocqchk_${module}.log"
  done
  python3 - "$VALIDATION_RUN_LOG" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
def axioms(path):
    inside, result = False, set()
    for line in path.read_text().splitlines():
        if line.startswith('* Axioms:'): inside = True; continue
        if inside and line.startswith('* Constants/Inductives'): break
        if inside and line.startswith('    '):
            item = line.strip()
            if item and item != '<none>': result.add(item)
    return result
foundation = axioms(root / 'rocqchk_foundation.log')
rows = {}
for module in ('SumSequence','SumInterval','Epsilon','Bigop','Setoid','Poet','Bigcat','Minmax','DivMod'):
    additional = axioms(root / f'rocqchk_{module}.log') - foundation
    known = {x for x in additional if x.endswith(('.propext','.Quot_sound','.Classical_choice'))}
    unexpected = sorted(additional - known)
    if unexpected: raise SystemExit(f'unexpected Rocq axioms for {module}: {unexpected}')
    rows[module] = {
      'type_in_type': [], 'unsafe_fixpoints': [], 'assumed_positivity': [],
      'lean_foundation_axioms': sorted(known),
      'unexpected_custom_rocq_axioms': unexpected,
    }
(root / 'rocqchk_trust_summary.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "assumption_summary=$VALIDATION_RUN_LOG/assumption_summary.json"
    "rocqchk_trust=$VALIDATION_RUN_LOG/rocqchk_trust_summary.json"
  )
}

validation_finalize_publication() {
  local publish="$VALIDATION_ROOT/imported/rocq90_batch3"
  local status="$VALIDATION_ROOT/planning/v06_pipeline/rocq90_batch3_status.json"
  mkdir -p "$publish" "$(dirname "$status")"
  local module
  for module in "${batch3_modules[@]}"; do
    cp "$VALIDATION_PREPARED/imported/$module.out" "$publish/$module.out"
    cp "$VALIDATION_PREPARED/imported/Imported$module.v" "$publish/Imported$module.v"
    cp "$VALIDATION_PREPARED/imported/Imported$module.vo" "$publish/Imported$module.vo"
  done
  for module in "${batch3_compile_order[@]}"; do
    cp "$VALIDATION_PHASE_WORK/certificates/$module.vo" "$publish/$module.vo"
  done
  cp "$VALIDATION_RUN_LOG/rocqchk_trust_summary.json" "$publish/trust_manifest.json"
  cp "$VALIDATION_PREPARED/export_manifest.json" "$publish/export_manifest.json"
  cp "$VALIDATION_PREPARED/import_manifest.json" "$publish/import_manifest.json"
  cp "$VALIDATION_PREPARED/generated/type_guard_metadata.json" \
    "$publish/type_guard_metadata.json"

  python3 - "$PROJECT_ROOT" "$SOURCE_ROOT" "$VALIDATION_ROOT" \
    "$VALIDATION_PREPARED" "$VALIDATION_RUN_LOG" "$batch3_cert_src" \
    "$publish/artifact_manifest.json" "$publish/declaration_manifest.json" \
    "$status" "$VALIDATION_SNAPSHOT_ID" <<'PY'
import csv, hashlib, json, subprocess, sys
from pathlib import Path
project, source, validation, prepared, logs, cert_root, artifact_out, declaration_out, status_out = map(Path, sys.argv[1:10])
snapshot = sys.argv[10]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
scope = [
  (12,'util/sum.v',25,'Sum',('SumSequence','SumInterval')),
  (13,'util/epsilon.v',0,'Epsilon',('Epsilon',)),
  (14,'util/bigop.v',1,'Bigop',('Bigop',)),
  (15,'util/setoid.v',3,'Setoid',('Setoid',)),
  (16,'util/poet.v',1,'Poet',('Poet',)),
  (17,'util/bigcat.v',13,'Bigcat',('Bigcat',)),
  (18,'util/minmax.v',10,'Minmax',('Minmax',)),
  (19,'util/div_mod.v',15,'Div_mod',('DivMod',)),
]
with (validation / 'planning/v06_dependency/declaration_inventory.csv').open(newline='') as handle:
    inventory = [r for r in csv.DictReader(handle) if r['source_file'] in {x[1] for x in scope}]
clusters = {}
for label in ('sum_sequence','sum_interval','bigop','setoid','poet','bigcat','minmax','div_mod'):
    config = json.loads((cert_root / f'{label}_cluster_config.json').read_text())
    for name, spec in config['declarations'].items():
        key = (config['source_file'], name)
        if key in clusters: raise SystemExit('duplicate cluster declaration: ' + repr(key))
        clusters[key] = {'cluster': label, **spec}
guards = {(r['source_file'], r['source_declaration']): r
          for r in json.loads((prepared / 'generated/type_guard_metadata.json').read_text())['guards']}
assumptions = json.loads((logs / 'assumption_summary.json').read_text())['certificates']
expected = {(r['source_file'], r['declaration_name']) for r in inventory}
if len(inventory) != 68 or set(clusters) != expected or set(guards) != expected:
    raise SystemExit('fail-closed 68-declaration publication mismatch')
rows = []
for item in inventory:
    key = (item['source_file'], item['declaration_name'])
    spec, guard = clusters[key], guards[key]
    audit = assumptions[spec['audit_key']]
    row = {
      'source_order': int(item['source_order']), 'source_file': key[0],
      'source_declaration': key[1], 'source_kind': item['kind'],
      'source_qualified_name': item['qualified_name'],
      'lean_production_declaration': guard['lean_declaration'],
      'actual_artifact_guard': 'PASS', 'cluster': spec['cluster'],
      'certificate': spec['certificate'], 'certificate_file': spec['certificate_file'],
      'semantic_premises': audit['semantic_premises'],
      'source_theorem_dependency': audit['source_theorem_dependency'],
      'target_theorem_dependency': audit['target_theorem_dependency'],
      'unexpected_assumptions': audit['unexpected'],
      'foundation_classification': audit['status'],
      'existing_rocq93_acceptance': True,
      'rocq90_migration_status': 'ACCEPTED',
    }
    if row['semantic_premises'] or row['source_theorem_dependency'] or row['target_theorem_dependency'] or row['unexpected_assumptions']:
        raise SystemExit('declaration trust contract failed: ' + repr(key))
    rows.append(row)
declaration_out.write_text(json.dumps({'schema_version': 1,
  'authoritative_count': 68, 'files': 8, 'declarations': rows}, indent=2, sort_keys=True) + '\n')

artifact_rows = []
for rank, file, count, lean_stem, modules in scope:
    lean_path = project / 'Prosa/Util' / f'{lean_stem}.lean'
    olean_path = prepared / 'olean/Prosa/Util' / f'{lean_stem}.olean'
    artifact_rows.append({
      'rank': rank, 'file': file, 'authoritative_declarations': count,
      'source_sha256': sha(source / file),
      'lean_source_sha256': sha(lean_path),
      'fresh_olean_sha256': sha(olean_path),
      'out_sha256': {m: sha(prepared / 'imported' / f'{m}.out') for m in modules},
      'vo_sha256': {m: sha(prepared / 'imported' / f'Imported{m}.vo') for m in modules},
      'import': 'PASS', 'certificates': 'PASS', 'assumption_audit': 'PASS',
      'rocqchk': 'PASS', 'acceptance': 'ACCEPTED_V06_FILE_ROCQ90',
    })
artifact_out.write_text(json.dumps({
  'schema_version': 1, 'snapshot_id': snapshot,
  'authoritative_prosa_commit': subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'], text=True).strip(),
  'mathlib_commit': subprocess.check_output(['git','-C',str(project/'.lake/packages/mathlib'),'rev-parse','HEAD'], text=True).strip(),
  'actual_artifact_guards': 68, 'statement_only': False,
  'normal_universe_checking': True, 'normal_elimination_checking': True,
  'files': artifact_rows,
}, indent=2, sort_keys=True) + '\n')
status = {
  'schema_version': 1, 'classification': 'ROCQ90_FULL_MIGRATION_BATCH3_ACCEPTED',
  'active_validation_baseline': 'Rocq 9.0.0',
  'historical_validation_provenance': 'Rocq 9.3',
  'snapshot_id': snapshot, 'files_accepted': 8,
  'authoritative_declarations': 68, 'declarations_accepted': 68,
  'translated_but_not_certified': 0, 'actual_artifact_guards': 68,
  'all_certificates': 'PASS', 'semantic_premises': [],
  'source_theorem_dependency': False, 'target_theorem_dependency': False,
  'unexpected_assumptions': [], 'normal_universe_checking': True,
  'normal_elimination_checking': True, 'type_in_type': 0,
  'unsafe_fixpoints': 0, 'assumed_positivity': 0,
  'unexpected_custom_rocq_axioms': 0,
  'production_translation_modified': False,
  'cumulative': {'files': 19, 'files_total': 357,
                 'declarations': 171, 'declarations_total': 2439},
  'files': artifact_rows,
  'declarations': rows,
  'next_ready': {'rank': 20, 'file': 'util/nondecreasing.v',
                 'authoritative_declarations': 33,
                 'stage': 'historical unfinished translation'},
}
status_out.write_text(json.dumps(status, indent=2, sort_keys=True) + '\n')
PY
  cp "$publish/artifact_manifest.json" "$VALIDATION_RUN_LOG/artifact_manifest.json"
  cp "$publish/declaration_manifest.json" "$VALIDATION_RUN_LOG/declaration_manifest.json"
  cp "$status" "$VALIDATION_RUN_LOG/rocq90_batch3_status.json"
  VALIDATION_STAGE_OUTPUTS=(
    "artifact_manifest=$VALIDATION_RUN_LOG/artifact_manifest.json"
    "declaration_manifest=$VALIDATION_RUN_LOG/declaration_manifest.json"
    "batch_status=$VALIDATION_RUN_LOG/rocq90_batch3_status.json"
    "trust_manifest=$VALIDATION_RUN_LOG/rocqchk_trust_summary.json"
  )
}
