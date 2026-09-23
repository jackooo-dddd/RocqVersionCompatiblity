# Phase 7: final representative Rocq 9.0 migration gate

Final classification: **`ROCQ90_MIGRATION_GATE_PASSED`**

SearchArg, ListLast, and Bigcat all pass their full semantic-certificate and
trust checks on stock Rocq 9.0.0. This phase does not change the formal
acceptance status and does not start the full declaration migration.

## Scope and preserved baseline

- Repository HEAD at the start and end of the experiment:
  `c281cc878e3e12c6596565ffe058ad7df2e3fc4e`.
- Phase 1--6 reports, artifacts, and logs were not overwritten.
- The Phase 6 SearchArg verification entry was rerun and remained
  `SEARCHARG_ROCQ90_FULLY_CERTIFIED`.
- Only ListLast and Bigcat were added to the representative gate. No
  ListLast/Bigcat result was written into the formal acceptance metadata.
- Fresh build products were isolated under `.work/phase7/final`; published
  Phase 7 artifacts and results are under `results/phase7`.

## Reproducible environment

| Component | Verified value |
|---|---|
| Rocq | 9.0.0, stock kernel |
| Rocq compiler | OCaml 4.14.2 |
| MathComp | 2.4.0 |
| mczify (`coq-mathcomp-zify`) | 1.5.0+2.0+8.16 |
| Lean | 4.33.1 (`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`) |
| Mathlib | `0df444a360eaa60ab8c11dca51a86af692955474` |
| lean4export | `c9f8373f8a37a65c0ed9bfd20480a3d7481a163e` |
| lean4export binary SHA-256 | `c20dbe1f14951dbcb2b806395f171d3e91e9bb5ccc22fa5cb63bd592a767e49b` |
| rocq-lean-import | `546979bfd55b94288abfb72583a534b0136d282d` plus the existing project and Rocq-9.0 API patches |

The importer is the Phase 2 stock-checking baseline. Its
`with_unsafe_univs` wrapper is a no-op, and the verification entry rejects any
source occurrence of `check_universes=false` or `check_eliminations=false`.
The negative audit also confirms that Rocq still rejects an explicit
type-in-type declaration and forbidden elimination from a payload-carrying
`SProp`.

Reproduction commands:

```sh
Prosa-Shunqi/rocq90-compat/scripts/phase7_generate_final_migration_gate.sh
Prosa-Shunqi/rocq90-compat/scripts/phase7_verify_final_migration_gate.sh
```

Both commands completed with exit code 0 from clean Phase 7 work directories.

## ListLast boundary and artifact binding

The full compiled proof closures of `last0_nth`, `max_of_dominating_seq`, and
`nth0_cons` enter `List.getD -> List.get?Internal -> List.brecOn -> Acc`.
The other twelve ListLast theorem proof closures and the two production
definitions are Acc-free. Exporting the three problematic declarations as
statement-only constants was not used.

The minimal proof-complete boundary therefore contains:

- the actual compiled `last0` and `max0` definitions;
- the actual proof bodies for the twelve Acc-free ListLast theorems;
- the required actual computation interfaces for append, filter, length,
  subtraction, and zero;
- a structurally recursive validation-only `getD` plus its three Nat
  equations.

The replacement `getD` is not an unrelated same-typed constant. In the fresh
Lean build, `getD_matches_compiled` proves for every list, index, and fallback
that it equals the exact `List.getD` used in the compiled theorem types. The
proof is structural recursion checked by the Lean kernel. In addition:

- explicit exact-type guards for all three omitted proof closures were checked;
- `Meta.isDefEq` succeeded for each compiled declaration against its guard;
- type hashes and the fresh `.olean`/`.out` hashes were recorded;
- `last0_nth_safe` is derived from the actual compiled `last0_nth` and the
  kernel-checked `getD` bridge;
- the bridge and the three declarations report only Lean's existing
  `propext` foundation dependency.

The bridge itself is deliberately checked in Lean rather than exported:
exporting its target-side occurrence of the implementation `List.getD` would
reintroduce the irrelevant `brecOn/Acc` closure that the semantic boundary is
designed to omit.

Fresh artifact identity:

- `ListLast.phase7.out` SHA-256:
  `e66988201a6aeb3b40127e8693e699a8899876b7a3d751b7be8a58fba9e9d473`
- `ListLastSafeInterface.olean` SHA-256:
  `d1f1f30c0d46dd673e8df507faeab75bf9bd99758726441e2273d9236ef8deb6`
- imported `ImportedListLast.vo` SHA-256:
  `1a302c9d910b4cae5cb6d152d2937898e92ef26ac0f6e3f18016960ff2686ea2`

The artifact has no `Acc`, `WellFounded`, `Acc_rec`, `Acc_rect`, `Nat.find`,
or `Nat.findX` declaration in its export closure.

### ListLast certificate result

All fifteen existing ListLast certificates compile on Rocq 9.0:

`last0_cons`, `last0_cat`, `last0_nth`, `last0_ex_cat`, `last0_filter`,
`max0_cons`, `max0_2cons_eq`, `max0_2cons_le`,
`last_of_seq_le_max_of_seq`, `max0_of_uniform_set`, `in_max0_le`,
`max0_in_seq`, `max0_rem0`, `max_of_dominating_seq`, and `nth0_cons`.

Rocq 9.0 exposed proof-elaboration relevance failures when tactics rewrote
inside imported `SProp` equalities. The reusable repair proves the equality
chain in ordinary `Prop` and performs one explicit conversion at the boundary.
It does not change a theorem statement, relation, or semantic premise. The
`getD` certificate portion uses the same pattern and the three structural
equations above.

The classified result over all 15 certificates is:

```text
semantic_premises=[]
source theorem dependency=false
target theorem dependency=false
unexpected assumptions=[]
```

## Bigcat boundary and artifact binding

Initial proof-closure analysis found that four arithmetic/finite-sum proofs
pulled large `omega`/well-founded implementation closures, while the
production Bigcat definitions themselves were safe. The fixes are
statement-preserving proof refactorings:

- `mem_bigcat_nat` and `mem_bigcat_nat_exists` use explicit Nat lemmas;
- `bigcat_nat_uniq` uses `Nat.ne_of_lt`;
- `size_big_nat` uses a structural `List.foldr`/flatten-length helper;
- `production_bigCatFin_succ` unfolds `List.ofFn` and uses `Fin.foldr_succ`,
  avoiding the `List.ofFn_succ` proof closure.

No source theorem statement, semantic relation, production definition, or
translation was changed. A kernel `Eq.refl` normalization guard and
`Meta.isDefEq` verify the finite-sum presentation used for `size_big_nat`.

The final boundary imports all thirteen actual compiled Bigcat theorem proof
bodies, the four production definitions, and the fifteen required computation
interfaces. It does not use statement-only export.

Fresh artifact identity:

- `Bigcat.phase7.out` SHA-256:
  `52353e489edc5abcab9dfea951b45b96b00bd8c7a97215a4f5346eae33c5be34`
- `Bigcat.olean` SHA-256:
  `0640431fea25e910d4d1f086f000acc2af3fe2eb62b196fe338d46fe96cc2707`
- imported `ImportedBigcat.vo` SHA-256:
  `09d65aeb0c6469c91012efffbc068093afa2becb07acbe4b6339f040a26dff46`

The artifact has no `Acc`, `WellFounded`, `Acc_rec`, `Acc_rect`, `Nat.find`,
or `Nat.findX` declaration in its export closure.

### Bigcat certificate result

All thirteen existing Bigcat certificates and all exact target type guards
compile on Rocq 9.0. The same general Rocq proof compatibility repair was
needed at two imported equality transports; no statement or premise changed.

The classified result over all 13 certificates is:

```text
semantic_premises=[]
source theorem dependency=false
target theorem dependency=false
unexpected assumptions=[]
```

## Trust audit

| Check | SearchArg | ListLast | Bigcat |
|---|---:|---:|---:|
| stock Rocq 9.0 import | PASS | PASS | PASS |
| all existing certificates | PASS | 15/15 PASS | 13/13 PASS |
| normal universe/elimination checking | PASS | PASS | PASS |
| type-in-type | none | none | none |
| unsafe fixpoints | none | none | none |
| assumed positivity | none | none | none |
| unexpected assumptions | none | none | none |
| source theorem dependency | false | false | false |
| target theorem dependency | false | false | false |

`rocqchk` reports `<none>` independently for type-in-type, unsafe
(co)fixpoints, and assumed positivity for both fresh imported Phase 7 modules.

Relative to the checked importer foundation, ListLast adds only the expected
translation of Lean `propext`. Bigcat adds only the already-declared Lean
foundation dependencies `propext`, `Quot.sound`, and `Classical.choice` that
are reported by Lean's own `#print axioms` audit. The axiom-delta classifier
finds zero unexpected or custom Rocq axioms. There is no added `Axiom`,
`Admitted`, `sorry`, kernel patch, disabled checking flag, unsafe fixpoint, or
assumed positivity.

## Evidence index

- `results/phase7/status.tsv`: fail-closed per-case status.
- `results/phase7/artifact_hashes.tsv`: Lean source, `.olean`, exporter, and
  export identities.
- `results/phase7/verification_hashes.tsv`: imported modules and certificate
  identities.
- `results/phase7/listlast_assumption_audit.json`: 15 classified certificates.
- `results/phase7/bigcat_assumption_audit.json`: 13 classified certificates.
- `logs/phase7/final/rocqchk-imported-listlast.log` and
  `rocqchk-imported-bigcat.log`: kernel trust summaries.
- `logs/phase7/final/rocqchk-axiom-delta.log`: expected/unknown axiom split.
- `tests/phase7/listlast_certificate_rocq90.patch`: isolated Rocq-9.0
  relevance and safe-boundary certificate adaptation.

## Gate decision

```text
SearchArg  PASS
ListLast   PASS
Bigcat     PASS
```

The representative compatibility experiments should stop here. The evidence
supports proceeding to a separately scoped **full Rocq 9.0 migration**; this
Phase 7 run intentionally does not begin that migration.

**`ROCQ90_MIGRATION_GATE_PASSED`**
