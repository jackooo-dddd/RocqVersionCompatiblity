---
name: prosa-v06-translation
description: Translate and semantically validate authoritative Prosa v0.6 files in the Prosa-Shunqi workspace. Use for new Prosa translations, Rocq revalidation, whole-file acceptance, file-DAG readiness, validation pipeline changes, or updates to canonical Prosa file reports.
---

# Prosa v0.6 translation and validation

## Authority and active baseline

- Treat Prosa v0.6 commit
  `414e66760333eaa4ef78c685bcf53291c527a548` as the only source
  specification.
- Use Lean 4.33.1 and Mathlib commit
  `0df444a360eaa60ab8c11dca51a86af692955474`.
- Use stock Rocq 9.0.0 as the active validation baseline. Treat Rocq 9.3 as
  historical provenance only.
- Treat the frozen compatibility Phase 1–7 evidence as migration
  justification, not as a runtime or artifact dependency of `Validation/`.
- Read `v06_file_translation_order.md`, the authoritative file DAG, the
  active Rocq-9.0 status, and the file's one canonical report before starting.

## Scope and scheduling

1. Work on the next unfinished file whose direct file dependencies have
   current Rocq-9.0 whole-file acceptance.
2. Use the rank order only to choose among READY files; never remove a DAG
   edge or treat partial declaration acceptance as file readiness.
3. Keep exactly one canonical report for each source file under
   `Reports/files/`. Append migration, retry, and revalidation evidence to it.
4. Do not publish downstream READY until every authoritative declaration in
   the predecessor file is certified and `translated-but-not-certified=0`.

## Required validation flow

Use fail-closed `prepare → check → finalize` validation.

- `prepare` must bind the environment, importer/exporter identities,
  authoritative source, production Lean source, fresh `.olean`, export
  boundary, and import options.
- `check` must compile all semantic certificates, classify assumptions, and
  run `rocqchk`.
- `finalize` may publish only a verified prepared snapshot whose complete
  check succeeds.
- Certificate-only edits may reuse a hash-verified prepare snapshot. Changes
  to Lean source, `.olean`, export boundary, importer, environment, or another
  declared prepare input must invalidate prepare.
- Never use a Rocq-9.3 `.vo` as Rocq-9.0 evidence.

For every production declaration require an independently stated exact-type
guard checked with `Meta.isDefEq` against the freshly compiled actual
artifact. A declaration compared only with itself is not a valid guard.

## Export and proof policy

- Export the smallest proof-complete semantic boundary: production
  computation, necessary computation equations, and the operation interfaces
  used by independent certificates.
- Do not use statement-only export as a substitute for actual-artifact
  semantics. Do not use a source or target business theorem to certify itself.
- Preserve actual `.olean → .out → Rocq import` binding and record hashes for
  source, `.olean`, `.out`, and `.vo`.
- Prefer direct compilation of pinned official Rocq source. Do not carry
  Rocq-9.3 source workarounds into Rocq 9.0 unless a new direct compile proves
  they are still required.
- For Rocq-9.0 relevance-sensitive equality, first prove ordinary Rocq `Prop`
  equality, explicitly transport it, and convert only once at the imported
  Lean equality/SProp boundary. Avoid broad `rewrite` inside SProp evidence.
- For SearchArg, keep the validated Nat.find-free `prop_on_ex_minn`
  formulation and its explicit semantic correspondence proof. Its export must
  not reintroduce `Nat.find`, `Acc`, or `WellFounded`.

## Forbidden escapes

Never use:

- `check_universes=false` or `check_eliminations=false`;
- a Rocq kernel patch;
- `Axiom`, `Admitted`, `admit`, or `sorry` to close migration obligations;
- the historical unsafe-universe patch or experimental Acc mapping;
- removal of importer safety assertions;
- a changed source statement, semantic relation, or hidden new premise to
  obtain a pass.

The pinned safe importer must retain `with_unsafe_univs f () = f ()`.

## Acceptance and trust gate

Every declaration must report:

```text
semantic_premises=[]
source_theorem_dependency=false
target_theorem_dependency=false
unexpected assumptions=[]
```

Classify the existing Prop/SProp foundation explicitly, for example
`CERTIFIED_WITH_PROP_SPROP_FOUNDATION`; do not mislabel it globally
axiom-free. Record actual Lean `#print axioms` results such as `propext`,
`Quot.sound`, and `Classical.choice` only where they occur.

Every imported module must pass `rocqchk` with:

```text
type-in-type = none
unsafe (co)fixpoints = none
assumed positivity = none
unexpected/custom Rocq axioms = 0
```

Fail closed on missing, truncated, unclassified, or unexpected audit output.
Do not convert BLOCKED or expected failure into PASS.

## Blocker handling

When a proof, relevance, or import blocker appears:

1. isolate the smallest failing declaration or interface;
2. preserve accurate failure evidence;
3. try a safe, general, reusable certificate or boundary repair;
4. rerun the invalidated portion of the pipeline;
5. keep already accepted independent files if a real blocker remains.

Do not redesign a faithful Lean translation for ordinary proof difficulty.
Allow semantics-preserving redesign only after multiple materially different
certificate/interface approaches establish that the representation itself is
the blocker; then fresh compile, export, import, certify, and audit everything
affected.
