# Phase 4: SearchArg full certification on Rocq 9.0

## Verdict

`SEARCHARG_ROCQ90_FULLY_CERTIFIED` was **not reached**.

The relevance failure in `SubadditivityNatCorrespondence.v` is fixed, and the
complete file plus `SearchArgDefinitionCertificate.v` compile on stock Rocq
9.0. The remaining exact blocker is `Nat.find`: omitting it keeps the export
Acc-free but leaves `ImportedSearchArg.Nat_find` unavailable; exporting the
actual compiled `Nat.find` immediately restores the dependency
`Nat.find -> Nat.findX -> WellFounded.fix -> Acc`, and the stock importer fails
at `Acc`.

This blocker cannot be removed within the Phase 4 constraints without changing
the `prop_on_ex_minn` statement/semantic relation, adding a premise or axiom,
or returning to the unsafe universe-check bypass.

## Frozen environment and inputs

| Item | Value |
|---|---|
| starting Git HEAD | `e04c3e5650b42c84a4183b45ba59252b58e1bf33` |
| Rocq | `9.0.0` |
| OCaml | `4.14.2` |
| MathComp ssreflect | `2.4.0` |
| mathcomp-zify | `1.5.0+2.0+8.16` |
| importer commit | `546979bfd55b94288abfb72583a534b0136d282d` |
| importer mode | stock API wrapper; `with_unsafe_univs` is a no-op |
| Phase 3 Acc-free artifact | `4568d291048e5f9bf14678b6012c0633b4fb16e84d04bb7c495823a4934cc3be` |
| reused compiled `SearchArg.olean` | `ef73a70c25b76a6a15d4bc881d0ac3d0d6869873f070032bde00b003db2c552f` |

No Lean source, Lean translation, Lean/Mathlib version, Rocq kernel, formal
acceptance state, ListLast, or Bigcat input was changed.

## Relevance compatibility repair

`sub_add_canonical` and `sub_mul_canonical` now use one proof pattern for all
four MathComp recurrence equations:

1. expose the actual imported kernel operation equality;
2. compose imported equalities with `sub_imported_eq_trans`;
3. lift the ordinary MathComp equality with
   `coq_eq_to_imported_eq` and `f_equal`.

This removes tactic rewriting from the SProp-valued imported equality goal.
It covers `addn0`, `addnS`, `muln0`, and the composed `mulnS`/`addnC` equation;
there are no per-lemma semantic exceptions. All lemma statements and semantic
relations are unchanged.

The same relevance-safe transport pattern was required at the corresponding
ordinary-equality rewrites inside `SearchArgDefinitionCertificate.v` and the
pre-`Nat.find` part of `SearchArgStatementCertificate.v`. These are proof-only
compatibility edits; no certificate statement was changed.

Evidence:

| Compilation | Result |
|---|---|
| `SubadditivityNatCorrespondence.v` | PASS |
| `SearchArgDefinitionCertificate.v` | PASS |
| `SearchArgStatementCertificate.v` | FAIL at first unavailable `ImportedSearchArg.Nat_find` reference |
| `SearchArgAssumptionAudit.v` | BLOCKED by the failed statement certificate |

Logs are under `logs/phase4/no-find/`.

## Minimal Acc boundary experiment

Two proof-complete exports were produced from the already compiled Phase 3
Lean artifact. Neither uses statement-only `#AX` records.

| Artifact | SHA-256 | `#AX` | `Acc`/`WellFounded` | stock Rocq 9.0 import |
|---|---|---:|---:|---|
| `SearchArg.statement-interfaces-no-find.out` | `afa92452b6dae4b7736c3304e014da2b82bc92f2df882c092e2a604b1a49c240` | 0 | 0 | PASS |
| `NatFind.acc-blocker.out` | `d675678d8549f02e09262798c3e5f502f9b607a8dc1e4e986f2c093290eb4daf` | 0 | 2 name hits | FAIL at export line 190, declaration `Acc` |

The first artifact extends the Phase 3 boundary only with the logical and Nat
interfaces referenced before `Nat.find`. With it, the stock import,
`SubadditivityNatCorrespondence`, and the definition certificate all pass; the
statement certificate reaches its first `Nat_find` use at source line 741.

The second artifact requests only the actual compiled `Nat.find` and its
proof-complete dependency closure. Stock Rocq 9.0 reports:

```text
Error at line 190 (for Acc): #IND 2 45 122 1 46 120 19
Anomaly "File "src/lean.ml", line 1548, characters 6-12: Assertion failed."
```

This is the minimal blocker. `Nat.find` returns a `Nat` from a proof of
existence and its compiled constructive implementation goes through
`Nat.findX`, `WellFounded.fix`, and `Acc`. Mapping Lean propositions to Rocq
SProp makes that dependency hit Rocq 9.0's forbidden squashed elimination.
Removing `Acc` therefore also removes the compiled `Nat.find` declaration
needed by the unchanged `prop_on_ex_minn` semantic certificate.

Evidence is in `logs/phase4/nat-find/stock-import.log`; both artifacts are kept
under `results/phase4/artifacts/`.

## Trust and safety boundary

For the largest importable no-`Nat.find` boundary, `rocqchk` reports:

- constants/inductives relying on type-in-type: `<none>`;
- constants/inductives relying on unsafe fixpoints: `<none>`;
- inductives whose positivity is assumed: `<none>`;
- additional axioms relative to `LeanImport.Lean`: `0`.

No changed certificate contains `Axiom`, `Admitted`, or `admit`; neither Phase
4 artifact contains `#AX`; the stock importer contains no
`check_universes=false`; and its safety assertions remain intact.

These checks establish the safety of the importable partial boundary only.
They do not turn the blocked full certificate into a pass.

## Required full-suite fields

| Field | Full-suite result |
|---|---|
| `semantic_premises=[]` | BLOCKED: full assumption audit could not run |
| source theorem dependency = false | BLOCKED: full assumption audit could not run |
| target theorem dependency = false | BLOCKED: full assumption audit could not run |
| unexpected assumptions = `[]` | BLOCKED: full assumption audit could not run |
| stock Rocq 9.0 | YES |
| Acc-free export | YES only for the partial boundary; incompatible with compiled `Nat.find` |
| no type-in-type / unsafe fixpoint / assumed positivity / added axiom | PASS for the partial boundary |

## Final conclusion

**BLOCKER: full Acc-free SearchArg certification is not feasible with the
unchanged `prop_on_ex_minn` statement on stock Rocq 9.0, because its actual
compiled `Nat.find` dependency necessarily reintroduces `Acc`.**

The result must not be recorded as `SEARCHARG_ROCQ90_FULLY_CERTIFIED`.
