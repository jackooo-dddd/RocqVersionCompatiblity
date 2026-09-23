#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
validation_root=$(cd "$script_dir/.." && pwd)
source "$script_dir/common/rocq90_environment.sh"
validation_rocq90_environment_init "$validation_root"

rocq_repository=https://rocq-prover.org/opam/released
mkdir -p "$validation_root/environment" "$validation_root/logs/environment/rocq90"

if [[ -d "$VALIDATION_OPAM_ROOT" && -d "$VALIDATION_ROCQ90_SWITCH" ]] && \
   "$script_dir/check_rocq90_environment.sh" >/dev/null; then
  echo 'Validation Rocq 9.0 environment already matches; reusing it'
  exit 0
fi

if [[ ! -d "$VALIDATION_OPAM_ROOT" ]]; then
  OPAMROOT="$VALIDATION_OPAM_ROOT" opam init --bare --disable-sandboxing -y \
    default https://opam.ocaml.org
fi
if ! OPAMROOT="$VALIDATION_OPAM_ROOT" opam repository list -a --short \
  | grep -qx rocq-released; then
  OPAMROOT="$VALIDATION_OPAM_ROOT" opam repository add rocq-released \
    "$rocq_repository" -y --all-switches
fi
if ! OPAMROOT="$VALIDATION_OPAM_ROOT" opam switch list --short \
  | grep -Fqx "$VALIDATION_ROCQ90_SWITCH"; then
  OPAMROOT="$VALIDATION_OPAM_ROOT" opam switch create \
    "$VALIDATION_ROCQ90_SWITCH" ocaml-base-compiler.4.14.2 \
    --repos=rocq-released,default -y
fi
OPAMROOT="$VALIDATION_OPAM_ROOT" opam install \
  --switch="$VALIDATION_ROCQ90_SWITCH" -y -j4 \
  rocq-prover.9.0.0 coq.9.0.0 \
  coq-mathcomp-ssreflect.2.4.0 coq-mathcomp-fingroup.2.4.0 \
  coq-mathcomp-algebra.2.4.0 coq-mathcomp-zify.1.5.0+2.0+8.16

"$script_dir/check_rocq90_environment.sh"
