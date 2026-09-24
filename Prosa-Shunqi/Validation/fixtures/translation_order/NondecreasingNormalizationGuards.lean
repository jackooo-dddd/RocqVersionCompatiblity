import Validation.fixtures.translation_order.NondecreasingComputationInterface

namespace Prosa.Validation.NondecreasingNormalization

open Prosa.Util.Nondecreasing
open Prosa.Validation.NondecreasingInterface

/-!
Kernel guards for the Rocq-9.0 Acc-free semantic boundary.  The exported
lookup is structurally recursive, while these non-exported proofs bind it to
the exact `List.getD` used by the fresh production artifact.
-/

theorem nthD_guard (xs : List Nat) (n : Nat) :
    nthD xs n = xs.getD n 0 :=
  nthD_matches_compiled xs n

theorem nondecreasing_sequence_guard (xs : List Nat) :
    nondecreasing_sequence xs ↔ nondecreasingSequence xs :=
  production_nondecreasing_sequence_eq xs

theorem increasing_sequence_guard (xs : List Nat) :
    increasing_sequence xs ↔ increasingSequence xs :=
  production_increasing_sequence_eq xs

theorem distances_guard (xs : List Nat) :
    distances xs =
      List.map (fun (p : Nat × Nat) => Nat.sub p.2 p.1)
        (List.zipWith Prod.mk xs (List.drop 1 xs)) := rfl

#print axioms nthD_guard
#print axioms nondecreasing_sequence_guard
#print axioms increasing_sequence_guard
#print axioms distances_guard

end Prosa.Validation.NondecreasingNormalization
