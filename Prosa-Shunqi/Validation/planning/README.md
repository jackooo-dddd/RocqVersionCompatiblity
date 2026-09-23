# Planning Snapshots

`v06_dependency/` and `v06_mapping/` are verbatim accepted snapshots copied
from `../../../Prosa-fei/Validation/planning/` during workspace creation.
They retain historical evidence, including any absolute paths that identify
the environment in which the evidence was generated. Those paths have not
been rewritten.

Copied reproduction scripts are therefore historical snapshot components.
Before rerunning them in this workspace, create a new `Prosa-Shunqi`-specific
reproduction entry point rather than altering or falsifying the old evidence.
Future pipeline planning belongs in `v06_pipeline/`.

The active validation baseline is Rocq 9.0.0. Rocq 9.3 status files and
artifacts are retained as historical provenance; active downstream readiness
must use `v06_pipeline/active_validation_baseline.json` and the Rocq 9.0 batch
status it names. The current publication is Batch 3, covering ranks 1–19 and
171 declarations. Never infer readiness from a historical 9.3 acceptance
alone.
