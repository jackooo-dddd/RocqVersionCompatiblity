import Prosa.Util.SearchArg

theorem phase6_omega_probe (a b : Nat) (h : ¬ a ≤ b) : b ≤ a := by
  omega

theorem phase6_bool_contradiction_probe (b : Bool)
    (hf : b = false) (ht : b = true) : False := by
  simp [hf] at ht

theorem phase6_if_probe (b : Bool) (h : b = true) :
    (if b = true then some 0 else none) = some 0 := by
  simp [h]

#print axioms phase6_omega_probe
#print axioms phase6_bool_contradiction_probe
#print axioms phase6_if_probe
