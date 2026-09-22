From mathcomp Require Import ssreflect ssrbool eqtype ssrnat seq fintype bigop.
Require Export mathcomp.zify.zify.
Require Import prosa.util.tactics.

Module GeneratedSearchArgSource.

Definition statement_earliest_pred_element_exists_case : Prop :=
  (forall (P : pred nat) (t1 t2 : nat), (forall t : nat, t1 <= t < t2 -> ~~ P t) \/ (exists t : nat, t1 <= t < t2 /\ P t /\ (forall t' : nat, t1 <= t' -> P t' -> t <= t'))).

Section SourceContext_1.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.

  Fixpoint search_arg (a b : nat) : option nat :=
    if a < b then
      match b with
      | 0 => None
      | S b' => match search_arg a b' with
                | None => if P (f b') then Some b' else None
                | Some x => if P (f b') && R (f b') (f x) then Some b' else Some x
                end
      end
    else None.

End SourceContext_1.

Section SourceContext_2.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.

Definition statement_search_arg_none : Prop :=
  (forall (T : Type) (f : nat -> T) (P : pred T) (R : rel T) (a b : nat), search_arg f P R a b = None <-> (forall x : nat, a <= x < b -> ~~ P (f x))).

End SourceContext_2.

Section SourceContext_3.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.

Definition statement_search_arg_not_none : Prop :=
  (forall (T : Type) (f : nat -> T) (P : pred T) (R : rel T) (a b : nat), (exists x : nat, a <= x < b /\ P (f x)) -> exists y : nat, search_arg f P R a b = Some y).

End SourceContext_3.

Section SourceContext_4.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.

Definition statement_search_arg_pred : Prop :=
  (forall (T : Type) (f : nat -> T) (P : pred T) (R : rel T) (a b x : nat), search_arg f P R a b = Some x -> P (f x)).

End SourceContext_4.

Section SourceContext_5.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.

Definition statement_search_arg_in_range : Prop :=
  (forall (T : Type) (f : nat -> T) (P : pred T) (R : rel T) (a b x : nat), search_arg f P R a b = Some x -> a <= x < b).

End SourceContext_5.

Section SourceContext_6.
  Context {T : Type}.
  Variable f : nat -> T.
  Variable P : pred T.
  Variable R : rel T.
  Hypothesis R_reflexive : reflexive R.
  Hypothesis R_transitive : transitive R.
  Hypothesis R_total : total R.

Definition statement_search_arg_extremum : Prop :=
  (forall (T : Type) (f : nat -> T) (P : pred T) (R : rel T), reflexive (T:=T) R -> transitive (T:=T) R -> total (T:=T) R -> forall a b x : nat, search_arg f P R a b = Some x -> forall y : nat, a <= y < b -> P (f y) -> R (f x) (f y)).

End SourceContext_6.

Definition statement_prop_on_ex_minn : Prop :=
  (forall (P : nat -> Prop) (pred : nat -> bool) (ex0 : exists n : nat, pred n), P (ex_minn (P:=pred) ex0) -> exists n : nat, P n /\ pred n /\ (forall n' : nat, pred n' -> n <= n')).

End GeneratedSearchArgSource.
