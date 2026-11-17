# 0996. A script hit can roll its value spell's die

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-17

## Context

Witch Hunter claim 242.0 (Coordinated Killing 705463, "Ranged auto attacks deal an additional ${$m3+$RAP*0.15} Shadow
Damage.") is struck by 567570, whose value the `script_hit` entries read from Shadow Rage 680275 effect 2 through
`value_spell` and `value_effect` (ADR 0208). In the server DBC set 680275 has EffectBasePoints[2] 56 and
EffectDieSides[2] 2, so `$m3` rolls 57..58, and the tooltip shows only `$m3`, the lower roll. `hits.rolled_values`
took the die sides from the hit spell 567570, so the model held one value (reference sigma 0.0, mean 92.0) and could
not state the roll range. The claim's base roll was counted by the readback label 705463 effect_value 680275e2 #1,
which the mentor asked to drop (D-415) once the hit model carries the range (D-416).

## Options

- Roll the value spell's die for every entry with `value_spell`: moves the Necromancer manifest (501997 script_hit
  803779 tick: mean 310.99999999999994 to 311.0, sigma 5.7e-14 to 0.0, float noise from rolling one value through a
  different path), so the Necromancer 23 snapshot digest would move.
- An opt-in `value_rolls` flag on `script_hit`, set only on the entries that need it.

## Decision

`script_hit` takes `value_rolls: true`, refused (unmodelled) without `value_spell`. With it, `rolled_values` reads
EffectBasePoints and EffectDieSides of (`value_spell`, `value_effect`), forces each roll on that effect and rereads
the tooltip, keyed by the hit's school effect index that `value_readout` remaps the value onto. Without it the hit
spell's die is rolled as before. The record carries `value_rolls` so the measured model rolls the same way.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical; the Necromancer float-noise difference
  is recorded here, not adopted.
- Witch Hunter: the two 680275 entries (`ranged_auto_strike`, `ranged_auto_strike_ap`) set the flag; their reference
  moves from mean 92.0, sigma 0.0, tooltip mean 92.55, 1 cast needed to mean 92.5, sigma 0.5, tooltip mean 93.05, 2
  casts needed. No other Witch Hunter `value_spell` entry sets it.
- Seeded tests in `test_hits.py` (`ValueSpellRollTest`): both rolls 57 and 58 plus 0.15 x the ranged attack power;
  the mutant that rolls the hit spell keeps one value and sigma 0.0 and must differ; the flag without `value_spell`
  is refused; the record holds the key only when set and refuses a non-boolean.
