# 1005. A metric delta can stop an Auto Shot by leaving its range

- Status: draft; window figures superseded by [ADR 1008](1008-two-metric-delta-options-promise-their-own-claim-words.md)
- Date: 2026-11-17
- Builds on: ADR 0582, ADR 0993

## Context

Defender of Darkshire 705531 ("... increase the melee haste of your Shadow Hounds by $573266s1% for $573266d.") is
procced by every critical ranged auto attack. The `hound_haste` entry reads the haste, but the continuing Auto Shot
refreshes 573266, so no read can show its 5000 ms end. The nf-a stop proposed a `stop_attack` step after the trigger
cast; by code reading the harness `stop_attack` calls `Unit::AttackStop`, which interrupts `CURRENT_MELEE_SPELL` only
(`Unit.cpp:8357`), while Auto Shot is `CURRENT_AUTOREPEAT_SPELL`, cancelled only by
`HandleCancelAutoRepeatSpellOpcode` (`SpellHandler.cpp:675-679`), which no harness action sends. Mentor D-468 chose the
existing `relocate` action over a new harness action (no harness C++), with the shot count read in the contract.

## Decision

A `metric_delta` option module `stop_shooting_after_ms` (opt-in): `{"ms", "dx", "spell", "target"}`. `ms` after the
treatment cast it reads the game time and the trigger's logged hit count at the target, then moves the caster `dx` yd
along x (relocate steps of at most 20 yd, the action's limit) beyond the spell's range, so
`Unit::_UpdateAutoRepeatSpell`'s `CheckCast` fails and no shot fires (`Unit.cpp:4740-4751`; Auto Shot is not
interrupted, it stays idle). The hit count is read again before the after and the expired readings. The before phase,
which casts no trigger under `trigger_only_after`, repeats the setup casts so the measured creature exists in it.

The metric delta's judge and its `game_time` windows are unchanged; the option makes the verdict `unmeasured` when no
hit landed before the move, any hit landed after it, the move came more than `ms` + 25 ms after the cast, or a read is
missing. The aura therefore started within `ms` + 25 ms of the cast stamp, and the entry's windows are sized for that
start (Witch Hunter: after 4825..4975 ms, expired 5375..5495 ms with `ms` 300 (ADR 1008; first 5375..5475), so 4500
and 5500 ms fail, D-200).
Provisional number, renumbered at merge (14.4).

## Consequences

- Entries without the option generate byte-identical scenarios.
- Seeded tests in `metric_delta_options/test_stop_shooting_after_ms.py`: the step order (one trigger cast, the setup
  cast in both phases, the move after the wait, two 20 yd steps, the hit reads before the judged readings), no move
  without the option, an `ok` reading, alerting mutants (a short and a long aura), `unmeasured` fixtures (no hit, a hit
  after the move, a late move, missing reads) and refused inputs.
- The move relies on the range check of the auto-repeat loop; the hit count is the evidence that it held in each run.
