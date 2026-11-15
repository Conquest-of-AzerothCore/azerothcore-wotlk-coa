# 0048. `spell_healing_taken` metric for received-side healing ratio checks

- Status: accepted
- Date: 2026-11-09

## Context

Round 5 through round 8 carried 705268/501606 (Templar "Final Prayer", "Doubles the healing done to you") as an
open `alert`: Testament of Faith healed the same 800 before and after learning Final Prayer, ratio 1.0 against
the tooltip's 2.0, filed as a confirmed server defect this round's dossier inherited unresolved.

Round 9 traced the measurement itself before accepting the defect. Final Prayer's own effect 1 is
`SPELL_AURA_MOD_HEALING_RECEIVED` (aura 283), a *taken*-side modifier: it is read on the healed unit, by
`Unit::SpellHealingBonusTaken`. The `ratio` behaviour's `"cast"` method (`behaviours.py`'s
`healing_ratio_scenario`) measures with `spell_healing_done`, which calls `Unit::SpellHealingBonusDone` — the
*caster*-side multiplier (`SpellPctHealingModsDone` and the caster's own fixed-bonus auras). Reading
`SpellHealingBonusDone`'s body confirms it never reads any aura of the healed unit; only `SpellHealingBonusTaken`
does. Fresh, reverted instrumentation at the top of both `Unit::SpellHealingBonusTaken` and `Spell::EffectHeal`
(logging unconditionally for spell 501606/801478, build+gameplay stamp `20261109-202131`) recorded zero
invocations during the scenario, while the metric still reported 800 both times: the measured number comes
entirely from the synthetic `SpellHealingBonusDone(target, info, 1000, HEAL, effect)` call `CoAGameplayTest.cpp`
makes on request, not from the real cast's landed heal, and that call is structurally blind to a taken-side aura
regardless of whether the server doubles the heal correctly. The check could never have passed or failed on this
aura's actual behaviour.

This is a measurement-coverage gap like ADR 0036's, not a judging-logic gap: `behaviour_ratio_verdict` already
judges a `before`/`after` delta correctly once it is given the right numbers.

## Considered options

1. Change `"cast"` targets to measure the real landed heal from the scenario's own cast (a combat-log-style
   reading) instead of a synthetic probe. Rejected for this item: a bigger harness change than the gap needs,
   and the existing `"cast"` method is correct for a caster-side (`MOD_HEALING_DONE_PCT`-style) doubling — nothing
   wrong with it is being fixed, so it stays as the default.
2. Redefine `spell_healing_done` to call `SpellHealingBonusTaken` instead of `SpellHealingBonusDone`. Rejected:
   silently changes a metric other classes' entries already rely on for the caster-side meaning (the harness
   rule requires a new name for a behaviour change, never redefining one in place).
3. Add a new, additive `spell_healing_taken` metric (`Unit::SpellHealingBonusTaken` on the named target) and a
   matching `"taken"` method on `HealingRatioTarget`, so a `targets` entry can ask for whichever side the
   tooltip's clause actually names. Chosen.

## Decision

- `CoAGameplayTest.cpp`'s metric dispatch already had `spell_healing_taken` (`unit->SpellHealingBonusTaken(
  GetUnit(target), info, 1000, periodic ? DOT : HEAL)`, read-only, used today by `passives.py`'s generic
  aura-driven passive checks) before this round; it needed no C++ change. This round reuses that existing
  metric from `behaviours.py`'s new `"taken"` method, with the same `{spell, target, periodic}` step shape
  `spell_healing_done` already uses. `spell_healing_done` is unchanged.
- `behaviours.py`'s `HealingRatioTarget` gains method `"taken"`: cast like `"cast"` (so mana/cooldown/aura
  prerequisites still apply and the real heal still lands, even though this metric does not read it), but
  measured with the new `spell_healing_taken` instead of `spell_healing_done`. `label()`/`cast_all()`/`measure()`
  grow one branch each; the `Expectation` shape and `behaviour_ratio_verdict`'s judging are untouched, and no
  class spell ids appear outside `classes/templar.json`.
- `classes/templar.json`'s Final Prayer entry changes its Testament of Faith target from the 2-element default
  (method `"cast"`) to `{"method": "taken"}`, naming the rank id actually cast at the test character's level
  (501606) rather than the base id (801478); Testament of Fortitude's `"effect_value"` target is unchanged.
- `docs/behaviour-scenarios.md` documents the new method and corrects the Final Prayer row, which previously
  asserted (incorrectly) that `"cast"`/`spell_healing_done` already measured the taken-side aura.

## Consequences

- Final Prayer's `705268 501606 behaviour_ratio` can now actually fail or pass on the tooltip's real claim;
  round 9's gameplay re-run after this change is the regression for this item (see
  `round9/mechanics-report.md`).
- Any future class passive that doubles healing *received* (a taken-side aura on the healed unit) can use
  method `"taken"` directly, with no new class-specific code; a caster-side doubling keeps using the existing
  default.
- The three-round-old "confirmed server defect" classification for this item is superseded: once measured on
  the correct side, this was an incorrect check, not a broken aura.
