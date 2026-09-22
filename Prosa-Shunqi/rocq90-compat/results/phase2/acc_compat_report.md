# Rocq 9.0 Acc historical compatibility experiment (phase 2)

Date: 2026-09-22 (Asia/Hong_Kong)

## Scope and repository state

This phase only restores a reproducible Rocq 9.0 experiment entry and tests the
historical `Acc` compatibility path. It does not change the Prosa source, Lean
exports, Lean/Mathlib versions, Rocq kernel, the Rocq 9.3 environments, the
translation DAG, or any formal acceptance status. No certificate sweep was
run.

The starting repository state was:

- Git HEAD: `f0faa5f549371f0ffa57768a4cb0ff931973f89b` (`main`).
- Worktree: clean; there were no pre-existing local changes to overwrite.
- No applicable `AGENTS.md` was present in this repository.
- The phase-1 reports, provenance, and two original importer patches were read
  and retained unchanged as the historical baseline.

All transient builds are under `.work/phase2/`; the isolated opam installation
is under `environment/`; new evidence is under `logs/phase2/` and
`results/phase2/`. The original importer checkout is not used as a build
result.

## Environment and reproducible entry

Status: **READY**.

The local switch was absent/unusable after the repository move, so it was
rebuilt inside this experiment. `scripts/phase2_setup_environment.sh` now
first validates and reuses a matching switch, and only installs when the
isolated environment is missing or mismatched. It never changes the global
default switch.

Verified versions:

| Component | Version |
|---|---:|
| Rocq / compatibility `coq` package | 9.0.0 |
| Compiler used by Rocq | OCaml 4.14.2 |
| MathComp ssreflect/fingroup/algebra | 2.4.0 |
| mczify (`coq-mathcomp-zify`) | 1.5.0+2.0+8.16 |

The complete installed package list and an opam switch export are in
`logs/phase2/environment/`. Reproduction commands are:

```sh
scripts/phase2_setup_environment.sh
scripts/phase2_run_ab_imports.sh
scripts/phase2_run_acc_audit.sh
tests/phase2/test_fail_closed.sh
```

The A/B runner raises only its child process stack limit to 65520 KiB. Without
that local limit, the large `ListLast` and `Bigcat` imports hit the default
macOS 8 MiB stack guard (exit 139). No global shell or operating-system setting
is changed.

## Frozen inputs and importer construction

All seven existing `.out` files matched the SHA-256 values in the phase-1
provenance before they were used. No Lean build or export was performed.

Both variants are fresh independent worktrees at importer commit
`546979bfd55b94288abfb72583a534b0136d282d`. The scripts check and apply, in
order:

1. the preserved project patch;
2. the preserved Rocq-9.0 API patch;
3. only for the candidate, `phase2-check-universes.patch`.

Every patch is checked with `git apply --check` before application. Both
importers compiled successfully against the isolated switch. Historical `.vo`,
`.vos`, `.vok`, and plugin binaries were not counted as phase-2 build results;
the fresh artifact hashes are recorded in `logs/phase2/build/`.

History check: the pinned importer already includes the change discussed in
[rocq-lean-import PR #57](https://github.com/rocq-community/rocq-lean-import/pull/57),
which uses Rocq's later `check_eliminations=false` escape hatch. Rocq 9.0 does
not expose that typing flag, which is why the phase-1 API patch made
`with_unsafe_univs` a no-op. The phase-2 candidate restores the older
`check_universes=false` implementation, while retaining exception-safe flag
restoration. This matches the historical compatibility direction discussed
alongside [Rocq PR #21531](https://github.com/rocq-prover/rocq/pull/21531); it is
not an upgrade to either repository's latest code.

## Fail-closed harness changes

`run_import_tests.sh` and `run_certificate_smoke.sh` now retain each real exit
code and return nonzero if any required item fails. A dependency failure is
recorded as `BLOCKED`; an unexecuted item cannot be reported as `PASS`.

The phase-2 A/B runner has the same aggregation rule. Its baseline `Acc`
failure is labeled `EXPECTED_FAILURE`, never import success. The failure
injection test forces an internal command to exit 1 and verifies that the
runner itself returns 97; the test passes. Each A/B case has a separate clean
directory and explicit importer/plugin load paths.

## A/B import results

The machine-readable table is `results/phase2/ab_import_status.tsv`; individual
exit codes and complete output are in `logs/phase2/imports/`.

| Variant | Module | Result | Imported entries |
|---|---|---|---:|
| baseline (API no-op) | Time | PASS | 3 |
| baseline (API no-op) | SearchArg | EXPECTED_FAILURE | stopped at `Acc` |
| historical candidate | SearchArg | PASS | 191 |
| historical candidate | ListLast | PASS | 852 |
| historical candidate | Bigcat | PASS | 879 |
| historical candidate | Time | PASS | 3 |
| historical candidate | Tactics | PASS | 15 |
| historical candidate | Subadditivity | PASS | 45 |
| historical candidate | ListSimple | PASS | 113 |

The baseline failure reproduces the phase-1 location exactly:
`SearchArg.out` line 4009, declaration `Acc`, followed by the preserved squash
assertion in `src/lean.ml`. Thus the previous report remains applicable on this
machine. Candidate expansion was performed only after candidate `SearchArg`
passed, and every A/B case used the same already-hashed `.out` input.

## Candidate scope and evidence beyond `.vo`

The candidate is diagnostic and opt-in. During only the importer callback that
declares a Coq-squashed but not Lean-squashed inductive, it saves all current
typing flags, sets only `check_universes=false`, then restores the complete
saved record on both normal and exception paths. A source-level test verifies
both restoration branches. It does not disable `check_guarded` or
`check_positive`, remove the squash assertion, add `Admitted`/`Axiom`, or alter
guard/positivity checks.

The SearchArg audit checks the existence and representative types of `Acc`,
`Acc_intro`, `Acc_rec`, `Acc_rect`, `WellFounded`, `WellFounded_fix`,
`search_arg`, and `prop_on_ex_minn`. In particular, imported `Acc` is an
`SProp` and `Acc_rec` eliminates into `Set`; `Acc_rect` eliminates into `Type`.
An explicit-universe negative declaration fails after import, confirming that
the current global universe check was restored on the normal return path.

The minimal closed `Acc_rec` application is accepted and has type `nat`, but it
does **not** reduce to `7` by kernel conversion/reflexivity: evaluation remains
stuck at the imported eliminator. The audit records this as an expected
negative test rather than claiming computation behavior was established.

Independent `rocqchk -o` evidence is stronger than merely observing `.vo`
creation or using `Print Assumptions` alone:

- `Acc`, `WellFounded`, `Acc_rec`, `Acc_ind`, `Acc_sind`, `Acc_rect`, and the
  imported `Iff` are reported as relying on type-in-type;
- unsafe (co)fixpoints: none;
- inductives whose positivity is assumed: none;
- the report also lists imported opaque propositions and runtime axioms in the
  module context.

Restoring the process-global flag after declaration does not retroactively
unmark or revalidate these declarations. The affected declaration metadata is
therefore part of the resulting `.vo` and remains visible to `rocqchk`.

## Conclusion and stop point

Environment recovery and baseline reproduction are complete. The historical
`check_universes=false` mechanism materially improves import coverage:
`SearchArg`, `ListLast`, and `Bigcat` now import, while all four selected
non-Acc regressions continue to pass. No required A/B import remains failed in
the tested set.

However, this is a **functional diagnostic success, not a trust or semantic
acceptance result**. The exact declarations above rely on disabled universe
checking, and the minimal recursor computation test does not establish the
desired reduction behavior. Passing these tests cannot prove the importer's
complete correctness.

Recommendation: it is reasonable to enter a narrowly scoped
relevance/certificate investigation using the candidate explicitly, because
the blocker is reproducibly bypassed and the imported declaration surface is
available. It is **not** suitable to promote the candidate to the default
pipeline or mark the affected artifacts accepted. The next phase must treat
the `rocqchk` type-in-type list and the non-reducing `Acc` computation probe as
open trust/semantic obligations. This phase stops here without running the
full certificate set or changing formal status.
