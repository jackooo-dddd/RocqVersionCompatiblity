#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"

output="$EXPERIMENT_ROOT/results/provenance.tsv"
mkdir -p "$EXPERIMENT_ROOT/results"
printf 'class\tdestination\torigin\tsha256_or_identity\n' >"$output"

record_file() {
  local class=$1 destination=$2 origin=$3
  printf '%s\t%s\t%s\t%s\n' \
    "$class" "$destination" "$origin" "$(sha256_file "$EXPERIMENT_ROOT/$destination")" \
    >>"$output"
}

record_identity() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >>"$output"
}

source_origin='/Users/shunqiwang/CityuHK/Research/ProsaRocqCompatibilityExperiment/prosa-v0.6@414e66760333eaa4ef78c685bcf53291c527a548'
record_identity source_snapshot source "$source_origin" \
  'git-tree:7d7e94c731f7eefde4ca738310d4cafdd7bebdf0;archive-sha256:ef07835e205fa673259d872a99c3813b9a6b3d4f3824636b1f2e5c9ce59fcf4b'
for rel in util/tactics.v util/seqset.v util/search_arg.v util/list.v util/div_mod.v; do
  record_file source "source/$rel" "$source_origin:$rel"
done

record_identity importer_base importer/rocq-lean-import \
  '../Validation/.work/tooling/rocq-lean-import' \
  'git-commit:546979bfd55b94288abfb72583a534b0136d282d'
record_file importer_patch importer/patches/rocq-lean-import.patch \
  '../Validation/tooling/patches/rocq-lean-import.patch'
record_file importer_patch importer/patches/rocq-9.0-api.patch \
  'experiment-local minimal Rocq-9.0 API port'

while IFS= read -r file; do
  base=$(basename "$file")
  record_file certificate_common "${file#"$EXPERIMENT_ROOT/"}" \
    "../Validation/certificates/common/$base"
done < <(find "$VALIDATION_ROOT/certificates/common" -type f -name '*.v' | sort)

while IFS= read -r file; do
  base=$(basename "$file")
  case "$base" in
    FoundationTimeCertificate.v)
      origin='../Validation/certificates/foundation_slice_1/FoundationTimeCertificate.v' ;;
    TacticsCertificate.v)
      origin='../Validation/certificates/foundation_slice_2/TacticsCertificate.v' ;;
    SearchArgDefinitionCertificate.v|SearchArgStatementCertificate.v|SearchArgAssumptionAudit.v|ListSimpleCertificate.v|ListSimpleAssumptionAudit.v|ListLastCertificate.v)
      origin="../Validation/certificates/utility_foundation/$base" ;;
    *) origin='experiment-local smoke/audit harness' ;;
  esac
  record_file certificate_smoke "${file#"$EXPERIMENT_ROOT/"}" "$origin"
done < <(find "$VALIDATION_ROOT/certificates/smoke" -type f \( -name '*.v' -o -name '*.json' \) | sort)

record_file generated_source validation/generated-source/GeneratedSearchArgSource.v \
  '../Validation/.work/runs/utility_search_arg.EniSWx/source/GeneratedSearchArgSource.v'
record_file generated_source validation/generated-source/GeneratedListSimpleSource.v \
  '../Validation/.work/list_cache_corruption_test_20260921/source/GeneratedListSimpleSource.v'
record_file generated_source validation/generated-source/GeneratedListLastSource.v \
  '../Validation/.work/list_snapshots/59d6a91640446026d494ea4a2f647bbcbdf3283aa97deded47e74351225308ff/source/GeneratedListLastSource.v'

for stem in Time Tactics Subadditivity SearchArg ListSimple ListLast Bigcat; do
  case "$stem" in
    Time) origin='../Validation/imported/foundation_slice_1' ;;
    Tactics|Subadditivity) origin='../Validation/imported/foundation_slice_2_closure' ;;
    SearchArg|ListSimple|ListLast) origin='../Validation/imported/utility_foundation' ;;
    Bigcat) origin='../Validation/imported/translation_order/bigcat' ;;
  esac
  record_file lean_export "validation/imported/$stem.out" "$origin/$stem.out"
  case "$stem" in
    Tactics|Subadditivity) wrapper_origin='../Validation/imported/foundation_slice_2' ;;
    *) wrapper_origin=$origin ;;
  esac
  record_file import_wrapper "validation/imported/Imported$stem.v" \
    "$wrapper_origin/Imported$stem.v"
done

record_file audit_tool scripts/audit_foundation_slice_1_assumptions.py \
  '../Validation/scripts/audit_foundation_slice_1_assumptions.py'
record_file audit_tool scripts/audit_assumptions.py \
  '../Validation/scripts/audit_assumptions.py'
record_file dependency_source environment/sources/mczify-1.5.0+2.0+8.16.tar.gz \
  'https://github.com/math-comp/mczify/archive/1.5.0+2.0+8.16.tar.gz'
record_file environment logs/environment/opam-list.txt 'isolated switch: opam list' 
record_file environment logs/environment/switch.export 'isolated switch: opam switch export'
