# 0544. A summon's lifetime is bracketed by game-time polls

- Status: accepted
- Date: 2026-11-13

## Context

Three Necromancer duration claims name the lifetime of a creature a proc summons: Harvest Plague's zombie "for
$525379d" (705747 and 707880, 15 s) and Unholy Erosion's Lesser Zombie "for $302586d" (807700, 10 s). They were
data with "route pending: a lifetime read of the summoned zombie is not built". The proc rolls on a periodic hit,
so the spawn time is not known in advance, and nominal wait sums drift (ADR 0485).

## Decision

- A behaviour kind `summon_lifetime` forces the talent's roll with the mentor-approved forcing fixture (N-a1, effect
  claims only: SPELLMOD_CHANCE_OF_SUCCESS +1000% for the scenario, removed and read gone at the end), casts the
  trigger once without the talent (control: no creature) and once with it, removes the trigger aura after its first
  tick so one creature is summoned, and polls the owned creature count every 25 ms with `game_time_ms` stamps
  around the spawn and around the expected end.
- The judge brackets the lifetime between the bracketed appearance and disappearance and judges it in the G-19 band
  of the stated duration: `ok` inside, `alert` outside or when the control summoned or the fixture remains,
  `measured` across an edge, `unmeasured` when a window misses its edge or holds more than one creature.
- No harness C++ change. Other entries generate the same scenarios (Templar `generate --class 19` and `--stack`
  byte-identical).

## Consequences

- Ledger claims 190.1, 216.1 and 289.1 gain the `zombie_lifetime` label next to their duration data label. The
  chance claims stay with their proc-rate entries; the forced roll proves no rate.
- Tests: `SummonLifetimeTests` (test_behaviours.py).
