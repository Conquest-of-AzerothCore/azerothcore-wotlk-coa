# 0630. A minion damage modifier is read on alternating swing windows

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0541

## Context

Two Necromancer claims state a percent on a minion's damage and were data only (mentor ruling, cycle 8): 147.1,
Rotting Flesh 574138 "increasing their damage dealt by $573131s1% per stack" (573131, a summon aura, aura 79
SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, 2% per stack, 10 stacks), and 198.0, Fetid Mark 706948 "increases the damage the
target takes from your Skeletal Warriors by $706949s1%" (706949 on the target, 1% per stack, 10 stacks, applied by
`Mark()` in `ModifyMeleeDamage`). The mentor (cycle 9, 21:32) asked for one two-arm minion swing kind, with the
contrast in the evidence. `minion_swing_ratio` compares a strike with the same minion's swings; there is no arm
without the modifier. A minion's swing rolls level x weight to 1.5 x that, plus its attack power, so a 2-point band on
a 10% bonus needs a narrow spread or about a thousand swings per arm.

## Options

1. Two scenarios, with and without the aura: two minions, two raises, drift between runs.
2. One scenario, the aura set and removed in alternating windows on the same minion, with a high caster spell power
   (Scale() turns it into the minion's attack power) to narrow the spread.

## Decision

Option 2, kind `minion_swing_arms` (kinds/minion_swing_arms.py): `windows` control and treatment windows alternate;
each removes the aura, a treatment window sets it at `stacks` (on the owner for a summon aura, on the dummy with the
caster as caster), and the minion's plain swings are counted over `window_ms`. The aura is read at each window end;
an arm that did not hold is unmeasured. The judge reads the per-swing means with the hit ratio judge's per-window
sample and 99% interval rules (`bonus.bonus_of`, `bonus_status`) against `stacks` x the DBC amount, which the entry's
`expected` must equal; the band is G-19. An entry without a treatment aura is refused at generation. The verdict
stamps `minion_swing_arm_damage`, registered `event` by the kind module (no base row is overridden, so
`KIND_ROW_OVERRIDES` stays empty).

## Consequences

- The contrast is in every verdict: a missing or unheld arm is unmeasured, and an ok needs the 99% interval of the
  bonus inside the band and away from 0.
- Uncounted pilots 20261113-205010 and -205142 (raw reads, 20000 spell power): Ghoul swings 1177 / 1416 (8 windows)
  and 1181 / 1418 (24 windows), Skeletal Warrior 1187 / 1303 and 1191 / 1306; the aura read 1 Ghoul and 10 stacks in
  every treatment window and 0 in every control window.
- Seeded tests and mutants: kinds/test_minion_swing_arms.py. Templar has no entry of the kind; Templar
  `generate --class 19` and `--stack` are byte-identical to 628582dc78.
