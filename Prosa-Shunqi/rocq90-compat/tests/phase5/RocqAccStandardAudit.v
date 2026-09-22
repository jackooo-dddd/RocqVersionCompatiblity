From Stdlib Require Import Init.Wf.

Set Universe Polymorphism.
Set Printing Universes.

Definition rocq_acc_type_guard@{u}
    (A : Type@{u}) (R : A -> A -> Prop) (a : A) : Prop :=
  Acc R a.

Definition rocq_acc_intro_guard@{u}
    (A : Type@{u}) (R : A -> A -> Prop) (a : A)
    (h : forall b, R b a -> Acc R b) : Acc R a :=
  @Acc_intro A R a h.

Definition rocq_acc_rect_guard@{u v}
    (A : Type@{u}) (R : A -> A -> Prop)
    (P : A -> Type@{v})
    (intro : forall (a : A) (h : forall b, R b a -> Acc R b),
      (forall (b : A) (hba : R b a), P b) -> P a) :
    forall (a : A) (h : Acc R a), P a :=
  @Acc_rect A R P intro.

Definition rocq_well_founded_guard@{u}
    (A : Type@{u}) (R : A -> A -> Prop) : Prop :=
  well_founded R.

Check @Acc.
Check @Acc_intro.
Check @Acc_rect.
Check @well_founded.

Print Assumptions rocq_acc_type_guard.
Print Assumptions rocq_acc_intro_guard.
Print Assumptions rocq_acc_rect_guard.
Print Assumptions rocq_well_founded_guard.
