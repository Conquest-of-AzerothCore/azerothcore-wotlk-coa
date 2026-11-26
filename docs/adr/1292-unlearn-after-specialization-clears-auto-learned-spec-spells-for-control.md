# 1292. `unlearn_after_specialization` clears auto-learned spec spells for the control arm

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25

## Context

Cultist Herald of the Depths 92131 (row 7, "Teaches you Herald of the Depths.") and Dreadnought 680750 (row 254,
"Teaches you Dreadnought.") are level-10 automatic specialization passives (`AscensionTaughtAbilityData.h:35-36`:
spec 40 teaches `520326`, spec 96 teaches `567524`). `SynchronizeTaughtAbilities` (`AscensionCompat.cpp:1082-1104`)
teaches the active spell only when the caster holds the matching specialization.

With `specialization` (`ORDER = 26`, ADR 1102), switching to spec 40 or 96 at level 60 runs
`SynchronizeAutomaticTalents` and `SynchronizeTaughtAbilities` in the `before` phase, auto-learning both the passive
and the taught active ability before the control `knows_spell` read (reading `1` before instead of `0`).
`unlearn_before` runs at `ORDER = 20`, before `specialization`, so it cannot clear spells granted by the spec switch.
Orchestrator decision D-39 approved an opt-in `unlearn_after_specialization` option (design note from `cu-t1`, reviewed
clean by `cu-rt1`).

## Decision

- Add opt-in `metric_delta` option module `unlearn_after_specialization`
  ([doc](../../apps/coa-gameplay-test/conformance/docs/metric_delta_options/unlearn_after_specialization.md)) at
  `ORDER = 27` (strictly after `specialization` at `ORDER = 26`).
- Accept a non-empty list of distinct positive spell ids; refuse any entry that does not also set `specialization`.
- In `phase_steps(spec, spells, after)`, emit `{'action': 'unlearn', 'actor': CASTER, 'spell': spell}` for each spell
  when `after` is false (and nothing when `after` is true), so the control arm reads `0` inside the required
  specialization and the `learn` between phases teaches the spell for `1`.

## Consequences

- Opt-in: absent, no scenario changes and finished classes regenerate byte-identical.
- Zero C++ harness changes and zero judge changes (`knows_spell` is already classified as `STATE` with `teach\w*|learn\w*`
  promise).
- Seeded tests in `test_unlearn_after_specialization.py` verify step ordering (`specialization < unlearn < before <
  learn < after`), absent no-op, `ok`, mutant alerts, and refusal without `specialization` or with invalid inputs.
