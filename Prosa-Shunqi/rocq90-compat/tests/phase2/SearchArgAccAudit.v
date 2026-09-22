From Phase2Imported Require Import ImportedSearchArg.

Module I := ImportedSearchArg.

(* Presence and representative-type checks for the imported Acc path. *)
Check I.Acc.
Check I.Acc_intro.
Check I.Acc_rec.
Check I.Acc_rect.
Check I.WellFounded.
Check I.WellFounded_fix.
Check I.Prosa_Util_SearchArg_search_arg.
Check I.Prosa_Util_SearchArg_prop_on_ex_minn.
Print I.Acc_rec.
Print I.Acc_rect.

(* A relation with no predecessors gives a closed Acc witness. *)
Inductive phase2_empty_rel : unit -> unit -> SProp := .

Definition phase2_unit_acc : I.Acc unit phase2_empty_rel tt :=
  @I.Acc_intro unit phase2_empty_rel tt
    (fun y edge => match edge with end).

(* Exercise the imported SProp-to-Set recursor and its computation rule. *)
Definition phase2_acc_compute : nat :=
  @I.Acc_rec unit phase2_empty_rel
    (fun _ _ => nat)
    (fun _ _ _ => 7)
    tt phase2_unit_acc.

Eval cbv delta [phase2_acc_compute] in phase2_acc_compute.

(* The imported recursor is present, but this closed application does not
   compute by kernel reduction.  Keep that limitation machine-checked. *)
Fail Definition phase2_acc_computes_by_reflexivity :
  phase2_acc_compute = 7 := eq_refl 7.

(* Negative control: universe checking must be back on after import. *)
Universe phase2_u.
Fail Definition phase2_type_in_type : Type@{phase2_u} := Type@{phase2_u}.
