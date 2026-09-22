import Prosa.Util.SearchArg

open Lean Elab Command Meta

namespace Prosa.Validation.SearchArgNatFindFree

def propOnExMinnExactTypeGuard :
    (P : Nat → Prop) → (pred : Nat → Bool) →
      (∃ n, pred n = true) →
      ((∀ n, pred n = true →
          (∀ n', pred n' = true → n ≤ n') → P n) →
        ∃ n, P n ∧ pred n = true ∧
          ∀ n', pred n' = true → n ≤ n') :=
  Prosa.Util.SearchArg.prop_on_ex_minn

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
  requireTypeDefEq ``Prosa.Util.SearchArg.prop_on_ex_minn
    ``propOnExMinnExactTypeGuard

#check @Prosa.Util.SearchArg.prop_on_ex_minn
#print Prosa.Util.SearchArg.prop_on_ex_minn
#print axioms Prosa.Util.SearchArg.prop_on_ex_minn

end Prosa.Validation.SearchArgNatFindFree
