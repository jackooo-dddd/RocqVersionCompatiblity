namespace Phase5

/- A compiled use of Lean's recursor whose motive depends on the carrier
   value, but not on the accessibility proof.  This is the exact fragment
   that may safely be represented by Rocq's standard [Acc_rect]. -/
def accRectNatSmoke (r : Nat → Nat → Prop)
    (P : Nat → Type)
    (step : ∀ (x : Nat) (h : ∀ y, r y x → Acc r y),
      (∀ (y : Nat) (hxy : r y x), P y) → P x)
    {x : Nat} (a : Acc r x) : P x :=
  @Acc.rec Nat r (fun y _ => P y)
    (fun y h ih => step y h ih) x a

end Phase5
