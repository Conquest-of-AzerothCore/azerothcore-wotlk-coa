# 0002. Bless restores 5% of maximum mana per tick

- Status: accepted
- Date: 2026-11-21

## Context

Bless 804247, streamed text (`rev_20261015_04_sun_cleric_bless_tooltip.sql`): "Bless yourself and an ally, restoring
5% of their maximum health and 1% of your maximum mana every 10 sec for 5 min." Its Spell.dbc text reads `$s2%` for
the mana part.

The caster's own tick runs `AscensionSunClericAuras.cpp:213-224`: it energizes `CalculatePct(max mana,
Amount(805360, 1))` as 504877, doubled while Lead Me Not Astray 300357 ("Doubles the healing done and mana restored by
Bless") is known.

- Server Spell.dbc 805360 effect 1 (`SPELL_EFFECT_ENERGIZE_PCT`): BasePoints 4, DieSides 1, value 5.
- `rev_20261015_05_sun_cleric_bless_mana.sql` replaces the 805360 `spell_dbc` row with `EffectBasePoints_2` = 1, so
  `CalcValue` gives 2.
- Measured by the batch 2 author (counted pair 20261120-220349 / -220604, server 6b19c29902): 57 mana per tick on
  2868 maximum mana (2.0%), 114 with 300357.
- No archived source gives the percent (mentor table D-31: client data 5, server 2% measured, project text 1%).

Owner ruling O-4 (2026-11-21): "Bless 804247: 5% of maximum mana per tick. Fix the pending SQL for 805360 and the
streamed text."

## Options

- Keep 2% and correct the text to it.
- Restore the client data value 5 and say 5% in the text (O-4).

## Decision

`rev_20261121_01_sun_cleric_bless_mana_five_percent.sql`:

- sets `spell_dbc` 805360 `EffectBasePoints_2` to 4, so effect 1 resolves to 5 as in Spell.dbc;
- rewrites the streamed text of 804247 with "5% of your maximum mana" (Description) and "restoring 5% maximum mana"
  (ToolTip). Every other word of both texts is unchanged.

No C++ changes: the aura handler already reads the 805360 value.

## Consequences

- One tick restores 5% of maximum mana, 10% with 300357.
- Readers of 805360 effect 1: only the Bless handler named above. 805360 is triggered only by 804247 Effect[0],
  whose default action that handler prevents. No other class reads 805360, 804247 or 300357.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-bless-mana-five-percent.json`, with a control that does
  not cast Bless (no 504877 energize), a plain caster (5%) and a caster with 300357 (10%).
  `sun-cleric-bless-periodic-mana-4554.json` already expects 5%.
- The batch 2 class entry `Bless (mana per tick)` and the three Bless ledger clauses are aligned to this ruling when
  that batch is merged.
