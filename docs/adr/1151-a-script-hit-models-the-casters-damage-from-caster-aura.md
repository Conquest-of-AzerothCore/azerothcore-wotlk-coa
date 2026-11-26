# 1151. A script hit models the caster's damage-from-caster aura

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0219 and ADR 0220 (script_hit model_auras)

## Context

Veil of Darkness 802100 puts SPELL_AURA_MOD_DAMAGE_FROM_CASTER (271, +15%, MiscValue 127, family 19, empty class
mask) on its target, and its pulse 806473 is a family 19 Shadow hit from the same caster. `Unit::SpellDamageBonusTaken`
multiplies the taken amount by every such aura of that caster that `AuraEffect::IsAffectedOnSpell` accepts (school
mask, then `SpellInfo::IsAffected` on the family and class mask) and truncates `(done) x mod` to uint32. The hit model
read only done modifiers (79, 341, 118, 136), so `veil_tick` expected 206 (engine 205) and read 235 in both final08
runs.

## Decision

The auras an entry names in `model_auras` also yield taken modifiers (`hits.taken_modifiers`) when the hit is the
caster's own (no `caster_entry`: aura 271 counts only for the aura's caster): each effect that applies aura 271 whose
school mask meets the hit's and whose family is 0, or equal to the hit's with an empty or intersecting class mask,
becomes a `damage_taken` modifier. `expected_hit` applies them after the done stage, with their own floor, for damage
only; the model lists them with its modifiers, and the expectation record names their auras in `taken_auras` (absent
when there are none), which the measured model reads. Known auras of the class file and `minion_model_auras` are not
read for this.

## Consequences

No Templar or Necromancer entry names such an aura: their generated scenarios (19 with and without `--stack`, 23) are
byte-identical. Class 13: `veil_tick` names 802100 and expects 236 (tooltip model) and 235 (engine model).
