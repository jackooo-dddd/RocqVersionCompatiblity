#!/usr/bin/env bash

set -u
source "$(dirname "$0")/common.sh"

mkdir -p "$EXPERIMENT_ROOT/logs/source"

make -C "$SOURCE_ROOT" prosaCoqProject \
  >"$EXPERIMENT_ROOT/logs/source/full-main-project.log" 2>&1

(
  cd "$SOURCE_ROOT"
  rocq_exec rocq makefile -f _CoqProject -o Makefile.rocq90
) >"$EXPERIMENT_ROOT/logs/source/full-main-makefile.log" 2>&1

set +e
rocq_exec make -C "$SOURCE_ROOT" -f Makefile.rocq90 -j4 \
  >"$EXPERIMENT_ROOT/logs/source/full-main-build.log" 2>&1
rc=$?
set -e
printf '%s\n' "$rc" >"$EXPERIMENT_ROOT/logs/source/full-main-build.exit"
exit "$rc"
