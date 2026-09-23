import Validation.fixtures.rocq90_batch2.ListComputationInterface

open Lean Elab Command Meta

set_option linter.defProp false

namespace Prosa.Validation.Rocq90Batch2

namespace Expected

universe u v

def max0 : List Nat → Nat := Prosa.Util.List.max0
def first0 : List Nat → Nat := Prosa.Util.List.first0
def last0 : List Nat → Nat := Prosa.Util.List.last0

def last0Cons (x : Nat) (xs : List Nat) :
    xs ≠ [] → Prosa.Util.List.last0 (x :: xs) = Prosa.Util.List.last0 xs :=
  Prosa.Util.List.last0_cons x xs

def last0Cat (xs_l xs_r : List Nat) :
    xs_r ≠ [] →
      Prosa.Util.List.last0 (xs_l ++ xs_r) = Prosa.Util.List.last0 xs_r :=
  Prosa.Util.List.last0_cat xs_l xs_r

def last0Nth (xs : List Nat) :
    Prosa.Util.List.last0 xs = xs.getD (xs.length - 1) 0 :=
  Prosa.Util.List.last0_nth xs

def last0ExCat (x : Nat) (xs : List Nat) :
    xs ≠ [] → Prosa.Util.List.last0 xs = x → ∃ xsh, xsh ++ [x] = xs :=
  Prosa.Util.List.last0_ex_cat x xs

def last0Filter (x : Nat) (xs : List Nat) (P : Nat → Bool) :
    xs ≠ [] → Prosa.Util.List.last0 xs = x → P x = true →
      Prosa.Util.List.last0 (xs.filter P) = x :=
  Prosa.Util.List.last0_filter x xs P

def max0Cons (x : Nat) (xs : List Nat) :
    Prosa.Util.List.max0 (x :: xs) = Nat.max x (Prosa.Util.List.max0 xs) :=
  Prosa.Util.List.max0_cons x xs

def max0OfUniformSet (k : Nat) (xs : List Nat) :
    xs.length > 0 → (∀ x, x ∈ xs → x = k) → Prosa.Util.List.max0 xs = k :=
  Prosa.Util.List.max0_of_uniform_set k xs

def inMax0Le (xs : List Nat) (x : Nat) :
    x ∈ xs → x ≤ Prosa.Util.List.max0 xs :=
  Prosa.Util.List.in_max0_le xs x

def max0InSeq (xs : List Nat) :
    xs ≠ [] → Prosa.Util.List.max0 xs ∈ xs :=
  Prosa.Util.List.max0_in_seq xs

def max02ConsEq (x : Nat) (xs : List Nat) :
    Prosa.Util.List.max0 (x :: x :: xs) = Prosa.Util.List.max0 (x :: xs) :=
  Prosa.Util.List.max0_2cons_eq x xs

def max02ConsLe (x1 x2 : Nat) (xs : List Nat) :
    x1 ≤ x2 →
      Prosa.Util.List.max0 (x1 :: x2 :: xs) =
        Prosa.Util.List.max0 (x2 :: xs) :=
  Prosa.Util.List.max0_2cons_le x1 x2 xs

def max0Rem0 (xs : List Nat) :
    Prosa.Util.List.max0 (xs.filter (fun x => decide (0 < x))) =
      Prosa.Util.List.max0 xs :=
  Prosa.Util.List.max0_rem0 xs

def lastOfSeqLeMaxOfSeq (xs : List Nat) :
    Prosa.Util.List.last0 xs ≤ Prosa.Util.List.max0 xs :=
  Prosa.Util.List.last_of_seq_le_max_of_seq xs

def maxOfDominatingSeq (xs ys : List Nat) :
    (∀ n, xs.getD n 0 ≤ ys.getD n 0) →
      Prosa.Util.List.max0 xs ≤ Prosa.Util.List.max0 ys :=
  Prosa.Util.List.max_of_dominating_seq xs ys

def remIn {T : Type u} [DecidableEq T] (x y : T) (xs : List T) :
    x ∈ xs.erase y → x ∈ xs :=
  Prosa.Util.List.rem_in x y xs

def inNeqImplRemIn {T : Type u} [DecidableEq T]
    (x y : T) (xs : List T) :
    x ∈ xs → x ≠ y → x ∈ xs.erase y :=
  Prosa.Util.List.in_neq_impl_rem_in x y xs

def filterSizeRem {T : Type u} [DecidableEq T]
    (x : T) (xs : List T) (P : T → Bool) :
    x ∈ xs → P x = true →
      (xs.filter P).length = ((xs.erase x).filter P).length + 1 :=
  Prosa.Util.List.filter_size_rem x xs P

def inSeqEquivUndup {T : Type u} [DecidableEq T]
    (xs : List T) (x : T) :
    decide (x ∈ xs.eraseDups) = decide (x ∈ xs) :=
  Prosa.Util.List.in_seq_equiv_undup xs x

def nth0Cons (x : Nat) (xs : List Nat) (n : Nat) :
    n > 0 → (x :: xs).getD n 0 = xs.getD (n - 1) 0 :=
  Prosa.Util.List.nth0_cons x xs n

def seq1Some {T : Type u} [DecidableEq T] (x y : T) :
    decide (([x] : List T) = [y]) =
      decide ((some x : Option T) = some y) :=
  Prosa.Util.List.seq1_some x y

def seqElimLast {T : Type u} (n : Nat) (xs : List T) :
    xs.length = n + 1 → ∃ x pre, xs = pre ++ [x] ∧ pre.length = n :=
  Prosa.Util.List.seq_elim_last n xs

def inCat {T : Type u} [DecidableEq T] (x : T) (xs : List T) :
    x ∈ xs → ∃ left right, xs = left ++ [x] ++ right :=
  Prosa.Util.List.in_cat x xs

def subseqLeqSize {T : Type u} [DecidableEq T] (xs ys : List T) :
    xs.Nodup → (∀ x, x ∈ xs → x ∈ ys) → xs.length ≤ ys.length :=
  Prosa.Util.List.subseq_leq_size xs ys

def inZip {T : Type u} {U : Type v} [DecidableEq T] [DecidableEq U]
    (xs : List T) (ys : List U) (x xDefault : T) (y yDefault : U) :
    xs.length = ys.length →
      (∃ idx, idx < xs.length ∧
        xs.getD idx xDefault = x ∧ ys.getD idx yDefault = y) →
      (x, y) ∈ xs.zip ys :=
  Prosa.Util.List.in_zip xs ys x xDefault y yDefault

def filterInPred0 {T : Type u} [DecidableEq T]
    (xs : List T) (P : T → Bool) :
    (∀ x, x ∈ xs → P x = false) → xs.filter P = [] :=
  Prosa.Util.List.filter_in_pred0 xs P

def eqIndInSeq {T : Type u} [DecidableEq T]
    (a b : T) (xs : List T) :
    xs.idxOf a = xs.idxOf b → a ∈ xs → b ∈ xs → a = b :=
  Prosa.Util.List.eq_ind_in_seq a b xs

def defaultOrIn {T : Type u} [DecidableEq T]
    (n : Nat) (d : T) (xs : List T) :
    xs.getD n d = d ∨ xs.getD n d ∈ xs :=
  Prosa.Util.List.default_or_in n d xs

def existsTwo {T : Type u} [DecidableEq T] (xs : List T) :
    1 < xs.length → xs.Nodup →
      ∃ a b, a ≠ b ∧ a ∈ xs ∧ b ∈ xs :=
  Prosa.Util.List.exists_two xs

def hasAllNilp {T : Type u} [DecidableEq T]
    (xs : List T) (P : T → Bool) :
    xs.all P = true → xs.isEmpty = false → xs.any P = true :=
  Prosa.Util.List.has_all_nilp xs P

def sortedSplit {T : Type u} [DecidableEq T]
    (xs : List T) (P : T → Bool) (f : T → Nat) (t : Nat) :
    Prosa.Util.List.boolSorted (fun x y => decide (f x ≤ f y)) xs →
      xs.filter P =
        xs.filter (fun x => P x && decide (f x ≤ t)) ++
          xs.filter (fun x => P x && decide (t < f x)) :=
  Prosa.Util.List.sorted_split xs P f t

def sortedCat {T : Type u} [DecidableEq T]
    (R : T → T → Bool) (xs1 xs2 : List T) :
    (∀ x y z, R x y = true → R y z = true → R x z = true) →
      Prosa.Util.List.boolSorted R (xs1 ++ xs2) →
        Prosa.Util.List.boolSorted R xs1 ∧ Prosa.Util.List.boolSorted R xs2 :=
  Prosa.Util.List.sorted_cat R xs1 xs2

def nonnilLast {T : Type u} [DecidableEq T]
    (xs : List T) (d1 d2 : T) :
    xs ≠ [] → xs.getLastD d1 = xs.getLastD d2 :=
  Prosa.Util.List.nonnil_last xs d1 d2

def filterLastMem {T : Type u} [DecidableEq T]
    (xs : List T) (d : T) (P : T → Bool) :
    xs.any P = true → (xs.filter P).getLastD d ∈ xs :=
  Prosa.Util.List.filter_last_mem xs d P

def remAll {T : Type u} [DecidableEq T] (x : T) : List T → List T :=
  Prosa.Util.List.rem_all x

def ninRemAll {T : Type u} [DecidableEq T] (x : T) (xs : List T) :
    x ∉ Prosa.Util.List.rem_all x xs :=
  Prosa.Util.List.nin_rem_all x xs

def inRemAll {T : Type u} [DecidableEq T]
    (a x : T) (xs : List T) :
    a ∈ Prosa.Util.List.rem_all x xs → a ∈ xs :=
  Prosa.Util.List.in_rem_all a x xs

def remLtId (x : Nat) (xs : List Nat) :
    (∀ y, y ∈ xs → x < y) → Prosa.Util.List.rem_all x xs = xs :=
  Prosa.Util.List.rem_lt_id x xs

def range : Nat → Nat → List Nat := Prosa.Util.List.range

def iotaDImpl (n_le m n : Nat) :
    n_le ≤ n →
      List.range' m n =
        List.range' m n_le ++ List.range' (m + n_le) (n - n_le) :=
  Prosa.Util.List.iotaD_impl n_le m n

def indexIotaLtStep (a b : Nat) :
    a < b → Prosa.Util.List.index_iota a b =
      a :: Prosa.Util.List.index_iota (a + 1) b :=
  Prosa.Util.List.index_iota_lt_step a b

def indexIotaCat (t t1 t2 : Nat) :
    t1 ≤ t ∧ t ≤ t2 →
      Prosa.Util.List.index_iota t1 t2 =
        Prosa.Util.List.index_iota t1 t ++ Prosa.Util.List.index_iota t t2 :=
  Prosa.Util.List.index_iota_cat t t1 t2

def rangeFilter2Cons (x : Nat) (xs : List Nat) (k : Nat) :
    (Prosa.Util.List.range 0 k).filter
        (fun rho => decide (rho ∈ x :: x :: xs)) =
      (Prosa.Util.List.range 0 k).filter
        (fun rho => decide (rho ∈ x :: xs)) :=
  Prosa.Util.List.range_filter_2cons x xs k

def indexIotaFilterEqx (x a b : Nat) :
    a ≤ x ∧ x < b →
      (Prosa.Util.List.index_iota a b).filter
        (fun rho => decide (rho = x)) = [x] :=
  Prosa.Util.List.index_iota_filter_eqx x a b

def indexIotaFilterSingl (x a b : Nat) :
    a ≤ x ∧ x < b →
      (Prosa.Util.List.index_iota a b).filter
        (fun rho => decide (rho ∈ [x])) = [x] :=
  Prosa.Util.List.index_iota_filter_singl x a b

def indexIotaFilterInxs (a b x : Nat) (xs : List Nat) :
    x < a →
      (Prosa.Util.List.index_iota a b).filter
          (fun rho => decide (rho ∈ xs)) =
        (Prosa.Util.List.index_iota a b).filter
          (fun rho => decide (rho ∈ Prosa.Util.List.rem_all x xs)) :=
  Prosa.Util.List.index_iota_filter_inxs a b x xs

def indexIotaFilterStep (x : Nat) (xs : List Nat) (a b : Nat) :
    a ≤ x ∧ x < b → (∀ y, y ∈ xs → x ≤ y) →
      (Prosa.Util.List.index_iota a b).filter
          (fun rho => decide (rho ∈ x :: xs)) =
        x :: (Prosa.Util.List.index_iota a b).filter
          (fun rho => decide (rho ∈ Prosa.Util.List.rem_all x xs)) :=
  Prosa.Util.List.index_iota_filter_step x xs a b

def rangeIotaFilterStep (x : Nat) (xs : List Nat) (k : Nat) :
    x ≤ k → (∀ y, y ∈ xs → x ≤ y) →
      (Prosa.Util.List.range 0 k).filter
          (fun rho => decide (rho ∈ x :: xs)) =
        x :: (Prosa.Util.List.range 0 k).filter
          (fun rho => decide (rho ∈ Prosa.Util.List.rem_all x xs)) :=
  Prosa.Util.List.range_iota_filter_step x xs k

def iotaFilterGt (x a b idx : Nat) (P : Nat → Bool) :
    x < a → idx < ((Prosa.Util.List.index_iota a b).filter P).length →
      x < ((Prosa.Util.List.index_iota a b).filter P).getD idx 0 :=
  Prosa.Util.List.iota_filter_gt x a b idx P

def subCountSeq {T : Type u} [DecidableEq T]
    (f g : T → Bool) (xs : List T) :
    (∀ x, x ∈ xs → f x = true → g x = true) →
      xs.countP f ≤ xs.countP g :=
  Prosa.Util.List.sub_count_seq f g xs

def countPredUI (P1 P2 : Nat → Bool) (xs : List Nat) :
    xs.countP (fun x => P1 x || P2 x) =
      xs.countP P1 + xs.countP P2 - xs.countP (fun x => P1 x && P2 x) :=
  Prosa.Util.List.count_predUI' P1 P2 xs

def prefixOf {T : Type u} [DecidableEq T] : List T → List T → Prop :=
  Prosa.Util.List.prefix_of

def strictPrefixOf {T : Type u} [DecidableEq T] : List T → List T → Prop :=
  Prosa.Util.List.strict_prefix_of

def shiftPointsPos : List Nat → Nat → List Nat :=
  Prosa.Util.List.shift_points_pos

def shiftPointsNeg : List Nat → Nat → List Nat :=
  Prosa.Util.List.shift_points_neg

end Expected

private def guardPairs : Array (Name × Name) := #[
  (``Prosa.Util.List.max0, ``Expected.max0),
  (``Prosa.Util.List.first0, ``Expected.first0),
  (``Prosa.Util.List.last0, ``Expected.last0),
  (``Prosa.Util.List.last0_cons, ``Expected.last0Cons),
  (``Prosa.Util.List.last0_cat, ``Expected.last0Cat),
  (``Prosa.Util.List.last0_nth, ``Expected.last0Nth),
  (``Prosa.Util.List.last0_ex_cat, ``Expected.last0ExCat),
  (``Prosa.Util.List.last0_filter, ``Expected.last0Filter),
  (``Prosa.Util.List.max0_cons, ``Expected.max0Cons),
  (``Prosa.Util.List.max0_of_uniform_set, ``Expected.max0OfUniformSet),
  (``Prosa.Util.List.in_max0_le, ``Expected.inMax0Le),
  (``Prosa.Util.List.max0_in_seq, ``Expected.max0InSeq),
  (``Prosa.Util.List.max0_2cons_eq, ``Expected.max02ConsEq),
  (``Prosa.Util.List.max0_2cons_le, ``Expected.max02ConsLe),
  (``Prosa.Util.List.max0_rem0, ``Expected.max0Rem0),
  (``Prosa.Util.List.last_of_seq_le_max_of_seq, ``Expected.lastOfSeqLeMaxOfSeq),
  (``Prosa.Util.List.max_of_dominating_seq, ``Expected.maxOfDominatingSeq),
  (``Prosa.Util.List.rem_in, ``Expected.remIn),
  (``Prosa.Util.List.in_neq_impl_rem_in, ``Expected.inNeqImplRemIn),
  (``Prosa.Util.List.filter_size_rem, ``Expected.filterSizeRem),
  (``Prosa.Util.List.in_seq_equiv_undup, ``Expected.inSeqEquivUndup),
  (``Prosa.Util.List.nth0_cons, ``Expected.nth0Cons),
  (``Prosa.Util.List.seq1_some, ``Expected.seq1Some),
  (``Prosa.Util.List.seq_elim_last, ``Expected.seqElimLast),
  (``Prosa.Util.List.in_cat, ``Expected.inCat),
  (``Prosa.Util.List.subseq_leq_size, ``Expected.subseqLeqSize),
  (``Prosa.Util.List.in_zip, ``Expected.inZip),
  (``Prosa.Util.List.filter_in_pred0, ``Expected.filterInPred0),
  (``Prosa.Util.List.eq_ind_in_seq, ``Expected.eqIndInSeq),
  (``Prosa.Util.List.default_or_in, ``Expected.defaultOrIn),
  (``Prosa.Util.List.exists_two, ``Expected.existsTwo),
  (``Prosa.Util.List.has_all_nilp, ``Expected.hasAllNilp),
  (``Prosa.Util.List.sorted_split, ``Expected.sortedSplit),
  (``Prosa.Util.List.sorted_cat, ``Expected.sortedCat),
  (``Prosa.Util.List.nonnil_last, ``Expected.nonnilLast),
  (``Prosa.Util.List.filter_last_mem, ``Expected.filterLastMem),
  (``Prosa.Util.List.rem_all, ``Expected.remAll),
  (``Prosa.Util.List.nin_rem_all, ``Expected.ninRemAll),
  (``Prosa.Util.List.in_rem_all, ``Expected.inRemAll),
  (``Prosa.Util.List.rem_lt_id, ``Expected.remLtId),
  (``Prosa.Util.List.range, ``Expected.range),
  (``Prosa.Util.List.iotaD_impl, ``Expected.iotaDImpl),
  (``Prosa.Util.List.index_iota_lt_step, ``Expected.indexIotaLtStep),
  (``Prosa.Util.List.index_iota_cat, ``Expected.indexIotaCat),
  (``Prosa.Util.List.range_filter_2cons, ``Expected.rangeFilter2Cons),
  (``Prosa.Util.List.index_iota_filter_eqx, ``Expected.indexIotaFilterEqx),
  (``Prosa.Util.List.index_iota_filter_singl, ``Expected.indexIotaFilterSingl),
  (``Prosa.Util.List.index_iota_filter_inxs, ``Expected.indexIotaFilterInxs),
  (``Prosa.Util.List.index_iota_filter_step, ``Expected.indexIotaFilterStep),
  (``Prosa.Util.List.range_iota_filter_step, ``Expected.rangeIotaFilterStep),
  (``Prosa.Util.List.iota_filter_gt, ``Expected.iotaFilterGt),
  (``Prosa.Util.List.sub_count_seq, ``Expected.subCountSeq),
  (``Prosa.Util.List.count_predUI', ``Expected.countPredUI),
  (``Prosa.Util.List.prefix_of, ``Expected.prefixOf),
  (``Prosa.Util.List.strict_prefix_of, ``Expected.strictPrefixOf),
  (``Prosa.Util.List.shift_points_pos, ``Expected.shiftPointsPos),
  (``Prosa.Util.List.shift_points_neg, ``Expected.shiftPointsNeg)
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
  unless guardPairs.size == 57 do throwError "expected 57 List declarations"
  for (target, guard) in guardPairs do requireActualType target guard
  logInfo "BATCH2_LIST_ACTUAL_ARTIFACT_GUARDS_OK count=57"

end Prosa.Validation.Rocq90Batch2
