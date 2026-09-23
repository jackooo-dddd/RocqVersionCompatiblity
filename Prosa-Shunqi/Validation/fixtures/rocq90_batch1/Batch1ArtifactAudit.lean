import Prosa.Behavior.Time
import Prosa.Util.Notation
import Prosa.Util.Tactics
import Prosa.Util.Rel
import Prosa.Util.Seqset
import Prosa.Util.Subadditivity
import Prosa.Util.Supremum
import Prosa.Util.Nat
import Prosa.Util.UnitGrowth
import Prosa.Util.SearchArg

open Lean Elab Command Meta

set_option linter.defProp false

namespace Prosa.Validation.Rocq90Batch1

namespace Expected

universe u v

def duration : Type := Prosa.Behavior.Time.duration
def instant : Type := Prosa.Behavior.Time.instant

def neqP {T : Type u} [DecidableEq T] (x y : T) :
    decide (x ≠ y) = true ↔ x ≠ y :=
  Prosa.Util.Tactics.neqP x y

def modusponens (P Q : Prop) : P → (P → Q) → Q :=
  Prosa.Util.Tactics.modusponens P Q

def constant {X : Type u} {Y : Type v} (c : Y) : X → Y :=
  Prosa.Util.Notation.constant c

def monotone {T : Type u} (R : T → T → Bool) (f : T → T) : Prop :=
  Prosa.Util.Rel.monotone R f

def totalOverList {T : Type u} [DecidableEq T]
    (R : T → T → Bool) (xs : List T) : Prop :=
  Prosa.Util.Rel.total_over_list R xs

def antisymmetricOverList {T : Type u} [DecidableEq T]
    (R : T → T → Bool) (xs : List T) : Prop :=
  Prosa.Util.Rel.antisymmetric_over_list R xs

def seqsetSet (T : Type u) [DecidableEq T] : Type u :=
  Prosa.Util.Seqset.set T

def seqsetSetOf (T : Type u) [DecidableEq T] : Type u :=
  Prosa.Util.Seqset.set_of T

def seqsetSetUniq {T : Type u} [DecidableEq T]
    (s : Prosa.Util.Seqset.set T) : s.val.Nodup :=
  Prosa.Util.Seqset.set_uniq s

def subadditiveAt (f : Nat → Nat) (h : Nat) : Prop :=
  ∀ a b, a + b = h → f h ≤ f a + f b

def subadditiveUntil (f : Nat → Nat) (h : Nat) : Prop :=
  ∀ x, x < h → Prosa.Util.Subadditivity.subadditive_at f x

def subadditive (f : Nat → Nat) : Prop :=
  ∀ h, Prosa.Util.Subadditivity.subadditive_at f h

def subadditiveStandard (f : Nat → Nat) : Prop :=
  ∀ a b, f (a + b) ≤ f a + f b

def subadditiveStandardEquivalence (f : Nat → Nat) :
    Prosa.Util.Subadditivity.subadditive f ↔
      Prosa.Util.Subadditivity.subadditive_standard f :=
  Prosa.Util.Subadditivity.subadditive_standard_equivalence f

def subadditiveLeqMul (f : Nat → Nat)
    (h : Prosa.Util.Subadditivity.subadditive f) :
    ∀ n m, 0 < m → f (m * n) ≤ m * f n :=
  Prosa.Util.Subadditivity.subadditive_leq_mul f h

def chooseSuperior {T : Type u}
    (R : T → T → Bool) (x : T) (maybeY : Option T) : Option T :=
  Prosa.Util.Supremum.choose_superior R x maybeY

def supremum {T : Type u}
    (R : T → T → Bool) (s : List T) : Option T :=
  Prosa.Util.Supremum.supremum R s

def supremumUnfold {T : Type u} [DecidableEq T]
    (R : T → T → Bool) (head : T) (tail : List T) :
    Prosa.Util.Supremum.supremum R (head :: tail) =
      Prosa.Util.Supremum.choose_superior R head
        (Prosa.Util.Supremum.supremum R tail) :=
  Prosa.Util.Supremum.supremum_unfold R head tail

def supremumExists {T : Type u} [DecidableEq T]
    (R : T → T → Bool) :
    ∀ x s, x ∈ s → Prosa.Util.Supremum.supremum R s ≠ none :=
  Prosa.Util.Supremum.supremum_exists R

def supremumNone {T : Type u} [DecidableEq T]
    (R : T → T → Bool) :
    ∀ s, Prosa.Util.Supremum.supremum R s = none → s = [] :=
  Prosa.Util.Supremum.supremum_none R

def supremumIn {T : Type u} [DecidableEq T]
    (R : T → T → Bool) :
    ∀ x s, Prosa.Util.Supremum.supremum R s = some x → x ∈ s :=
  Prosa.Util.Supremum.supremum_in R

def supremumSpec {T : Type u} [DecidableEq T]
    (R : T → T → Bool)
    (hRefl : ∀ x, R x x = true)
    (hTotal : ∀ x y, (R x y || R y x) = true)
    (hTrans : ∀ x y z, R x y = true → R y z = true → R x z = true) :
    ∀ x s, Prosa.Util.Supremum.supremum R s = some x →
      ∀ y, y ∈ s → R x y = true :=
  Prosa.Util.Supremum.supremum_spec R hRefl hTotal hTrans

def subnACA {m n p q : Nat} :
    p ≤ m → q ≤ n → (m + n) - (p + q) = (m - p) + (n - q) :=
  Prosa.Util.Nat.subnACA

def leqSubRLImpl {m n p : Nat} : m + n ≤ p → n ≤ p - m :=
  Prosa.Util.Nat.leq_subRL_impl

def unitGrowthFunction (f : Nat → Nat) : Prop :=
  ∀ t, f (t + 1) ≤ f t + 1

def unitGrowthKSteps (f : Nat → Nat)
    (h : Prosa.Util.UnitGrowth.unit_growth_function f) :
    ∀ x k, f (x + k) ≤ k + f x :=
  Prosa.Util.UnitGrowth.unit_growth_function_k_steps_bounded f h

def existsIntermediatePoint (f : Nat → Nat)
    (hunit : Prosa.Util.UnitGrowth.unit_growth_function f)
    (x1 x2 : Nat) (hinterval : x1 ≤ x2)
    (y : Nat) (hbetween : f x1 ≤ y ∧ y < f x2) :
    ∃ xmid, (x1 ≤ xmid ∧ xmid < x2) ∧ f xmid = y :=
  Prosa.Util.UnitGrowth.exists_intermediate_point
    f hunit x1 x2 hinterval y hbetween

def existsIntermediatePointLeq (f : Nat → Nat)
    (hunit : Prosa.Util.UnitGrowth.unit_growth_function f)
    (x1 x2 : Nat) (hinterval : x1 ≤ x2)
    (y : Nat) (hbetween : f x1 ≤ y ∧ y ≤ f x2) :
    ∃ xmid, (x1 ≤ xmid ∧ xmid ≤ x2) ∧ f xmid = y :=
  Prosa.Util.UnitGrowth.exists_intermediate_point_leq
    f hunit x1 x2 hinterval y hbetween

def existsFirstIntermediatePoint (P : Nat → Bool) (t1 t2 : Nat)
    (ht12 : t1 ≤ t2) (hnot : P t1 = false) (hat : P t2 = true) :
    ∃ t, (t1 < t ∧ t ≤ t2) ∧
      (∀ x, t1 ≤ x ∧ x < t → P x = false) ∧ P t = true :=
  Prosa.Util.UnitGrowth.exists_first_intermediate_point P t1 t2 ht12 hnot hat

def slowed (F : Nat → Nat) : Nat → Nat :=
  Prosa.Util.UnitGrowth.slowed F

def slowedRespectsPointwiseLeq (f F : Nat → Nat) (delta : Nat)
    (hunit : Prosa.Util.UnitGrowth.unit_growth_function f)
    (hle : ∀ x, x ≤ delta → f x ≤ F x) :
    f delta ≤ Prosa.Util.UnitGrowth.slowed F delta :=
  Prosa.Util.UnitGrowth.slowed_respects_pointwise_leq f F delta hunit hle

def slowedIsUnitStep (f : Nat → Nat) :
    Prosa.Util.UnitGrowth.unit_growth_function
      (Prosa.Util.UnitGrowth.slowed f) :=
  Prosa.Util.UnitGrowth.slowed_is_unit_step f

def slowedRespectsMonotone (f : Nat → Nat)
    (hmono : Prosa.Util.Rel.monotone
      (fun x y : Nat => decide (x ≤ y)) f) :
    Prosa.Util.Rel.monotone
      (fun x y : Nat => decide (x ≤ y))
      (Prosa.Util.UnitGrowth.slowed f) :=
  Prosa.Util.UnitGrowth.slowed_respects_monotone f hmono

def slowedNeverExceeds (f : Nat → Nat) (x : Nat) :
    Prosa.Util.UnitGrowth.slowed f x ≤ f x :=
  Prosa.Util.UnitGrowth.slowed_never_exceeds f x

def boundPreservedUnderSlowed (f : Nat → Nat) (delta A F : Nat)
    (hle : A ≤ F - f delta) :
    A ≤ F - Prosa.Util.UnitGrowth.slowed f delta :=
  Prosa.Util.UnitGrowth.bound_preserved_under_slowed f delta A F hle

def slowedSubtractionValuePreservation (f : Nat → Nat) (delta : Nat)
    (hmono : Prosa.Util.Rel.monotone
      (fun x y : Nat => decide (x ≤ y)) f) :
    ∃ d, d ≤ delta ∧ delta - f delta =
      d - Prosa.Util.UnitGrowth.slowed f d :=
  Prosa.Util.UnitGrowth.slowed_subtraction_value_preservation f delta hmono

def earliestPredElementExistsCase (P : Nat → Bool) (t1 t2 : Nat) :
    (∀ t, t1 ≤ t ∧ t < t2 → P t = false) ∨
      ∃ t, (t1 ≤ t ∧ t < t2) ∧ P t = true ∧
        ∀ t', t1 ≤ t' → P t' = true → t ≤ t' :=
  Prosa.Util.SearchArg.earliest_pred_element_exists_case P t1 t2

def searchArg {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool) (a b : Nat) : Option Nat :=
  Prosa.Util.SearchArg.search_arg f P R a b

def searchArgNone {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool) (a b : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a b = none ↔
      ∀ x, a ≤ x ∧ x < b → P (f x) = false :=
  Prosa.Util.SearchArg.search_arg_none f P R a b

def searchArgNotNone {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool) (a b : Nat) :
    (∃ x, (a ≤ x ∧ x < b) ∧ P (f x) = true) →
      ∃ y, Prosa.Util.SearchArg.search_arg f P R a b = some y :=
  Prosa.Util.SearchArg.search_arg_not_none f P R a b

def searchArgPred {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool) (a b x : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a b = some x →
      P (f x) = true :=
  Prosa.Util.SearchArg.search_arg_pred f P R a b x

def searchArgInRange {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool) (a b x : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a b = some x →
      a ≤ x ∧ x < b :=
  Prosa.Util.SearchArg.search_arg_in_range f P R a b x

def searchArgExtremum {T : Type u} (f : Nat → T) (P : T → Bool)
    (R : T → T → Bool)
    (hRefl : ∀ x, R x x = true)
    (hTrans : ∀ x y z, R x y = true → R y z = true → R x z = true)
    (hTotal : ∀ x y, R x y = true ∨ R y x = true)
    (a b x : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a b = some x →
      ∀ y, a ≤ y ∧ y < b → P (f y) = true → R (f x) (f y) = true :=
  Prosa.Util.SearchArg.search_arg_extremum
    f P R hRefl hTrans hTotal a b x

def propOnExMinn (P : Nat → Prop) (pred : Nat → Bool)
    (ex : ∃ n, pred n = true) :
    (∀ n, pred n = true →
        (∀ n', pred n' = true → n ≤ n') → P n) →
      ∃ n, P n ∧ pred n = true ∧
        ∀ n', pred n' = true → n ≤ n' :=
  Prosa.Util.SearchArg.prop_on_ex_minn P pred ex

end Expected

private def guardPairs : Array (Name × Name) := #[
  (``Prosa.Behavior.Time.duration, ``Expected.duration),
  (``Prosa.Behavior.Time.instant, ``Expected.instant),
  (``Prosa.Util.Tactics.neqP, ``Expected.neqP),
  (``Prosa.Util.Tactics.modusponens, ``Expected.modusponens),
  (``Prosa.Util.Notation.constant, ``Expected.constant),
  (``Prosa.Util.Rel.monotone, ``Expected.monotone),
  (``Prosa.Util.Rel.total_over_list, ``Expected.totalOverList),
  (``Prosa.Util.Rel.antisymmetric_over_list, ``Expected.antisymmetricOverList),
  (``Prosa.Util.Seqset.set, ``Expected.seqsetSet),
  (``Prosa.Util.Seqset.set_of, ``Expected.seqsetSetOf),
  (``Prosa.Util.Seqset.set_uniq, ``Expected.seqsetSetUniq),
  (``Prosa.Util.Subadditivity.subadditive_at, ``Expected.subadditiveAt),
  (``Prosa.Util.Subadditivity.subadditive_until, ``Expected.subadditiveUntil),
  (``Prosa.Util.Subadditivity.subadditive, ``Expected.subadditive),
  (``Prosa.Util.Subadditivity.subadditive_standard, ``Expected.subadditiveStandard),
  (``Prosa.Util.Subadditivity.subadditive_standard_equivalence, ``Expected.subadditiveStandardEquivalence),
  (``Prosa.Util.Subadditivity.subadditive_leq_mul, ``Expected.subadditiveLeqMul),
  (``Prosa.Util.Supremum.choose_superior, ``Expected.chooseSuperior),
  (``Prosa.Util.Supremum.supremum, ``Expected.supremum),
  (``Prosa.Util.Supremum.supremum_unfold, ``Expected.supremumUnfold),
  (``Prosa.Util.Supremum.supremum_exists, ``Expected.supremumExists),
  (``Prosa.Util.Supremum.supremum_none, ``Expected.supremumNone),
  (``Prosa.Util.Supremum.supremum_in, ``Expected.supremumIn),
  (``Prosa.Util.Supremum.supremum_spec, ``Expected.supremumSpec),
  (``Prosa.Util.Nat.subnACA, ``Expected.subnACA),
  (``Prosa.Util.Nat.leq_subRL_impl, ``Expected.leqSubRLImpl),
  (``Prosa.Util.UnitGrowth.unit_growth_function, ``Expected.unitGrowthFunction),
  (``Prosa.Util.UnitGrowth.unit_growth_function_k_steps_bounded, ``Expected.unitGrowthKSteps),
  (``Prosa.Util.UnitGrowth.exists_intermediate_point, ``Expected.existsIntermediatePoint),
  (``Prosa.Util.UnitGrowth.exists_intermediate_point_leq, ``Expected.existsIntermediatePointLeq),
  (``Prosa.Util.UnitGrowth.exists_first_intermediate_point, ``Expected.existsFirstIntermediatePoint),
  (``Prosa.Util.UnitGrowth.slowed, ``Expected.slowed),
  (``Prosa.Util.UnitGrowth.slowed_respects_pointwise_leq, ``Expected.slowedRespectsPointwiseLeq),
  (``Prosa.Util.UnitGrowth.slowed_is_unit_step, ``Expected.slowedIsUnitStep),
  (``Prosa.Util.UnitGrowth.slowed_respects_monotone, ``Expected.slowedRespectsMonotone),
  (``Prosa.Util.UnitGrowth.slowed_never_exceeds, ``Expected.slowedNeverExceeds),
  (``Prosa.Util.UnitGrowth.bound_preserved_under_slowed, ``Expected.boundPreservedUnderSlowed),
  (``Prosa.Util.UnitGrowth.slowed_subtraction_value_preservation, ``Expected.slowedSubtractionValuePreservation),
  (``Prosa.Util.SearchArg.earliest_pred_element_exists_case, ``Expected.earliestPredElementExistsCase),
  (``Prosa.Util.SearchArg.search_arg, ``Expected.searchArg),
  (``Prosa.Util.SearchArg.search_arg_none, ``Expected.searchArgNone),
  (``Prosa.Util.SearchArg.search_arg_not_none, ``Expected.searchArgNotNone),
  (``Prosa.Util.SearchArg.search_arg_pred, ``Expected.searchArgPred),
  (``Prosa.Util.SearchArg.search_arg_in_range, ``Expected.searchArgInRange),
  (``Prosa.Util.SearchArg.search_arg_extremum, ``Expected.searchArgExtremum),
  (``Prosa.Util.SearchArg.prop_on_ex_minn, ``Expected.propOnExMinn)
]

private def requireActualType (target guard : Name) : MetaM Unit := do
  let targetInfo ← getConstInfo target
  let guardInfo ← getConstInfo guard
  unless targetInfo.levelParams.length == guardInfo.levelParams.length do
    throwError "UNIVERSE_ARITY_MISMATCH target={target}"
  let levels ← targetInfo.levelParams.mapM fun _ => mkFreshLevelMVar
  let targetType := targetInfo.type.instantiateLevelParams targetInfo.levelParams levels
  let guardType := guardInfo.type.instantiateLevelParams guardInfo.levelParams levels
  unless ← Meta.isDefEq targetType guardType do
    throwError "TYPE_DEF_EQ_FAILED target={target}"
  logInfo m!"TYPE_DEF_EQ_OK target={target} type_hash={hash targetInfo.type}"

run_cmd liftTermElabM do
  unless guardPairs.size == 46 do throwError "expected 46 Batch 1 declarations"
  for (target, guard) in guardPairs do requireActualType target guard
  logInfo "BATCH1_ACTUAL_ARTIFACT_GUARDS_OK count=46"

end Prosa.Validation.Rocq90Batch1
