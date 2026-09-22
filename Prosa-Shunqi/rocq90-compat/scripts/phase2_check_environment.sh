#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_ROOT="$EXPERIMENT_ROOT/logs/phase2/environment"
mkdir -p "$LOG_ROOT"

required=(
  'ocaml-base-compiler=4.14.2'
  'rocq-prover=9.0.0'
  'coq=9.0.0'
  'coq-mathcomp-ssreflect=2.4.0'
  'coq-mathcomp-fingroup=2.4.0'
  'coq-mathcomp-algebra=2.4.0'
  'coq-mathcomp-zify=1.5.0+2.0+8.16'
)

if [[ ! -d "$OPAM_ROOT" || ! -d "$ROCQ_SWITCH" ]]; then
  echo 'phase2 environment is absent; run scripts/phase2_setup_environment.sh' >&2
  exit 2
fi

rocq_exec rocq --version | tee "$LOG_ROOT/rocq-version.txt"
rocq_exec coqc --version | tee "$LOG_ROOT/coqc-version.txt"
rocq_exec ocamlc -version | tee "$LOG_ROOT/ocaml-version.txt"
OPAMROOT="$OPAM_ROOT" opam list --switch="$ROCQ_SWITCH" --installed \
  --columns=name,version --separator='=' \
  | sed -E '/^#/d; s/[[:space:]]+=/=/' >"$LOG_ROOT/opam-packages.tsv"
OPAMROOT="$OPAM_ROOT" opam switch export --switch="$ROCQ_SWITCH" \
  "$LOG_ROOT/switch.export" --full

for spec in "${required[@]}"; do
  if ! grep -Fqx "$spec" "$LOG_ROOT/opam-packages.tsv"; then
    echo "required package/version missing: $spec" >&2
    exit 1
  fi
done

grep -Fq 'The Rocq Prover, version 9.0.0' "$LOG_ROOT/rocq-version.txt"
grep -Fq 'compiled with OCaml 4.14.2' "$LOG_ROOT/rocq-version.txt"
grep -Fq 'The Rocq Prover, version 9.0.0' "$LOG_ROOT/coqc-version.txt"
grep -Fxq '4.14.2' "$LOG_ROOT/ocaml-version.txt"

echo 'phase2 environment: READY'
