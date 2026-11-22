# Fanaticism 805628 out-of-sample prediction (pre-registered, before any arm of the setup runs)

Model: ADR sun-cleric 0008 (reproduced engine arithmetic), method of `model_check.py` (b4t), ported unchanged to
`predict.py` in this folder with the attack power and the target armor as arguments. Control check of the port:
`python -B predict.py 528 70` gives Wrath +27.14%, Grace +23.85%, Light +21.67%, Horusath +19.34%, the ADR 0008 table.

## Setup (not measured so far)

The Valkyr set itself is **not** new: `spell_weapon_sets` maps 805628 to Valkyr and the ADR 0008 rolls (90..119) are
item 2529. A different weapon set cannot be chosen per entry without a tool change, so the new setup differs by
two stat inputs, both only data:

| Input | Measured so far | Out-of-sample setup | Source |
|---|---|---|---|
| Attack power | 70 | 280 = 70 + fixture `attack_power` 210 | the `attack_power` read of the scenario (`Unit::GetTotalAttackPowerValue`); the fixture adds a flat TOTAL_VALUE of 210 (`CoAGameplayTest.cpp:3029`) |
| Target | creature 36, armor 528 | creature 603 Grimtooth, armor 3750, level 60 set by the fixture | `creature_template` 603 (unit_class 1, ArmorModifier 1, minlevel = maxlevel = 60, no resistance rows, no AI, no script); `creature_classlevelstats` level 60 class 1 basearmor 3750; `min_level_armor` gives `ceil(basearmor x ArmorModifier)` (`CreatureData.h:336`) |
| Weapon | 2529 x2 (Valkyr), 73.62..103.34, 2800 ms | unchanged | `item_template` 2529 |

Weapon roll with AP 280: `uint32(73.62 + 280/14 x 3.3)` .. `uint32(103.34 + 280/14 x 3.3)` = 139..169 (float32).
Flat values, percent, `ceil` armor reduction and the Horusath resist are exactly those of ADR 0008 (DBC 800617 BasePoints 44
die 11, 800614 22 die 4, 800611 11 die 1 with a per-level term below 1, 500154 72 die 12 per level 1.06; read from
`/srv/coa/server-data/dbc`). Horusath Blast is Holy with no AP term: its prediction is unchanged by the new inputs
(the AP fixture tests the ADR's "no attack power term" and the new target tests "no resistance of its own").

## Prediction (`python -B predict.py 3750 280`)

| Spell | Mean hit without | Mean hit with | Predicted bonus | G-19 band (+/- pts) | 99.99% half-width, full casts (pts) | half-width, half the casts (pts) | 99% half-width, full casts (pts) | relative sd without / with |
|---|---|---|---|---|---|---|---|---|
| Gavel of Wrath 800617 | 121.7918 | 152.6862 | +25.37% | 2.00 | 0.84 | 1.18 | 0.56 | 0.047 / 0.045 |
| Gavel of Grace 800614 | 106.6290 | 130.8387 | +22.70% | 2.00 | 0.83 | 1.17 | 0.56 | 0.050 / 0.049 |
| Gavel of Light 800611 | 99.1935 | 120.1290 | +21.11% | 2.00 | 0.82 | 1.15 | 0.55 | 0.054 / 0.054 |
| Horusath Blast 500154 | 73.8708 | 88.1542 | +19.34% | 2.00 | 1.09 | 1.54 | 0.73 | 0.100 / 0.099 |

Sizing = the sizing of the four existing entries: casts per arm Wrath 1400 (14 x 100), Grace 1600 (16 x 100), Light 1900
(19 x 100), Horusath 3500 (35 x 100). Half-widths are the exact enumerated per-hit standard deviations through the
delta method on the ratio of two means, with z = 3.84 (two-sided p 1.23e-04; 8 readings, so at most 9.8e-04 per pair) and
z = 2.576 (99%). "Half the casts lost" is the pessimistic case where half of the casts are critical and not counted.

## Judging rules, fixed now

1. A reading is the bonus of the treatment mean over the control mean of one run, non-critical hits only (the entries'
   `critical: false`), one reading per run and spell: 8 readings.
2. **Inside** = within the G-19 band of the predicted bonus (+/- 2.00 points for all four). Outside in any reading: stop,
   the model goes back to the mentor, no expectation changes.
3. Also a stop: the predicted bonus outside the reading's own interval at z = 3.84.
4. Reported, not a stop: the predicted bonus outside the 99% interval (expected in about 1% of readings).
5. Residual failure probability of a false stop: even with half the casts lost the standard error is at most 0.40
   points (Horusath), so the 2-point band is 5 standard errors (p about 6e-07 per reading); rule 3 contributes at most
   9.8e-04 per pair. The total stays at or below the 0.1% per pair.
6. Validity: the reads of the scenario must be attack power 280 and target armor 3750 in both runs. A different read
   is a setup error, not a model result; `predict.py` is then re-run with the reads as arguments (the script is
   committed here, so the method is fixed) and the report says so. No measured bonus is ever an input.
7. The pair is one build, two runs, no flip. Controls are the entries' own arms (passive not learned vs learned).

Reference search (guide section 4): ADR 0008's search stands (0 combat-log events for the passive and the three Gavel roots);
nothing found for creature 603 or an attack-power dependence of Fanaticism.
