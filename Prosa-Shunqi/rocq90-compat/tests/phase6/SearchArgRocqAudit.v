From LeanImport Require Import Lean.
From FoundationImported Require Import ImportedSearchArg.

Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg.
Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_1.
Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_2.
Check ImportedSearchArg.Prosa_Util_SearchArg_prop_on_ex_minn.

Print Assumptions ImportedSearchArg.Prosa_Util_SearchArg_prop_on_ex_minn.

Fail Check ImportedSearchArg.Nat_find.
Fail Check ImportedSearchArg.Nat_findX.
Fail Check ImportedSearchArg.Acc.
Fail Check ImportedSearchArg.WellFounded.
Fail Check ImportedSearchArg.Acc_rec.
Fail Check ImportedSearchArg.Acc_rect.

Universe phase6_u.
Fail Definition phase6_type_in_type : Type@{phase6_u} := Type@{phase6_u}.

Inductive phase6_sprop_payload : SProp :=
| phase6_sprop_payload_intro : nat -> phase6_sprop_payload.

Fail Definition phase6_forbidden_sprop_elimination
    (p : phase6_sprop_payload) : nat :=
  match p with
  | phase6_sprop_payload_intro n => n
  end.
