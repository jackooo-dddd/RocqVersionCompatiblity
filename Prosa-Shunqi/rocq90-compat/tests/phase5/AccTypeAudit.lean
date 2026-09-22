import Lean

open Lean Elab Command Meta

namespace Prosa.Validation.SafeAccMapping

universe u v

def accTypeGuard {α : Sort u} (r : α → α → Prop) (a : α) : Prop :=
  Acc r a

def accIntroGuard {α : Sort u} (r : α → α → Prop) (a : α)
    (h : ∀ b, r b a → Acc r b) : Acc r a :=
  Acc.intro a h

def accRecGuard {α : Sort u} {r : α → α → Prop}
    {motive : (a : α) → Acc r a → Sort v}
    (intro : ∀ (a : α) (h : ∀ b, r b a → Acc r b),
      (∀ (b : α) (hba : r b a), motive b (h b hba)) →
        motive a (Acc.intro a h)) :
    ∀ (a : α) (h : Acc r a), motive a h :=
  @Acc.rec α r motive intro

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
  requireTypeDefEq ``Acc ``accTypeGuard
  requireTypeDefEq ``Acc.intro ``accIntroGuard
  requireTypeDefEq ``Acc.rec ``accRecGuard

#check @Acc
#check @Acc.intro
#check @Acc.rec
#print axioms accTypeGuard
#print axioms accIntroGuard
#print axioms accRecGuard

end Prosa.Validation.SafeAccMapping
