From mathcomp Require Import ssreflect ssrbool eqtype seq.
From FoundationImported Require Import ImportedSupremum.
From prosa Require Import util.supremum.

Inductive SupValidationTrue : SProp := sup_validation_I.
Inductive SupValidationFalse : SProp := .

Definition SupBoolRel (bR : bool) (bL : ImportedSupremum.Bool) : SProp :=
  match bR, bL with
  | true, ImportedSupremum.Bool_true => SupValidationTrue
  | false, ImportedSupremum.Bool_false => SupValidationTrue
  | _, _ => SupValidationFalse
  end.

Inductive SupOptionRel (T : Type) :
    option T -> ImportedSupremum.Option T -> SProp :=
| sup_option_none :
    SupOptionRel T None (ImportedSupremum.Option_none T)
| sup_option_some : forall x,
    SupOptionRel T (Some x) (ImportedSupremum.Option_some T x).

Inductive SupListRel (T : Type) :
    seq T -> ImportedSupremum.List T -> SProp :=
| sup_list_nil :
    SupListRel T nil (ImportedSupremum.List_nil T)
| sup_list_cons : forall x xsR xsL,
    SupListRel T xsR xsL ->
    SupListRel T (x :: xsR) (ImportedSupremum.List_cons T x xsL).

Definition sup_option_rel_transport (T : Type)
    (source source' : option T)
    (target target' : ImportedSupremum.Option T) :
    Logic.eq source source' -> Logic.eq target target' ->
    SupOptionRel T source target -> SupOptionRel T source' target' :=
  fun Hsource Htarget Hrel =>
    match Hsource in Logic.eq _ source0 return
      Logic.eq target target' ->
      SupOptionRel T source0 target'
    with
    | Logic.eq_refl => fun Htarget0 =>
        match Htarget0 in Logic.eq _ target0 return
          SupOptionRel T source target0
        with
        | Logic.eq_refl => Hrel
        end
    end Htarget.

Lemma choose_superior_correspondence_certificate :
  forall (T : eqType)
         (RR : T -> T -> bool)
         (RL : T -> T -> ImportedSupremum.Bool),
    (forall x y, SupBoolRel (RR x y) (RL x y)) ->
    forall x maybeR maybeL,
      SupOptionRel T maybeR maybeL ->
      SupOptionRel T
        (@prosa.util.supremum.choose_superior T RR x maybeR)
        (Prosa_Util_Supremum_choose_superior T RL x maybeL).
Proof.
  intros T RR RL HR x maybeR maybeL Hmaybe.
  destruct Hmaybe as [|y].
  - exact (sup_option_some T x).
  - specialize (HR x y).
    destruct (RR x y) eqn:HRR;
      destruct (RL x y) eqn:HRL;
      cbn in HR |- *.
    + destruct HR.
    + refine (sup_option_rel_transport T (Some x) _
        (ImportedSupremum.Option_some T x) _ _ _
        (sup_option_some T x)).
      * rewrite HRR. reflexivity.
      * unfold ImportedSupremum.Prosa_Util_Supremum_choose_superior.
        rewrite HRL. reflexivity.
    + refine (sup_option_rel_transport T (Some y) _
        (ImportedSupremum.Option_some T y) _ _ _
        (sup_option_some T y)).
      * rewrite HRR. reflexivity.
      * unfold ImportedSupremum.Prosa_Util_Supremum_choose_superior.
        rewrite HRL. reflexivity.
    + destruct HR.
Qed.

Lemma supremum_correspondence_certificate :
  forall (T : eqType)
         (RR : T -> T -> bool)
         (RL : T -> T -> ImportedSupremum.Bool),
    (forall x y, SupBoolRel (RR x y) (RL x y)) ->
    forall xsR xsL,
      SupListRel T xsR xsL ->
      SupOptionRel T
        (@prosa.util.supremum.supremum T RR xsR)
        (Prosa_Util_Supremum_supremum T RL xsL).
Proof.
  intros T RR RL HR xsR xsL Hxs.
  induction Hxs.
  - exact (sup_option_none T).
  - cbn.
    exact (choose_superior_correspondence_certificate T RR RL HR x _ _ IHHxs).
Qed.
