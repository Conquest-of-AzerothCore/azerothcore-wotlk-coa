# 1198. Ratio-only arms, single-landing durations, no-cast dispel arms, equip and movement kinds

- Status: proposed (provisional number; renumbered at merge, guide 14.4)
- Date: 2026-11-22
- Related: [ADR 0582](0582-metric-delta-options-are-modules.md) (option modules),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (evidence classes),
  [ADR 0160](0160-judge-a-script-cast-hit-against-the-tooltip-that-states-it.md) (script hits),
  [ADR 0900](0900-a-proc-rate-can-count-avoided-swings.md) (avoided trigger), [ADR 1197](1197-opt-in-fixture-fields-a-cooldown-tick-cut-kind-and-ground-effect-reach-reads.md).
- Decided by: mentor D-163 (Sun Cleric tool group 6) and D-166 (script hit avoidance), controller approval of each
  design note.

## Context

Sun Cleric claims state an amount as a percent of another amount of the same phase (301011 "heals ... for $s1% of
the amount it heals you", 800612 "$s1% of the damage dealt", 803913 "mana equal to $807451s1% of the damage dealt"),
a stun reduction that the three-landing duration scenario reads on a diminished re-application (704581), and a
disease count that needs a control without the cast (504848). The absolute totals of the first three are not stated
by any data, and the mana is truncated per strike.

## Options

- A new `total_ratio` kind (design g6 need 1). Rejected: the `metric_delta` option `ally_arm` already reads arms after
  each main reading and judges a ratio of their deltas; it lacked only caster-only arms, arms without an absolute
  expectation, a truncation band and a summed denominator.
- Change the defaults of `duration_ratio`, `dispel_count` and `script_hit`. Rejected: Templar and Witch Hunter use the
  first two, and their scenarios would move.
- Opt-in fields, absent by default.

## Decision

- `ally_arm`: `allies: 0` (no ally player, no group step); ratio-only arms (`count_metric` in place of
  `before_expected`, `expected`, `tolerance`), judged only through a ratio, which is unmeasured unless every
  ratio-only arm's count moved; a ratio's `denominator` may be a list of ratio-only arms, summed; `floor_count`
  widens only the low end by the counted events over the denominator (one unit per truncated event), with a
  tolerance below 10% of `expected` and the ratio unmeasured when the widened band no longer excludes 10% below.
  A precondition arm (ADR 1199) is never ratio-only, and no ratio names it, in a denominator list or as
  `floor_count` included.
- `duration_ratio`: `attempts` (1 to 3, default 3) and `margin_ms` (mentor D-170). With `margin_ms` each phase reads
  the game time after its last landing and after its read; the expected delta is the vehicle's full DBC duration
  times (tooltip ratio - 1), never a reading; the margin is `margin_ms` plus the tick overshoot; the trial is void
  (unmeasured) unless the before read plus its elapsed time equals the full duration and both reads share one landing
  offset, each within the margin, and unmeasured unless the margin stays below 10% of the expected delta.
  Fix round (review I3/I4, controller approval): the judged delta is the one between the landing-corrected durations,
  each read plus its elapsed time, so a difference of the landing offsets no longer adds to the tolerance, and a
  margin at or above 10% of the expected delta is refused (unmeasured) whatever the reads, so the 10% exclusion holds
  by construction. The verdict's `measured` is the ratio of the landing-corrected durations, on the same scale as its
  `low` and `high` (full duration x ratio +- margin over the full duration), so an ok verdict always reads inside its
  band (704581, pair2 reads: 8003 / 10003 = 0.80006 against 0.7925 to 0.8075, where the raw read ratio was 0.789).
- `off_hand_weapons` entries may state `grants`, spell ids the `hit_ratio` off-hand path learns right before the
  equip (other off-hand callers ignore them).
- `dispel_count` arms: `learns` (learned before the arm, unlearned after) and `cast: false` (a no-cast control that
  expects no removal).
- `script_hit`: `caster_avoidance {dodge, parry}` set before each trial with a hostile melee striker in place of
  `strike_spell`.
- Kind module `equip_grant`: a grant learned between a refused and an accepted off-hand equip, read with
  `equipped_item` (Valkyr's Grip 707072).
- Kind module `move_under_aura` (mentor D-171): a movement step sent through the existing `client_packet` action
  (`MSG_MOVE_START_FORWARD`, `MSG_MOVE_STOP`, consumed false), with a control move without the aura that must move the
  player, then the same move under the aura (Sunstorm 760379). No harness action is added.
- `coverage` (mentor D-171): the `casting` state read is promised by `interrupt\w*` as well (547214 c110).
- Harness read `melee_missed_taken` (mentor D-175, tool note for the owner, G-39): the attacker-state packets whose
  victim is the player and whose hit info carries `HITINFO_MISS`, counted per attacker beside
  `meleeVictimStatesTakenFrom` in the packet handler that already parses them; optional `target` (the attacker). It
  touches no game state and changes no existing read. The opt-in `proc_avoided` field `count_misses` (misses in the
  avoided-swing denominator, with a trial voided unless attacks taken = hits + misses + avoided) is approved but not
  built on this branch: the balance check needs a hook in the shared proc trial judge.

## Consequences

- Witch Hunter 15, Templar 19 (with `--stack`) and Necromancer 23 regenerate byte-identical and their coverage audits
  are identical before and after. The fix round's verdict change is reachable only through a model carrying
  `margin_ms`, which no finished-class entry states (their `duration_ratio` entries have none), and it leaves the
  generated scenarios unchanged.
- An unmeasured ratio is not behaviour evidence (tested through `clause_coverage`).
- Known limit of the default path, for the owner (G-39), unchanged here: without `margin_ms` the judge expects
  `before x (ratio - 1)`, a reduction of the remaining time read after the settle, while both reads are taken the same
  time after their landing, so the true delta is `full x (ratio - 1)`; the two differ by `elapsed x (1 - ratio)`
  (about 100 ms for a 20% reduction read 500 ms after landing), which the default 500 ms margin absorbs and hides.
  Measured on 704581 (Stun 2880, 10000 ms): 9494 then 7494 ms, delta -2000 ms against the default model's -1898.8 ms.
- 807507 c408 and 807873 c415 stay tool gaps: 10% of their expected 381.6 ms delta is below any tick margin; an exact
  read needs a player aura maximum-duration harness read, not built here.
