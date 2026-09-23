import Prosa.Util.List

namespace Prosa.Validation.Phase7ListLastInterface

universe u

/-- Structurally recursive presentation of defaulted list lookup. -/
def getD {T : Type u} : List T → Nat → T → T
  | [], _, fallback => fallback
  | x :: _, 0, _ => x
  | _ :: xs, n + 1, fallback => getD xs n fallback

theorem getD_nil {T : Type u} (n : Nat) (fallback : T) :
    getD ([] : List T) n fallback = fallback := by
  rfl

theorem getD_zero {T : Type u} (x : T) (xs : List T) (fallback : T) :
    getD (x :: xs) 0 fallback = x := by
  rfl

theorem getD_succ {T : Type u} (x : T) (xs : List T)
    (n : Nat) (fallback : T) :
    getD (x :: xs) (n + 1) fallback = getD xs n fallback := by
  rfl

theorem getD_nat_nil (n : Nat) : getD ([] : List Nat) n 0 = 0 := by
  rfl

theorem getD_nat_zero (x : Nat) (xs : List Nat) :
    getD (x :: xs) 0 0 = x := by
  rfl

theorem getD_nat_succ (x : Nat) (xs : List Nat) (n : Nat) :
    getD (x :: xs) (n + 1) 0 = getD xs n 0 := by
  rfl

/-- Lean-kernel semantic bridge to the operation in the actual compiled
    theorem types.  This theorem is checked in the fresh Lean build but is not
    exported, because traversing the implementation of `List.getD` would
    reintroduce its irrelevant `List.get?Internal`/`brecOn` graph. -/
theorem getD_matches_compiled (xs : List Nat) (n : Nat) (fallback : Nat) :
    getD xs n fallback = xs.getD n fallback := by
  induction xs generalizing n with
  | nil => rfl
  | cons x xs ih =>
    cases n with
    | zero => rfl
    | succ n => exact ih n

theorem last0_nth_safe (xs : List Nat) :
    Prosa.Util.List.last0 xs = getD xs (xs.length - 1) 0 := by
  exact (Prosa.Util.List.last0_nth xs).trans
    (getD_matches_compiled xs (xs.length - 1) 0).symm

#print axioms getD_matches_compiled
#print axioms last0_nth_safe

end Prosa.Validation.Phase7ListLastInterface
