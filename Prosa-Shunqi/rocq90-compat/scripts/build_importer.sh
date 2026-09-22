#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

mkdir -p "$EXPERIMENT_ROOT/logs/importer"

git -C "$IMPORTER_ROOT" rev-parse HEAD \
  >"$EXPERIMENT_ROOT/logs/importer/base-commit.txt"
git -C "$IMPORTER_ROOT" diff --binary \
  >"$EXPERIMENT_ROOT/logs/importer/applied.patch"
shasum -a 256 "$EXPERIMENT_ROOT/logs/importer/applied.patch" \
  >"$EXPERIMENT_ROOT/logs/importer/applied-patch.sha256"

set +e
OPAMROOT="$OPAM_ROOT" opam exec --switch="$ROCQ_SWITCH" -- \
  make -C "$IMPORTER_ROOT" -j4 \
  >"$EXPERIMENT_ROOT/logs/importer/build.log" 2>&1
rc=$?
set -e
printf '%s\n' "$rc" >"$EXPERIMENT_ROOT/logs/importer/build.exit"
exit "$rc"
