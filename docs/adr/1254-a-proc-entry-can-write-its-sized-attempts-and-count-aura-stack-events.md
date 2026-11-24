# 1254. A proc entry can write its sized attempts and count aura stack events

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

Two Felsworn proc claims could not be expressed by `procs`:

- Chaotic 681376 ($h% = 8%) needs `residual_target` 0.001 with `min_detectable` 4 points: 8918 trials, 13377 attempts
  with the 1.5x outcome margin. The band sizing schedules 7326, so generate refused the entry as under-sized; the entry
  had been loosened to `min_detectable` 5, which left a false alert of 9.11e-03 per pair at the scheduled trials.
  Mentor ruling D-70: keep the default sizing cap, add a per-entry override carrying the sized number, never loosen
  `min_detectable`, fit the stage timeout by parts and pool them by the existing rule.
- Azzinoth's Battery 705137 and Illidari Magi 560639 change a stack count of Felfury (aura 800058), with no spell cast
  to count. 705137 is the preserve chance of the Azzinoth's Assault 801904 cost rule (2 stacks,
  `PreserveCostChancePercent` 30, `AscensionCustomResourceData.h:520-521`, skipped consumption at
  `AscensionCompat.cpp:3475-3479`); the first entry counted the 801024 trigger spell, which the server never casts, and
  every cast was refused for want of Felfury. 560639 calls `Gain(player, 1)` on a periodic damage event
  (`AscensionFelswornEvents.cpp:86-88, 172-176`), while its Bane of Chaos 704368 trigger itself gains 1 stack per
  completed cast (`ResourceGainRules`, `AscensionCustomResourceData.h:116`). The harness counts first aura applications
  only (`AuraApplyCounter`), not stack changes.

## Decision

- `sized_attempts` (procs entry, opt-in): the scheduled attempts. Refused below the band sizing default and without
  `residual_target`; the residual check still applies. Parts and attempts per part come from the existing
  `PART_BUDGET_MS` split, so every part fits the stage timeout; the judge pools parts as for every proc entry. Judge,
  band and `min_detectable` are unchanged.
- `event_metric: "aura_stacks"` (module `proc_stacks.py`, opt-in) on a cast trigger, with `stack_aura`, `stack_set`
  and the signed `stack_per_cast` (the change a completed cast makes without a proc, from the server's resource rules).
  `attempt_auras` must set `stack_aura` to `stack_set` on the caster before each cast, as a named precondition fixture,
  not the subject. The stacks are read after each cast; the drain is one more window, reset before it and read after it,
  so late periodic events are read like the trials they add. Events = sum of the reads - `stack_set` x windows -
  `stack_per_cast` x completed casts (`spell_cast_count`), `events_per_proc` per proc: a refused cast reads
  `stack_set` and adds none. The baseline arm is required: the same casts and reads before the passive is learned,
  with its own completed-cast count, must give no event; generate refuses the entry without it and the judge returns
  `insufficient_trials` when no counted part holds it. The Wilson judge is unchanged.

## Uses

| Entry | Field | Value | Basis |
|---|---|---|---|
| 681376 Chaotic | `sized_attempts` | 13377 (min_detectable 5 -> 4, 65 parts of 206) | residual sizing, mentor D-70 |
| 705137 Azzinoth's Battery | `aura_stacks` | stack_set 2, stack_per_cast -2, events_per_proc 2 | AscensionCustomResourceData.h:520-521 |
| 560639 Illidari Magi | `aura_stacks` | stack_set 1, stack_per_cast +1, events_per_proc 1 | AscensionCustomResourceData.h:116, AscensionFelswornEvents.cpp:172-176 |

## Consequences

- Entries without the fields generate byte-identical scenarios.
- A per-attempt read is one measurement per cast (the `spell_charges` precedent).
- 805245 Demonic Fortitude and 804822 Vengeance Is Mine stay open: the first needs an avoided trigger that holds a
  condition aura (B-7), the second gains per Twin Slice hit, not by chance.
- Tests: `SizedAttemptsTest`, `AuraStackEntryTest`, `AuraStackCompareTest` (test_procs.py).
