From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq.
From LeanImport Require Import Lean.
From FoundationImported Require Import
  ImportedNondecreasing ImportedSubadditivity.
From FoundationCertificates Require Import
  PropSPropFoundation LogicalRelation SubadditivityNatCorrespondence
  NatSubCorrespondence NondecreasingBaseAdapter.
From prosa Require Import GeneratedNondecreasingSource.

(** Artifact-local realization of the approved [seq nat <-> List Nat]
    relation.  Unlike the generic same-carrier adapter, this map also applies
    the already certified Rocq-[nat] / imported-Lean-[Nat] isomorphism. *)
Fixpoint nd_nat_list_to_imported (xs : seq nat) :
    ImportedNondecreasing.List_inst1 Lean.Nat :=
  match xs with
  | [::] => ImportedNondecreasing.List_nil_inst1 Lean.Nat
  | x :: tail => ImportedNondecreasing.List_cons_inst1 Lean.Nat
      (sub_nat_to_imported x) (nd_nat_list_to_imported tail)
  end.

Fixpoint nd_nat_list_to_rocq
    (xs : ImportedNondecreasing.List_inst1 Lean.Nat) : seq nat :=
  match xs with
  | ImportedNondecreasing.List_nil_inst1 => [::]
  | ImportedNondecreasing.List_cons_inst1 x tail =>
      sub_nat_to_rocq x :: nd_nat_list_to_rocq tail
  end.

Definition NdNatListRel (xsR : seq nat)
    (xsL : ImportedNondecreasing.List_inst1 Lean.Nat) : SProp :=
  Lean.eq (nd_nat_list_to_imported xsR) xsL.

Definition nd_nat_list_cons_congr (x y : Lean.Nat)
    (xs ys : ImportedNondecreasing.List_inst1 Lean.Nat) :
  Lean.eq x y -> Lean.eq xs ys ->
  Lean.eq (ImportedNondecreasing.List_cons_inst1 Lean.Nat x xs)
    (ImportedNondecreasing.List_cons_inst1 Lean.Nat y ys) :=
  fun Hx Hxs => sub_imported_eq_congr2
    (ImportedNondecreasing.List_cons_inst1 Lean.Nat) x y xs ys Hx Hxs.

Lemma nd_nat_list_source_roundtrip (xs : seq nat) :
  Logic.eq (nd_nat_list_to_rocq (nd_nat_list_to_imported xs)) xs.
Proof.
  induction xs as [|x xs IH]; cbn; first reflexivity.
  f_equal.
  - exact (sub_nat_rocq_roundtrip x).
  - exact IH.
Qed.

Lemma nd_nat_list_target_roundtrip
    (xs : ImportedNondecreasing.List_inst1 Lean.Nat) :
  Lean.eq (nd_nat_list_to_imported (nd_nat_list_to_rocq xs)) xs.
Proof.
  induction xs as [|x xs IH]; cbn.
  - exact (@Lean.eq_refl _
      (ImportedNondecreasing.List_nil_inst1 Lean.Nat)).
  - exact (nd_nat_list_cons_congr _ _ _ _
      (sub_nat_imported_roundtrip x) IH).
Qed.

Definition nd_target_length
    (xs : ImportedNondecreasing.List_inst1 Lean.Nat) : Lean.Nat :=
  ImportedNondecreasing.List_length_inst1 Lean.Nat xs.

Definition nd_target_nthD
    (xs : ImportedNondecreasing.List_inst1 Lean.Nat)
    (n : Lean.Nat) : Lean.Nat :=
  ImportedNondecreasing.Prosa_Validation_NondecreasingInterface_nthD xs n.

Definition nd_target_le (a b : Lean.Nat) : SProp :=
  ImportedNondecreasing.LE_le_inst1 Lean.Nat
    ImportedNondecreasing.instLENat a b.

Definition nd_target_lt (a b : Lean.Nat) : SProp :=
  ImportedNondecreasing.LT_lt_inst1 Lean.Nat
    ImportedNondecreasing.instLTNat a b.

Lemma nd_le_correspondence aR aL bR bL :
  SubNatRel aR aL -> SubNatRel bR bL ->
  PropSPropRel (is_true (leq aR bR)) (nd_target_le aL bL).
Proof. exact (sub_nat_le_correspondence aR aL bR bL). Qed.

Lemma nd_lt_correspondence aR aL bR bL :
  SubNatRel aR aL -> SubNatRel bR bL ->
  PropSPropRel (is_true (ltn aR bR)) (nd_target_lt aL bL).
Proof. exact (sub_nat_lt_correspondence aR aL bR bL). Qed.

Lemma nd_length_canonical (xs : seq nat) :
  SubNatRel (size xs) (nd_target_length (nd_nat_list_to_imported xs)).
Proof.
  induction xs as [|x xs IH].
  - exact (@Lean.eq_refl Lean.Nat Lean.Nat_zero).
  - cbn [nd_target_length nd_nat_list_to_imported].
    exact (sub_imported_eq_congr Lean.Nat_succ _ _ IH).
Qed.

Lemma nd_length_related xsR xsL : NdNatListRel xsR xsL ->
  SubNatRel (size xsR) (nd_target_length xsL).
Proof.
  intro Hxs. exact (sub_imported_eq_trans _ _ _
    (nd_length_canonical xsR)
    (sub_imported_eq_congr nd_target_length _ _ Hxs)).
Qed.

Lemma nd_nthD_canonical (xs : seq nat) (n : nat) :
  SubNatRel (nth O xs n)
    (nd_target_nthD (nd_nat_list_to_imported xs)
      (sub_nat_to_imported n)).
Proof.
  revert n. induction xs as [|x xs IH]; intro n; destruct n;
    cbn [nd_target_nthD nd_nat_list_to_imported sub_nat_to_imported];
    try exact (@Lean.eq_refl Lean.Nat Lean.Nat_zero);
    try exact (@Lean.eq_refl Lean.Nat (sub_nat_to_imported x));
    exact (IH n).
Qed.

Lemma nd_nthD_related xsR xsL nR nL :
  NdNatListRel xsR xsL -> SubNatRel nR nL ->
  SubNatRel (nth O xsR nR) (nd_target_nthD xsL nL).
Proof.
  intros Hxs Hn. unfold SubNatRel.
  exact (sub_imported_eq_trans _ _ _
    (nd_nthD_canonical xsR nR)
    (sub_imported_eq_congr2 nd_target_nthD _ _ _ _ Hxs Hn)).
Qed.

(** The target namespace has its own imported spelling of Lean's truncated
    subtraction.  The computational proof is an artifact-local adapter over
    the already certified Rocq iterated-predecessor characterization. *)
Definition nd_target_sub (a b : Lean.Nat) : Lean.Nat :=
  ImportedNondecreasing.Nat_sub a b.

Lemma nd_target_sub_zero (a : Lean.Nat) :
  Lean.eq (nd_target_sub a Lean.Nat_zero) a.
Proof. exact (@Lean.eq_refl Lean.Nat a). Qed.

Lemma nd_target_sub_succ (a b : Lean.Nat) :
  Lean.eq (nd_target_sub a (Lean.Nat_succ b))
    (ImportedNondecreasing.Nat_pred (nd_target_sub a b)).
Proof.
  exact (@Lean.eq_refl Lean.Nat
    (ImportedNondecreasing.Nat_pred (nd_target_sub a b))).
Qed.

Definition nd_target_pred_canonical (n : nat) :
  Lean.eq (ImportedNondecreasing.Nat_pred (sub_nat_to_imported n))
    (sub_nat_to_imported (Nat.pred n)) :=
  match n return
    Lean.eq (ImportedNondecreasing.Nat_pred (sub_nat_to_imported n))
      (sub_nat_to_imported (Nat.pred n))
  with
  | O => @Lean.eq_refl Lean.Nat Lean.Nat_zero
  | S n' => @Lean.eq_refl Lean.Nat (sub_nat_to_imported n')
  end.

Lemma nd_target_sub_iterated_pred (a b : nat) :
  Lean.eq
    (nd_target_sub (sub_nat_to_imported a) (sub_nat_to_imported b))
    (sub_nat_to_imported (rocq_iterated_pred a b)).
Proof.
  induction b as [|b IH].
  - exact (nd_target_sub_zero (sub_nat_to_imported a)).
  - exact (sub_imported_eq_trans _ _ _
      (nd_target_sub_succ _ _)
      (sub_imported_eq_trans _ _ _
        (sub_imported_eq_congr ImportedNondecreasing.Nat_pred _ _ IH)
        (nd_target_pred_canonical (rocq_iterated_pred a b)))).
Qed.

Lemma nd_target_sub_correspondence aR aL bR bL :
  SubNatRel aR aL -> SubNatRel bR bL ->
  SubNatRel (aR - bR) (nd_target_sub aL bL).
Proof.
  intros Ha Hb. unfold SubNatRel.
  exact (sub_imported_eq_trans _ _ _
    (sub_imported_eq_sym _ _
      (sub_imported_eq_trans _ _ _
        (nd_target_sub_iterated_pred aR bR)
        (coq_eq_to_imported_eq _ _
          (f_equal sub_nat_to_imported
            (rocq_iterated_pred_is_subn aR bR)))))
    (sub_imported_eq_congr2 nd_target_sub _ _ _ _ Ha Hb)).
Qed.

Lemma nd_distances_canonical (xs : seq nat) :
  NdNatListRel (GeneratedNondecreasingSource.distances xs)
    (ImportedNondecreasing.Prosa_Util_Nondecreasing_distances
      (nd_nat_list_to_imported xs)).
Proof.
  induction xs as [|x xs IH].
  - exact (@Lean.eq_refl _ _).
  - destruct xs as [|y ys].
    + exact (@Lean.eq_refl _ _).
    + unfold NdNatListRel in IH |- *.
      unfold GeneratedNondecreasingSource.distances,
        ImportedNondecreasing.Prosa_Util_Nondecreasing_distances.
      cbn [nd_nat_list_to_imported].
      exact (nd_nat_list_cons_congr _ _ _ _
        (nd_target_sub_correspondence y (sub_nat_to_imported y)
          x (sub_nat_to_imported x)
          (sub_nat_rel_canonical y) (sub_nat_rel_canonical x)) IH).
Qed.

Theorem distances_definition_certificate xsR xsL :
  NdNatListRel xsR xsL ->
  NdNatListRel (GeneratedNondecreasingSource.distances xsR)
    (ImportedNondecreasing.Prosa_Util_Nondecreasing_distances xsL).
Proof.
  intro Hxs. unfold NdNatListRel.
  exact (sub_imported_eq_trans _ _ _ (nd_distances_canonical xsR)
    (sub_imported_eq_congr
      ImportedNondecreasing.Prosa_Util_Nondecreasing_distances _ _ Hxs)).
Qed.

(** The two order predicates are proved compositionally from the already
    certified Nat order, list length, and zero-defaulted lookup operations.
    Neither proof uses the source or imported business theorem constants. *)
Theorem nondecreasing_sequence_definition_certificate xsR xsL :
  NdNatListRel xsR xsL ->
  PropSPropRel
    (GeneratedNondecreasingSource.nondecreasing_sequence xsR)
    (ImportedNondecreasing.Prosa_Util_Nondecreasing_nondecreasing_sequence
      xsL).
Proof.
  intro Hxs. apply prop_sprop_rel_intro.
  - intros HR n1L n2L HboundsL.
    set n1R := sub_nat_to_rocq n1L.
    set n2R := sub_nat_to_rocq n2L.
    have Hn1 : SubNatRel n1R n1L := sub_nat_rel_surjective n1L.
    have Hn2 : SubNatRel n2R n2L := sub_nat_rel_surjective n2L.
    destruct HboundsL as [HleL HltL].
    apply (prop_to_sprop _ _
      (nd_le_correspondence _ _ _ _
        (nd_nthD_related xsR xsL n1R n1L Hxs Hn1)
        (nd_nthD_related xsR xsL n2R n2L Hxs Hn2))).
    apply HR. apply/andP; split.
    + exact (sprop_to_prop _ _
        (nd_le_correspondence _ _ _ _ Hn1 Hn2) HleL).
    + exact (sprop_to_prop _ _
        (nd_lt_correspondence _ _ _ _ Hn2
          (nd_length_related xsR xsL Hxs)) HltL).
  - intro HL. apply strictly_inhabits.
    intros n1R n2R HboundsR.
    move: HboundsR => /andP [HleR HltR].
    have Hn1 := sub_nat_rel_canonical n1R.
    have Hn2 := sub_nat_rel_canonical n2R.
    exact (sprop_to_prop _ _
      (nd_le_correspondence _ _ _ _
        (nd_nthD_related xsR xsL n1R (sub_nat_to_imported n1R) Hxs Hn1)
        (nd_nthD_related xsR xsL n2R (sub_nat_to_imported n2R) Hxs Hn2))
      (HL (sub_nat_to_imported n1R) (sub_nat_to_imported n2R)
        (Lean.And_intro _ _
          (prop_to_sprop _ _
            (nd_le_correspondence _ _ _ _ Hn1 Hn2) HleR)
          (prop_to_sprop _ _
            (nd_lt_correspondence _ _ _ _ Hn2
              (nd_length_related xsR xsL Hxs)) HltR)))).
Qed.

Theorem increasing_sequence_definition_certificate xsR xsL :
  NdNatListRel xsR xsL ->
  PropSPropRel
    (GeneratedNondecreasingSource.increasing_sequence xsR)
    (ImportedNondecreasing.Prosa_Util_Nondecreasing_increasing_sequence xsL).
Proof.
  intro Hxs. apply prop_sprop_rel_intro.
  - intros HR n1L n2L HboundsL.
    set n1R := sub_nat_to_rocq n1L.
    set n2R := sub_nat_to_rocq n2L.
    have Hn1 : SubNatRel n1R n1L := sub_nat_rel_surjective n1L.
    have Hn2 : SubNatRel n2R n2L := sub_nat_rel_surjective n2L.
    destruct HboundsL as [Hlt12L HltLenL].
    apply (prop_to_sprop _ _
      (nd_lt_correspondence _ _ _ _
        (nd_nthD_related xsR xsL n1R n1L Hxs Hn1)
        (nd_nthD_related xsR xsL n2R n2L Hxs Hn2))).
    apply HR. apply/andP; split.
    + exact (sprop_to_prop _ _
        (nd_lt_correspondence _ _ _ _ Hn1 Hn2) Hlt12L).
    + exact (sprop_to_prop _ _
        (nd_lt_correspondence _ _ _ _ Hn2
          (nd_length_related xsR xsL Hxs)) HltLenL).
  - intro HL. apply strictly_inhabits.
    intros n1R n2R HboundsR.
    move: HboundsR => /andP [Hlt12R HltLenR].
    have Hn1 := sub_nat_rel_canonical n1R.
    have Hn2 := sub_nat_rel_canonical n2R.
    exact (sprop_to_prop _ _
      (nd_lt_correspondence _ _ _ _
        (nd_nthD_related xsR xsL n1R (sub_nat_to_imported n1R) Hxs Hn1)
        (nd_nthD_related xsR xsL n2R (sub_nat_to_imported n2R) Hxs Hn2))
      (HL (sub_nat_to_imported n1R) (sub_nat_to_imported n2R)
        (Lean.And_intro _ _
          (prop_to_sprop _ _
            (nd_lt_correspondence _ _ _ _ Hn1 Hn2) Hlt12R)
          (prop_to_sprop _ _
            (nd_lt_correspondence _ _ _ _ Hn2
              (nd_length_related xsR xsL Hxs)) HltLenR)))).
Qed.

Print Assumptions nd_nat_list_source_roundtrip.
Print Assumptions nd_nat_list_target_roundtrip.
Print Assumptions nd_le_correspondence.
Print Assumptions nd_lt_correspondence.
Print Assumptions nd_length_related.
Print Assumptions nd_nthD_related.
Print Assumptions nd_target_sub_correspondence.
Print Assumptions distances_definition_certificate.
Print Assumptions nondecreasing_sequence_definition_certificate.
Print Assumptions increasing_sequence_definition_certificate.
