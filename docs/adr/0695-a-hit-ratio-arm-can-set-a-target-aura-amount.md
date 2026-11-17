# 0695. A hit ratio arm can set a target aura amount

- Status: proposed
- Date: 2026-11-15

## Context

Stake 681350 says "ignoring enemy armor". Its `hit_mean` (ADR 0689) shows the hit unmitigated at one armor value, the
reference dummy's 528. A contrast needs the same hit at two armor values, and a physical spell that does not ignore
armor falling between them. No step sets a creature's armor. `hit_ratio` has `target_auras` at the spec level (the
same in both arms) and `aura_amounts` on the caster only.

## Options

- A harness step `set_armor` that writes the creature's `UNIT_MOD_ARMOR` base value: harness C++ beyond reads and
  recording (a G-39 note), the same slot the `min_level_armor` fixture writes, and a shared-file change for every
  class.
- An existing armor aura set on the dummy through the harness `set_aura` action, which already takes `target`,
  `caster`, `effect` and `amount` (`AuraEffect::ChangeAmount`), with one arm field in `behaviours.py`.
- Keep the one-armor `hit_mean`.

## Decision

A `hit_ratio` arm takes `target_aura_amounts`, a list of `[spell, effect, amount]` with distinct spells and an effect
0-2. Before every trial of that arm the caster sets each aura on the cast target, one stack, with that effect amount;
after the arm it removes them. Any arm that sets one makes the scenario read the target's `armor` at the end of each
arm (`<label> <arm> target armor`, listed in the model's `target_armor_reads`), so the run shows the fixture took. It
needs a cast target other than the caster and no swings.

Stake uses Lesser Armor 673 (Spell.dbc: one effect, aura 22 SPELL_AURA_MOD_RESISTANCE, misc 1 armor) at 5000 in the
treatment arm. The amount is a fixture size, not a claimed value; the expected ratios follow from the read armor:
Stake 1.0, and Darkslayer 804179 (physical, no ignore-armor attribute) 0.5466 from
`mitigation.armor_reduction` at armor 528 and 5528 (Unit.cpp:2569-2572).

## Consequences

- Tests: `HitRatioTargetAuraAmountTests` (test_behaviours.py).
- Entries: `681350 behaviour_hit_ratio armored` and `681350 behaviour_hit_ratio armored_control`, cited with
  `681350 hit_mean` by the "ignoring enemy armor" claim.
- The field defaults to empty: the finished classes' scenarios are unchanged.
- Number provisional: shared ADRs are numbered at merge.
