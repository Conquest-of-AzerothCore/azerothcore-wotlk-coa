# 0637. A minion crit gate is bracketed by two swing intervals

- Status: accepted
- Date: 2026-11-13
- Builds on: Necromancer ADR 0045

## Context

Necromancer claim 105.0, Dominion of Frost 537208 "Can only occur once per sec.": a minion crit cuts Unholy Frenzy
805029 by 3000 ms through `Chance(player, 537208, 1, 1000)`. `minion_crit_gate` (Necromancer ADR 0045) uses two minions
that both swing every 2000 ms with an unread offset d, so every gate in (d, 2000 - d) gives the same cut pattern: its
cast-gate attempts bracket the gate without pinning 1000 ms (cycle 9 design flag, mentor-approved design).

## Options

- More minions or more attempts at 2000 ms: the unread offset still hides the gate.
- One minion at two swing intervals set by a haste aura amount, the stated gate binding in one arm only.

## Decision

Kind `minion_haste_gate` (kinds/minion_haste_gate.py, no C++). One minion attacks the dummy with the caster, forced to
crit, its swing interval set by an owned-creature haste aura at a harness amount (a whole percent of the base attack
time). Two arms: one interval above the stated gate (every crit cuts) and one below it (every other crit is gated).
In each arm the observed spell is cast, its own auras are cleared from the caster and the minion, its attack time is
read (within 1% of the arm's, else unmeasured), then the spell is attempted early (refused) and late (cast). The spec
rejects attempt times that do not separate the stated gate from the next slower and, in the gated arm, the ungated
pattern, with a 10% timing margin. The metric is `cast_failure`, an event read.

## Consequences

- For 537208 at 1250 and 800 ms the gate is bracketed between 800 and 1250 ms instead of (d, 2000 - d).
- Seeded tests in kinds/test_minion_haste_gate.py: the stated gate passes; an ungated cut, a gate above the slow
  interval and a gate above two fast intervals alert; a minion off its interval or with too few crits is unmeasured;
  attempts that cannot separate the gate are refused.
- Cycle 10 integration (mentor, 22:03): the 800-1250 ms bracket is wider than the 5% band, so a second 537208 entry,
  `once_per_sec_band`, swings at 1047 ms (+91% haste) and 952 ms (+110%) and puts the gate in 952..1047 ms. An arm's
  interval is now the truncated `base x 100 / (100 + haste)`, as the server's int32 swing timer is
  (`Unit::resetAttackTimer`, `GetAttackTime`), instead of an exact division; seeded test: the band arms set haste 91
  and 110 and accept every 1047 and 1904 ms.
