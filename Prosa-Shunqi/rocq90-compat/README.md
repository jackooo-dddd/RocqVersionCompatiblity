# Rocq 9.0 Compatibility Experiment

This directory is an isolated experiment for Prosa v0.6 and the existing
Lean-to-Rocq validation pipeline. Nothing outside this directory is modified.

## Frozen inputs

- Prosa v0.6 commit: `414e66760333eaa4ef78c685bcf53291c527a548`
- Prosa tree: `7d7e94c731f7eefde4ca738310d4cafdd7bebdf0`
- Rocq: `9.0.0`
- OCaml: `4.14.2`
- MathComp: `2.4.0`
- mczify: `coq-mathcomp-zify.1.5.0+2.0+8.16` (exact 1.5.0 tag)
- rocq-lean-import base commit:
  `546979bfd55b94288abfb72583a534b0136d282d`
- rocq-lean-import project patch SHA-256:
  `0b3f5ad7903d43ee211f77d92a814ab799d0392bd6848d6eec5906a16b5de3f4`

The authoritative source was materialized with `git archive` from the exact
commit. The archive SHA-256 is
`ef07835e205fa673259d872a99c3813b9a6b3d4f3824636b1f2e5c9ce59fcf4b`.

## Layout

- `source/`: pristine authoritative Prosa source plus local compilation output
- `importer/`: pinned importer checkout and copied project patch
- `validation/`: copied `.out`, import wrappers, generated source interfaces,
  and existing certificate sources
- `environment/`: isolated opam root and local Rocq 9.0 switch
- `scripts/`: reproducible experiment entry points
- `logs/`: complete command output and exit codes
- `results/`: machine-readable summaries and the final report

## Reproduction

All scripts derive paths from this directory and force the local opam root and
switch. Run them in order:

```sh
scripts/run_source_tests.sh
scripts/run_full_source_build.sh
scripts/build_importer.sh
scripts/run_import_tests.sh
scripts/run_certificate_smoke.sh
scripts/record_provenance.sh
```

The focused source tests and the 343-file main-development build compile the
unmodified official files. The direct build failure of the exact currently
used project-patched importer is retained in `logs/importer/`; the checked-out
working tree also carries the separate Rocq-9.0 API port. That port is kept as
`importer/patches/rocq-9.0-api.patch`; it makes the plugin build, but cannot
recreate the newer kernel's unsafe elimination switch. See
`results/rocq90_compat_report.md` for the resulting `Acc` import blocker.

Exact mczify 1.5.0 belongs to the compatibility `coq-*` opam namespace. Its
dependencies are Rocq 9.0 compatibility binaries/metapackages pointing to the
same installed Rocq 9.0 and MathComp 2.4 libraries. The official 1.5.0 source
tag is retained under `environment/sources/`; installation and package-list
evidence is retained in `logs/environment/`.
