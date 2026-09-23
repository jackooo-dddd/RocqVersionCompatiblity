# Full Rocq 9.0 Migration — Batch 2

## Classification

`ROCQ90_FULL_MIGRATION_BATCH2_ACCEPTED`

Rank 11, `util/list.v`, now has current stock-Rocq-9.0 whole-file acceptance:
57/57 authoritative declarations, 57 actual-artifact type guards, every
certificate PASS, and `translated-but-not-certified=0`. Production Lean
translation was not modified. Batch 2 stops here; `util/sum.v` was not started.

## Reproducibility identities

- Starting repository HEAD: `d2f7001873bc0c78c7e448d1e76da2138347fef6`.
- Authoritative Prosa v0.6:
  `414e66760333eaa4ef78c685bcf53291c527a548`.
- Lean 4.33.1; Mathlib
  `0df444a360eaa60ab8c11dca51a86af692955474`.
- Rocq 9.0.0; OCaml 4.14.2; MathComp 2.4.0.
- `lean4export` base
  `c9f8373f8a37a65c0ed9bfd20480a3d7481a163e`, binary SHA-256
  `c20dbe1f14951dbcb2b806395f171d3e91e9bb5ccc22fa5cb63bd592a767e49b`.
- `rocq-lean-import` base
  `546979bfd55b94288abfb72583a534b0136d282d`, plugin SHA-256
  `e39bf1e216751e3accdcee3fa06ed2effe629a7b3bbcda911a7862f5853c5ec6`,
  `Lean.vo` SHA-256
  `1cd8548cac7649cddf8d289876a2fb7869f4b879b654e8512cc4fe76eac1e8cf`.
- Importer project patch SHA-256
  `0b3f5ad7903d43ee211f77d92a814ab799d0392bd6848d6eec5906a16b5de3f4`
  followed by Rocq-9.0 API patch SHA-256
  `18cc125a349449c09ed0689a301992db8d57d277036aab58486502711fef39a2`.
- Sealed prepare snapshot:
  `33f4ac5f5c46df4dda4c8ee1bbcc8a261d75725e33d8d994b25c03b5dd473a9d`.

The importer retains `with_unsafe_univs f () = f ()`; normal universe and
elimination checking are enabled. No Phase 2 unsafe-universe patch, Phase 5
Acc mapping, kernel patch, `Axiom`, `Admitted`, or `sorry` is used.

## Inventory and acceptance

The authoritative `declaration_inventory.csv` contains exactly 57 declarations
for `util/list.v`. Its set equals the union of the canonical ListSimple,
ListLast, ListBatch3, ListBatch4, and ListBatch5 publication clusters, with no
duplicate or missing declaration. The fresh Lean audit independently checks
all 57 production constants against separately stated expected signatures and
rejects universe-arity or `Meta.isDefEq` mismatch.

| Rank | File | Decls | Import | Certs | Audit | `rocqchk` | Acceptance |
|---:|---|---:|---|---|---|---|---|
| 11 | `util/list.v` | 57 | PASS | PASS | PASS | PASS | ACCEPTED |

```text
files accepted: 1/1
declarations accepted: 57/57
translated-but-not-certified: 0
unexpected assumptions: 0
unexpected/custom Rocq axioms: 0
```

All 57 published rows satisfy:

```text
semantic_premises=[]
source_theorem_dependency=false
target_theorem_dependency=false
unexpected assumptions=[]
```

The assumption classifier records 5 declarations as `CERTIFIED` and 52 as
`CERTIFIED_WITH_PROP_SPROP_FOUNDATION`; the latter is an explicit foundation
classification and is not mislabeled globally axiom-free.

## Artifact ledger

| Artifact | SHA-256 |
|---|---|
| official `util/list.v` | `7bb5784dc312aef4ec80b00314a36f938a20e29ed1e7d68475b9c2dca9cada6a` |
| production `Prosa/Util/List.lean` | `c5f9503dc9d55fe3eec5be2bf2f7743f896a6b2d14c8fdc9afe6421e19d42e5a` |
| fresh `List.olean` | `cd008d9e3d4c410e3db1d8cc4c1c5d4c2cdb9873e69adaa68a6938a54349ee89` |
| `ListLast.out` | `eea8924a89070413d9e8755ebcca56ea3a30718b1839003612206fab9714f641` |
| `ImportedListLast.vo` | `3a6008b9a70f40e4e60185ad6d05187e22ecf84e5c7cbbbfa91f4b5d54376f68` |
| `ListSimple.out` | `033db5ef70e40a66f0547a6af76392d1e7fe64214cff8356029e07a94ba8dd8e` |
| `ImportedListSimple.vo` | `66a5158f88291d1f89c3d2b6ebcd5770a3fca795b4c63714fedb78394aa6e46e` |

The complete machine ledger is
`Validation/imported/rocq90_batch2/artifact_manifest.json`; the 57 declaration
rows are in `declaration_manifest.json`. Earlier Rocq 9.3 acceptance remains in
the canonical List report as historical provenance and is not active evidence.

## Boundary and compatibility repairs

Official Prosa `tactics.v`, `supremum.v`, and the complete `list.v` compile
directly on Rocq 9.0. The formal export is minimal and proof-complete: actual
production computations, operation equations with bodies, and small stable
interfaces used by independent certificates. It exports no target business
theorem as statement-only evidence (`statement_only=false`).

The Phase 7 `List.getD` method is integrated as a validation-only structurally
recursive operation. A non-exported Lean theorem proves it equal to actual
fresh compiled `List.getD`; this kernel guard depends only on `propext`. The
export graph contains no `Acc`, `Acc_rec`, `Acc_rect`, `WellFounded`,
`List.get?Internal`, `Nat.find`, or `Nat.findX`. Ordinary Lean List/Nat
foundation records named `*.brecOn` remain in the shared closure even for
basic `max0`/append exports; they are not the excluded `getD`/Acc path, and the
trust audit reports no unsafe fixpoint.

Rocq-9.0 proof repairs use one reusable pattern: prove or transport an ordinary
Rocq `Prop` equality first, then cross to imported Lean equality/SProp once.
This resolved relevance failures in max, recursive erase, pair membership,
index/range successor, and count proofs. Stable actual-operation interfaces
remove dependencies on importer-generated `_instN` naming for Nat order and
membership, decidable membership, Nat `rem_all`, and singleton List/Option
equality. These changes are certificate/interface changes only; no source
statement, semantic relation, semantic premise, or production Lean declaration
changed.

## Trust result

Fresh Lean `#print axioms` classification records only the expected foundations
already used by actual declarations. The export records exactly `propext` and
`Quot.sound` for `ListLast`, and no foundation axiom for `ListSimple`.

For both imported modules, `rocqchk` reports:

```text
type-in-type: none
unsafe (co)fixpoints: none
assumed positivity: none
unexpected/custom Rocq axioms: 0
```

The only additional imported foundation entries are classified Lean
`propext`/`Quot.sound`; no custom Rocq axiom was added.

## Mainline publication and stop point

The self-contained entry is:

```text
Validation/scripts/prepare_rocq90_batch2.sh
Validation/scripts/check_rocq90_batch2.sh
Validation/scripts/finalize_rocq90_batch2.sh
Validation/scripts/validate_rocq90_batch2.sh
```

It extends the Batch 1 content-addressed `prepare -> check -> finalize` driver
and publishes to `Validation/imported/rocq90_batch2/` plus
`Validation/planning/v06_pipeline/rocq90_batch2_status.json`. It has no runtime
dependency on `rocq90-compat` and never reuses Rocq 9.3 `.vo` evidence.

Batch 2 stops after Rank 11. The next READY file is:

```text
Rank 12: util/sum.v (25 authoritative declarations)
```
