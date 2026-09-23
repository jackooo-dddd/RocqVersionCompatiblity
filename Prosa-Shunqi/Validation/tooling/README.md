# Reproducible validation tooling

The active semantic validator uses pinned, workspace-local builds of
`lean4export` and `rocq-lean-import` under stock Rocq 9.0.0. Rocq 9.3 remains
historical validation provenance only. The checked-in Rocq 9.0 importer is
built from commit `546979b…`, first with `rocq90-project.patch` and then with
`rocq90-api.patch`; the setup verifies that `with_unsafe_univs f () = f ()`
and rejects any `check_universes=false` or `check_eliminations=false` path.
Phase 2's unsafe-universe patch and Phase 5's experimental Acc mapping are not
part of this tooling.

Batch 1 uses proof-complete semantic boundaries rather than statement-only
production declarations. A fresh `.olean` audit binds all 46 production
types with `Meta.isDefEq`; exports contain only definitions, necessary
computation equations, and safe operation interfaces. In particular,
SearchArg uses the Phase 6 Nat.find-free boundary, and Nat/UnitGrowth do not
import theorem implementation graphs that would reintroduce `Acc`.
The exporter includes an opt-in
`LEAN4EXPORT_PRESERVE_REDUCIBLE_THEOREM_TYPES=1` mode: after a selected
subexpression projection has passed `Meta.isDefEq`, it preserves that projected
expression instead of globally unfolding unrelated reducible terms. This is
needed for theorem types containing Boolean recursors and does not bypass the
kernel normalization guard.

Run:

```bash
../scripts/setup_rocq90_environment.sh
./setup_validation_tooling.sh
```

The resulting worktrees are created under
`Validation/.work/tooling/rocq90/`. The local OPAM root and switch live under
`Validation/environment/`; neither path is acceptance evidence. The setup
fails closed on base-commit, ordered patches,
worktree-diff, toolchain, or output-artifact mismatch.  `Export.lean.orig` is
recreated only to reproduce the recorded Slice 1 worktree status; it is not a
build input.

The formal Rank 1–10 entry points are:

```bash
Validation/scripts/prepare_rocq90_batch1.sh
Validation/scripts/check_rocq90_batch1.sh
Validation/scripts/finalize_rocq90_batch1.sh
```

## Incremental validation protocol

New file validators should use the shared content-addressed protocol rather
than copying a complete shell pipeline:

```bash
Validation/scripts/run_incremental_validation.sh prepare \
  --name NAME --config DESCRIPTOR.json --hooks HOOKS.sh
Validation/scripts/run_incremental_validation.sh check \
  --name NAME --config DESCRIPTOR.json --hooks HOOKS.sh
Validation/scripts/run_incremental_validation.sh finalize \
  --name NAME --config DESCRIPTOR.json --hooks HOOKS.sh
```

`incremental_validation_state.py` binds the prepared snapshot to declared
source/production/dependency files, exact tool binaries, repository commits,
versions, options, and module-loading configuration. It hashes every declared
prepared output before reuse. Missing, mismatched, or damaged artifacts fail
closed. The hooks contain only file-specific build, extraction, export/import,
certificate, audit, and publication actions.

The evidence schema records `lean_build`, `source_acquisition`, `export`,
`rocq_import`, `certificate_compile`, `assumption_audit`, and `publication`,
including execution counts, `FRESH`/`VERIFIED_CACHE` mode, elapsed time, input
fingerprint, and output hashes. Certificate/audit files belong to the check
fingerprint, not the prepared snapshot, so a certificate-only edit reuses a
verified prepare cache but recompiles and re-audits the affected certificate
DAG. `CLEAN_FULL=1` remains available for independent reproduction.

`export_actual_artifact.sh` is the config-driven exporter entry point.
[`export_patterns.json`](export_patterns.json) records the approved uses of
statement-only export, computation-equation bodies, definition-body
projection, guarded normalization, and universe-sensitive datatype
interfaces. A normalized export without a declared kernel guard is rejected.

`generate_artifact_bool_list_adapter.py` instantiates the audited template in
`Validation/templates/ArtifactBoolListAdapter.v.tpl`. Generated adapters prove
Bool truth, `eqType`/`DecidableEq`, ordered `seq`/`List` roundtrips, and
membership against the exact imported datatype; they are ordinary Rocq source
and must pass kernel compilation and the normal assumption classifier.

The 2026-09-22 regression sample covers accepted Sum (25 declarations), Poet
(1), and Bigcat (13). Its cold prepare measured 100.29 s for the isolated Lean
closure; an identical rerun verified all four prepare stages from cache in
0.019 s. The final adapter check/finalize took 4.24 s. All 18 generated adapter
checks had no semantic premise or unexpected assumption; only Bool-truth and
membership used the existing `PropSPropFoundation.interpret_strict` boundary.
The existing 39 semantic results were unchanged. Evidence is under
`Validation/logs/incremental/workflow_regression/`.
