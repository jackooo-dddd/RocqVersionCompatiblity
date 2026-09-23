#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(cd "$EXPERIMENT_ROOT/.." && pwd)
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase7/final/lean"
OLEAN_ROOT="$WORK_ROOT/olean"
EXPORTER="$EXPERIMENT_ROOT/.work/phase3/lean4export"
RESULT_ROOT="$EXPERIMENT_ROOT/results/phase7"
ARTIFACT_ROOT="$RESULT_ROOT/artifacts"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase7/final"
EXPORTER_COMMIT=c9f8373f8a37a65c0ed9bfd20480a3d7481a163e
EXPORTER_PATCH="$PROJECT_ROOT/Validation/tooling/patches/lean4export.patch"

if [[ -e "$WORK_ROOT" ]]; then
  find "$WORK_ROOT" -depth -delete
fi
mkdir -p "$OLEAN_ROOT/Prosa/Util" \
  "$OLEAN_ROOT/Validation/fixtures/utility_foundation" \
  "$OLEAN_ROOT/Validation/fixtures/translation_order" \
  "$OLEAN_ROOT/Phase7" "$ARTIFACT_ROOT" "$LOG_ROOT"

export ELAN_TOOLCHAIN=leanprover/lean4:v4.33.1
[[ $(lean --version) == *'version 4.33.1'* ]]
[[ $(git -C "$PROJECT_ROOT/.lake/packages/mathlib" rev-parse HEAD) == \
  0df444a360eaa60ab8c11dca51a86af692955474 ]]

MATHLIB_PATH=$(cd "$PROJECT_ROOT" && lake env printenv LEAN_PATH)
export LEAN_PATH="$OLEAN_ROOT:$PROJECT_ROOT:$MATHLIB_PATH"

compile_project_module() {
  local module=$1
  local output="$OLEAN_ROOT/${module}.olean"
  mkdir -p "$(dirname "$output")"
  lean -DautoImplicit=false -R "$PROJECT_ROOT" -o "$output" \
    "$PROJECT_ROOT/${module}.lean"
}

for module in Supremum Tactics Notation List Bigcat; do
  compile_project_module "Prosa/Util/$module" \
    >"$LOG_ROOT/lean-$module.log" 2>&1
done

compile_project_module \
  Validation/fixtures/utility_foundation/ListLastComputationInterface \
  >"$LOG_ROOT/lean-listlast-computation-interface.log" 2>&1
lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$OLEAN_ROOT/Phase7/ListLastSafeInterface.olean" \
  "$EXPERIMENT_ROOT/tests/phase7/ListLastSafeInterface.lean" \
  >"$LOG_ROOT/lean-listlast-safe-interface.log" 2>&1
lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$OLEAN_ROOT/Phase7/ListLastBoundary.olean" \
  "$EXPERIMENT_ROOT/tests/phase7/ListLastBoundary.lean" \
  >"$LOG_ROOT/lean-listlast-boundary.log" 2>&1
lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$OLEAN_ROOT/Phase7/ListLastArtifactAudit.olean" \
  "$EXPERIMENT_ROOT/tests/phase7/ListLastArtifactAudit.lean" \
  >"$LOG_ROOT/lean-listlast-artifact-audit.log" 2>&1

compile_project_module \
  Validation/fixtures/translation_order/BigcatComputationInterface \
  >"$LOG_ROOT/lean-bigcat-computation-interface.log" 2>&1
compile_project_module \
  Validation/fixtures/translation_order/BigcatNormalizationGuard \
  >"$LOG_ROOT/lean-bigcat-normalization-guard.log" 2>&1
lean -DautoImplicit=false \
  "$PROJECT_ROOT/Validation/fixtures/translation_order/LeanBigcatAudit.lean" \
  >"$LOG_ROOT/lean-bigcat-artifact-audit.log" 2>&1

rg -q 'TYPE_DEF_EQ_OK target=Prosa.Util.List.last0_nth' \
  "$LOG_ROOT/lean-listlast-artifact-audit.log"
rg -q 'TYPE_DEF_EQ_OK target=Prosa.Util.List.max_of_dominating_seq' \
  "$LOG_ROOT/lean-listlast-artifact-audit.log"
rg -q 'TYPE_DEF_EQ_OK target=Prosa.Util.List.nth0_cons' \
  "$LOG_ROOT/lean-listlast-artifact-audit.log"
rg -q 'KERNEL_NORMALIZATION_GUARD.*size_big_nat.*proof=Eq.refl' \
  "$LOG_ROOT/lean-bigcat-normalization-guard.log"

if [[ ! -d "$EXPORTER/.git" ]]; then
  git clone https://github.com/leanprover/lean4export.git "$EXPORTER"
  git -C "$EXPORTER" checkout --detach "$EXPORTER_COMMIT"
  git -C "$EXPORTER" apply --check "$EXPORTER_PATCH"
  git -C "$EXPORTER" apply "$EXPORTER_PATCH"
fi
[[ $(git -C "$EXPORTER" rev-parse HEAD) == "$EXPORTER_COMMIT" ]]
ELAN_TOOLCHAIN=$ELAN_TOOLCHAIN lake -d "$EXPORTER" build lean4export \
  >"$LOG_ROOT/exporter-build.log" 2>&1

unset LEAN4EXPORT_STATEMENT_ONLY LEAN4EXPORT_BODY_THEOREMS \
  LEAN4EXPORT_NORMALIZE_THEOREM_TYPES \
  LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS \
  LEAN4EXPORT_NORMALIZE_DEFINITION_BODIES \
  LEAN4EXPORT_DEFINITION_BODY_PROJECTIONS || true

listlast_theorems=(
  Prosa.Util.List.last0_cons
  Prosa.Util.List.last0_cat
  Prosa.Util.List.last0_ex_cat
  Prosa.Util.List.last0_filter
  Prosa.Util.List.max0_cons
  Prosa.Util.List.max0_2cons_eq
  Prosa.Util.List.max0_2cons_le
  Prosa.Util.List.last_of_seq_le_max_of_seq
  Prosa.Util.List.max0_of_uniform_set
  Prosa.Util.List.in_max0_le
  Prosa.Util.List.max0_in_seq
  Prosa.Util.List.max0_rem0
)
listlast_interfaces=(
  Prosa.Validation.ListLastInterface.nat_zero
  Prosa.Validation.ListLastInterface.append_nil
  Prosa.Validation.ListLastInterface.append_cons
  Prosa.Validation.ListLastInterface.filter_nil
  Prosa.Validation.ListLastInterface.filter_cons
  Prosa.Validation.ListLastInterface.length_nil
  Prosa.Validation.ListLastInterface.length_cons_succ
  Prosa.Validation.ListLastInterface.sub_one
  Prosa.Validation.Phase7ListLastInterface.getD_nat_nil
  Prosa.Validation.Phase7ListLastInterface.getD_nat_zero
  Prosa.Validation.Phase7ListLastInterface.getD_nat_succ
)
export LEAN4EXPORT_BODY_THEOREMS=$(printf '%s\n' \
  "${listlast_theorems[@]}" "${listlast_interfaces[@]}")
"$EXPORTER/.lake/build/bin/lean4export" Phase7.ListLastBoundary -- \
  Prosa.Util.List.last0 Prosa.Util.List.max0 \
  Prosa.Validation.Phase7ListLastInterface.getD \
  "${listlast_theorems[@]}" "${listlast_interfaces[@]}" \
  >"$ARTIFACT_ROOT/ListLast.phase7.out" 2>"$LOG_ROOT/export-listlast.log"

bigcat_theorems=(
  Prosa.Util.Bigcat.mem_bigcat_nat
  Prosa.Util.Bigcat.mem_bigcat_nat_exists
  Prosa.Util.Bigcat.mem_bigcat_ord
  Prosa.Util.Bigcat.bigcat_nat_uniq
  Prosa.Util.Bigcat.bigcat_nat_filter_eq_filter_bigcat_nat
  Prosa.Util.Bigcat.size_big_nat
  Prosa.Util.Bigcat.mem_bigcat
  Prosa.Util.Bigcat.mem_bigcat_exists
  Prosa.Util.Bigcat.bigcat_filter_eq_filter_bigcat
  Prosa.Util.Bigcat.bigcat_uniq
  Prosa.Util.Bigcat.seq_different_elements_nil
  Prosa.Util.Bigcat.bigcat_seq_uniqK
  Prosa.Util.Bigcat.bigcat_partitions
)
bigcat_interfaces=(
  Prosa.Validation.BigcatInterface.production_bigCat_same
  Prosa.Validation.BigcatInterface.production_bigCat_of_le
  Prosa.Validation.BigcatInterface.production_bigCat_add_succ
  Prosa.Validation.BigcatInterface.production_bigCatFin_zero
  Prosa.Validation.BigcatInterface.production_bigCatFin_succ
  Prosa.Validation.BigcatInterface.production_bigCatSeq_eq
  Prosa.Validation.BigcatInterface.production_bigCatSeqAll_eq
  Prosa.Validation.BigcatInterface.production_append_nil
  Prosa.Validation.BigcatInterface.production_append_cons
  Prosa.Validation.BigcatInterface.production_flatMap_nil
  Prosa.Validation.BigcatInterface.production_flatMap_cons
  Prosa.Validation.BigcatInterface.production_filter_nil
  Prosa.Validation.BigcatInterface.production_filter_cons
  Prosa.Validation.BigcatInterface.production_length_nil
  Prosa.Validation.BigcatInterface.production_length_cons
)
export LEAN4EXPORT_BODY_THEOREMS=$(printf '%s\n' \
  "${bigcat_theorems[@]}" "${bigcat_interfaces[@]}")
export LEAN4EXPORT_NORMALIZE_THEOREM_TYPES=Prosa.Util.Bigcat.size_big_nat
export LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS=Finset.sum
"$EXPORTER/.lake/build/bin/lean4export" \
  Validation.fixtures.translation_order.BigcatComputationInterface -- \
  "${bigcat_theorems[@]}" \
  Prosa.Util.Notation.bigCat Prosa.Util.Bigcat.bigCatFin \
  Prosa.Util.Bigcat.bigCatSeq Prosa.Util.Bigcat.bigCatSeqAll \
  "${bigcat_interfaces[@]}" \
  >"$ARTIFACT_ROOT/Bigcat.phase7.out" 2>"$LOG_ROOT/export-bigcat.log"

for artifact in ListLast Bigcat; do
  [[ -s "$ARTIFACT_ROOT/$artifact.phase7.out" ]]
  ! rg -q '#NS [0-9]+ (Acc|WellFounded|Acc_rec|Acc_rect|find|findX)$' \
    "$ARTIFACT_ROOT/$artifact.phase7.out"
done
[[ $(rg -c '^#AX ' "$ARTIFACT_ROOT/ListLast.phase7.out") == 1 ]]
[[ $(rg -c '^#AX ' "$ARTIFACT_ROOT/Bigcat.phase7.out") == 3 ]]
rg -q '^NORMALIZED_THEOREM_TYPE Prosa.Util.Bigcat.size_big_nat.*defeq=true$' \
  "$LOG_ROOT/export-bigcat.log"

{
  printf 'artifact\tsha256\n'
  printf 'List.lean\t%s\n' "$(sha256_file "$PROJECT_ROOT/Prosa/Util/List.lean")"
  printf 'List.olean\t%s\n' "$(sha256_file "$OLEAN_ROOT/Prosa/Util/List.olean")"
  printf 'ListLastSafeInterface.olean\t%s\n' \
    "$(sha256_file "$OLEAN_ROOT/Phase7/ListLastSafeInterface.olean")"
  printf 'ListLast.phase7.out\t%s\n' \
    "$(sha256_file "$ARTIFACT_ROOT/ListLast.phase7.out")"
  printf 'Bigcat.lean\t%s\n' "$(sha256_file "$PROJECT_ROOT/Prosa/Util/Bigcat.lean")"
  printf 'Bigcat.olean\t%s\n' "$(sha256_file "$OLEAN_ROOT/Prosa/Util/Bigcat.olean")"
  printf 'Bigcat.phase7.out\t%s\n' \
    "$(sha256_file "$ARTIFACT_ROOT/Bigcat.phase7.out")"
  printf 'lean4export\t%s\n' \
    "$(sha256_file "$EXPORTER/.lake/build/bin/lean4export")"
} >"$RESULT_ROOT/artifact_hashes.tsv"

echo 'phase7 fresh Lean compile and proof-complete exports: PASS'
