# 0028. Lights of Absolution restores on Solar Flare damage, from missing health, once every 0.5 sec

- Status: accepted
- Date: 2026-11-22
- Ruling: owner O-13 (card Q-sc-2, option a), mentor decision log, 2026-11-22
- Superseded by: [0041](0041-lights-of-absolution-restores-missing-resources-not-mana.md) (owner ruling O-30) for the
  energize line of the Decision and the unmeasured resource part of the Consequences.

## Context

Light of Absolution 807523, granted by Lights of Absolution 807343 on Horusath Blast damage, reads: "Damage dealt by
Solar Flares now restores $807525s1% missing health, Energy, Focus, Runic Power, and Rage to allies within $807524a1
yds. Can only occur once every 0.5 sec." The port (e36bc50aad, "Restore mechanics for five additional classes", no
stated reason) did otherwise:

- `Select(807523)` accepted only Radiant Flame 806060, so the next Radiant Flame cast carried the marker, consumed the
  buff, and each of its 807058 ticks cast 807524; Solar Flare 807175 never did (flare_heal read 0, pair
  20261122-001533 / -001615);
- 807525 Effect[0] is `SPELL_EFFECT_HEAL_PCT`, which the engine takes from maximum health
  (`Spell::EffectHealPct`, `CountPctFromMaxHealth`);
- nothing enforced the 0.5 sec limit (no recovery time, no proc entry, the cast is triggered).

The owner ruled: the heal is triggered by Solar Flare damage, the Radiant Flame trigger goes, the base becomes
missing health, and the tooltip's "once every 0.5 sec" applies.

## Options

- In the class hit hook: a damaging Solar Flare hit by a caster holding 807523 casts 807524, gated per caster; a
  spell script on 807525 heals the percent of missing health.
- Rewrite 807525 to a flat heal and compute the amount per ally in the hook: duplicates the area selection 807524
  already does.
- Reuse another class's missing-health heal: a cross-class link (refused).

## Decision

The first option, in Sun Cleric code only (`AscensionSunClericAbilities.cpp`):

- `Select` no longer accepts Radiant Flame for 807523 and triggered spells no longer copy its marker, so no Radiant
  Flame cast carries or consumes the buff; it lasts its 10 sec.
- `OnSpellHitResult`: a Solar Flare 807175 hit that deals damage, cast by the player, casts 807524 when
  `Chance(player, 807523, 500)` passes: the buff is held, its ProcChance 100 rolls, and a 500 ms timer per caster
  closes the gate. 807524 keeps the DBC chain: 807526 and 807525 on allies within 40 yd.
- `spell_ascension_sun_cleric_lights_of_absolution` on 807525: Effect[0] heals its value as a percent of the
  target's missing health, through the caster's healing done and the target's healing taken. Effects 1 and 2
  (energize) are unchanged. The script is bound by one idempotent `spell_script_names` row (807525,
  `spell_ascension_sun_cleric_lights_of_absolution`), a DELETE then INSERT in
  `data/sql/updates/pending_db_world/rev_20261122_13_sun_cleric_lights_of_absolution_missing_health.sql`, checked
  with `codestyle-sql.py --files`.

## Consequences

- Regression in the class file, 807343 entries: `flare_heal` (caster at 3000 of 10000 health: 112 = 2% of 7000
  missing x 0.8 class tuning; a current-health base reads 48 and a maximum-health base 160), `radiant_none` (0 with
  the ticks and the buff read), `gate_once` (two flares 470 ms apart heal once) and its control `gate_after` (530 ms
  apart heal twice), so a gate 10% off (0.45 s or 0.55 s) fails one of them, and `ally_radius` (caster and allies at
  3000 of 10000 health: ally at 39 yd healed 112, ally at 41 yd not; the distance arms and the 0-heal arm guard the
  offsets). Every before phase is the no-buff control.
- The Energy, Focus, Runic Power and Rage part of the tooltip is not measured: its ledger claim stays open.
- The 807524 edge is 40.0 yd: TargetB 30 takes no leeway and a player target adds no reach (ADR 1190 terms).
- The `ally_radius` entry uses the new metric delta option `ally_offsets` (ADR 1196).
- No other class reads 807523 to 807526; the class map lists 807343 for class 27 only.
