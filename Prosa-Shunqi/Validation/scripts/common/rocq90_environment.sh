#!/usr/bin/env bash

# Hermetic Rocq 9.0 environment used by the active Validation pipeline.
# This file is sourced by setup/check/build scripts; callers enable strict mode.

validation_rocq90_environment_init() {
  local validation_root=$1
  VALIDATION_OPAM_ROOT=${VALIDATION_OPAM_ROOT:-"$validation_root/environment/opam-root"}
  VALIDATION_ROCQ90_SWITCH=${VALIDATION_ROCQ90_SWITCH:-"$validation_root/environment/rocq-9.0"}
  export OPAMROOT="$VALIDATION_OPAM_ROOT"
}

validation_rocq90_exec() {
  OPAMROOT="$VALIDATION_OPAM_ROOT" opam exec \
    --switch="$VALIDATION_ROCQ90_SWITCH" -- "$@"
}

