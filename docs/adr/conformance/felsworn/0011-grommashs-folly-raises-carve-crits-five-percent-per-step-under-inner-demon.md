# 0011. Grommash's Folly raises Carve critical strikes by 5% per channel step under Inner Demon

- Status: accepted (owner rulings Felsworn O-21 (2026-11-23) and Felsworn O-23 (2026-11-23))
- Date: 2026-11-23

## Context

Grommash's Folly 805236 (server Spell.dbc, Description[enUS]): "While Inner Demon is active, your melee haste is now
increased by $s2% and you now heal equal to $807426s1% of all damage dealt by critical strikes with auto attacks. In
addition, critical strikes with Carve deal $807427s1% increased damage, increasing up to 60% with each strike based on
how long you channel."

Server DBC set:

| Id | What it is |
|---|---|
| 800206 Carve (channel) | DurationIndex 66 = 2500 ms. The Felsworn contract makes Effect[0] periodic every 250 ms (`AscensionFelswornContracts.cpp:161-163`): 10 steps in a full channel. |
| 803715 Carve (strike) | The release strike, one per enemy in front (`AscensionFelswornAuras.cpp:210-238`). |
| 807427 Carve (crit) | Effect[0] aura 108 `SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_CRIT_DAMAGE_BONUS`, 4 + 1 = 5 per stack ($807427s1), StackAmount 12. No spell triggers it. |

The server counted the steps of the channel (capped at 10, an expired channel forced to 10) and multiplied a critical
803715 hit by `1 + 0.03 x steps` whenever 805236 was known (`AscensionFelswornAbilities.cpp:192-193`, from
`46bf8121e5` with no recorded source): +3% per step, +30% at most, with or without Inner Demon. That matches no
reading of the tooltip, which starts at 5%. The live combat logs show 807427 reaching 3-4 stacks per channel and
expiring 0.5 s after the first step, with no measurable crit bonus at the release. No source decided the expected
value, so the case went to the owner (question Q-805236).

## Options

- (a) Live behaviour: apply 807427 per step with its 500 ms duration. Almost no bonus at the release.
- (b) Tooltip, whole critical hit: factor `1 + 0.05 x steps`, +5% at 1 step, +50% at 10 steps.
- (c) Tooltip through the DBC aura held to the release: 807427 stacks raise only the crit bonus part (2.5x base at
  10 steps instead of 3.0x).
- (d) Keep 3% per step (no source).

## Decision

Option (b) (Felsworn O-21 (2026-11-23)), gated on Inner Demon 804216 (Felsworn O-23 (2026-11-23): the owner reads "While Inner Demon is active" as covering the
Carve sentence). In `AscensionFelswornAbilities.cpp`, keyed to the Felsworn strike 803715 and the talent 805236, a
critical Carve strike is multiplied by `1 + $807427s1 / 100 x min(10, steps)` when Inner Demon was on the caster as the
strike was cast (the spell's 804216 script value, set from the caster's auras at the same moment as the step count).
The per-step figure is read from 807427 Effect[0] instead of a literal. The haste part stays as the tooltip says (its
entries `haste` and `haste_no_inner_demon` already prove it), and the talent adds no critical chance.

## Consequences

- With Inner Demon, a critical Carve strike deals 1.05 times its value at 1 step and 1.50 times at 10 steps (was 1.03
  and 1.30). Without Inner Demon it is unchanged (was 1.30 at 10 steps).
- Known: the tooltip's "up to 60%" (807427 StackAmount 12) stays unreachable. A channel counts at most 10 steps, so
  the bonus stops at 50%.
- 807427 is still never applied as an aura; only its Effect[0] value is read. No client text change and no DBC file
  change.
- Readers of the touched values: 803715, 805236 and 807427 are Felsworn spells (SpellFamilyName 20), read in
  `src/server/coa` only by the Felsworn files. The stock `Unit.cpp` Carve hooks (lines 5048 and 5129, class 14) and
  the resource table (`AscensionCustomResourceData.h:524`) do not read the factor. The Mystic Enchant dummy proc row
  1163070 (`rev_20261029_54_wcr_mystic_enchant_dummy_procs.sql`) only lists these ids. No other class is reached.
- Regressions: the `hit_ratio` entries `805236 crit_inner` (full channel with Inner Demon, control without 805236:
  1.5) and `805236 crit_no_inner` (the same without Inner Demon: 1.0), and the scenario
  `felsworn-grommash-folly-carve-crit.json`, which also cancels the channel after one step (1.05), a case
  `hit_ratio` cannot schedule.
