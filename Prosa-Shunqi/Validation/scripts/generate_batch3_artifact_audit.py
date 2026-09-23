#!/usr/bin/env python3
"""Generate independent Lean exact-type guards for Rocq 9.0 Batch 3.

The expected types come from the frozen Rocq 9.0 Batch 3 type inventory,
while the guarded constants come from the freshly compiled production
modules.  The generated Lean module checks the pair with Meta.isDefEq; it
never derives an expected type from the declaration being guarded.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path


FILES = (
    "util/sum.v",
    "util/bigop.v",
    "util/setoid.v",
    "util/poet.v",
    "util/bigcat.v",
    "util/minmax.v",
    "util/div_mod.v",
)

IMPORTS = (
    "Prosa.Util.Sum",
    "Prosa.Util.Bigop",
    "Prosa.Util.Setoid",
    "Prosa.Util.Poet",
    "Prosa.Util.Bigcat",
    "Prosa.Util.Minmax",
    "Prosa.Util.Div_mod",
)


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def expected_type(row: dict[str, object]) -> tuple[str, str]:
    target = str(row["lean_declaration"])
    frozen = str(row["lean_elaborated_type"])
    head = re.split(
        rf"\n(?:theorem|def|inductive) {re.escape(target)}", frozen, maxsplit=1
    )[0].strip()
    recorded = str(row["lean_type_sha256"])
    if sha256(head) != recorded and sha256(frozen) != recorded:
        raise SystemExit(f"frozen type fingerprint mismatch: {target}")
    if " : " not in head:
        raise SystemExit(f"cannot isolate historical type: {target}")
    return head.split(" : ", 1)[1].strip(), recorded


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--metadata", type=Path, required=True)
    args = parser.parse_args()

    with args.inventory.open(newline="") as handle:
        inventory = [
            row
            for row in csv.DictReader(handle)
            if row["source_file"] in FILES
        ]

    by_source_name: dict[tuple[str, str], dict[str, object]] = {}
    for manifest_path in args.manifest:
        data = json.loads(manifest_path.read_text())
        for row in data.get("declarations", []):
            key = (str(row.get("source_file")), str(row.get("rocq_declaration", "")).rsplit(".", 1)[-1])
            if key[0] not in FILES:
                continue
            if key in by_source_name:
                raise SystemExit(f"duplicate frozen declaration: {key}")
            by_source_name[key] = row

    expected_keys = {(row["source_file"], row["declaration_name"]) for row in inventory}
    if len(inventory) != 68 or set(by_source_name) != expected_keys:
        missing = sorted(expected_keys - set(by_source_name))
        extra = sorted(set(by_source_name) - expected_keys)
        raise SystemExit(
            f"fail-closed Batch 3 guard coverage mismatch: count={len(inventory)} "
            f"missing={missing!r} extra={extra!r}"
        )

    lines = [*(f"import {module}" for module in IMPORTS), "", "open Lean Elab Command Meta", "", "set_option linter.defProp false", "", "namespace Prosa.Validation.Rocq90Batch3", "", "namespace Expected", "", "universe u_1 u_2", ""]
    pairs: list[tuple[str, str]] = []
    metadata: list[dict[str, object]] = []
    for index, item in enumerate(inventory, 1):
        key = (item["source_file"], item["declaration_name"])
        row = by_source_name[key]
        target = str(row["lean_declaration"])
        typ, fingerprint = expected_type(row)
        guard = f"guard_{index:02d}"
        lines.extend((f"def {guard} : {typ} :=", f"  @{target}", ""))
        pairs.append((target, f"Expected.{guard}"))
        metadata.append(
            {
                "source_file": key[0],
                "source_declaration": key[1],
                "lean_declaration": target,
                "expected_type_sha256": fingerprint,
                "guard": guard,
            }
        )

    lines.extend(("end Expected", "", "private def guardPairs : Array (Name × Name) := #["))
    for index, (target, guard) in enumerate(pairs):
        comma = "," if index + 1 < len(pairs) else ""
        lines.append(f"  (``{target}, ``{guard}){comma}")
    lines.extend(
        (
            "]",
            "",
            "private def requireActualType (target guard : Name) : MetaM Unit := do",
            "  let targetInfo ← getConstInfo target",
            "  let guardInfo ← getConstInfo guard",
            "  unless targetInfo.levelParams.length == guardInfo.levelParams.length do",
            "    throwError \"UNIVERSE_ARITY_MISMATCH target={target}\"",
            "  let levels ← targetInfo.levelParams.mapM fun _ => mkFreshLevelMVar",
            "  let targetType := targetInfo.type.instantiateLevelParams targetInfo.levelParams levels",
            "  let guardType := guardInfo.type.instantiateLevelParams guardInfo.levelParams levels",
            "  unless ← Meta.isDefEq targetType guardType do",
            "    throwError \"TYPE_DEF_EQ_FAILED target={target}\"",
            "  logInfo m!\"TYPE_DEF_EQ_OK target={target} type_hash={hash targetInfo.type}\"",
            "",
            "run_cmd liftTermElabM do",
            "  unless guardPairs.size == 68 do throwError \"expected 68 Batch 3 declarations\"",
            "  for (target, guard) in guardPairs do requireActualType target guard",
            "  logInfo \"BATCH3_ACTUAL_ARTIFACT_GUARDS_OK count=68\"",
            "",
            "end Prosa.Validation.Rocq90Batch3",
            "",
        )
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.metadata.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines))
    args.metadata.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "authoritative_count": 68,
                "expected_type_source": "Rocq 9.0 Batch 3 type inventories",
                "guards": metadata,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )


if __name__ == "__main__":
    main()
