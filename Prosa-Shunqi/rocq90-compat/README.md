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

## Phase 2: Acc compatibility diagnostic

Phase 2 is a separate, fail-closed diagnostic. It does not modify the original
source tree, Lean exports, Rocq kernel, formal certificate status, or the
historical results above. Its opam root, importer worktrees, compilation
directories, logs, and results are isolated under this experiment.

Run the current-machine reproduction entry points in this order:

```sh
scripts/phase2_setup_environment.sh
scripts/phase2_run_ab_imports.sh
scripts/phase2_run_acc_audit.sh
tests/phase2/test_fail_closed.sh
```

The setup script reuses an already matching local switch. Otherwise it creates
only `environment/opam-root` and `environment/rocq-9.0`, with the frozen
versions listed above; it does not select or alter a global default switch.
The A/B runner checks every reused `.out` hash, rebuilds both importer variants
from the pinned commit in independent worktrees, and compiles each case in a
clean directory with explicit plugin paths. The candidate compatibility patch
is opt-in and lives at
`importer/patches/phase2-check-universes.patch`; it is never applied to the
baseline or original importer checkout.

Machine-readable outcomes are in `results/phase2/`; complete exit codes and
logs are in `logs/phase2/`. See `results/phase2/acc_compat_report.md` for the
semantic and trust boundary of the experiment.
