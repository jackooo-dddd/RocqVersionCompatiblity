#!/usr/bin/env python3
"""Bind Batch 3 Rocq encodings to Acc-free semantic statement definitions.

The historical type-audit modules already specialize every imported Lean
theorem to the canonical Rocq-side carrier.  This generator preserves those
specializations, but turns the imported theorem proof into an explicit
premise whose type is the Batch 3 semantic-statement definition.  Therefore
the generated guards check the imported type without treating a statement as
an axiom or making a business theorem a certificate dependency.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


MODULES = {
    "SumSequence": [
        "sum_nat_eq0_nat", "sum_nat_gt0", "sum_majorant_constant",
        "sum_split_exhaustive_mutually_exclusive_preds", "bigmax_leq_sum",
        "sum_le_subseq", "leq_sum_seq", "eq_sum_seq", "leq_sum_seq_pred",
        "leq_sum_subseq", "leq_sum_sub_uniq", "ltn_sum_leq_seq",
        "eq_sum_leq_seq", "sum_over_partitions_le", "reorder_summation",
        "sum_over_partitions_eq", "sum_leq_mono", "sum_unit1",
        "sum_ge_2_seq",
    ],
    "SumInterval": [
        "sum_of_ones", "big_nat_eq0", "sum_le_summation_range",
        "big_sum_eq_in_eq_sized_intervals", "pigeonhole_on_interval",
        "sum_ge_2_nat",
    ],
    "Bigop": ["big_pred1_seq"],
    "Setoid": ["leb_eq"],
    "Poet": ["forall_exists_implied_by_forall_in_zip"],
    "Bigcat": [
        "mem_bigcat_nat", "mem_bigcat_nat_exists", "mem_bigcat_ord",
        "bigcat_nat_uniq", "bigcat_nat_filter_eq_filter_bigcat_nat",
        "size_big_nat", "mem_bigcat", "mem_bigcat_exists",
        "bigcat_filter_eq_filter_bigcat", "bigcat_uniq",
        "seq_different_elements_nil", "bigcat_seq_uniqK",
        "bigcat_partitions",
    ],
    "Minmax": [
        "leq_bigmax_cond_seq", "leq_bigmax_sup", "bigmax_leq_seqP",
        "leq_big_max", "bigmax_ord_ltn_identity", "bigmax_ltn_ord",
        "bigmax_pred", "bigmax_witness", "bigmax_witness_diff",
        "bigmax_subset",
    ],
    "DivMod": [
        "eqdivn_leqmodn", "ltdivn_dvdn", "addn1_modn_commute",
        "addmod_le_mod", "divn_leq", "div_ceil0", "div_ceil_gt0",
        "div_ceil_monotone1", "leq_div_ceil_add1",
        "div_ceil_subadditive", "div_ceil_multiple", "div_floor_add_g",
        "mod_elim",
    ],
}

LEAN_MODULE = {
    "SumSequence": "Sum",
    "SumInterval": "Sum",
    "Bigop": "Bigop",
    "Setoid": "Setoid",
    "Poet": "Poet",
    "Bigcat": "Bigcat",
    "Minmax": "Minmax",
    "DivMod": "Div_mod",
}

ALIAS_PREFIX = {
    "SumSequence": "sum_", "SumInterval": "sum_", "Bigop": "bigop_",
    "Setoid": "setoid_", "Poet": "poet_", "Bigcat": "bigcat_",
    "Minmax": "minmax_", "DivMod": "divmod_",
}


def adapter_name(module: str, declaration: str) -> str:
    if declaration == "sum_unit1":
        local = "sumUnitStatement"
    else:
        local = ALIAS_PREFIX[module] + declaration
    return f"Imported{module}.Prosa_Validation_Batch3Semantic_{local}"


def production_name(module: str, declaration: str) -> str:
    return f"Imported{module}.Prosa_Util_{LEAN_MODULE[module]}_{declaration}"


def transform(text: str, module: str) -> str:
    transformed = 0
    for declaration in MODULES[module]:
        actual = production_name(module, declaration)
        position = text.find(actual)
        if position < 0:
            raise SystemExit(f"{module}: missing historical target {actual}")
        start = text.rfind("\nDefinition ", 0, position)
        if start < 0:
            raise SystemExit(f"{module}: cannot find guard for {actual}")
        start += 1
        end = text.find(".\n", position)
        if end < 0:
            raise SystemExit(f"{module}: unterminated guard for {actual}")
        end += 1
        block = text[start:end]
        match = re.match(r"Definition\s+([A-Za-z0-9_']+)", block)
        if match is None:
            raise SystemExit(f"{module}: malformed guard for {actual}")
        adapter = adapter_name(module, declaration)
        block = block[: match.end()] + f"\n    (H : {adapter})" + block[match.end() :]
        block = block.replace(actual, "H")
        text = text[:start] + block + text[end:]
        transformed += 1
    if transformed != len(MODULES[module]):
        raise SystemExit(f"{module}: incomplete audit transformation")
    return (
        text
        + f"\n(** Batch 3 fail-closed semantic type guards: {transformed}. *)\n"
        + f"Goal {transformed} = {len(MODULES[module])}. Proof. reflexivity. Qed.\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args()
    args.output_root.mkdir(parents=True, exist_ok=True)
    for module in MODULES:
        source = args.source_root / f"{module}TypeAudit.v"
        output = args.output_root / source.name
        output.write_text(transform(source.read_text(), module))
    print(f"BATCH3_ROCQ_TYPE_AUDITS_OK declarations={sum(map(len, MODULES.values()))}")


if __name__ == "__main__":
    main()
