# 0023. Vampire Hunter counts the curse just applied in its damage reduction

- Status: accepted
- Date: 2026-11-17

## Context

Vampire Hunter 803638 reads (server Spell.dbc Description): "When an enemy applies a curse to you, your Magic damage
taken is reduced by 10% for 8 seconds. The damage reduction is increased by 5% and duration is increased by 2 seconds
for every curse active." The buff is 704570: Effect[0] aura 214 with base -10 (EffectBasePoints -11, DieSides 1),
DurationIndex 31 (8000 ms).

`OnAuraApply` in `AscensionWitchHunterDefenses.cpp` counts the harmful curse auras on the player after the enemy curse
is applied, so the count includes it. The duration used `8000 + 2000 * count`, the percent `10 + 5 * (count - 1)`.
The f-b7 pair (20261116-221827 / -221902, worldserver 17b06838948b) and the n343 reproduction (worldserver
dd2bf749, run 20261117-061548) read -10 at one curse and -20 at three against -15 and -25, while the durations read
10000 and 14000 ms.

The tooltip alone left open whether "every curse active" counts the curse just applied. Owner ruling O-35 (card
Q-wh-30, "fix it in a follow-up"), relayed by mentor D-394 with classification D-376: it does, as the duration
already does.

## Options

- Count every active curse for the percent, the new one included (chosen).
- Keep the offset: the percent and the duration keep reading two different counts.

## Decision

The percent becomes `min(95, 10 + 5 * count)`. The cap of 95 and the duration are unchanged. The change is one line
of Witch Hunter code: no SQL, no DBC, no engine file. 704570 is cast only by this handler, and
`AscensionWitchHunterCompletion.cpp` only sets its aura type; no other class reads 803638 or 704570.

## Consequences

- One enemy curse gives -15% for 10 s, two -20% for 12 s, three -25% for 14 s.
- Regressions: `803638 behaviour_metric_delta curse_amount_1`, `curse_amount_2`, `curse_amount_3` and
  `curse_duration_1`, `curse_duration_2`, `curse_duration_3`, each with a control phase without the enemy curse, and
  `curse_control_noncurse` (a non-curse magic hit grants nothing). The two-curse arms read the middle step, so the
  step is read and not only its ends.
