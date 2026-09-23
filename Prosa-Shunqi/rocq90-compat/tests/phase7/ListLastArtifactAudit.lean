import Phase7.ListLastSafeInterface

open Lean Elab Command Meta

namespace Prosa.Validation.Phase7ListLastAudit

def last0NthExactTypeGuard :
    (xs : List Nat) →
      Prosa.Util.List.last0 xs = xs.getD (xs.length - 1) 0 :=
  Prosa.Util.List.last0_nth

def maxOfDominatingSeqExactTypeGuard :
    (xs ys : List Nat) →
      (∀ n, xs.getD n 0 ≤ ys.getD n 0) →
      Prosa.Util.List.max0 xs ≤ Prosa.Util.List.max0 ys :=
  Prosa.Util.List.max_of_dominating_seq

def nth0ConsExactTypeGuard :
    (x : Nat) → (xs : List Nat) → (n : Nat) → n > 0 →
      (x :: xs).getD n 0 = xs.getD (n - 1) 0 :=
  Prosa.Util.List.nth0_cons

private def requireTypeDefEq (target guard : Name) : MetaM Unit := do
  let targetInfo ← getConstInfo target
  let guardInfo ← getConstInfo guard
  unless targetInfo.levelParams.length == guardInfo.levelParams.length do
    throwError "UNIVERSE_ARITY_MISMATCH target={target} guard={guard}"
  let levels ← targetInfo.levelParams.mapM fun _ => mkFreshLevelMVar
  let targetType := targetInfo.type.instantiateLevelParams targetInfo.levelParams levels
  let guardType := guardInfo.type.instantiateLevelParams guardInfo.levelParams levels
  unless ← Meta.isDefEq targetType guardType do
    throwError "TYPE_DEF_EQ_FAILED target={target} guard={guard}"
  logInfo m!"TYPE_DEF_EQ_OK target={target} guard={guard} target_hash={hash targetInfo.type} guard_hash={hash guardInfo.type}"

run_cmd liftTermElabM do
  requireTypeDefEq ``Prosa.Util.List.last0_nth ``last0NthExactTypeGuard
  requireTypeDefEq ``Prosa.Util.List.max_of_dominating_seq
    ``maxOfDominatingSeqExactTypeGuard
  requireTypeDefEq ``Prosa.Util.List.nth0_cons ``nth0ConsExactTypeGuard

/-- Kernel proof that the Acc-free exported lookup is extensionally the exact
    `List.getD` occurring in the three compiled theorem types. -/
def getDBridgeKernelGuard (xs : List Nat) (n fallback : Nat) :
    Phase7ListLastInterface.getD xs n fallback = xs.getD n fallback :=
  Phase7ListLastInterface.getD_matches_compiled xs n fallback

#check @Prosa.Util.List.last0_nth
#check @Prosa.Util.List.max_of_dominating_seq
#check @Prosa.Util.List.nth0_cons
#check @Phase7ListLastInterface.getD_matches_compiled
#print axioms Prosa.Util.List.last0_nth
#print axioms Prosa.Util.List.max_of_dominating_seq
#print axioms Prosa.Util.List.nth0_cons
#print axioms Phase7ListLastInterface.getD_matches_compiled
#print axioms Phase7ListLastInterface.last0_nth_safe

end Prosa.Validation.Phase7ListLastAudit
