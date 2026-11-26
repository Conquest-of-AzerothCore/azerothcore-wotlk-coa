# 0041. Lights of Absolution restores missing Energy, Focus, Runic Power and Rage, and no mana

- Status: accepted
- Date: 2026-11-23
- Ruling: owner O-30 (owner packet section 4, option A, extending O-13 to the resources)
- Supersedes: the energize line of [0028](0028-lights-of-absolution-restores-on-solar-flare-damage.md) ("Effects 1 and
  2 (energize) are unchanged") and its consequence that the resource part is not measured.

## Context

Light of Absolution 807523 reads: "Damage dealt by Solar Flares now restores $807525s1% missing health, Energy, Focus,
Runic Power, and Rage to allies within $807524a1 yds. Can only occur once every 0.5 sec." 807524 triggers 807526
(Effect[0]) and 807525 (Effect[1]) on the allies of its 40 yd area. In the server Spell.dbc:

- 807525: Effect[0] HEAL_PCT, Effect[1] ENERGIZE_PCT MiscValue 0 (mana), Effect[2] ENERGIZE_PCT MiscValue 1 (rage);
- 807526: Effect[0..2] ENERGIZE_PCT MiscValue 2, 3, 6 (focus, energy, runic power);
- every effect is BasePoints 1 + DieSides 1 = 2 ($807525s1).

`Spell::EffectEnergizePct` gives `CalculatePct(GetMaxPower(power), damage)`, a percent of the maximum, and 807525
restores mana, which the tooltip does not name. ADR 0028 moved the heal to missing health (O-13) and left the
energize effects as served. The pair 20261123-074556 / -074900 (build fe10e6bfb958, server commit 06c926cb875e, no
flip) read the stock behaviour on full pools, as the nominal gain before the cap: a Rage or Runic Power pool of 1000
logs 20, an Energy or Focus pool of 100 logs 2, and a Sun Cleric mana pool of 2868 logs 57.

The owner ruled (O-30): the restore is 2% of the missing Energy, Focus, Runic Power and Rage, as for health, and mana
is no longer restored.

## Options

- The class script on 807525 and 807526: each ENERGIZE_PCT effect restores its value as a percent of the target's
  missing power, and the mana effect restores nothing.
- Change `Spell::EffectEnergizePct` for these spells: a shared engine path every class reads (refused).
- Rewrite 807525 and 807526 in SQL to flat energizes and compute the amounts in the hit hook: duplicates the area
  selection 807524 already does, as ADR 0028 found for the heal.

## Decision

The first option, in Sun Cleric code only (`AscensionSunClericAbilities.cpp`):

- `spell_ascension_sun_cleric_lights_of_absolution` gains a hit-target hook on every `SPELL_EFFECT_ENERGIZE_PCT`
  effect. It prevents the default effect and, for any power but mana, energizes `CalculatePct(GetMaxPower - GetPower,
  value)` through `Unit::EnergizeBySpell`, with the engine's own skips (a dead or isolated target, a player that is not
  active in the power type, `Unit::CanReceivePowerFromSpell`). A gain of 0 sends no energize log. The mana effect
  restores nothing.
- The heal hooks stay on 807525 only (`m_scriptSpellId`), so the script binds to 807526 without an effect mismatch.
- The script is bound to 807526 by one idempotent `spell_script_names` row, a DELETE then INSERT in
  `data/sql/updates/pending_db_world/rev_20261123_30_sun_cleric_lights_of_absolution_missing_power.sql`; the 807525 row
  of ADR 0028 is unchanged.

## Consequences

- Regression in the class file, 807343 entries, each read as the logged gain (`spell_energize_total`) with the
  before phase (no Light of Absolution fixture) as the control at 0. The harness sets every power of an actor to its
  maximum at setup (`CoAGameplayTest.cpp:3053-3054`), so every ally pool is full:
  - `restore_rage` (Fleshwarden ally), `restore_runic` (Reaper ally), `restore_energy` (Templar ally) and
    `restore_focus` (Ranger ally): a full pool restores 0 (stock: 20 of 1000, 20 of 1000, 2 of 100, 2 of 100), with a
    precondition `power` arm at the maximum and a reach arm (one 807525 heal on the ally at 3000 of 10000 health,
    `ally_health`: the restore landed);
  - `restore_mana`: the full Sun Cleric ally reads 0 (stock: 57), and an arm reads 0 on the caster, whose mana is set
    to 1363 (`cast_power`), a partial pool.
- A partial pool of an ally's Energy, Focus, Runic Power or Rage cannot be set with the existing options, so the arms
  "a partial pool restores 2% of the missing amount" are not built for any of the four power types: a tool need (an
  ally power setting ahead of the trigger, as `ally_health` does for health), returned to the mentor. Until then the
  resource claim is proven for the full pool and for mana only.
- No other class reads 807523 to 807526: 807524 is the only spell that triggers 807525 and 807526 (DBC links), and no
  code under `src/server` outside the Sun Cleric files and no other class file or fixture names 807343 or 807523 to
  807526. `Spell::EffectEnergizePct` is unchanged.

## Addendum: the partial-pool arms

- Date: 2026-11-23
- Decided by: owner ruling O-30 (mentor D-303); the tool need above is met by `ally_arm` `ally_power` (ADR 1244)

Five entries set the ally's pool ahead of the trigger in both phases and read it after landing with a judged `power`
arm: `restore_rage_partial` and `restore_runic_partial` at 500 of 1000 log 10 (stock 20), `restore_energy_partial`
and `restore_focus_partial` at 50 of 100 log 1 (stock 2), `restore_mana_partial` at 1400 of 2868 logs 0 (stock 57).
Pair 20261123-080621 / -080716, build 0361bbda8f2f, server commit 93da3b7e0ffa (src and data identical to
b2a2ea1baa), no flip, 18/18 ok. No pre-fix run of these arms exists and the pre-fix tree is not rebuilt; the stock
figures come from code reading (`Spell::EffectEnergizePct`, SpellEffects.cpp:3040-3044) and match the full-pool
before pair.

No pre-fix run exists for the partial-pool arms: their after readings discriminate by themselves (10/10/1/1/0 on
half-empty pools is 2% of the missing amount and cannot be 2% of the maximum, 20/20/2/2/57, which the full-pool arms
measured before the fix).
