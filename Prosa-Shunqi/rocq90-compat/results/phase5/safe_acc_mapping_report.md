# Phase 5: safe standard-`Acc` mapping on Rocq 9.0

## Conclusion

`SAFE_ACC_MAPPING_NOT_FEASIBLE`

The restricted mapping is sufficient for a compiled `Nat`/`Type 0`
non-dependent `Acc.rec` smoke test, but it is not sufficient for the actual
compiled `Nat.find` artifact.  The final blocker is a checked Rocq 9.0
elimination restriction, not a missing universe bypass: the Lean proof builds
`Acc` through a match and equality transport on Lean propositions represented
as Rocq `SProp`, while the proposed standard-library representation of `Acc`
lives in Rocq `Prop`.  Stock Rocq rejects the required non-empty
`SProp -> Prop` elimination.

No unsafe fallback was attempted.  In particular, this phase did not use
`check_universes=false`, modify the kernel, add an axiom/admitted proof, delete
an importer assertion, or change `prop_on_ex_minn`.

## Scope and preserved baseline

- Repository HEAD at phase start and report time:
  `42e9ca46311d54b1b86118ebbc53742b78307b3c`.
- Phase 4 reports, logs, artifacts, and acceptance state were not modified.
- The Phase 5 importer was built in `.work/phase5/importer-safe-acc` from
  upstream commit `546979bfd55b94288abfb72583a534b0136d282d`, after the two
  existing project patches, followed by the isolated diagnostic patch
  `importer/patches/phase5-safe-acc-mapping.patch`.
- The candidate remains diagnostic-only and is not enabled by the normal
  importer or acceptance pipeline.
- SearchArg, ListLast, and Bigcat translations were not redesigned or rerun.

## Reproduced environment

| component | observed version |
|---|---|
| Rocq | 9.0.0 |
| OCaml | 4.14.2 |
| MathComp ssreflect | 2.4.0 |
| `coq-mathcomp-zify` | 1.5.0+2.0+8.16 |

The repository-local OPAM root and switch from `scripts/common.sh` were used.
The safety-source scan found no `check_universes=false` or
`check_eliminations=false`.  The existing `with_unsafe_univs` compatibility
wrapper remains the checked no-op `let with_unsafe_univs f () = f ()`, and the
existing squash and recursive-parameter assertions remain present.

Evidence: `logs/phase5/environment.log`,
`logs/phase5/audit/safety-source-scan.log`, and the importer build logs under
`logs/phase5/importer/`.

## Type and recursor correspondence

The source and target are not definitionally identical:

- Lean `Acc` accepts a carrier in `Sort u`, a relation returning Lean `Prop`,
  and itself returns Lean `Prop`.
- Lean `Acc.rec` permits a motive depending on both the carrier value and the
  `Acc` proof.
- Rocq 9.0 `Init.Wf.Acc` accepts a `Type` carrier and a `Prop` relation, and
  returns `Prop`.
- Rocq `Acc_rect` has a motive `P : A -> Type`; it does **not** depend on the
  accessibility proof.
- Rocq `well_founded` is `forall a, Acc R a`, rather than Lean's one-field
  `WellFounded` structure.

The candidate therefore does all of the following explicitly:

1. boxes each imported `SProp` relation witness into a checked `Prop` record
   before using standard `Acc`;
2. represents Lean `Acc` and `WellFounded` by transparent wrappers around
   standard `Acc` and `well_founded` rather than declaring recursive `SProp`
   accessibility trees;
3. accepts `Acc.rec` only when its compiled motive is an explicit two-binder
   lambda whose proof binder is unused;
4. preserves the standard `Well_founded.u0` and `Acc_rect.u0` upper bounds as
   ordinary Rocq universe constraints; and
5. fails closed for a proof-dependent or ambiguous recursor motive.

This establishes a correspondence only for that restricted fragment.  It does
not establish a general correspondence for Lean's proof-dependent recursor or
for arbitrary Lean universes.

## Ordered tests

### 1. Minimal compiled `Acc` / `Acc.rec`

The compiled Lean smoke uses carrier `Nat`, result universe `Type 0`, and a
motive depending on the carrier but not on the `Acc` proof.

| item | result |
|---|---|
| Lean type audit (`Meta.isDefEq`) | PASS |
| Rocq standard `Acc`/constructor/recursor/well-founded audit | PASS |
| minimal `Acc` family import | PASS |
| compiled non-dependent `Acc.rec` smoke import | PASS |
| `Print Assumptions Phase5_accRectNatSmoke` | `Closed under the global context` |
| proof-dependent recursor negative test | EXPECTED_FAILURE |

The negative artifact is rejected with:

> Lean Acc.rec motive is not an explicit two-binder lambda; refusing the safe standard Rocq Acc_rect mapping

Artifact identities:

| artifact | SHA-256 | `#AX` |
|---|---|---:|
| `artifacts/AccRecursorSmoke.out` | `93b4df77b3e4c0825da12f14d64f1f69fc899a78ac4202eff54f61858bdbc7e7` | 0 |
| `artifacts/AccDependentRecursorNegative.out` | `554b533a4130059c6265e7e96eb4f81923ec86c80f85e9717bd0e3dfa50643a7` | 0 |

Evidence: `logs/phase5/acc-minimal/`,
`logs/phase5/acc-recursor-smoke/`, and
`logs/phase5/acc-dependent-negative/`.

### 2. Actual compiled `Nat.find`

The exact Phase 4 artifact was reused without rebuilding or changing Lean:

- artifact: `results/phase4/artifacts/NatFind.acc-blocker.out`
- SHA-256:
  `d675678d8549f02e09262798c3e5f502f9b607a8dc1e4e986f2c093290eb4daf`
- `#AX`: 0

The candidate successfully passed the former early blockers:

| export declaration | result |
|---|---|
| line 190, `Acc` | mapped to standard-`Acc` wrapper |
| line 205, `WellFounded` | mapped to standard-`well_founded` wrapper |
| line 278, `WellFounded.fixF` | compiled with checked upper bounds |
| line 317, `WellFounded.apply` | mapped to checked projection wrapper |
| line 352, `WellFounded.fix` | compiled with checked upper bounds |

Import then fails at export line 2493,
`_private.Mathlib.Data.Nat.Find0.Nat.wf_lbp`.  Its compiled body matches on an
`SProp` relation proof and transports along `SProp` equality while the motive
returns the proposed `Prop`-based `Lean_Acc`.  The exact final diagnostic is:

> the match helper expects a motive returning `SProp`, but the supplied motive returns `Prop`

This cannot be repaired by the standard `Acc_rect` adapter alone.  Empty
`SProp` elimination was separately handled and accepted by Rocq; the remaining
match is non-empty and includes equality transport, so normal Rocq 9.0
elimination checking correctly rejects it.  Mapping the entire relevant Lean
proposition graph from `SProp` to `Prop`, changing the kernel, or restoring the
Phase 2 unsafe universe path would exceed this phase and was not attempted.

Evidence: `logs/phase5/nat-find/import.log` and
`logs/phase5/nat-find/import.exit` (`1`).

### 3. SearchArg boundary and certificates

Per the required order, these steps were not run after actual `Nat.find`
failed:

| required item | Phase 5 result |
|---|---|
| full SearchArg boundary re-export/import | BLOCKED by actual `Nat.find` |
| `SearchArgDefinitionCertificate` | BLOCKED (Phase 4 baseline retained) |
| `SearchArgStatementCertificate` | BLOCKED |
| `SearchArgAssumptionAudit` | BLOCKED |
| `semantic_premises=[]` | NOT ESTABLISHED for a Phase 5 full certificate |
| source theorem dependency = false | NOT ESTABLISHED |
| target theorem dependency = false | NOT ESTABLISHED |
| unexpected assumptions = `[]` | NOT ESTABLISHED |

No formal acceptance status was changed.

## Trust audit

`rocqchk -silent -o` succeeds for both the Phase 5 importer foundation and the
successful compiled `Acc.rec` smoke module.  Relative to the importer
foundation it reports:

- additional axioms: 0;
- constants/inductives relying on type-in-type: none;
- constants/inductives relying on unsafe (co)fixpoints: none; and
- inductives whose positivity is assumed: none.

The foundation's existing Uint63 primitive axioms are unchanged and the axiom
delta is zero.  These checks apply to the successful restricted smoke module;
there is no `Nat.find` `.vo` to certify because its import failed atomically.

Evidence: `logs/phase5/audit/rocqchk-foundation.log`,
`logs/phase5/audit/rocqchk-acc-smoke.log`, and
`logs/phase5/audit/rocqchk-axiom-delta.log`.

## Reproducible candidate

The isolated patch has SHA-256
`5e37f9f70d6fee63b49fdb87cc6273c7d12a72dc94fe4cf04408a0250bd0ced9`.
`patch --dry-run -p1` succeeds against the Phase 2 baseline importer after the
two existing project patches.  The tracked Lean sources for the positive and
negative minimal artifacts are under `tests/phase5/`.

The experiment does not justify entering a SearchArg relevance/certificate
stage through this mapping: actual compiled `Nat.find` is still unavailable
under stock Rocq 9.0 with normal universe and elimination checking.
