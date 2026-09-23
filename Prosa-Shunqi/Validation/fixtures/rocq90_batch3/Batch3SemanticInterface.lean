import Validation.fixtures.utility_foundation.SumSequenceComputationInterface
import Validation.fixtures.translation_order.BigopComputationInterface
import Validation.fixtures.translation_order.SetoidComputationInterface
import Validation.fixtures.translation_order.PoetComputationInterface
import Validation.fixtures.translation_order.BigcatComputationInterface
import Validation.fixtures.translation_order.MinmaxComputationInterface
import Validation.fixtures.translation_order.DivModComputationInterface

open Lean Elab Command Meta

namespace Prosa.Validation.Batch3Semantic

/-!
The compiled `Finset.univ` implementation over `Unit` reaches
`WellFounded/Acc`.  This validation-only one-element operation has a
kernel-checked equality to that exact expression, while its exported body is
structural and Acc-free.
-/
def sumUnit (F : Unit → Nat) : Nat := F ()

theorem sumUnit_eq (F : Unit → Nat) : sumUnit F = F () := rfl

theorem sumUnit_matches_compiled (F : Unit → Nat) :
    sumUnit F = ∑ r : Unit, F r := by
  simp [sumUnit]

def sumUnitStatement : Prop := ∀ F : Unit → Nat, sumUnit F = F ()

theorem sumUnitStatement_iff_compiled :
    sumUnitStatement ↔ ∀ F : Unit → Nat, (∑ r : Unit, F r) = F () := by
  constructor
  · intro _ F
    exact Prosa.Util.Sum.sum_unit1 F
  · intro _ F
    exact sumUnit_eq F

/--
Expose the exact proposition of a kernel-checked production theorem as a
definition, without exporting the theorem as an axiom and without traversing
an implementation-only proof closure.  Independent exact-type guards bind
the production declaration to a frozen expected type; Rocq type audits bind
these definitions to the independently encoded certificate statements.
-/
syntax "#semantic_statement " ident " as " ident : command

private def projectNatIcoSum? (e : Expr) : Option Expr := do
  guard <| e.getAppFn.isConstOf ``Finset.sum
  let args := e.getAppArgs
  guard <| args.size == 5
  guard <| args[0]!.isConstOf ``Nat
  guard <| args[1]!.isConstOf ``Nat
  let interval := args[3]!
  guard <| interval.getAppFn.isConstOf ``Finset.Ico
  let intervalArgs := interval.getAppArgs
  guard <| intervalArgs.size == 5
  guard <| intervalArgs[0]!.isConstOf ``Nat
  let one := mkApp (.const ``Nat.succ []) (.const ``Nat.zero [])
  let length := mkApp2 (.const ``Nat.sub []) intervalArgs[4]! intervalArgs[3]!
  let range := mkApp3 (.const ``List.range' []) intervalArgs[3]! length one
  let mapped := mkApp4 (.const ``List.map [.zero, .zero])
    (.const ``Nat []) (.const ``Nat []) args[4]! range
  return mkApp5 (.const ``List.foldr [.zero, .zero])
    (.const ``Nat []) (.const ``Nat []) (.const ``Nat.add [])
    (.const ``Nat.zero []) mapped

private partial def projectNatIcoSums (e : Expr) : MetaM Expr := do
  if let some projected := projectNatIcoSum? e then
    return projected
  match e with
  | .app f a => return e.updateApp! (← projectNatIcoSums f) (← projectNatIcoSums a)
  | .lam _ d b _ => return e.updateLambdaE! (← projectNatIcoSums d) (← projectNatIcoSums b)
  | .forallE _ d b _ => return e.updateForallE! (← projectNatIcoSums d) (← projectNatIcoSums b)
  | .letE _ t v b _ =>
      return e.updateLetE! (← projectNatIcoSums t) (← projectNatIcoSums v)
        (← projectNatIcoSums b)
  | .mdata _ b => return e.updateMData! (← projectNatIcoSums b)
  | .proj _ _ b => return e.updateProj! (← projectNatIcoSums b)
  | _ => return e

syntax "#normalized_semantic_statement " ident " as " ident : command

elab_rules : command
  | `(#semantic_statement $target:ident as $outName:ident) => do
      let targetName ← resolveGlobalConstNoOverload target
      liftTermElabM <| Term.withoutErrToSorry do
        let info ← getConstInfo targetName
        unless (← inferType info.type).isProp do
          throwError "semantic interface target is not a proposition"
        let name := (← getCurrNamespace) ++ outName.getId
        addAndCompile <| Declaration.defnDecl {
          name
          levelParams := info.levelParams
          type := .sort .zero
          value := info.type
          hints := ReducibilityHints.abbrev
          safety := DefinitionSafety.safe
        }

elab_rules : command
  | `(#normalized_semantic_statement $target:ident as $outName:ident) => do
      let targetName ← resolveGlobalConstNoOverload target
      liftTermElabM <| Term.withoutErrToSorry do
        let info ← getConstInfo targetName
        let normalized ← projectNatIcoSums info.type
        unless ← Meta.isDefEq info.type normalized do
          throwError "normalized semantic statement is not definitionally equal"
        unless (← inferType normalized).isProp do
          throwError "normalized semantic interface target is not a proposition"
        let name := (← getCurrNamespace) ++ outName.getId
        addAndCompile <| Declaration.defnDecl {
          name
          levelParams := info.levelParams
          type := .sort .zero
          value := normalized
          hints := ReducibilityHints.abbrev
          safety := DefinitionSafety.safe
        }
        logInfo m!"NORMALIZED_SEMANTIC_STATEMENT target={targetName} alias={name} proof=Meta.isDefEq"

#semantic_statement Prosa.Util.Sum.sum_majorant_constant as sum_sum_majorant_constant
#semantic_statement Prosa.Util.Sum.bigmax_leq_sum as sum_bigmax_leq_sum
#semantic_statement Prosa.Util.Sum.leq_sum_sub_uniq as sum_leq_sum_sub_uniq
#semantic_statement Prosa.Util.Sum.eq_sum_leq_seq as sum_eq_sum_leq_seq
#normalized_semantic_statement Prosa.Util.Sum.sum_of_ones as sum_sum_of_ones
#normalized_semantic_statement Prosa.Util.Sum.big_nat_eq0 as sum_big_nat_eq0
#normalized_semantic_statement Prosa.Util.Sum.sum_le_summation_range as sum_sum_le_summation_range
#normalized_semantic_statement Prosa.Util.Sum.big_sum_eq_in_eq_sized_intervals as sum_big_sum_eq_in_eq_sized_intervals
#semantic_statement Prosa.Util.Sum.sum_over_partitions_le as sum_sum_over_partitions_le
#semantic_statement Prosa.Util.Sum.reorder_summation as sum_reorder_summation
#semantic_statement Prosa.Util.Sum.sum_over_partitions_eq as sum_sum_over_partitions_eq
#normalized_semantic_statement Prosa.Util.Sum.pigeonhole_on_interval as sum_pigeonhole_on_interval
#semantic_statement Prosa.Util.Sum.sum_ge_2_seq as sum_sum_ge_2_seq
#normalized_semantic_statement Prosa.Util.Sum.sum_ge_2_nat as sum_sum_ge_2_nat

#semantic_statement Prosa.Util.Sum.sum_nat_eq0_nat as sum_sum_nat_eq0_nat
#semantic_statement Prosa.Util.Sum.sum_nat_gt0 as sum_sum_nat_gt0
#semantic_statement Prosa.Util.Sum.sum_split_exhaustive_mutually_exclusive_preds as sum_sum_split_exhaustive_mutually_exclusive_preds
#semantic_statement Prosa.Util.Sum.sum_le_subseq as sum_sum_le_subseq
#semantic_statement Prosa.Util.Sum.leq_sum_seq as sum_leq_sum_seq
#semantic_statement Prosa.Util.Sum.eq_sum_seq as sum_eq_sum_seq
#semantic_statement Prosa.Util.Sum.leq_sum_seq_pred as sum_leq_sum_seq_pred
#semantic_statement Prosa.Util.Sum.leq_sum_subseq as sum_leq_sum_subseq
#semantic_statement Prosa.Util.Sum.ltn_sum_leq_seq as sum_ltn_sum_leq_seq
#semantic_statement Prosa.Util.Sum.sum_leq_mono as sum_sum_leq_mono

#semantic_statement Prosa.Util.Bigop.big_pred1_seq as bigop_big_pred1_seq

#semantic_statement Prosa.Util.Setoid.leb_eq as setoid_leb_eq

#semantic_statement Prosa.Util.Poet.forall_exists_implied_by_forall_in_zip as poet_forall_exists_implied_by_forall_in_zip

#semantic_statement Prosa.Util.Bigcat.mem_bigcat_nat as bigcat_mem_bigcat_nat
#semantic_statement Prosa.Util.Bigcat.mem_bigcat_nat_exists as bigcat_mem_bigcat_nat_exists
#semantic_statement Prosa.Util.Bigcat.mem_bigcat_ord as bigcat_mem_bigcat_ord
#semantic_statement Prosa.Util.Bigcat.bigcat_nat_uniq as bigcat_bigcat_nat_uniq
#semantic_statement Prosa.Util.Bigcat.bigcat_nat_filter_eq_filter_bigcat_nat as bigcat_bigcat_nat_filter_eq_filter_bigcat_nat
#normalized_semantic_statement Prosa.Util.Bigcat.size_big_nat as bigcat_size_big_nat
#semantic_statement Prosa.Util.Bigcat.mem_bigcat as bigcat_mem_bigcat
#semantic_statement Prosa.Util.Bigcat.mem_bigcat_exists as bigcat_mem_bigcat_exists
#semantic_statement Prosa.Util.Bigcat.bigcat_filter_eq_filter_bigcat as bigcat_bigcat_filter_eq_filter_bigcat
#semantic_statement Prosa.Util.Bigcat.bigcat_uniq as bigcat_bigcat_uniq
#semantic_statement Prosa.Util.Bigcat.seq_different_elements_nil as bigcat_seq_different_elements_nil
#semantic_statement Prosa.Util.Bigcat.bigcat_seq_uniqK as bigcat_bigcat_seq_uniqK
#semantic_statement Prosa.Util.Bigcat.bigcat_partitions as bigcat_bigcat_partitions

#semantic_statement Prosa.Util.Minmax.bigmax_ord_ltn_identity as minmax_bigmax_ord_ltn_identity
#semantic_statement Prosa.Util.Minmax.bigmax_pred as minmax_bigmax_pred
#semantic_statement Prosa.Util.Minmax.bigmax_witness_diff as minmax_bigmax_witness_diff
#semantic_statement Prosa.Util.Minmax.leq_bigmax_cond_seq as minmax_leq_bigmax_cond_seq
#semantic_statement Prosa.Util.Minmax.leq_bigmax_sup as minmax_leq_bigmax_sup
#semantic_statement Prosa.Util.Minmax.bigmax_leq_seqP as minmax_bigmax_leq_seqP
#semantic_statement Prosa.Util.Minmax.leq_big_max as minmax_leq_big_max
#semantic_statement Prosa.Util.Minmax.bigmax_ltn_ord as minmax_bigmax_ltn_ord
#semantic_statement Prosa.Util.Minmax.bigmax_witness as minmax_bigmax_witness
#semantic_statement Prosa.Util.Minmax.bigmax_subset as minmax_bigmax_subset

#semantic_statement Prosa.Util.Div_mod.eqdivn_leqmodn as divmod_eqdivn_leqmodn
#semantic_statement Prosa.Util.Div_mod.ltdivn_dvdn as divmod_ltdivn_dvdn
#semantic_statement Prosa.Util.Div_mod.addn1_modn_commute as divmod_addn1_modn_commute
#semantic_statement Prosa.Util.Div_mod.addmod_le_mod as divmod_addmod_le_mod
#semantic_statement Prosa.Util.Div_mod.div_ceil_monotone1 as divmod_div_ceil_monotone1
#semantic_statement Prosa.Util.Div_mod.leq_div_ceil_add1 as divmod_leq_div_ceil_add1
#semantic_statement Prosa.Util.Div_mod.div_ceil_subadditive as divmod_div_ceil_subadditive
#semantic_statement Prosa.Util.Div_mod.div_ceil_multiple as divmod_div_ceil_multiple
#semantic_statement Prosa.Util.Div_mod.div_floor_add_g as divmod_div_floor_add_g
#semantic_statement Prosa.Util.Div_mod.mod_elim as divmod_mod_elim
#semantic_statement Prosa.Util.Div_mod.divn_leq as divmod_divn_leq
#semantic_statement Prosa.Util.Div_mod.div_ceil0 as divmod_div_ceil0
#semantic_statement Prosa.Util.Div_mod.div_ceil_gt0 as divmod_div_ceil_gt0

#print axioms sumUnit_matches_compiled
#print axioms sumUnitStatement_iff_compiled

end Prosa.Validation.Batch3Semantic
