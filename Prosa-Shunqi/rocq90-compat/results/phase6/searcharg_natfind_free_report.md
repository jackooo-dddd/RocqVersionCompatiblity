# Phase 6: Nat.find-free SearchArg certification on Rocq 9.0

Date: 2026-09-22 (Asia/Hong_Kong)

Final classification: **`SEARCHARG_ROCQ90_FULLY_CERTIFIED`**

## Result

The actual compiled Phase 6 `prop_on_ex_minn` declaration now imports on
stock Rocq 9.0 with its proof body, normal universe/elimination checking, and
no `Nat.find`, `Acc`, `WellFounded`, or `#AX` entry in the selected artifact
closure. The complete existing SearchArg definition, statement, and assumption
certificate suite passes.

The fail-closed assumption classifier reports, for all eight SearchArg
certificates:

- `semantic_premises=[]`;
- source theorem dependency = `false`;
- target theorem dependency = `false`;
- unexpected assumptions = `[]`.

Phase 1–5 reports, logs, patches, and acceptance records were not modified.
The repository HEAD at Phase 6 start was
`0dd3d65ae5a6997c7356e129a9bfd6cf36172c69`.

## Translation design and semantic correspondence

Only `Prosa.Util.SearchArg.prop_on_ex_minn` and two private local helpers were
changed. All other SearchArg declarations and the official Prosa v0.6 source
statement remain unchanged.

The target no longer chooses a natural directly from an existential proof.
The private `leastWitnessUpTo` helper performs structural recursion over an
explicit finite bound and returns `Option Nat`. Its private specification is
proved by structural induction. The existential proof is destructed only
inside a theorem whose result remains in `Prop`; it is never eliminated into
`Nat` or another computational `Type`.

The target premise is now:

```text
forall n,
  pred n = true ->
  (forall n', pred n' = true -> n <= n') ->
  P n
```

This is not an additional semantic premise. It is the witness-independent
form of the source premise `P (ex_minn ex)`: MathComp's `ex_minn ex` satisfies
the predicate and global minimality; conversely, every target witness with
those two properties equals `ex_minn ex` by antisymmetry. The updated
`prop_on_ex_minn_statement_certificate` proves both directions explicitly,
then reuses the unchanged result correspondence. No source or target theorem
is used to prove its own certificate.

No `Classical.choice` or other Lean axiom is used. The final Lean
`#print axioms Prosa.Util.SearchArg.prop_on_ex_minn` result is:

```text
'Prosa.Util.SearchArg.prop_on_ex_minn' does not depend on any axioms
```

The unrelated `earliest_pred_element_exists_case` source declaration still
contains its pre-existing `Nat.find` implementation and was not modified, as
required. It is outside this Phase 6 actual-artifact closure; its semantic
statement certificate remains part of, and passes in, the full SearchArg
certificate suite.

## Iterations retained

| Candidate | Result | Minimal blocker / outcome |
|---|---|---|
| high-level `omega`/`simp` proof | REJECTED | Exact type guard passed, but `#print axioms` exposed `propext` and `Quot.sound`; rejected before final export |
| kernel-style proof, minimal roots | PARTIAL | Actual theorem imported and the definition certificate passed; statement certificate stopped at a missing proof-complete `Iff` interface |
| kernel-style proof plus four `Iff` interfaces | PASS | Actual theorem import and all SearchArg certificates/audits passed |

The candidate-3 certificate needed two Rocq-9.0 proof-term compatibility
repairs: explicit `Logic.eq_ind` for ordinary `Prop` transport and a directly
expected SProp lambda instead of a relevance-ambiguous local `have`. These are
proof-only changes; the source theorem statement and semantic relation were
not weakened. All failed-attempt logs remain under `logs/phase6/` and are
indexed by `results/phase6/attempts.tsv`.

## Fresh artifact binding and import boundary

Lean 4.33.1 and the locked Mathlib commit
`0df444a360eaa60ab8c11dca51a86af692955474` were used for a fresh isolated
compile. `SearchArgNatFindFreeAudit.lean` checks the public theorem type with
`Meta.isDefEq`; the imported Rocq declaration has a second explicit exact-type
guard.

| Artifact | SHA-256 |
|---|---|
| `Prosa/Util/SearchArg.lean` | `7f3ef794add839809480d6a5277c4a99f54564bfd1f9525a933356ba8264f064` |
| fresh `SearchArg.olean` | `39b221b0a8fe2b6dd78926c6226fe40d0bddc5a73c58ce532229d48d640e3be7` |
| `SearchArg.natfind-free.out` | `9f2fb2d2d69d3cc889ac42a8e1e740dbfd9df14e797be41dc110f6691ad28d54` |
| stock-imported `ImportedSearchArg.vo` | `bb58af281520984dbf5590e42cde9248ab23a09f6f2b9576cd62c77c755fca9a` |
| stock importer plugin | `f8e1ef08471b69581eea936e666f359e79a9625d4694d446571034046f9c5bd1` |

The proof-complete export roots are the actual compiled `search_arg`, its two
computation equations, the actual compiled `prop_on_ex_minn`, and the four
small `Iff` interfaces needed by the existing statement certificates. Neither
the target theorem nor any helper is emitted statement-only. The final export
contains zero `#AX` entries and no name entry for `find`, `findX`, `Acc`,
`WellFounded`, `Acc_rec`, or `Acc_rect`.

## Stock Rocq 9.0 and safety audit

The reused local environment is Rocq 9.0.0 on OCaml 4.14.2 with MathComp
2.4.0 and mathcomp-zify `1.5.0+2.0+8.16`. The importer is the stock Phase 2
baseline at upstream commit `546979bfd55b94288abfb72583a534b0136d282d` plus
the previously recorded project/API patches. Its `with_unsafe_univs` wrapper
is a no-op; its source contains neither `check_universes=false` nor
`check_eliminations=false`, and no safety assertion was removed.

The Phase 6 negative tests confirm that Rocq rejects both an explicit
type-in-type definition and an SProp-to-`nat` elimination. `rocqchk -o` reports:

- constants/inductives relying on type-in-type: `<none>`;
- constants/inductives relying on unsafe fixpoints: `<none>`;
- inductives whose positivity is assumed: `<none>`.

The stock LeanImport foundation and the imported module each expose the same
57 Rocq Int63/runtime axioms; the set difference is zero. `Print Assumptions`
on the actual imported theorem shows only the existing LeanImport definitional
UIP annotations. No additional Rocq axiom was introduced.

## Full certificate results

| Check | Result |
|---|---|
| stock Rocq 9.0 import of actual proof-complete boundary | PASS |
| `SubadditivityNatCorrespondence` | PASS |
| `SearchArgDefinitionCertificate` | PASS |
| `SearchArgStatementCertificate` | PASS |
| `SearchArgAssumptionAudit` | PASS |
| `semantic_premises=[]` | PASS, 8/8 |
| source theorem dependency = false | PASS, 8/8 |
| target theorem dependency = false | PASS, 8/8 |
| unexpected assumptions = `[]` | PASS, 8/8 |
| normal universe and elimination checking | PASS |
| no type-in-type / unsafe fixpoint / assumed positivity | PASS |
| additional Rocq axioms | PASS, zero |

Reproduction:

```sh
rocq90-compat/scripts/phase6_generate_searcharg_natfind_free.sh
rocq90-compat/scripts/phase6_verify_searcharg_natfind_free.sh
```

Machine-readable evidence is in `results/phase6/status.tsv`,
`results/phase6/artifact_hashes.tsv`, and
`results/phase6/searcharg_assumption_audit.json`; final logs are under
`logs/phase6/final/`.

## Conclusion

**`SEARCHARG_ROCQ90_FULLY_CERTIFIED`**
