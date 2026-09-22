import Prosa.Util.SearchArg

open Lean Elab Command Meta

namespace Prosa.Validation.SearchArgAccFree

universe u

/- This definition is audit-only and is never exported.  Its value is the
   actual compiled declaration, so elaboration checks the exact public type. -/
def search_arg_exact_type_guard {T : Type u}
    (f : Nat → T) (P : T → Bool) (R : T → T → Bool) (a b : Nat) :
    Option Nat :=
  Prosa.Util.SearchArg.search_arg f P R a b

theorem search_arg_eq_1_refl_guard {T : Type u}
    (f : Nat → T) (P : T → Bool) (R : T → T → Bool) (a : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a 0 =
      if a < 0 then none else none := by
  rfl

theorem search_arg_eq_2_refl_guard {T : Type u}
    (f : Nat → T) (P : T → Bool) (R : T → T → Bool) (a b : Nat) :
    Prosa.Util.SearchArg.search_arg f P R a b.succ =
      if a < b.succ then
        match Prosa.Util.SearchArg.search_arg f P R a b with
        | none => if P (f b) = true then some b else none
        | some x => if (P (f b) && R (f b) (f x)) = true then some b else some x
      else none := by
  rfl

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
  requireTypeDefEq ``Prosa.Util.SearchArg.search_arg
    ``search_arg_exact_type_guard
  requireTypeDefEq ``Prosa.Util.SearchArg.search_arg.eq_1
    ``search_arg_eq_1_refl_guard
  requireTypeDefEq ``Prosa.Util.SearchArg.search_arg.eq_2
    ``search_arg_eq_2_refl_guard

#check @Prosa.Util.SearchArg.search_arg
#check @Prosa.Util.SearchArg.search_arg.eq_1
#check @Prosa.Util.SearchArg.search_arg.eq_2
#print axioms search_arg_eq_1_refl_guard
#print axioms search_arg_eq_2_refl_guard

end Prosa.Validation.SearchArgAccFree
