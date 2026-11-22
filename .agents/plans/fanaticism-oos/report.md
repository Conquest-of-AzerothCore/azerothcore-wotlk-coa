# Fanaticism 805628 out-of-sample test (mentor D-61, condition 2): all eight readings inside

Prediction commit (before any arm ran): `95f8ff6c99` (`prediction.md`, `predict.py`). Entries commit: `1a5de3fb58`.
Pair: runs `20261122-024352` and `20261122-024635`, one worldserver build `ae5062c3e291...`, server commit `1a5de3fb58f1`,
no flip (all five verdicts `ok` in both runs). Both runs `INCOMPLETE` as exploratory files are (85/85 scenarios passed each).
Judged files: `pair/run1`, `pair/run2` (`verdicts.json`, `alerts.tsv`, `report.md`), reports and logs in `pair/verify-run1`, `-run2`.

## Setup actually used

- The Valkyr set is **not** new: `spell_weapon_sets` maps 805628 to Valkyr and the ADR 0008 rolls are item 2529. A per-entry
  weapon set (the Piety staff 2030) needs a tool change, so I did not do it (not mine to touch). The new setup is two
  stat inputs: attack power 70 -> 280 (fixture `attack_power` 210) and target creature 603 Grimtooth (armor 3750, was 528
  on creature 36). Weapon, flat values, percent and resist unchanged.
- Validity reads (rule 6 of the prediction), both runs: `attack_power` read 280 in all 84 hit-ratio scenarios; the
  diagnostic `dummy_armor_oos` read armor 3750 (verdict `ok`, tolerance 0.5); `weapon_damage_min` read 129.62 = 73.62 + 280/14 x 2.8.
- Horusath Blast carries no AP term and the target has no resistance: its prediction is unchanged (+19.34%); its readings test
  "no attack power term, no resistance of creature 603" and replicate ADR 0008, they are not a new weapon/armor point.

## Readings against the pre-registered predictions (non-critical hits, bonus in %, G-19 band +/- 2.00 for all)

| Spell | Predicted | Run 1 (99% half) | Run 2 (99% half) | Deviation 1 / 2 | Casts per arm |
|---|---|---|---|---|---|
| Gavel of Wrath 800617 | +25.37 | +25.57 (0.57) | +25.08 (0.56) | +0.20 / -0.29 | 1400 |
| Gavel of Grace 800614 | +22.70 | +22.71 (0.55) | +22.85 (0.56) | +0.00 / +0.14 | 1600 |
| Gavel of Light 800611 | +21.11 | +21.22 (0.55) | +21.02 (0.55) | +0.12 / -0.08 | 1900 |
| Horusath Blast 500154 | +19.34 | +19.53 (0.74) | +19.18 (0.75) | +0.19 / -0.16 | 3500 |

Predictions are `predict.py 3750 280`: Wrath +25.3666, Grace +22.7046, Light +21.1057, Horusath +19.3356 (entries carry the
ratios to four decimals, so the verdict's expected differs by under 0.004 points). The measured half-widths equal the
predicted 99% half-widths (0.56 / 0.56 / 0.55 / 0.73), so almost every cast gave a non-critical hit.

Pre-registered rules: (2) inside the G-19 band: yes, 8 of 8, largest deviation 0.29 points. (3) predicted bonus inside the
reading's own z = 3.84 interval: yes, 8 of 8. (4) inside the 99% interval: yes, 8 of 8. No stop condition holds. The model of ADR 0008
predicted the new mean hits too (Wrath without 121.79, with 152.69, from the enumeration); the counted readings are bonuses.
Residual failure probability of a false stop: stated in `prediction.md` (rule 5), at most 0.1% per pair.

Reference search: nothing found for creature 603 or an attack-power dependence of Fanaticism (ADR 0008's search stands).

## Not claimed

- The bonus is nearly armor-independent (Wrath +27.11 at armor 3750, 70 AP, against +27.14 at 528); the armor term is
  therefore checked through the new inputs together, not alone. The AP step moves the Gavels by 1.8, 1.2 and 0.6 points.
- Not tested: a different weapon (Piety staff, tool change needed), a different level, spell power.
- The controller fills the four claims' ledger labels; I changed no ledger label and no existing expectation.

## Housekeeping

Source stage: `VERIFY ALL: PASSED` (`.cache/verify-all/20261122-024812/report.json`, source 52 passed, 0 failed,
`--base origin/main`). Gameplay with `--gameplay-db-workers 4`, in-RAM MySQL. Disk checked before each run (89 GB free, 91%).
Agent-minutes 13.5 (progress timestamps 03:35:56 to 03:49:27+01:00, +01:00). Tokens: the controller measures them.
Commits: `95f8ff6c99` prediction, `1a5de3fb58` entries, plus the report commit on this branch. No push.
