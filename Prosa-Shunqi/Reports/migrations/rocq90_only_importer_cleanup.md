# Rocq 9.0-only importer and repository cleanup

Classification: `ROCQ90_ONLY_MAINLINE_VERIFIED`

Starting HEAD: `777f634cd0b53e409b174dfdfbae2dcca7a53d66`.

## Final supported environment

The project now supports only stock Rocq 9.0.0 with OCaml 4.14.2,
MathComp 2.4.0, and coq-mathcomp-zify 1.5.0+2.0+8.16. The Lean side remains
Lean 4.33.1 with Mathlib
`0df444a360eaa60ab8c11dca51a86af692955474`; the authoritative Prosa source
remains v0.6 commit `414e66760333eaa4ef78c685bcf53291c527a548`.

The selected importer base is upstream commit
`b8291b9dae4f5ed780112e95eea484e435199b46`, the immediate predecessor of
upstream breaking point `50802fbc22c96706189a070ab7e9da6f34a90409`. Its
opam metadata admits Rocq 9.0, but the unpatched checkout does not build
against the pinned stock environment: it hits the `UGraph.add_universe` API
change. Current Lean 4.33 exports additionally require UInt32/BitVec, current
string construction, and non-record/dependent projection lowering.

One audited patch now owns all required adaptations:

- `Validation/tooling/patches/rocq90-importer.patch`
- SHA-256: `7bfe3fec08074ce6818d12621aad7afc68899453805c74b36d7bd3fe55572fa0`
- 316 changed LOC (additions plus deletions), 2 patched files
- plugin SHA-256:
  `6f0c2fecd1297de31cca1c4aafe8cd1c346701b4aed95dc73e6004032aa3b13b`
- importer foundation SHA-256:
  `441cec39e694c4dd090dfe525308884bf1af83c5798a1966c2c816e79e03f210`

There is no separate `rocq90-api.patch`. The single patch still contains the
small stock-Rocq-9.0 API adaptation that b829 needs; removing a separately
named file is not represented as removing that necessary code. It preserves
`with_unsafe_univs f () = f ()` and contains no universe/elimination bypass.

## Formal regression

The final cold run rebuilt and published all three mainline batches:

| Batch | Files | Declarations | Import | Certificates | Audit / `rocqchk` | Publication |
|---|---:|---:|---|---|---|---|
| 1 | 10/10 | 46/46 | PASS | PASS | PASS | PASS |
| 2 | 1/1 | 57/57 | PASS | PASS | PASS | PASS |
| 3 | 8/8 | 68/68 | PASS | PASS | PASS | PASS |
| Total | 19/19 | 171/171 | PASS | PASS | PASS | PASS |

The published state has `translated-but-not-certified=0`, empty semantic
premises and unexpected assumptions, no source/target theorem dependency,
normal universe and elimination checking, no type-in-type, unsafe fixpoint,
assumed positivity, or unexpected/custom Rocq axiom.

The final cold `prepare → check → finalize` run took 717.03 s with peak RSS
2,995,093,504 bytes. Its import-stage sum was 17.859587 s and certificate
compile sum was 74.555216 s.

## Benchmark result

The comparison uses the same machine and content-identical exported
boundaries. The old scheme was importer commit `546979bfd55b94288abfb72583a534b0136d282d`
plus separate project and API patches; the new scheme is b829 plus the one
patch above.

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| clean importer build | 2.07 s | 2.64 s | +0.57 s |
| Time import | 0.21 s | 0.25 s | +0.04 s |
| SearchArg import | 0.72 s | 0.79 s | +0.07 s |
| ListSimple + ListLast import | 2.68 s | 2.74 s | +0.06 s |
| Bigcat import | 2.73 s | 2.76 s | +0.03 s |
| Rank 1–19 import-stage sum | 18.217702 s | 17.859587 s | -0.358115 s |
| Rank 1–19 certificate compile | 72.041714 s | 74.555216 s | +2.513502 s |
| full cold run | 632.57 s | 717.03 s | +84.46 s |
| full-run peak RSS | 3,013,754,880 B | 2,995,093,504 B | -18,661,376 B |
| representative `.vo` size | 2,310,560 B | 2,266,805 B | -43,755 B |

The new importer is not uniformly faster. The full import stages were 1.97%
faster in this single run, while individual representative imports, clean
build, certificates, and total cold wall time were slower. The total wall
increase was dominated by fresh Lean build variance, especially Batch 3, not
by Rocq import time. These are single-run measurements, not statistical
performance claims.

## Dependency and disk result

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| OPAM installed packages | 57 | 57 | 0 |
| OPAM transitive dependencies | 50 | 50 | 0 |
| switch disk | 1,963,108 KiB | 1,963,108 KiB | 0 |
| importer patch LOC | 278 | 316 | +38 |
| patched files | 2 | 2 | 0 |
| tracked validation scripts/configs | 77 | 39 | -38 |
| imported closure records | 3,703 | 3,703 | 0 |
| formal Rank 1–19 artifact disk | 12,072 KiB | 10,356 KiB | -1,716 KiB |
| workspace disk | 9,057,240 KiB | 5,759,060 KiB | -3,298,180 KiB |

The OPAM dependency graph is unchanged and the consolidated importer patch is
38 LOC larger because current-format and projection backports moved onto the
older base. Repository support surface and disk use are smaller: obsolete
validation scripts/configs, superseded imported evidence, compatibility
experiments, run caches, and logs were removed. The Rocq 9.0 switch and all
published Rank 1–19 evidence remain.

No Rank 20 work was started.
