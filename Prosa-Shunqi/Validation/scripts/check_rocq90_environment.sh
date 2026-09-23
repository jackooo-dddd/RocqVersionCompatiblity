#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
validation_root=$(cd "$script_dir/.." && pwd)
source "$script_dir/common/rocq90_environment.sh"
validation_rocq90_environment_init "$validation_root"

log_root="$validation_root/logs/environment/rocq90"
mkdir -p "$log_root"

required=(
  'ocaml-base-compiler=4.14.2'
  'rocq-prover=9.0.0'
  'coq=9.0.0'
  'coq-mathcomp-ssreflect=2.4.0'
  'coq-mathcomp-fingroup=2.4.0'
  'coq-mathcomp-algebra=2.4.0'
  'coq-mathcomp-zify=1.5.0+2.0+8.16'
)

[[ -d "$VALIDATION_OPAM_ROOT" && -d "$VALIDATION_ROCQ90_SWITCH" ]] || {
  echo 'Rocq 9.0 Validation environment is absent; run setup_rocq90_environment.sh' >&2
  exit 2
}

validation_rocq90_exec rocq --version | tee "$log_root/rocq-version.txt"
validation_rocq90_exec coqc --version | tee "$log_root/coqc-version.txt"
validation_rocq90_exec ocamlc -version | tee "$log_root/ocaml-version.txt"
OPAMROOT="$VALIDATION_OPAM_ROOT" opam list --switch="$VALIDATION_ROCQ90_SWITCH" \
  --installed --columns=name,version --separator='=' \
  | sed -E '/^#/d; s/[[:space:]]+=/=/' >"$log_root/opam-packages.tsv"

for spec in "${required[@]}"; do
  grep -Fqx "$spec" "$log_root/opam-packages.tsv" || {
    echo "required package/version missing: $spec" >&2
    exit 1
  }
done
grep -Fq 'The Rocq Prover, version 9.0.0' "$log_root/rocq-version.txt"
grep -Fq 'compiled with OCaml 4.14.2' "$log_root/rocq-version.txt"
grep -Fq 'The Rocq Prover, version 9.0.0' "$log_root/coqc-version.txt"
grep -Fxq '4.14.2' "$log_root/ocaml-version.txt"

echo 'Validation Rocq 9.0 environment: READY'

