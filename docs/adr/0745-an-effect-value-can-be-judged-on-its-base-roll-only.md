# 0745. An effect value can be judged on its base roll only

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 238.0 (Shadow Rage 705455, "deal an additional ${$m3*$<scalingbp>+$RAP*0.15} Shadow Damage") was
split (D-218): the hit labels `804192 script_hit 567570 hound_strike` and its +1000 ranged attack power contrast
`hound_strike_rap` count the whole amount, and `705455 effect_value 804192e2 #1` reads the CalcValue of 804192
effect 2. That read is the base roll only, 56 = int(57 x 0.98743): the server adds the 0.15 x ranged attack power term
in the class script, after CalcValue. `judge_token` compares it with the full token (91.83 at ranged attack power
237), so the label alerts though the base roll is right. Mentor rulings D-219 and D-57 (a modelled effect value with
a power term proves the base roll only; the power term needs a passing hit label of the same claim, with its
contrast arm), D-198 (a flag that lacks its proof is an alert, never a pass), D-195 (opt-in).

## Options

- An opt-in `effect_overrides` entry flag `base_roll_only`, naming the hit label that counts the power term and its
  contrast arm; the judge subtracts the power term and the verdict is accepted only when both labels pass in the
  same comparison.
- Dropping the read: the base roll would no longer be measured by any label.
- Subtracting every power term of every token: it would move verdicts of the finished classes.

## Decision

The opt-in flag. For a flagged `effect_value` of a fixed roll, the judge reads the token a second time with attack
power, ranged attack power and spell power at 0; the difference with the token at the measured stats is the power
term, and the measured value is judged against the remaining base with the usual deterministic band. The verdict
explanation and its `base_roll_only` detail show the full value, the subtracted term and the judged base, with the two
named labels.

After every label is judged, a flagged verdict becomes `alert` when its entry names no `power_term_label` or no
distinct `contrast_label`, when either label is absent from the comparison, is not a hit label, or is not
conformant. A flagged token with no power term, a rolled effect, or a token whose text changes without power is an
alert too.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 hold no flag and regenerate byte-identical (`snapshots.py check`);
  unflagged labels take the unchanged path.
- Seeded tests (`test_compare.py`): unflagged, the token is judged on its full value (alert); flagged, it is judged
  on its base with the full value, term and base shown; flagged off the base alerts; flagged with both labels passing
  is accepted; flagged without named labels, with labels absent from the comparison, with a failing, unmeasured,
  missing or non-hit contrast, or on a token without a power term, alerts.
- Witch Hunter: the 804192 effect 2 entry carries the flag with `804192 script_hit 567570 hound_strike` and
  `804192 script_hit 567570 hound_strike_rap`.
