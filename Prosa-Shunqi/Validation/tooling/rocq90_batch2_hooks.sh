#!/usr/bin/env bash

# Formal Rocq 9.0 Batch 2 hooks for the authoritative util/list.v file.
# This pipeline is self-contained under Validation and never reads compatibility
# experiment work, logs, results, or artifacts.

batch2_boundary="$VALIDATION_ROOT/tooling/rocq90_batch2_boundary.json"
batch2_fixture="$VALIDATION_ROOT/fixtures/utility_foundation"
batch2_cert_src="$VALIDATION_ROOT/certificates/utility_foundation"
batch2_common_src="$VALIDATION_ROOT/certificates/common"

VALIDATION_PREPARE_INPUTS=(
  "$VALIDATION_ROOT/tooling/rocq90_batch2_descriptor.json"
  "$VALIDATION_ROOT/tooling/rocq90_batch2_hooks.sh"
  "$batch2_boundary"
  "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py"
  "$batch2_fixture/ListLastComputationInterface.lean"
  "$VALIDATION_ROOT/fixtures/rocq90_batch2/ListComputationInterface.lean"
  "$VALIDATION_ROOT/fixtures/rocq90_batch2/ListArtifactAudit.lean"
)
VALIDATION_CHECK_INPUTS=(
  "$VALIDATION_ROOT/scripts/audit_assumptions.py"
  "$VALIDATION_ROOT/scripts/audit_lean_axioms.py"
)
while IFS= read -r input; do
  VALIDATION_CHECK_INPUTS+=("$input")
done < <(find "$batch2_common_src" "$batch2_cert_src" -type f \
  \( -name '*.v' -o -name '*assumption_config.json' -o -name '*cluster_config.json' \) \
  | sort)

batch2_common_modules=(
  PropSPropFoundation LogicalRelation SubadditivityNatCorrespondence
)
batch2_certificate_modules=(
  ListSimpleCertificate ListLastCertificate ListRemCertificate
  ListBatch2Certificate ListBatch3Operations ListBatch3Certificate
  ListBatch4Operations ListBatch4Certificate ListBatch5Operations
  ListBatch5Certificate ListSimpleAssumptionAudit ListLastAssumptionAudit
  ListBatch2AssumptionAudit ListBatch3AssumptionAudit ListBatch4AssumptionAudit
  ListBatch5AssumptionAudit
)
batch2_axiom_groups=(simple last batch2 batch3 batch4 batch5)
batch2_cluster_groups=(simple last batch3 batch4 batch5)

batch2_rocq_compile() {
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

batch2_prepared_rocq_compile() {
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
  if rg -n '\b(sorry|axiom|unsafe)\b' "$PROJECT_ROOT/Prosa/Util/List.lean"; then
    echo 'forbidden production proof escape in Prosa/Util/List.lean' >&2
    return 1
  fi
  mkdir -p "$VALIDATION_PREPARED/olean/Prosa/Util" \
    "$VALIDATION_PREPARED/olean/Validation/fixtures/utility_foundation" \
    "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch2"
  local module label fixture config
  for module in Prosa/Util/Tactics Prosa/Util/Supremum Prosa/Util/List \
    Validation/fixtures/utility_foundation/ListLastComputationInterface \
    Validation/fixtures/rocq90_batch2/ListComputationInterface; do
    label=${module##*/}
    validation_compile_lean_module "$VALIDATION_PREPARED" "$module" \
      >"$VALIDATION_RUN_LOG/fresh_${label}.log" 2>&1
  done
  lean -DautoImplicit=false -R "$PROJECT_ROOT" \
    -o "$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch2/ListArtifactAudit.olean" \
    "$VALIDATION_ROOT/fixtures/rocq90_batch2/ListArtifactAudit.lean" \
    >"$VALIDATION_PREPARED/lean_artifact_audit.log" 2>&1
  [[ $(rg -c 'TYPE_DEF_EQ_OK target=' \
      "$VALIDATION_PREPARED/lean_artifact_audit.log") == 57 ]]
  rg -q 'BATCH2_LIST_ACTUAL_ARTIFACT_GUARDS_OK count=57' \
    "$VALIDATION_PREPARED/lean_artifact_audit.log"

  python3 - "$VALIDATION_ROOT/planning/v06_dependency/declaration_inventory.csv" \
    "$batch2_cert_src" "$VALIDATION_PREPARED/inventory_check.json" <<'PY'
import csv, json, sys
from pathlib import Path
inventory, cert_root, output = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
with inventory.open(newline='') as handle:
    authority = [r['declaration_name'] for r in csv.DictReader(handle)
                 if r['source_file'] == 'util/list.v']
clusters = {}
for label in ('simple', 'last', 'batch3', 'batch4', 'batch5'):
    data = json.loads((cert_root / f'list_{label}_cluster_config.json').read_text())
    for name, spec in data['declarations'].items():
        if name in clusters:
            raise SystemExit('duplicate cluster declaration: ' + name)
        clusters[name] = spec
if len(authority) != 57:
    raise SystemExit(f'authoritative List count is {len(authority)}, expected 57')
if set(authority) != set(clusters):
    raise SystemExit('inventory/cluster mismatch: missing=' + repr(sorted(set(authority)-set(clusters))) +
                     ' extra=' + repr(sorted(set(clusters)-set(authority))))
output.write_text(json.dumps({'authoritative_count': 57,
    'authoritative_order': authority, 'certificate_cluster_count': len(clusters)},
    indent=2, sort_keys=True) + '\n')
PY

  python3 - "$batch2_fixture" "$VALIDATION_RUN_LOG/combined_lean_axiom_config.json" <<'PY'
import json, sys
from pathlib import Path
root, output = Path(sys.argv[1]), Path(sys.argv[2])
combined = {'declarations': {}}
for label in ('simple', 'last', 'batch2', 'batch3', 'batch4', 'batch5'):
    rows = json.loads((root / f'list_{label}_axiom_config.json').read_text())['declarations']
    for name, spec in rows.items():
        if name in combined['declarations']:
            raise SystemExit('duplicate Lean axiom target: ' + name)
        combined['declarations'][name] = spec
output.write_text(json.dumps(combined, indent=2, sort_keys=True) + '\n')
PY
  : >"$VALIDATION_RUN_LOG/lean_freeze_and_axioms.log"
  while IFS='|' read -r label fixture; do
    lean -DautoImplicit=false -R "$PROJECT_ROOT" "$fixture" \
      >>"$VALIDATION_RUN_LOG/lean_freeze_and_axioms.log" 2>&1
  done <<EOF
simple|$batch2_fixture/LeanListSimpleAudit.lean
last|$batch2_fixture/LeanListLastAudit.lean
max|$batch2_fixture/LeanListMaxAudit.lean
rem|$batch2_fixture/LeanListRemAudit.lean
batch2|$batch2_fixture/LeanListBatch2Audit.lean
batch3|$batch2_fixture/LeanListBatch3Audit.lean
batch4|$batch2_fixture/LeanListBatch4Audit.lean
batch5|$batch2_fixture/LeanListBatch5Audit.lean
EOF
  python3 "$VALIDATION_ROOT/scripts/audit_lean_axioms.py" \
    --config "$VALIDATION_RUN_LOG/combined_lean_axiom_config.json" \
    --log "$VALIDATION_RUN_LOG/lean_freeze_and_axioms.log" \
    --output "$VALIDATION_PREPARED/lean_axiom_summary.json" \
    >"$VALIDATION_RUN_LOG/lean_axiom_classifier.log" 2>&1
  cp "$VALIDATION_RUN_LOG/fresh_ListComputationInterface.log" \
    "$VALIDATION_PREPARED/lean_computation_bridge_axioms.log"
  rg -q 'getD_matches_compiled' \
    "$VALIDATION_PREPARED/lean_computation_bridge_axioms.log"
  rg -q 'last0_nth_safe' \
    "$VALIDATION_PREPARED/lean_computation_bridge_axioms.log"
  if rg -n '\b(axiom|sorry)\b' \
      "$VALIDATION_PREPARED/lean_computation_bridge_axioms.log"; then
    echo 'validation adapter introduced an unsupported Lean axiom' >&2
    return 1
  fi
  VALIDATION_STAGE_OUTPUTS=(
    "list_olean=$VALIDATION_PREPARED/olean/Prosa/Util/List.olean"
    "interface_olean=$VALIDATION_PREPARED/olean/Validation/fixtures/rocq90_batch2/ListComputationInterface.olean"
    "artifact_audit=$VALIDATION_PREPARED/lean_artifact_audit.log"
    "lean_axioms=$VALIDATION_PREPARED/lean_axiom_summary.json"
    "inventory_check=$VALIDATION_PREPARED/inventory_check.json"
  )
}

validation_prepare_source_acquisition() {
  mkdir -p "$VALIDATION_PREPARED/source/util"
  local source_file
  for source_file in util/tactics.v util/supremum.v util/list.v; do
    cp "$SOURCE_ROOT/$source_file" "$VALIDATION_PREPARED/source/$source_file"
    cmp -s "$SOURCE_ROOT/$source_file" "$VALIDATION_PREPARED/source/$source_file"
    (
      ulimit -s 65520
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$source_file"
    ) >"$VALIDATION_RUN_LOG/official_${source_file//\//_}.log" 2>&1
  done
  local declarations computational simple
  declarations=$(python3 -c \
    'import json,sys; print(",".join(json.load(open(sys.argv[1]))["source_declarations"]))' \
    "$batch2_boundary")
  computational=$(python3 -c \
    'import json,sys; print(",".join(json.load(open(sys.argv[1]))["computational_source_declarations"]))' \
    "$batch2_boundary")
  simple=$(python3 -c \
    'import json,sys; print(",".join(json.load(open(sys.argv[1]))["simple_source_declarations"]))' \
    "$batch2_boundary")
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/list.v \
    --module GeneratedListLastSource --declarations "$declarations" \
    --computational "$computational" \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.list \
    --output "$VALIDATION_PREPARED/source/GeneratedListLastSource.v" \
    --metadata "$VALIDATION_PREPARED/source/list_last_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/list_last_source_extraction.log" 2>&1
  python3 "$VALIDATION_ROOT/scripts/extract_v06_semantic_source.py" \
    --source-root "$SOURCE_ROOT" --source-file util/list.v \
    --module GeneratedListSimpleSource --declarations "$simple" \
    --computational "$simple" \
    --elaborated-evidence "$VALIDATION_ROOT/planning/v06_dependency/declaration_type_evidence.json" \
    --qualified-prefix prosa.util.list \
    --output "$VALIDATION_PREPARED/source/GeneratedListSimpleSource.v" \
    --metadata "$VALIDATION_PREPARED/source/list_simple_source_extraction.json" \
    >"$VALIDATION_RUN_LOG/list_simple_source_extraction.log" 2>&1
  for source_file in GeneratedListLastSource.v GeneratedListSimpleSource.v; do
    (
      ulimit -s 65520
      cd "$VALIDATION_PREPARED/source"
      validation_rocq90_exec rocq c -R "$VALIDATION_PREPARED/source" prosa \
        "$source_file"
    ) >"$VALIDATION_RUN_LOG/generated_${source_file%.v}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "official_list_vo=$VALIDATION_PREPARED/source/util/list.vo"
    "list_last_source_vo=$VALIDATION_PREPARED/source/GeneratedListLastSource.vo"
    "list_simple_source_vo=$VALIDATION_PREPARED/source/GeneratedListSimpleSource.vo"
    "list_last_source_metadata=$VALIDATION_PREPARED/source/list_last_source_extraction.json"
    "list_simple_source_metadata=$VALIDATION_PREPARED/source/list_simple_source_extraction.json"
  )
}

validation_prepare_export() {
  mkdir -p "$VALIDATION_PREPARED/imported"
  unset LEAN4EXPORT_STATEMENT_ONLY LEAN4EXPORT_NORMALIZE_THEOREM_TYPES \
    LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS \
    LEAN4EXPORT_NORMALIZE_DEFINITION_BODIES \
    LEAN4EXPORT_DEFINITION_BODY_PROJECTIONS || true
  local body_targets target
  local -a list_targets simple_targets
  body_targets=$(python3 -c \
    'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["body_theorem_targets"]))' \
    "$batch2_boundary")
  export LEAN4EXPORT_BODY_THEOREMS="$body_targets"
  while IFS= read -r target; do list_targets+=("$target"); done < <(
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("\n".join(d["definition_targets"]+d["body_theorem_targets"]))' \
      "$batch2_boundary")
  "$EXPORTER_ROOT/.lake/build/bin/lean4export" \
    Validation.fixtures.rocq90_batch2.ListComputationInterface -- \
    "${list_targets[@]}" >"$VALIDATION_PREPARED/imported/ListLast.out" \
    2>"$VALIDATION_RUN_LOG/export_ListLast.log"
  [[ -s "$VALIDATION_PREPARED/imported/ListLast.out" ]]
  unset LEAN4EXPORT_BODY_THEOREMS
  while IFS= read -r target; do simple_targets+=("$target"); done < <(
    python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["simple_definition_targets"]))' \
      "$batch2_boundary")
  "$EXPORTER_ROOT/.lake/build/bin/lean4export" Prosa.Util.List -- \
    "${simple_targets[@]}" >"$VALIDATION_PREPARED/imported/ListSimple.out" \
    2>"$VALIDATION_RUN_LOG/export_ListSimple.log"
  [[ -s "$VALIDATION_PREPARED/imported/ListSimple.out" ]]

  python3 - "$VALIDATION_PREPARED" "$batch2_boundary" <<'PY'
import hashlib, json, re, sys
from pathlib import Path
root, boundary_path = Path(sys.argv[1]), Path(sys.argv[2])
boundary = json.loads(boundary_path.read_text())
rows = {}
for name in ('ListLast', 'ListSimple'):
    path = root / 'imported' / f'{name}.out'
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
    foundations = sorted(qualified(line.split()[1]) for line in lines if line.startswith('#AX '))
    unexpected = [x for x in foundations if not x.endswith(('propext', 'Quot.sound', 'Classical.choice'))]
    if unexpected:
        raise SystemExit(f'{name}: unexpected #AX records: {unexpected}')
    if name == 'ListLast':
        names = set()
        for line in lines:
            parts = line.split()
            if len(parts) >= 2 and parts[0] in ('#DEF', '#AX'):
                names.add(qualified(parts[1]))
            elif len(parts) >= 3 and parts[0] == '#IND':
                names.add(qualified(parts[2]))
        forbidden = set(boundary['forbidden_export_names'])
        leaked = sorted(x for x in names if x.rsplit('.', 1)[-1] in forbidden)
        if leaked:
            raise SystemExit('forbidden implementation graph leaked: ' + repr(leaked))
    rows[name] = {
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'lean_foundation_records': foundations,
        'unexpected_axiom_records': unexpected,
        'statement_only': False,
        'normal_universe_checking': True,
        'normal_elimination_checking': True,
    }
(root / 'export_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "list_last_export=$VALIDATION_PREPARED/imported/ListLast.out"
    "list_simple_export=$VALIDATION_PREPARED/imported/ListSimple.out"
    "export_manifest=$VALIDATION_PREPARED/export_manifest.json"
  )
}

validation_prepare_rocq_import() {
  printf 'From LeanImport Require Import Lean.\n\nLean Import "ListLast.out".\n' \
    >"$VALIDATION_PREPARED/imported/ImportedListLast.v"
  printf 'From LeanImport Require Import Lean.\n\nLean Import "ListSimple.out".\n' \
    >"$VALIDATION_PREPARED/imported/ImportedListSimple.v"
  local dependency="$VALIDATION_ROOT/imported/rocq90_batch1/ImportedSubadditivity.vo"
  local expected
  expected=$(jq -r '.files[] | select(.file=="util/subadditivity.v") | .vo_sha256' \
    "$VALIDATION_ROOT/imported/rocq90_batch1/artifact_manifest.json")
  [[ $(validation_sha256 "$dependency") == "$expected" ]]
  cp "$dependency" "$VALIDATION_PREPARED/imported/ImportedSubadditivity.vo"
  local module
  for module in ListLast ListSimple; do
    batch2_prepared_rocq_compile "$VALIDATION_PREPARED/imported" \
      "Imported${module}.v" >"$VALIDATION_RUN_LOG/import_${module}.log" 2>&1
  done
  python3 - "$VALIDATION_PREPARED" <<'PY'
import hashlib, json, sys
from pathlib import Path
root = Path(sys.argv[1])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
rows = {name: {'sha256': sha(root / 'imported' / f'Imported{name}.vo')}
        for name in ('Subadditivity', 'ListLast', 'ListSimple')}
(root / 'import_manifest.json').write_text(json.dumps(rows, indent=2, sort_keys=True) + '\n')
PY
  VALIDATION_STAGE_OUTPUTS=(
    "subadditivity_dependency=$VALIDATION_PREPARED/imported/ImportedSubadditivity.vo"
    "list_last_import=$VALIDATION_PREPARED/imported/ImportedListLast.vo"
    "list_simple_import=$VALIDATION_PREPARED/imported/ImportedListSimple.vo"
    "import_manifest=$VALIDATION_PREPARED/import_manifest.json"
  )
}

validation_check_setup() {
  cp -R "$VALIDATION_PREPARED/olean/." "$VALIDATION_PHASE_WORK/olean/"
  cp -R "$VALIDATION_PREPARED/source/." "$VALIDATION_PHASE_WORK/source/"
  cp -R "$VALIDATION_PREPARED/imported/." "$VALIDATION_PHASE_WORK/imported/"
  mkdir -p "$VALIDATION_PHASE_WORK/certificates"
  local module source
  for module in "${batch2_common_modules[@]}"; do
    source="$batch2_common_src/$module.v"
    cp "$source" "$VALIDATION_PHASE_WORK/certificates/"
  done
  for module in "${batch2_certificate_modules[@]}"; do
    cp "$batch2_cert_src/$module.v" "$VALIDATION_PHASE_WORK/certificates/"
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
  for module in "${batch2_common_modules[@]}" "${batch2_certificate_modules[@]}"; do
    batch2_rocq_compile "$VALIDATION_PHASE_WORK/certificates" "$module.v" \
      >"$VALIDATION_RUN_LOG/certificate_${module}.log" 2>&1
  done
  VALIDATION_STAGE_OUTPUTS=(
    "list_simple_certificate=$VALIDATION_PHASE_WORK/certificates/ListSimpleCertificate.vo"
    "list_last_certificate=$VALIDATION_PHASE_WORK/certificates/ListLastCertificate.vo"
    "list_batch5_certificate=$VALIDATION_PHASE_WORK/certificates/ListBatch5Certificate.vo"
  )
}

validation_check_assumption_audit() {
  local combined="$VALIDATION_RUN_LOG/combined_assumption_config.json"
  python3 - "$batch2_cert_src" "$combined" <<'PY'
import json, sys
from pathlib import Path
root, output = Path(sys.argv[1]), Path(sys.argv[2])
configs = [json.loads((root / f'list_{label}_assumption_config.json').read_text())
           for label in ('simple', 'last', 'batch2', 'batch3', 'batch4', 'batch5')]
out = {
    'prop_sprop_foundation': sorted(set().union(*(set(c.get('prop_sprop_foundation', [])) for c in configs))),
    'importer_foundation': sorted(set().union(*(set(c.get('importer_foundation', [])) for c in configs))),
    'rocq_sprop_uip': sorted(set().union(*(set(c.get('rocq_sprop_uip', [])) for c in configs))),
    'certificates': {},
}
for config in configs:
    for key, spec in config['certificates'].items():
        if key in out['certificates']:
            raise SystemExit('duplicate assumption audit target: ' + key)
        out['certificates'][key] = spec
output.write_text(json.dumps(out, indent=2, sort_keys=True) + '\n')
PY
  : >"$VALIDATION_RUN_LOG/assumptions.log"
  local label
  for label in Simple Last Batch2 Batch3 Batch4 Batch5; do
    cat "$VALIDATION_RUN_LOG/certificate_List${label}AssumptionAudit.log" \
      >>"$VALIDATION_RUN_LOG/assumptions.log"
  done
  python3 "$VALIDATION_ROOT/scripts/audit_assumptions.py" \
    --config "$combined" --log "$VALIDATION_RUN_LOG/assumptions.log" \
    --output "$VALIDATION_RUN_LOG/assumption_summary.json" \
    >"$VALIDATION_RUN_LOG/assumption_classifier.log" 2>&1
  python3 - "$VALIDATION_RUN_LOG/assumption_summary.json" <<'PY'
import json, sys
report = json.load(open(sys.argv[1]))
for name, row in report['certificates'].items():
    assert row['semantic_premises'] == [], name
    assert row['source_theorem_dependency'] is False, name
    assert row['target_theorem_dependency'] is False, name
    assert row['unexpected'] == [], name
    assert row['status'] in ('CERTIFIED', 'CERTIFIED_WITH_PROP_SPROP_FOUNDATION'), (name, row['status'])
PY

  validation_rocq90_exec rocqchk -silent -o \
    -Q "$IMPORTER_ROOT/src" LeanImport LeanImport.Lean \
    >"$VALIDATION_RUN_LOG/rocqchk_foundation.log" 2>&1
  local module
  for module in ImportedListLast ImportedListSimple; do
    validation_rocq90_exec rocqchk -silent -o \
      -Q "$IMPORTER_ROOT/src" LeanImport \
      -Q "$VALIDATION_PHASE_WORK/imported" FoundationImported \
      "FoundationImported.$module" \
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
for module in ('ImportedListLast', 'ImportedListSimple'):
    additional = axioms(root / f'rocqchk_{module}.log') - foundation
    known = {x for x in additional if x.endswith(('.propext', '.Quot_sound', '.Classical_choice'))}
    unexpected = sorted(additional - known)
    if unexpected:
        raise SystemExit(f'unexpected Rocq axioms for {module}: {unexpected}')
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
  local publish="$VALIDATION_ROOT/imported/rocq90_batch2"
  local status="$VALIDATION_ROOT/planning/v06_pipeline/rocq90_batch2_status.json"
  mkdir -p "$publish" "$(dirname "$status")"
  local stem module
  for stem in ListLast ListSimple; do
    cp "$VALIDATION_PREPARED/imported/$stem.out" "$publish/$stem.out"
    cp "$VALIDATION_PREPARED/imported/Imported$stem.v" "$publish/Imported$stem.v"
    cp "$VALIDATION_PREPARED/imported/Imported$stem.vo" "$publish/Imported$stem.vo"
  done
  for module in "${batch2_certificate_modules[@]}"; do
    cp "$VALIDATION_PHASE_WORK/certificates/$module.vo" "$publish/$module.vo"
  done
  cp "$VALIDATION_RUN_LOG/rocqchk_trust_summary.json" "$publish/trust_manifest.json"
  cp "$VALIDATION_PREPARED/export_manifest.json" "$publish/export_manifest.json"
  python3 - "$PROJECT_ROOT" "$SOURCE_ROOT" "$VALIDATION_ROOT" \
    "$VALIDATION_PREPARED" "$VALIDATION_RUN_LOG" "$batch2_cert_src" \
    "$publish/artifact_manifest.json" "$publish/declaration_manifest.json" \
    "$status" "$VALIDATION_SNAPSHOT_ID" <<'PY'
import csv, hashlib, json, subprocess, sys
from pathlib import Path
project, source, validation, prepared, logs, cert_root, artifact_out, declaration_out, status_out = map(Path, sys.argv[1:10])
snapshot = sys.argv[10]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
with (validation / 'planning/v06_dependency/declaration_inventory.csv').open(newline='') as handle:
    inventory = [r for r in csv.DictReader(handle) if r['source_file'] == 'util/list.v']
clusters = {}
for label in ('simple', 'last', 'batch3', 'batch4', 'batch5'):
    config = json.loads((cert_root / f'list_{label}_cluster_config.json').read_text())
    for name, spec in config['declarations'].items():
        if name in clusters: raise SystemExit('duplicate cluster declaration: ' + name)
        clusters[name] = {'cluster': label, **spec}
assumptions = json.loads((logs / 'assumption_summary.json').read_text())['certificates']
if len(inventory) != 57 or set(r['declaration_name'] for r in inventory) != set(clusters):
    raise SystemExit('fail-closed 57-declaration coverage mismatch')
rows = []
for item in inventory:
    name = item['declaration_name']
    spec = clusters[name]
    audit = assumptions[spec['audit_key']]
    rows.append({
        'source_order': int(item['source_order']), 'source_declaration': name,
        'source_kind': item['kind'], 'source_qualified_name': item['qualified_name'],
        'lean_production_declaration': 'Prosa.Util.List.' + name,
        'actual_artifact_guard': 'PASS', 'cluster': spec['cluster'],
        'certificate': spec['certificate'], 'certificate_file': spec['certificate_file'],
        'semantic_premises': audit['semantic_premises'],
        'source_theorem_dependency': audit['source_theorem_dependency'],
        'target_theorem_dependency': audit['target_theorem_dependency'],
        'unexpected_assumptions': audit['unexpected'],
        'foundation_classification': audit['status'],
        'rocq90_migration_status': 'ACCEPTED',
    })
if any(r['semantic_premises'] or r['source_theorem_dependency'] or
       r['target_theorem_dependency'] or r['unexpected_assumptions'] for r in rows):
    raise SystemExit('declaration trust contract failed')
declaration_out.write_text(json.dumps({'schema_version': 1,
    'source_file': 'util/list.v', 'authoritative_count': 57,
    'declarations': rows}, indent=2, sort_keys=True) + '\n')
artifact = {
    'schema_version': 1, 'snapshot_id': snapshot,
    'authoritative_prosa_commit': subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'], text=True).strip(),
    'mathlib_commit': subprocess.check_output(['git','-C',str(project/'.lake/packages/mathlib'),'rev-parse','HEAD'], text=True).strip(),
    'source_sha256': sha(source / 'util/list.v'),
    'lean_source_sha256': sha(project / 'Prosa/Util/List.lean'),
    'fresh_olean_sha256': sha(prepared / 'olean/Prosa/Util/List.olean'),
    'list_last_out_sha256': sha(prepared / 'imported/ListLast.out'),
    'list_simple_out_sha256': sha(prepared / 'imported/ListSimple.out'),
    'imported_list_last_vo_sha256': sha(prepared / 'imported/ImportedListLast.vo'),
    'imported_list_simple_vo_sha256': sha(prepared / 'imported/ImportedListSimple.vo'),
    'actual_artifact_guards': 57, 'statement_only': False,
  }
artifact_out.write_text(json.dumps(artifact, indent=2, sort_keys=True) + '\n')
status = {
    'schema_version': 1, 'classification': 'ROCQ90_FULL_MIGRATION_BATCH2_ACCEPTED',
    'file': 'util/list.v', 'rank': 11,
    'whole_file_acceptance': 'ACCEPTED_V06_FILE_ROCQ90',
    'active_validation_baseline': 'Rocq 9.0.0',
    'snapshot_id': snapshot, 'authoritative_declarations': 57,
    'declarations_accepted': 57, 'translated_but_not_certified': 0,
    'actual_artifact_guards': 57, 'all_certificates': 'PASS',
    'semantic_premises': [], 'source_theorem_dependency': False,
    'target_theorem_dependency': False, 'unexpected_assumptions': [],
    'normal_universe_checking': True, 'normal_elimination_checking': True,
    'type_in_type': 0, 'unsafe_fixpoints': 0, 'assumed_positivity': 0,
    'unexpected_custom_rocq_axioms': 0,
    'production_translation_modified': False,
    'next_ready': {'rank': 12, 'file': 'util/sum.v', 'authoritative_declarations': 25},
    'declarations': rows,
  }
status_out.write_text(json.dumps(status, indent=2, sort_keys=True) + '\n')
PY
  cp "$publish/artifact_manifest.json" "$VALIDATION_RUN_LOG/artifact_manifest.json"
  cp "$publish/declaration_manifest.json" "$VALIDATION_RUN_LOG/declaration_manifest.json"
  cp "$status" "$VALIDATION_RUN_LOG/rocq90_batch2_status.json"
  VALIDATION_STAGE_OUTPUTS=(
    "artifact_manifest=$VALIDATION_RUN_LOG/artifact_manifest.json"
    "declaration_manifest=$VALIDATION_RUN_LOG/declaration_manifest.json"
    "batch_status=$VALIDATION_RUN_LOG/rocq90_batch2_status.json"
    "trust_manifest=$VALIDATION_RUN_LOG/rocqchk_trust_summary.json"
  )
}
