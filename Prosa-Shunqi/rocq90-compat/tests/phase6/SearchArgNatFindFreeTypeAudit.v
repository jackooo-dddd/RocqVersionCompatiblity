From LeanImport Require Import Lean.
From FoundationImported Require Import ImportedSearchArg.

(** This definition is an exact imported-type guard only.  The semantic
    certificate does not import it or depend on the target theorem. *)
Definition phase6_prop_on_ex_minn_exact_type_guard :
  forall (P : Lean.Nat -> SProp)
      (pred : Lean.Nat -> ImportedSearchArg.Bool)
      (ex : ImportedSearchArg.Exists Lean.Nat
        (fun n => Lean.eq (pred n) ImportedSearchArg.Bool_true)),
    (forall n,
      Lean.eq (pred n) ImportedSearchArg.Bool_true ->
      (forall n', Lean.eq (pred n') ImportedSearchArg.Bool_true ->
        ImportedSearchArg.LE_le_inst1 Lean.Nat
          ImportedSearchArg.instLENat n n') ->
      P n) ->
    ImportedSearchArg.Exists Lean.Nat (fun n =>
      Lean.And (P n)
        (Lean.And
          (Lean.eq (pred n) ImportedSearchArg.Bool_true)
          (forall n', Lean.eq (pred n') ImportedSearchArg.Bool_true ->
            ImportedSearchArg.LE_le_inst1 Lean.Nat
              ImportedSearchArg.instLENat n n'))) :=
  ImportedSearchArg.Prosa_Util_SearchArg_prop_on_ex_minn.

Print Assumptions phase6_prop_on_ex_minn_exact_type_guard.
