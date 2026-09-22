#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

ROCQ_REPOSITORY=https://rocq-prover.org/opam/released
OCAML_VERSION=4.14.2
ROCQ_VERSION=9.0.0
MATHCOMP_VERSION=2.4.0
MCZIFY_VERSION=1.5.0+2.0+8.16

mkdir -p "$EXPERIMENT_ROOT/environment" "$EXPERIMENT_ROOT/logs/phase2/environment"

if [[ -d "$OPAM_ROOT" && -d "$ROCQ_SWITCH" ]] \
  && "$(dirname "$0")/phase2_check_environment.sh"; then
  echo 'phase2 environment already matches; reusing it without installation'
  exit 0
fi

if [[ ! -d "$OPAM_ROOT" ]]; then
  OPAMROOT="$OPAM_ROOT" opam init --bare --disable-sandboxing -y \
    default https://opam.ocaml.org
fi

if ! OPAMROOT="$OPAM_ROOT" opam repository list -a --short | grep -qx rocq-released; then
  OPAMROOT="$OPAM_ROOT" opam repository add rocq-released "$ROCQ_REPOSITORY" \
    -y --all-switches
fi

if ! OPAMROOT="$OPAM_ROOT" opam switch list --short | grep -Fqx "$ROCQ_SWITCH"; then
  OPAMROOT="$OPAM_ROOT" opam switch create "$ROCQ_SWITCH" \
    "ocaml-base-compiler.$OCAML_VERSION" --repos=rocq-released,default -y
fi

OPAMROOT="$OPAM_ROOT" opam install --switch="$ROCQ_SWITCH" -y -j4 \
  "rocq-prover.$ROCQ_VERSION" \
  "coq.$ROCQ_VERSION" \
  "coq-mathcomp-ssreflect.$MATHCOMP_VERSION" \
  "coq-mathcomp-fingroup.$MATHCOMP_VERSION" \
  "coq-mathcomp-algebra.$MATHCOMP_VERSION" \
  "coq-mathcomp-zify.$MCZIFY_VERSION"

"$(dirname "$0")/phase2_check_environment.sh"
