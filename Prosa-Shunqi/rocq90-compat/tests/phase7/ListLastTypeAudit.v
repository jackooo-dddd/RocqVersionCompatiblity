From mathcomp Require Import ssreflect ssrbool eqtype.
From FoundationImported Require Import ImportedListLast.
From FoundationCertificates Require Import ListLastCertificate.
From prosa Require Import GeneratedListLastSource.

Check GeneratedListLastSource.statement_last0_nth.
Check GeneratedListLastSource.statement_max_of_dominating_seq.
Check GeneratedListLastSource.statement_nth0_cons.
Check ImportedListLast.Prosa_Validation_Phase7ListLastInterface_getD_nat_nil.
Check ImportedListLast.Prosa_Validation_Phase7ListLastInterface_getD_nat_zero.
Check ImportedListLast.Prosa_Validation_Phase7ListLastInterface_getD_nat_succ.

Definition last0_cons_target_type_guard : ll_target_last0_cons_statement :=
  ImportedListLast.Prosa_Util_List_last0_cons.

Definition last0_cat_target_type_guard : ll_target_last0_cat_statement :=
  ImportedListLast.Prosa_Util_List_last0_cat.

Definition last0_ex_cat_target_type_guard : ll_target_last0_ex_cat_statement :=
  ImportedListLast.Prosa_Util_List_last0_ex_cat.

Definition last0_filter_target_type_guard : ll_target_last0_filter_statement :=
  ImportedListLast.Prosa_Util_List_last0_filter.

Definition max0_cons_target_type_guard : ll_target_max0_cons_statement :=
  ImportedListLast.Prosa_Util_List_max0_cons.

Definition max0_2cons_eq_target_type_guard :
    ll_target_max0_2cons_eq_statement :=
  ImportedListLast.Prosa_Util_List_max0_2cons_eq.

Definition max0_2cons_le_target_type_guard :
    ll_target_max0_2cons_le_statement :=
  ImportedListLast.Prosa_Util_List_max0_2cons_le.

Definition last_of_seq_le_max_of_seq_target_type_guard :
    ll_target_last_le_max_statement :=
  ImportedListLast.Prosa_Util_List_last_of_seq_le_max_of_seq.

Definition max0_of_uniform_set_target_type_guard :
    ll_target_max0_of_uniform_set_statement :=
  ImportedListLast.Prosa_Util_List_max0_of_uniform_set.

Definition in_max0_le_target_type_guard : ll_target_in_max0_le_statement :=
  ImportedListLast.Prosa_Util_List_in_max0_le.

Definition max0_in_seq_target_type_guard : ll_target_max0_in_seq_statement :=
  ImportedListLast.Prosa_Util_List_max0_in_seq.

Definition max0_rem0_target_type_guard : ll_target_max0_rem0_statement :=
  ImportedListLast.Prosa_Util_List_max0_rem0.

Print Assumptions last0_cons_target_type_guard.
Print Assumptions last0_cat_target_type_guard.
Print Assumptions last0_ex_cat_target_type_guard.
Print Assumptions last0_filter_target_type_guard.
Print Assumptions max0_cons_target_type_guard.
Print Assumptions max0_2cons_eq_target_type_guard.
Print Assumptions max0_2cons_le_target_type_guard.
Print Assumptions last_of_seq_le_max_of_seq_target_type_guard.
Print Assumptions max0_of_uniform_set_target_type_guard.
Print Assumptions in_max0_le_target_type_guard.
Print Assumptions max0_in_seq_target_type_guard.
Print Assumptions max0_rem0_target_type_guard.
