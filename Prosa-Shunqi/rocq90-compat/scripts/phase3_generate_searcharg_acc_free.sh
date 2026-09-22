#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(cd "$EXPERIMENT_ROOT/.." && pwd)
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase3"
LEAN_ROOT="$WORK_ROOT/lean"
EXPORTER="$WORK_ROOT/lean4export"
OUTPUT="$EXPERIMENT_ROOT/results/phase3/artifacts/SearchArg.acc-free.out"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase3"
EXPORTER_COMMIT=c9f8373f8a37a65c0ed9bfd20480a3d7481a163e
EXPORTER_PATCH="$PROJECT_ROOT/Validation/tooling/patches/lean4export.patch"

mkdir -p "$LEAN_ROOT/olean/Prosa/Util" "$LOG_ROOT/lean" \
  "$LOG_ROOT/export" "$(dirname "$OUTPUT")"

export ELAN_TOOLCHAIN=leanprover/lean4:v4.33.1
[[ $(cd "$PROJECT_ROOT" && lean --version) == *'version 4.33.1'* ]]
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
  "$PROJECT_ROOT/Prosa/Util/Tactics.lean" >"$LOG_ROOT/lean/Tactics.log" 2>&1
lean -DautoImplicit=false -R "$PROJECT_ROOT" \
  -o "$LEAN_ROOT/olean/Prosa/Util/SearchArg.olean" \
  "$PROJECT_ROOT/Prosa/Util/SearchArg.lean" >"$LOG_ROOT/lean/SearchArg.log" 2>&1

if [[ ! -d "$EXPORTER/.git" ]]; then
  git clone https://github.com/leanprover/lean4export.git "$EXPORTER"
  git -C "$EXPORTER" checkout --detach "$EXPORTER_COMMIT"
  git -C "$EXPORTER" apply --check "$EXPORTER_PATCH"
  git -C "$EXPORTER" apply "$EXPORTER_PATCH"
fi
[[ $(git -C "$EXPORTER" rev-parse HEAD) == "$EXPORTER_COMMIT" ]]
ELAN_TOOLCHAIN=$ELAN_TOOLCHAIN lake -d "$EXPORTER" build lean4export \
  >"$LOG_ROOT/export/exporter-build.log" 2>&1

lean -DautoImplicit=false -o "$LEAN_ROOT/SearchArgBoundaryAudit.olean" \
  "$EXPERIMENT_ROOT/tests/phase3/SearchArgBoundaryAudit.lean" \
  >"$LOG_ROOT/lean/boundary-audit.log" 2>&1

export LEAN4EXPORT_STATEMENT_ONLY=
export LEAN4EXPORT_BODY_THEOREMS=
export LEAN4EXPORT_NORMALIZE_THEOREM_TYPES=
export LEAN4EXPORT_NORMALIZE_SUBEXPRESSION_HEADS=
export LEAN4EXPORT_NORMALIZE_DEFINITION_BODIES=
export LEAN4EXPORT_DEFINITION_BODY_PROJECTIONS=

"$EXPORTER/.lake/build/bin/lean4export" Prosa.Util.SearchArg -- \
  Prosa.Util.SearchArg.search_arg \
  Prosa.Util.SearchArg.search_arg.eq_1 \
  Prosa.Util.SearchArg.search_arg.eq_2 \
  >"$OUTPUT" 2>"$LOG_ROOT/export/final.log"

if rg -q '^#AX ' "$OUTPUT"; then
  echo 'phase3 export unexpectedly contains #AX records' >&2
  exit 1
fi
if rg -q '(^|[^A-Za-z])(Acc|WellFounded|Acc_rec|Acc_rect)([^A-Za-z]|$)' "$OUTPUT"; then
  echo 'phase3 export contains a forbidden Acc dependency' >&2
  exit 1
fi

{
  printf 'artifact\tsha256\n'
  printf 'SearchArg.lean\t%s\n' "$(sha256_file "$PROJECT_ROOT/Prosa/Util/SearchArg.lean")"
  printf 'SearchArg.olean\t%s\n' "$(sha256_file "$LEAN_ROOT/olean/Prosa/Util/SearchArg.olean")"
  printf 'SearchArg.acc-free.out\t%s\n' "$(sha256_file "$OUTPUT")"
  printf 'lean4export\t%s\n' "$(sha256_file "$EXPORTER/.lake/build/bin/lean4export")"
} >"$EXPERIMENT_ROOT/results/phase3/artifact_hashes.tsv"

echo 'phase3 SearchArg proof-complete Acc-free export: READY'
