# Full Rocq 9.0 Migration — Batch 3

## Result

`ROCQ90_FULL_MIGRATION_BATCH3_ACCEPTED`

Ranks 12–19 are formally accepted on the active stock Rocq 9.0 baseline:
**8/8 files, 68/68 authoritative declarations**, and zero
translated-but-not-certified declarations. This restores every previously
completed Rocq-9.3 utility acceptance to the current Rocq-9.0 baseline.
Production Lean translation was not modified.

## Fixed authority and environment

- Starting repository HEAD:
  `6a43af87b8cef4daacb89dc0a83edd91e3f29316`.
- Prosa v0.6: `414e66760333eaa4ef78c685bcf53291c527a548`.
- Lean 4.33.1; Mathlib
  `0df444a360eaa60ab8c11dca51a86af692955474`.
- Stock Rocq 9.0.0; OCaml 4.14.2; MathComp 2.4.0.
- `rocq-lean-import` base:
  `546979bfd55b94288abfb72583a534b0136d282d` with only the approved project
  and Rocq-9.0 API patches. Plugin SHA-256:
  `e39bf1e216751e3accdcee3fa06ed2effe629a7b3bbcda911a7862f5853c5ec6`.
- `lean4export` binary SHA-256:
  `c20dbe1f14951dbcb2b806395f171d3e91e9bb5ccc22fa5cb63bd592a767e49b`.
- Universe and elimination checking remained enabled. No unsafe compatibility
  patch, kernel patch, `Axiom`, `Admitted`, `sorry`, or statement-only export
  was used.

The formal content-addressed snapshot is
`769cbc4f3ad46b0ac39c038ef67a34a55e24384911fd4668948485a51210db8f`.
The pipeline is self-contained under `Validation/` and does not read
`rocq90-compat/.work`, logs, results, or artifacts.

## Formal execution

The new entry point is:

```text
prepare_rocq90_batch3.sh
→ check_rocq90_batch3.sh
→ finalize_rocq90_batch3.sh
```

The prepare snapshot fresh-compiles the complete Rank 1–19 Lean dependency
closure, then compiles the eight production modules and semantic interfaces.
It verifies 68 independent historical expected types against the actual fresh
production declarations using `Meta.isDefEq`. Official Prosa sources through
Rank 19 compile directly under Rocq 9.0 without Rocq-9.3 source patches.

The proof-complete export is split into Sum sequence/interval modules plus the
seven remaining module interfaces. Semantic statement definitions expose the
exact compiled proposition as data; they are neither theorem axioms nor
statement-only exporter mode. The Unit sum adapter has kernel-checked equality
and statement correspondence to the compiled `Finset.univ` expression. Six
interval Sum statements and `size_big_nat` use explicit `Meta.isDefEq`
normalization guards. No exported module declares the Lean `Acc` family.

The check phase compiles the complete existing certificate set, 64 generated
Rocq specialization/type guards, and 70 assumption targets (68 authoritative
declarations plus the finite-sum operation and epsilon module gates). Every
audited declaration has:

```text
semantic_premises=[]
source_theorem_dependency=false
target_theorem_dependency=false
unexpected assumptions=[]
```

## Compatibility repairs

The reusable Rocq-9.0 repair is consistent across Sum, Bigop, Poet, Bigcat,
Minmax, and DivMod:

```text
ordinary Rocq Prop equality
→ explicit transport
→ imported Lean equality / SProp boundary
```

This removes relevance-sensitive rewriting inside imported `SProp` goals.
Bigcat additionally exports the proof-relevant `Fin.isLt` projection needed
by the ordinal/`Fin` correspondence. The fixes change validation proofs and
the minimal boundary only; no source theorem, semantic relation, or production
Lean declaration changed.

The fail-closed cold run retained two diagnostic failures: the first snapshot
lacked fresh upstream Lean dependency `.olean` files, and the next check used
the wrong source directory for `SubadditivityClosureCertificate.v`. Both
prevented publication, were corrected in the shared pipeline, and the entire
invalidated chain was rerun before acceptance.

## Artifacts and whole-file acceptance

| Rank | File | Decls | Import | Certs | Audit | Acceptance |
|---:|---|---:|---|---|---|---|
| 12 | `util/sum.v` | 25 | PASS | PASS | PASS | ACCEPTED |
| 13 | `util/epsilon.v` | 0 | PASS | PASS | PASS | ACCEPTED |
| 14 | `util/bigop.v` | 1 | PASS | PASS | PASS | ACCEPTED |
| 15 | `util/setoid.v` | 3 | PASS | PASS | PASS | ACCEPTED |
| 16 | `util/poet.v` | 1 | PASS | PASS | PASS | ACCEPTED |
| 17 | `util/bigcat.v` | 13 | PASS | PASS | PASS | ACCEPTED |
| 18 | `util/minmax.v` | 10 | PASS | PASS | PASS | ACCEPTED |
| 19 | `util/div_mod.v` | 15 | PASS | PASS | PASS | ACCEPTED |

Full source, Lean source, fresh `.olean`, `.out`, and imported `.vo` hashes
are published per file in
`Validation/imported/rocq90_batch3/artifact_manifest.json`. Per-declaration
coverage and certificate classifications are in `declaration_manifest.json`;
the active machine status is
`Validation/planning/v06_pipeline/rocq90_batch3_status.json`.

## Trust result

`rocqchk` passed for all nine imported modules:

```text
type-in-type = none
unsafe (co)fixpoints = none
assumed positivity = none
unexpected/custom Rocq axioms = 0
```

The actual Lean foundation record `propext` occurs in SumSequence, Bigcat,
Minmax, and DivMod and is classified explicitly; it is not described as
axiom-free and was not introduced by migration. No other imported Batch 3
module has a Lean foundation axiom record.

## Coverage and stop point

```text
files accepted: 8/8
declarations accepted: 68/68
translated-but-not-certified: 0
unexpected assumptions: 0
unexpected/custom Rocq axioms: 0

cumulative active Rocq 9.0 coverage:
19/357 files
171/2439 declarations
```

Batch 3 stops before Rank 20. The next READY file is
`util/nondecreasing.v` (33 declarations), which begins the stage of completing
historically unfinished translation rather than revalidating an existing
Rocq-9.3 acceptance.
