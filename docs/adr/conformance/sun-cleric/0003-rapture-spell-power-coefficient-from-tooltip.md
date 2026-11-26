# 0003. Rapture adds 1.03734 times Fire spell power

- Status: accepted
- Date: 2026-11-21

## Context

Rapture 806477 and its ranks 807367 to 807372, server Spell.dbc Description[enUS], identical for all seven: "Call
down a streak of sun light to smite your target, dealing ${$m1+0+$spfi*1.03734} Fire damage to them and nearby
enemies, piercing all immunities, but dealing less damage with each enemy struck." No streamed client text overrides
it, and no `spell_bonus_data` row exists for these spells.

`SunClericCoefficients` in `src/server/coa/AscensionSunClericData.h` gave the seven spells an sp coefficient of 2.0,
which `sun_cleric_scaling::ModifySpellEffectBaseValue` adds to effect 0.

- Measured on 807372 (class entry `807372 behaviour_metric_delta damage_sp`, counted pair of the b2b batch): 20879 and
  20914 at +10000 spell power, 884 and 911 at spell power 0, a slope of 2.00 against the tooltip's 1.03734.
- The bindmysoul talents snapshot (fan export, fetched 2026-07-22) reads "111 + 200% fire SP Fire damage". The 24
  logged hits of 807372 in `coa-history` record no spell power and cannot separate the two.

Owner ruling O-5 (2026-11-21): "Rapture 807372: coefficient 1.03734 (tooltip). Fix SunClericCoefficients for 806477
and ranks 807367-807372."

## Options

- Keep 2.0 and correct the client text to 200%.
- Use the tooltip coefficient 1.03734 for the seven spells (O-5).

## Decision

`SunClericCoefficients` sets the sp coefficient of 806477 and 807367 to 807372, effect 0, to 1.03734. No SQL and no
client text change: the tooltip already states 1.03734.

## Consequences

- A Rapture hit adds 1.03734 times the caster's Fire spell damage bonus, at every rank.
- Readers of these rows: `sun_cleric_scaling` (Sun Cleric family 33 spells, keyed by spell id) and
  `sun_cleric_devotion_scaling`, which only reads Dawnsear and Sunflare (SpellFamilyFlags word 1 0x2 and 0x100);
  Rapture carries word 1 0x80000, so the devotion hook does not read it. No other class's file, fixture or code names
  806477 or 807367 to 807372.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-rapture-spell-power-coefficient.json`, ranks 807372 and
  806477, each with a spell power 0 control and a +10000 spell power arm.
- The class entry `807372 behaviour_metric_delta damage_sp` and its ledger claim `$spfi*1.03734` already expect this
  value.
