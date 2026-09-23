From LeanImport Require Import Lean.
From FoundationImported Require Import ImportedListLast ImportedBigcat.

Fail Check ImportedListLast.Acc.
Fail Check ImportedListLast.WellFounded.
Fail Check ImportedListLast.Nat_find.
Fail Check ImportedBigcat.Acc.
Fail Check ImportedBigcat.WellFounded.
Fail Check ImportedBigcat.Nat_find.

Universe phase7_u.
Fail Definition phase7_type_in_type : Type@{phase7_u} := Type@{phase7_u}.

Inductive phase7_sprop_payload : SProp :=
| phase7_sprop_payload_intro : nat -> phase7_sprop_payload.

Fail Definition phase7_forbidden_sprop_elimination
    (p : phase7_sprop_payload) : nat :=
  match p with
  | phase7_sprop_payload_intro n => n
  end.
