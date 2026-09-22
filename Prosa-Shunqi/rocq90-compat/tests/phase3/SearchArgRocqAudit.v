From LeanImport Require Import Lean.
From Phase3Imported Require Import ImportedSearchArg.

Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg.
Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_1.
Check ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_2.

Print Assumptions ImportedSearchArg.Prosa_Util_SearchArg_search_arg.
Print Assumptions ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_1.
Print Assumptions ImportedSearchArg.Prosa_Util_SearchArg_search_arg_eq_2.

Fail Check ImportedSearchArg.Acc.
Fail Check ImportedSearchArg.WellFounded.
Fail Check ImportedSearchArg.Acc_rec.
Fail Check ImportedSearchArg.Acc_rect.

Universe phase3_u.
Fail Definition phase3_type_in_type : Type@{phase3_u} := Type@{phase3_u}.
