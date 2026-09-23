# Full Rocq 9.0 Migration — Batch 1

## Classification

`ROCQ90_FULL_MIGRATION_BATCH1_ACCEPTED`

The active `Validation/` baseline is now stock Rocq 9.0.0 for execution ranks
1–10. All ten authoritative files and all 46 authoritative declarations have
fresh actual-artifact semantic revalidation. Rocq 9.3 artifacts remain
historical provenance only.

## Reproducibility identities

- Starting repository HEAD: `17074b2b7cea242e7371c3ba84ba80f9c46803ae`
- Authoritative Prosa: v0.6,
  `414e66760333eaa4ef78c685bcf53291c527a548`
- Lean: `4.33.1`
- Mathlib: `0df444a360eaa60ab8c11dca51a86af692955474`
- Rocq: `9.0.0`; OCaml: `4.14.2`; MathComp: `2.4.0`;
  `coq-mathcomp-zify`: `1.5.0+2.0+8.16`
- `lean4export` base: `c9f8373f8a37a65c0ed9bfd20480a3d7481a163e`;
  binary SHA-256:
  `c20dbe1f14951dbcb2b806395f171d3e91e9bb5ccc22fa5cb63bd592a767e49b`
- `rocq-lean-import` base:
  `546979bfd55b94288abfb72583a534b0136d282d`; project patch SHA-256
  `0b3f5ad7903d43ee211f77d92a814ab799d0392bd6848d6eec5906a16b5de3f4`;
  Rocq-9.0 API patch SHA-256
  `18cc125a349449c09ed0689a301992db8d57d277036aab58486502711fef39a2`;
  combined diff SHA-256
  `4848820b463c5de34a7d70571277cf5fb44bf5eeb3899b7d5a75d231787982f6`
- Importer plugin SHA-256:
  `e39bf1e216751e3accdcee3fa06ed2effe629a7b3bbcda911a7862f5853c5ec6`;
  `Lean.vo` SHA-256:
  `1cd8548cac7649cddf8d289876a2fb7869f4b879b654e8512cc4fe76eac1e8cf`
- Sealed prepare snapshot:
  `6c6d3fe7179a65fdcbb1a2d2a93f36901de4c03703762b7bcfccaea01389888a`

The importer applies only the safe project patch followed by the Rocq-9.0 API
patch. Its checked implementation has
`with_unsafe_univs f () = f ()`. Universe and elimination checking remain
enabled. Neither the Phase 2 unsafe-universe patch nor the Phase 5 experimental
Acc mapping is present.

## Inventory and acceptance

The authoritative inventory resolves to exactly 10 files and 46 public
declarations, matching the planned count.

| Rank | File | Decls | Import | Certs | Audit | `rocqchk` | Acceptance |
|---:|---|---:|---|---|---|---|---|
| 01 | `behavior/time.v` | 2 | PASS | PASS | PASS | PASS | ACCEPTED |
| 02 | `util/tactics.v` | 2 | PASS | PASS | PASS | PASS | ACCEPTED |
| 03 | `util/notation.v` | 1 | PASS | PASS | PASS | PASS | ACCEPTED |
| 04 | `util/rel.v` | 3 | PASS | PASS | PASS | PASS | ACCEPTED |
| 05 | `util/seqset.v` | 3 | PASS | PASS | PASS | PASS | ACCEPTED |
| 06 | `util/subadditivity.v` | 6 | PASS | PASS | PASS | PASS | ACCEPTED |
| 07 | `util/supremum.v` | 7 | PASS | PASS | PASS | PASS | ACCEPTED |
| 08 | `util/nat.v` | 2 | PASS | PASS | PASS | PASS | ACCEPTED |
| 09 | `util/unit_growth.v` | 12 | PASS | PASS | PASS | PASS | ACCEPTED |
| 10 | `util/search_arg.v` | 8 | PASS | PASS | PASS | PASS | ACCEPTED |

Summary:

```text
files accepted: 10/10
declarations accepted: 46/46
translated-but-not-certified: 0
unexpected assumptions: 0
unexpected/custom Rocq axioms: 0
```

Every classified production declaration has:

```text
semantic_premises=[]
source_theorem_dependency=false
target_theorem_dependency=false
unexpected assumptions=[]
```

## Artifact ledger

`source` is the pinned official Rocq file; `Lean` is the production Lean
source; `.olean` is freshly compiled; `.out` and `.vo` are the published
Rocq-9.0 artifacts.

| Rank | source SHA-256 | Lean SHA-256 | `.olean` SHA-256 | `.out` SHA-256 | imported `.vo` SHA-256 |
|---:|---|---|---|---|---|
| 01 | `9fea3f9a3181ca697e8abdb9eee90a656057081f62b00157c3ce9fbe59e53230` | `aae8e9834a60bdb04abc633fcf10e9441542d7f54f418e596790e800317f9330` | `bf431d237f41ff3a54f88adac803f174db6e2f635165a81989f2bfdfe4cbaefb` | `8b2354769dc908175b0386f4fb1b2113be48db89164e384fe34b5539264e115a` | `d609c1512bf936d0a07d5331cd53a1087d9507f290d1e535d6baec96f0d8825f` |
| 02 | `b55a2ee4f5efbd6e8593b0c95d6ae42414517a4f2cc0f4ccf90488371c2a7eff` | `a3f2038336aea8982b18505220253f1561c0b7afbc924e05db4ac4456fd09551` | `5368934f7dd802233f693c9aaa5a900ea04701d2680a61a8e835c3fbb9246d04` | `4a83503540ec133b97d68ccaa03cabd2257a7cf230a2a9767957aa720d5408b8` | `0f72acfb437fa73bdfb4a589513e260fc612a34739aa0e6b3f09f269ea24e58a` |
| 03 | `bcf52e6ffd31ceca50e479567147014b7ed1fc941cbf38ceba74917962a8b17d` | `d1f0b378e5d8cfd157afc569109a201c428bc64b8395d3d9dc3048047e413cf2` | `ad09e66380bbbb9f60fce4f970b33978f6a366989e11826c9fb9466ee9af0714` | `310e9e71641fcdc2d92c2f499802efa7b7d764ce63a76c0190f772ab80b70de3` | `2d303e07ac9421b7a5fbc14f7545d0472ea59f2f5f64b7e669f4a9e74946d247` |
| 04 | `6479aed5a7b8254defac344fa85886446b2095fd848184196dadfa9f5a90779b` | `ece4043fd95269bc0edb71e10474304b9a966a14358144809981f110ab937853` | `7848bd2d90bf1a793ce54d96cfbad26a41f26d16d7fb122c61e5e0a9e48e1a6a` | `4c6834a8cecfaacd3a19bb34ad2897b9952010205cb59548dccb854c6d67f040` | `f4ae052d01dbb9fbd54962dd05101d2eb72af7708e6cbac954f7f47e1bb34cf5` |
| 05 | `85f90ee3725f452c81cffd963050bca3bcdc2357cd49cca8f6abb39a0b9ab7c2` | `228a32a80a6eeb0c36bfffa3d90ace215c520c5681bdac44e3194b6269ba6748` | `f5cb2db9eaff86e5fa1beb793d5e22185afd78bf8aba1a95c412492a42a97e9b` | `1f37930415e3afebc78ebf4884e41753a9d751f47a526f957e532594f97f54d0` | `a0132efa2420c9aa80e07952af665af540e6cfc2d1ec06f9d4afdadf96e3234d` |
| 06 | `6ddce0f7553d2a09b606ef71e1ea108ce31bbc3c082da2625804cc2824eda8f2` | `c052d81c91c8e2fb43a61662925530f8764424e1d60feb65dadade4ca91a4647` | `2d92187a20d884699d19f2844dce6fd36b5d15736656a322507efd78a93c7195` | `be47922ae3a492bdb3146eace70bfc1d53b5475e67d10d37d26e05ae1526f30b` | `01032163c7c6fb6843ea6f21ed1390950ea4be4db76285647bfda211f488b6bf` |
| 07 | `f62d8c1221ea790940762d7d870d3a8ae976fc83838c1cf007e6c5fa3651eac4` | `1ec42ef3acff6e498b9674dd7680e91804d899738895311f825d59b43e0814de` | `0b58b4a80e4091390416af808e4b62b5f437b09245ef2807867a85db8ef2f276` | `2610dc9504375c0cac738f65ccbd731398556e9e6fe6aef1e05c2730434cb615` | `a7d181366a837eb0d86bc062d760e54930a39e529e78b222217c82e50618a7ce` |
| 08 | `6f1c4f84dd87d461fad3f617325e1ff7acd7c55a474143eede5ffe2de08c3b80` | `0938c16034b3147d1ef47323925bf2846569cf7e3b2ee84b437d400c2d61c994` | `c1591f7071923f6f6593b161a5083136f021ebb6f221c7920f2c358b78cc4f21` | `b53ad61327c698cca1517def79676982b2dd822c9dea0e2459aacc90cd2b29c0` | `eae9a11f2c71e8c054503a2fe827d392b872efa9b75f68b950f187e1275609a0` |
| 09 | `c74cc6169150abdf2401953588c36f5744bf780def785ab084f8c3299e8d178b` | `5ada621c34fee95d821ed422395e4b507170fbcbe297a6552a1ff6ce607d7a5c` | `179ab829cd579b10f26fec070504f855780585fc58143ca12b39c2e1dcffcc0d` | `ea95ee9472f695604390335a7fa5f02deec6335c77d0da55940f590cd7f99e00` | `9aa360d313e48822f5e43300e1b9a668e32fa9e64479a550eeb0d4311dfb30b3` |
| 10 | `7bc98acacf5ff1a8d312f1bb6689046d2d21ce8d44b12f8a288f0ccb6106e122` | `7f3ef794add839809480d6a5277c4a99f54564bfd1f9525a933356ba8264f064` | `39b221b0a8fe2b6dd78926c6226fe40d0bddc5a73c58ce532229d48d640e3be7` | `9f2fb2d2d69d3cc889ac42a8e1e740dbfd9df14e797be41dc110f6691ad28d54` | `04aa702cbd5094629912cc09ce8e9060fcf4eebc96dfe29b51cceb24d1a21197` |

The machine-readable source of this ledger is
`Validation/imported/rocq90_batch1/artifact_manifest.json`; active acceptance
is `Validation/planning/v06_pipeline/rocq90_batch1_status.json`.

## Source, boundary, and translation decisions

All ten pinned v0.6 source files compile directly under Rocq 9.0. No Rocq-9.3
source extraction workaround is used for tactics, Seqset, or SearchArg.

This batch did not change production Lean translations. It adopts the already
validated Phase 6 Nat.find-free `Prosa.Util.SearchArg.prop_on_ex_minn`
reformulation. The SearchArg export contains no `Nat.find`, `Acc`, or
`WellFounded` graph. Its semantic correspondence to the official v0.6
`ex_minn` statement is proved by the existing complete SearchArg certificates,
not treated as a semantic premise.

Nat and UnitGrowth use minimal proof-complete operation boundaries. UnitGrowth
adds only the compiled `HSub`/`Nat.sub`, `LT`, `Decidable.decide`, and
`Prosa.Util.Rel.monotone` interfaces required by its independent certificates;
no target business theorem is exported as a certificate premise. All 46
production declarations are checked against independently stated exact
signatures with `Meta.isDefEq`. Every `.out` is marked
`statement_only=false`. The fail-closed export classifier records zero `#AX`
entries for seven boundaries; Tactics, Subadditivity, and Supremum each contain
only their expected Lean `propext` foundation entry. SearchArg has zero `#AX`
entries.

Rocq-9.0 relevance incompatibilities were handled uniformly: ordinary `Prop`
equalities are established first, then explicitly transported, with a final
conversion to imported Lean equality/SProp. No proof statement or semantic
relation changed.

## Assumption and trust boundary

The declaration classifiers distinguish ordinary closed certificates from
`CERTIFIED_WITH_PROP_SPROP_FOUNDATION`. The latter records the existing,
explicit `PropSPropFoundation.interpret_strict` boundary; this report does not
claim those certificates are globally axiom-free. Actual Lean `#print axioms`
results record only the expected foundation dependencies (`propext`,
`Quot.sound`, and where actually used `Classical.choice`), with no migration-
introduced assumption. In particular, the Nat.find-free
`prop_on_ex_minn` declaration itself reports no Lean axioms.

For every imported module, `rocqchk` reports:

```text
type-in-type: none
unsafe (co)fixpoints: none
assumed positivity: none
unexpected/custom Rocq axioms: 0
```

The only additional imported Lean foundation entries observed by `rocqchk`
are expected `propext` entries in Tactics, Subadditivity, and Supremum; they are
classified as Lean foundation dependencies rather than hidden Rocq axioms.

## Pipeline and provenance

The formal entry is `prepare → check → finalize`. A certificate-only change
reuses a hash-verified prepared snapshot; changes to Lean source, fresh
artifact, export boundary, importer, environment, or declared inputs invalidate
prepare. Published artifacts live entirely below `Validation/`; the active
pipeline does not read compatibility-experiment work, log, or result trees and
does not reuse Rocq-9.3 `.vo` files.

Phase 1–7 remain frozen migration justification. Earlier Rocq-9.3 acceptance
and artifact hashes remain in each canonical file report as provenance, while
the active acceptance rows now point to Rocq 9.0.

## Stop point

Batch 1 stops here. The next READY work item is:

```text
Full Rocq 9.0 Migration — Batch 2
Rank 11: util/list.v whole-file migration
```

No `util/list.v`, `util/sum.v`, or `util/bigcat.v` migration was started by
this batch.
