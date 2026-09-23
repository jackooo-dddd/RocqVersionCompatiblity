# Reports

## Canonical file reports

Each authoritative Prosa v0.6 source file has at most one current report at:

```text
Reports/files/<source-directory>/<first-report-timestamp>_<source-basename>.md
```

Once work starts on a source file, its translation batches, blockers,
revalidation runs, fixes, and final acceptance are appended to that file's
canonical report. The leading timestamp is copied from the earliest historical
report that covered the source file, uses no timezone suffix, and is not
changed on later updates. Do not create another report for the same source
file. File existence is not acceptance; the machine-readable status and
manifest files under `Validation/planning/v06_pipeline/` remain authoritative.

Current canonical reports, in the approved execution order:

| Rank | Source file | Canonical report | Current file status |
|---:|---|---|---|
| 1 | `behavior/time.v` | [time](files/behavior/2026-09-20_210930_time.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 2 | `util/tactics.v` | [tactics](files/util/2026-09-20_214230_tactics.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 3 | `util/notation.v` | [notation](files/util/2026-09-20_214230_notation.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 4 | `util/rel.v` | [rel](files/util/2026-09-20_214230_rel.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 5 | `util/seqset.v` | [seqset](files/util/2026-09-20_214230_seqset.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 6 | `util/subadditivity.v` | [subadditivity](files/util/2026-09-20_214230_subadditivity.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 7 | `util/supremum.v` | [supremum](files/util/2026-09-20_214230_supremum.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 8 | `util/nat.v` | [nat](files/util/2026-09-21_082258_nat.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 9 | `util/unit_growth.v` | [unit_growth](files/util/2026-09-21_082258_unit_growth.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 10 | `util/search_arg.v` | [search_arg](files/util/2026-09-21_082258_search_arg.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 11 | `util/list.v` | [list](files/util/2026-09-21_082258_list.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 12 | `util/sum.v` | [sum](files/util/2026-09-21_082258_sum.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 13 | `util/epsilon.v` | [epsilon](files/util/2026-09-22_034433_epsilon.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 14 | `util/bigop.v` | [bigop](files/util/2026-09-22_034433_bigop.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 15 | `util/setoid.v` | [setoid](files/util/2026-09-22_042247_setoid.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 16 | `util/poet.v` | [poet](files/util/2026-09-22_044913_poet.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 17 | `util/bigcat.v` | [bigcat](files/util/2026-09-22_053020_bigcat.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 18 | `util/minmax.v` | [minmax](files/util/2026-09-22_082537_minmax.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 19 | `util/div_mod.v` | [div_mod](files/util/2026-09-22_103919_div_mod.md) | `ACCEPTED_V06_FILE_ROCQ90` |
| 20 | `util/nondecreasing.v` | [nondecreasing](files/util/2026-09-22_133028_nondecreasing.md) | `HISTORICAL_TRANSLATION_IN_PROGRESS` |

## Current proof progress

On the active Rocq-9.0 baseline, machine-published acceptance is **19 / 357
source files** and **171 / 2439 public declarations**, with **0
translated-but-not-certified**. Rank 1–19 passed fresh actual-artifact import,
all semantic certificates, assumption classification, and `rocqchk`. The
latest formal batch result is
[`rocq90_full_migration_batch3.md`](migrations/rocq90_full_migration_batch3.md).

The next READY work is rank 20,
`util/nondecreasing.v` (33 declarations), which resumes the historically
unfinished translation stage rather than another migration-only revalidation.

The formal scheduling document is
[`../v06_file_translation_order.md`](../v06_file_translation_order.md).
Dependency readiness still comes from the accepted file DAG, not from report
text.

The current validator uses content-addressed `prepare → check → finalize`
execution. Its supported entry points and trust policy are documented in
`Validation/tooling/README.md`.

The repository-wide supported-baseline and importer cleanup is recorded in
[`rocq90_only_importer_cleanup.md`](migrations/rocq90_only_importer_cleanup.md).
