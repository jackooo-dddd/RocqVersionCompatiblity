namespace Phase5

/- This exposes the genuinely dependent fragment of [Acc.rec].  The safe
   importer candidate must reject it rather than silently treating it as
   Rocq's proof-independent [Acc_rect]. -/
def accDependentRecursorNegative (r : Nat → Nat → Prop)
    (motive : (x : Nat) → Acc r x → Type)
    (step : ∀ (x : Nat) (h : ∀ y, r y x → Acc r y),
      ((y : Nat) → (hxy : r y x) → motive y (h y hxy)) →
      motive x (Acc.intro x h))
    {x : Nat} (a : Acc r x) : motive x a :=
  @Acc.rec Nat r motive step x a

end Phase5
