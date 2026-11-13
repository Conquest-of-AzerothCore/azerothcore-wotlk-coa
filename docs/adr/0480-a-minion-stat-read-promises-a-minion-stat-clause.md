# 0480. A minion stat read promises a minion stat clause

- Status: accepted
- Date: 2026-11-13

## Context

Three Necromancer claims state a minion's Stamina: Summoning Expert 807494 "and your Undead minion's Stamina by
$s2%" (Effect[1] 190 with aura 137 MiscValue 2 on the summons) and Sepulchral Might 572638 / 706472 "spell power by
an amount equal to $s1% of the total of your Raised minion's Stamina". The harness read a minion's maximum health,
armor and power, but not its stats; the maximum health follows the class scaling code, so it cannot isolate Stamina.

## Decision

- The harness metric `owned_creature_stat` reads `GetStat(stat)` of the caster's present owned creature of `entry`
  (stat 0 to 4). It is a read only (G-39), beside `owned_creature_armor`.
- `METRIC_EVIDENCE` classes it as a STATE read, and `STATE_PROMISES['owned_creature_stat']` names the five stats: a
  learned contrast of the read proves a clause that states a minion stat.

## Consequences

- Summoning Expert reads one Ghoul's Stamina without and with the talent (ratio 1.10, judged to the rounding).
  Sepulchral Might reads two Ghouls' Stamina and the caster's spell power on one build: the spell power is the stated
  percent of their total.
- Tests: `OwnedCreatureStatPromiseTest` (test_coverage.py), the minion Stamina clause and a Life Force proxy (data).
