import Validation.fixtures.utility_foundation.ListLastComputationInterface

/-!
Rocq-9.0 validation interface for the complete `util/list.v` migration.

`List.getD` is implemented through `List.get?Internal`/`List.brecOn`, whose
implementation closure contains `Acc`.  The structurally recursive operation
below is used only in the exported semantic boundary.  The generic theorem
`getD_matches_compiled` binds it extensionally to the exact `List.getD` in the
fresh production artifact.  That bridge is kernel checked during prepare and
deliberately not exported, so the irrelevant `Acc` graph is not imported.
-/

namespace Prosa.Validation.Rocq90Batch2ListInterface

universe u

def getD {T : Type u} : List T → Nat → T → T
  | [], _, fallback => fallback
  | x :: _, 0, _ => x
  | _ :: xs, n + 1, fallback => getD xs n fallback

/-- Monomorphic operation interface used by List certificates.  Its body is
the ordinary compiled Lean `Nat` order operation, not a replacement theorem. -/
def natLt (a b : Nat) : Prop := a < b

/-- Monomorphic interface for the compiled `List Nat` membership relation. -/
def natMem (x : Nat) (xs : List Nat) : Prop := x ∈ xs

/-- Stable exported name for Lean's ordinary decidable List membership. -/
def decidableMem {T : Type u} [DecidableEq T]
    (x : T) (xs : List T) : Decidable (x ∈ xs) := inferInstance

/-- Nat-specialized view of the actual production `rem_all` definition. -/
def natRemAll (x : Nat) (xs : List Nat) : List Nat :=
  Prosa.Util.List.rem_all x xs

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

theorem getD_matches_compiled {T : Type u}
    (xs : List T) (n : Nat) (fallback : T) :
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

end Prosa.Validation.Rocq90Batch2ListInterface
