# Rocq 9.0 compatibility report

## Decision

`MIGRATION_HAS_MAJOR_BLOCKER`

The source-side experiment is a strong success: the pristine Prosa v0.6 main
development (343 files) and every requested focus file compile with Rocq
9.0.0. The existing Lean-to-Rocq pipeline, however, cannot be migrated as-is.
The importer relies on a newer Rocq kernel switch that disables elimination
constraints for Lean inductives such as `Acc`; Rocq 9.0 has no corresponding
`typing_flags.check_eliminations` field. Existing exports containing `Acc`
therefore fail before certificates can be checked.

## Frozen inputs and environment

- Prosa commit: `414e66760333eaa4ef78c685bcf53291c527a548`
- Prosa tree: `7d7e94c731f7eefde4ca738310d4cafdd7bebdf0`
- Materialized archive SHA-256:
  `ef07835e205fa673259d872a99c3813b9a6b3d4f3824636b1f2e5c9ce59fcf4b`
- Integrity check: all 357 authoritative `.v` files match the pinned commit;
  zero mismatches (`logs/source/official-v-integrity.txt`).
- Rocq: 9.0.0, compiled with OCaml 4.14.2
- MathComp ssreflect/fingroup/algebra: 2.4.0
- mczify: `coq-mathcomp-zify.1.5.0+2.0+8.16` (exact 1.5.0 tag)
- Importer base: `546979bfd55b94288abfb72583a534b0136d282d`
- Existing project importer patch SHA-256:
  `0b3f5ad7903d43ee211f77d92a814ab799d0392bd6848d6eec5906a16b5de3f4`
- Rocq-9.0 API patch SHA-256:
  `18cc125a349449c09ed0689a301992db8d57d277036aab58486502711fef39a2`

The switch is local to `environment/rocq-9.0`, under the experiment-local
`environment/opam-root`; no Rocq 9.3 switch was replaced. The Rocq 9.0
compatibility package supplies `coqc`, and both `rocq --version` and
`coqc --version` report Rocq 9.0.0 with OCaml 4.14.2.

Exact mczify 1.5.0 is published in the compatibility `coq-*` namespace. Its
`coq-core` and MathComp dependencies are compatibility packages that point to
the installed Rocq 9.0 / MathComp 2.4 libraries. The experiment pins the
official `1.5.0+2.0+8.16` source tag locally; its tarball SHA-256 is
`5988389c6c8dfde4d2f3a370278c6b2aa1b5a0f56531cb30b0cce2d550b4387c`.
After installing it, the Prosa source, importer, imports, and certificates were
all rebuilt, so the reported results share this exact environment.

## Official Prosa source

The official main-development target, which excludes only the separately
managed `implementation/refinements/` subtree, compiled all 343 `.v` files
with exit code 0. No source workaround was applied.

| File/check | Result | Observation |
|---|---|---|
| full main development | PASS | 343/343 `.vo` produced |
| `util/tactics.v` | PASS | official source; no `ssreflect.done` patch |
| `util/seqset.v` | PASS | official binder syntax accepted |
| `util/search_arg.v` | PASS | no automation stack overflow; 2.20 s |
| `util/list.v` | PASS | complete file, including `last0_cons`; no stack overflow; 2.66 s |
| `util/div_mod.v` | PASS | official old proof script accepted; 1.65 s |

The warnings in the logs are notation/projection warnings, not proof failures.

## Importer build and existing exports

The exact currently used base plus project patch does not build directly on
Rocq 9.0. Its first error is the changed `UGraph.add_universe` API. A separate,
minimal compatibility patch updates renamed universe/sort APIs, record
projection declarations, name-generation calls, and timeout results. With
that patch, the plugin builds successfully:

- `lean_import.cmxs` SHA-256:
  `0e66c159559c9a2407790560f8c324f3f0a5254b95eb9f38006355775c0533ea`
- `Lean.vo` SHA-256:
  `8d721804239bf84a3ca58a888ce1d4db94d529c75936f6d0eb070ae84598d17f`

This build success is `PASS_WITH_WORKAROUND`, not an end-to-end pass. The
Rocq-9.0 patch must replace the importer's `with_unsafe_univs` implementation
with a no-op because the 9.0 `typing_flags` record lacks
`check_eliminations`.

| Existing `.out` | Result | Exact outcome |
|---|---|---|
| Time | PASS | imported `.vo` produced |
| Tactics | PASS | imported `.vo` produced |
| Subadditivity | PASS | imported `.vo` produced |
| ListSimple | PASS | imported `.vo` produced |
| SearchArg | FAIL | `Acc`, export line 4009; squash assertion |
| ListLast | FAIL | `Acc`, export line 11258; squash assertion |
| Bigcat | FAIL | `Acc`, export line 26532; squash assertion |

The failure is not merely the assertion. In a diagnostic-only build that
skipped it, SearchArg immediately failed with an illegal elimination of the
Rocq-9.0-squashed `Acc` from `SProp` to `Type`. Thus removing the assertion is
not a valid repair and would change the imported semantics. Evidence is in
`logs/importer/imports/SearchArg-diagnostic-no-squash-assert.log`.

## Certificate smoke tests

The experiment reuses existing certificate sources; no proof was rewritten.

| Certificate slice | Result | Assumptions / cause |
|---|---|---|
| `behavior/time.v` | PASS | 3 closed checks; 5 use only allowed `Lean.eq` definitional UIP; no unexpected assumptions |
| `util/tactics.v` | PASS | closed under the global context; no semantic premises or self-dependencies |
| ListSimple | FAIL | shared `SubadditivityNatCorrespondence.v` fails under 9.0 with a relevant/irrelevant binder mismatch near `sub_add_canonical` |
| SearchArg | FAIL | prerequisite `ImportedSearchArg.vo` unavailable because of `Acc` |
| ListLast / `last0_cons` | FAIL | prerequisite `ImportedListLast.vo` unavailable because of `Acc` |

For the two passing slices:

- `semantic_premises = []`
- source theorem self-dependency = `false`
- target theorem self-dependency = `false`
- unexpected assumptions = `[]`

The fail-closed audit outputs are `results/time_assumption_audit.json` and
`results/tactics_assumption_audit.json`; the consolidated fields are in
`results/certificate_smoke_summary.json`. The Time audit's known importer
foundation (`Lean.eq` definitional UIP) is classified as allowed, not as a
semantic premise.

## Answers to the six required questions

1. **Can official Prosa v0.6 compile on Rocq 9.0?** Yes. The unmodified
   343-file official main development compiles completely. The separately
   managed refinements target was not part of this phase.
2. **Can the Rocq 9.3 `tactics.v` and `seqset.v` compatibility patches be
   removed?** Yes for a Rocq 9.0 build. Both official files are `PASS` without
   those patches.
3. **Do the `search_arg.v` and `list.v` stack overflows disappear?** Yes on the
   official source path. Both full files compile normally, without the source
   signature extractor; no stack overflow occurs.
4. **Does the official `div_mod.v` proof script work again?** Yes. It compiles
   unchanged (`PASS`).
5. **Can the current importer build and import existing `.out` files?** Only
   partially. It needs a small Rocq-9.0 API port to build, then imports Time,
   Tactics, Subadditivity, and ListSimple. It cannot import representative
   `Acc`-containing SearchArg, ListLast, or Bigcat exports. End-to-end answer:
   **no**.
6. **Can existing semantic certificates basically recompile unchanged?** No
   as a pipeline-wide statement. Time and Tactics recompile unchanged and
   pass assumption audits. SearchArg and ListLast are blocked by the importer;
   ListSimple is additionally blocked by a Rocq-9.0 relevance mismatch in an
   existing shared correspondence proof.

## Blockers

1. **Major:** Rocq 9.0 lacks the elimination-constraint control needed to
   preserve Lean's non-squashed treatment of `Acc`. Fixing this is not a small
   importer API rename and would require a kernel/backport strategy or a
   representation/export redesign, both outside Phase 1.
2. **Certificate compatibility:** `SubadditivityNatCorrespondence.v` has a
   Rocq-9.0 relevance-mark failure. This appears to be a proof/tactic
   compatibility issue and was deliberately not rewritten here.

All copied-input hashes and origins are in `results/provenance.tsv`; concise
machine-readable outcomes are in `results/status.tsv`.
