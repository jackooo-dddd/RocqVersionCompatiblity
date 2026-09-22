#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(cd "$EXPERIMENT_ROOT/.." && pwd)
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase6/final"
LEAN_ROOT="$WORK_ROOT/lean"
EXPORTER="$EXPERIMENT_ROOT/.work/phase3/lean4export"
OUTPUT="$EXPERIMENT_ROOT/results/phase6/artifacts/SearchArg.natfind-free.out"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase6/final"
EXPORTER_COMMIT=c9f8373f8a37a65c0ed9bfd20480a3d7481a163e
EXPORTER_PATCH="$PROJECT_ROOT/Validation/tooling/patches/lean4export.patch"

if [[ -e "$LEAN_ROOT" ]]; then
  find "$LEAN_ROOT" -depth -delete
fi
mkdir -p "$LEAN_ROOT/olean/Prosa/Util" "$LOG_ROOT" "$(dirname "$OUTPUT")"

export ELAN_TOOLCHAIN=leanprover/lean4:v4.33.1
[[ $(lean --version) == *'version 4.33.1'* ]]
[[ $(git -C "$PROJECT_ROOT/.lake/packages/mathlib" rev-parse HEAD) == \
  0df444a360eaa60ab8c11dca51a86af692955474 ]]

if [[ ! -f "$PROJECT_ROOT/.lake/packages/mathlib/.lake/build/lib/lean/Mathlib/Tactic.olean" \
   || ! -f "$PROJECT_ROOT/.lake/packages/mathlib/.lake/build/lib/lean/Mathlib/Data/Nat/Find.olean" ]]; then
  (cd "$PROJECT_ROOT" && lake exe cache get Mathlib.Tactic Mathlib.Data.Nat.Find)
fi

MATHLIB_PATH=$(cd "$PROJECT_ROOT" && lake env printenv LEAN_PATH)
export LEAN_PATH="$LEAN_ROOT/olean:$PROJECT_ROOT:$MATHLIB_PATH"

lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$LEAN_ROOT/olean/Prosa/Util/Tactics.olean" \
  "$PROJECT_ROOT/Prosa/Util/Tactics.lean" >"$LOG_ROOT/lean-tactics.log" 2>&1
lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$LEAN_ROOT/olean/Prosa/Util/SearchArg.olean" \
  "$PROJECT_ROOT/Prosa/Util/SearchArg.lean" >"$LOG_ROOT/lean-searcharg.log" 2>&1

lean -DautoImplicit=false \
  -o "$LEAN_ROOT/SearchArgNatFindFreeAudit.olean" \
  "$EXPERIMENT_ROOT/tests/phase6/SearchArgNatFindFreeAudit.lean" \
  >"$LOG_ROOT/lean-type-and-axiom-audit.log" 2>&1
rg -q 'TYPE_DEF_EQ_OK target=Prosa.Util.SearchArg.prop_on_ex_minn' \
  "$LOG_ROOT/lean-type-and-axiom-audit.log"
rg -q "'Prosa.Util.SearchArg.prop_on_ex_minn' does not depend on any axioms" \
  "$LOG_ROOT/lean-type-and-axiom-audit.log"

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

"$EXPORTER/.lake/build/bin/lean4export" Prosa.Util.SearchArg -- \
  Prosa.Util.SearchArg.search_arg \
  Prosa.Util.SearchArg.search_arg.eq_1 \
  Prosa.Util.SearchArg.search_arg.eq_2 \
  Prosa.Util.SearchArg.prop_on_ex_minn \
  Iff Iff.intro Iff.mp Iff.mpr \
  >"$OUTPUT" 2>"$LOG_ROOT/export.log"

if rg -q '^#AX ' "$OUTPUT"; then
  echo 'phase6 export unexpectedly contains #AX records' >&2
  exit 1
fi
if rg -q '#NS [0-9]+ (find|findX|Acc|WellFounded|Acc_rec|Acc_rect)$' "$OUTPUT"; then
  echo 'phase6 export contains a forbidden Nat.find/Acc dependency' >&2
  exit 1
fi

{
  printf 'artifact\tsha256\n'
  printf 'SearchArg.lean\t%s\n' "$(sha256_file "$PROJECT_ROOT/Prosa/Util/SearchArg.lean")"
  printf 'SearchArg.olean\t%s\n' "$(sha256_file "$LEAN_ROOT/olean/Prosa/Util/SearchArg.olean")"
  printf 'SearchArg.natfind-free.out\t%s\n' "$(sha256_file "$OUTPUT")"
  printf 'lean4export\t%s\n' "$(sha256_file "$EXPORTER/.lake/build/bin/lean4export")"
} >"$EXPERIMENT_ROOT/results/phase6/artifact_hashes.tsv"

echo 'phase6 fresh Lean compile and proof-complete Nat.find-free export: PASS'
