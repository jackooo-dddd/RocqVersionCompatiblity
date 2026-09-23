#!/usr/bin/env bash
set -euo pipefail

tooling_dir=$(cd "$(dirname "$0")" && pwd)
validation_root=$(cd "$tooling_dir/.." && pwd)
work_root="$validation_root/.work/tooling/rocq90"
exporter="$work_root/lean4export"
importer="$work_root/rocq-lean-import"
exporter_url=https://github.com/leanprover/lean4export.git
importer_url=https://github.com/rocq-community/rocq-lean-import.git
exporter_commit=c9f8373f8a37a65c0ed9bfd20480a3d7481a163e
importer_commit=b8291b9dae4f5ed780112e95eea484e435199b46
exporter_patch="$tooling_dir/patches/lean4export.patch"
importer_patch="$tooling_dir/patches/rocq90-importer.patch"
expected_exporter_patch=371bbdd53f3ca868c7c1c09734372f81634060ca3023c491dab95c8f7e9a61f4
expected_importer_patch=7bfe3fec08074ce6818d12621aad7afc68899453805c74b36d7bd3fe55572fa0
expected_exporter_diff=$expected_exporter_patch
expected_importer_diff=$expected_importer_patch
expected_exporter_status=2be73180d81e431f05e5311437ba98e26e0440bf00f75e2adad0ec46c1bb92e2
expected_importer_status=36e27329d0e78477933bec8f1889b14d6fb3e75ca96656227f9483ed03fd8104
source "$validation_root/scripts/common/rocq90_environment.sh"
validation_rocq90_environment_init "$validation_root"

sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
stream_sha256() { shasum -a 256 | awk '{print $1}'; }

[[ $(sha256 "$exporter_patch") == "$expected_exporter_patch" ]]
[[ $(sha256 "$importer_patch") == "$expected_importer_patch" ]]
mkdir -p "$work_root"

prepare_checkout() {
  local url=$1 target=$2 commit=$3 patch=$4 preserve_original=${5:-0}
  if [[ ! -e "$target/.git" ]]; then
    if [[ -e "$target" ]]; then
      echo "tool target exists but is not a Git checkout: $target" >&2
      exit 1
    fi
    git clone "$url" "$target"
    git -C "$target" checkout --detach "$commit"
    if [[ "$preserve_original" == 1 ]]; then
      cp "$target/Export.lean" "$target/Export.lean.orig"
    fi
    git -C "$target" apply "$patch"
  fi
  [[ $(git -C "$target" rev-parse HEAD) == "$commit" ]] || {
    echo "tool base commit mismatch: $target" >&2
    exit 1
  }
}

prepare_checkout "$exporter_url" "$exporter" "$exporter_commit" "$exporter_patch" 1
if [[ ! -e "$importer/.git" ]]; then
  if [[ -e "$importer" ]]; then
    echo "tool target exists but is not a Git checkout: $importer" >&2
    exit 1
  fi
  git clone "$importer_url" "$importer"
  git -C "$importer" checkout --detach "$importer_commit"
  git -C "$importer" apply --check "$importer_patch"
  git -C "$importer" apply "$importer_patch"
fi
[[ $(git -C "$importer" rev-parse HEAD) == "$importer_commit" ]] || {
  echo "tool base commit mismatch: $importer" >&2
  exit 1
}

[[ $(git -C "$exporter" diff | stream_sha256) == "$expected_exporter_diff" ]]
[[ $(git -C "$importer" diff | stream_sha256) == "$expected_importer_diff" ]]
[[ $(git -C "$exporter" status --porcelain | stream_sha256) == "$expected_exporter_status" ]]
[[ $(git -C "$importer" status --porcelain | stream_sha256) == "$expected_importer_status" ]]

ELAN_TOOLCHAIN=leanprover/lean4:v4.33.1 lake -d "$exporter" build lean4export
"$validation_root/scripts/check_rocq90_environment.sh" >/dev/null
validation_rocq90_exec make -C "$importer" -j2

[[ $(rg -c '^let with_unsafe_univs f \(\) = f \(\)$' "$importer/src/lean.ml") == 1 ]]
! rg -q 'check_universes[[:space:]]*=[[:space:]]*false' "$importer/src"
! rg -q 'check_eliminations[[:space:]]*=[[:space:]]*false' "$importer/src"

cat <<EOF
LEAN4EXPORT_SRC=$exporter
ROCQLI_SRC=$importer
LEAN4EXPORT_BINARY_SHA256=$(sha256 "$exporter/.lake/build/bin/lean4export")
ROCQLI_PLUGIN_SHA256=$(sha256 "$importer/src/lean_import.cmxs")
ROCQLI_FOUNDATION_SHA256=$(sha256 "$importer/src/Lean.vo")
EOF
