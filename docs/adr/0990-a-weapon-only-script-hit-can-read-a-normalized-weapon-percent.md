# 0990. A weapon-only script hit can read a normalized weapon percent

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 278.2 (Vengeful Intent 705534, "you now have a $h% chance to strike back for $520265s1% Weapon
Damage.") is struck by 520265: Effect[0] SPELL_EFFECT_WEAPON_PERCENT_DAMAGE at 75% and Effect[1]
SPELL_EFFECT_NORMALIZED_WEAPON_DMG with 0 flat points, Physical, no school damage effect (server DBC set). Effect
121 makes the weapon roll normalized (`Unit::CalculateDamage` with `normalized = true`: attack power / 14 x the
normalized speed of `Unit::GetAPMultiplier`), and the 75% applies to that roll. `weapon_only` (ADR 0742) models the
actual weapon speed and `normalized_value` (ADR 0762) adds passed points to a normalized roll; neither expresses a
percent of a normalized roll. The option came with the f-m13 entries (commit 79bd5904ae) without an ADR (review14
I-3).

## Options

- An opt-in `normalized_percent` flag inside `weapon_only`, with its own model function.
- Widening `normalized_value` to take a percent: it would change a model that counted entries use.
- A new kind: more code for one hit model.

## Decision

`script_hit` takes `normalized_percent: true`, refused without `weapon_only`. `hits.script_normalized_percent_model`
accepts only a hit spell whose weapon effects are exactly a weapon percent effect followed by a normalized weapon
damage effect, with 0 flat points, no school damage effect, a purely physical mask and the main hand; anything else is
unmodelled. The model: the main-hand weapon roll from `uint32(min + bonus)` to `uint32(max + bonus)`, bonus = attack
power / 14 x `normalized_speed`, each roll times the tooltip percent and truncated, then the aura modifiers of the
physical school and armor mitigation.

## Consequences

- Absent by default: entries without the flag model and generate as before; Templar 19 and Necromancer 23 regenerate
  byte-identical.
- Seeded tests in `test_behaviours.py` (`ScriptHitNormalizedPercentTests`): the tooltip mean is 75% of the weapon
  average plus the normalized attack power term; mutants without the attack power term or without the percent differ
  by more than 5%; the flag is refused outside its shape.
- Limit (review14 M-1): on the default Houndmaster one-hander (item 2027, speed 2.3, normalized 2.4) a pair does not
  separate the normalized term from the actual speed term, and the speed mutant test is not a must-alert mutant. The
  pair excludes a 70% or 80% percent, not the speed term.
- Witch Hunter: `705534 behaviour_script_hit strike_back`.
