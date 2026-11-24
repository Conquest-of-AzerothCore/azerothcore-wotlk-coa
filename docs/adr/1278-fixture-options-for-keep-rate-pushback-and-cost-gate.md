# 1278. Fixture options for keep rate, pushback reduction and cost gate

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

Three Felsworn claims could not be expressed by their nearest kind, though each kind's judge already fits:

- Infernal Doom 804219, "Ruin now has a $s1% chance not to consume Felfury": `aura_keep_rate` sets the consumed aura
  at one stack and sets nothing before a treatment cast. Ruin 501298 costs 2 Felfury 800058 (the resource cost table
  of `AscensionCustomResourceData.h`), checked against the stacks of 800058 before the cast, so every treatment cast
  of the first design, at one stack, was refused `SPELL_FAILED_NO_POWER`.
- Unphased 803645, "reduces spell pushback suffered from damaging attacks by $s2% while Inner Demon is active":
  `pushback_reduction` has no condition on the caster. The server sets the REDUCE_PUSHBACK amount only while Inner
  Demon 804216 is up (`AscensionFelsworn::RefreshUnphased`).
- Reachwalker 705135, "Casting Chaos Rush now reduces the cooldown of Felhoof Charge": Chaos Rush dashes the caster
  10 yd forward past the dummy, so the attempt of Felhoof Charge 800204 was refused for its facing (134) or range (97)
  instead of its cooldown, and `cost_gate` has no step that moves the caster back.

## Options

- New kinds for each claim: three judges that repeat existing ones.
- Change the existing fixtures for every entry: moves finished-class scenarios and digests.
- One opt-in fixture option per kind, with the judges, tolerances, evidence classes and closing keys unchanged.

## Decision

The third option, approved by the controller on 2026-11-24 within the mentor's delegation O-12:

- `aura_keep_rate` `aura_stacks` (whole, at least 1, default 1): the stacks of `aura` set before every cast of both
  arms. The judge still counts a cast as kept when the `aura` read is not 0. A `treatment_auras` fixture was approved
  with it and left out: Ruin's `CasterAuraSpell` 803468 is already set by the kind's cast step (`required_aura_steps`),
  and the pilot's 125 casts were all accepted with `aura_stacks` alone.
- `pushback_reduction` `caster_auras` (`[[spell, stacks]]`, stacks at least 1): before every cast of every phase each
  aura is removed and set again on the caster (two `set_aura` steps), so every cast starts under a fresh application
  and the contrast stays the reducer's cast or learn. The model is unchanged.
- `cost_gate` `relocate_before_attempt` (`{"dx": yards}`, nonzero, at most 20, the harness bound of one `relocate`
  step): a `relocate` step right before each judged attempt of the gated spell. Combined with `only_arm`, each arm
  starts from the fixture position and the relative move undoes the dash.

## Consequences

- Absent by default: entries without the options generate the same scenarios and models; the finished classes
  regenerate byte-identical.
- No harness change: `set_aura` and `relocate` are existing actions; `relocate` is relative and keeps the facing, so
  the shift must be sized from the dash and the charge range, and a wrong shift reads as a range or facing refusal
  in the judged cast failure, not as a pass.
- Seeded tests: `kinds/test_aura_keep_rate.py` (the stacks set before every cast, the default equal to no option, a
  talent that never keeps the stacked aura alerts, stacks under 1 refused),
  `kinds/test_pushback_reduction.py` (the condition set afresh before every cast of every phase, the model equal to the
  plain one, no condition by default, stacks under 1 refused), `test_cost_gate_relocate.py` (one relocate before each
  judged attempt only, the plain scenario plus relocates equals the option's, bounds refused).
