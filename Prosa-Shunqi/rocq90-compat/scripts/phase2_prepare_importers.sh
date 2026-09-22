#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

BASE_COMMIT=546979bfd55b94288abfb72583a534b0136d282d
UPSTREAM=https://github.com/rocq-community/rocq-lean-import.git
WORK_ROOT="$EXPERIMENT_ROOT/.work/phase2"
CACHE="$WORK_ROOT/importer.git"
BASELINE="$WORK_ROOT/importer-baseline"
CANDIDATE="$WORK_ROOT/importer-candidate"
LOG_ROOT="$EXPERIMENT_ROOT/logs/phase2/patches"
PROJECT_PATCH="$EXPERIMENT_ROOT/importer/patches/rocq-lean-import.patch"
API_PATCH="$EXPERIMENT_ROOT/importer/patches/rocq-9.0-api.patch"
CANDIDATE_PATCH="$EXPERIMENT_ROOT/importer/patches/phase2-check-universes.patch"

mkdir -p "$WORK_ROOT" "$LOG_ROOT"

if [[ ! -d "$CACHE" ]]; then
  git clone --mirror "$UPSTREAM" "$CACHE"
else
  git -C "$CACHE" fetch --prune origin
fi

if [[ $(git -C "$CACHE" rev-parse "$BASE_COMMIT^{commit}") != "$BASE_COMMIT" ]]; then
  echo "pinned importer commit is unavailable: $BASE_COMMIT" >&2
  exit 1
fi

prepare_worktree() {
  local target=$1
  if [[ -e "$target" ]]; then
    git -C "$CACHE" worktree remove --force "$target"
  fi
  git -C "$CACHE" worktree add --detach "$target" "$BASE_COMMIT"
  git -C "$target" apply --check "$PROJECT_PATCH"
  git -C "$target" apply "$PROJECT_PATCH"
  git -C "$target" apply --check "$API_PATCH"
  git -C "$target" apply "$API_PATCH"
}

prepare_worktree "$BASELINE"
prepare_worktree "$CANDIDATE"
git -C "$CANDIDATE" apply --check "$CANDIDATE_PATCH"
git -C "$CANDIDATE" apply "$CANDIDATE_PATCH"

# The preserved project patch contains known trailing spaces in Lean.v.
# Check the independently maintained OCaml compatibility edits themselves.
git -C "$BASELINE" diff --check -- src/lean.ml
git -C "$CANDIDATE" diff --check -- src/lean.ml
git -C "$BASELINE" diff --binary >"$LOG_ROOT/baseline-applied.patch"
git -C "$CANDIDATE" diff --binary >"$LOG_ROOT/candidate-applied.patch"
git -C "$BASELINE" rev-parse HEAD >"$LOG_ROOT/base-commit.txt"
shasum -a 256 "$PROJECT_PATCH" "$API_PATCH" "$CANDIDATE_PATCH" \
  >"$LOG_ROOT/input-patches.sha256"

printf '%s\n' "$BASELINE" >"$WORK_ROOT/baseline.path"
printf '%s\n' "$CANDIDATE" >"$WORK_ROOT/candidate.path"
echo 'phase2 importer worktrees: READY'
