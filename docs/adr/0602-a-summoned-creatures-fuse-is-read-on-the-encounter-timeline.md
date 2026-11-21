# 0602. A summoned creature's fuse is read on the encounter timeline

- Status: accepted
- Date: 2026-11-13

## Context

Claim 279.0, Muck Summoner 806086 "and explode after $807640t2 sec", had only data (`aura_amplitude_ms`): the c6 tool
groups listed a creature-entry event-time stream (a spawn and a cast on one stream) as the gap. The `summon_lifetime`
kind cannot stand in: Animate: Muckworm 806087 DurationIndex 28 is also 5000 ms, so a Rotling's lifetime does not tell
an explosion from its summon expiring, and it summons two creatures where the kind needs one.

## Options

- A new harness read of an owned creature's cast times (C++ beyond the existing reads).
- The existing encounter timeline (`encounter_start`, `timeline_first_ms`): it records `spawn` and `cast` events of
  every unit on the map with their source entry, read only.

## Decision

Kind `spawn_fuse` (kinds/spawn_fuse.py): an encounter timeline on the dummy, a forced roll (mentor N-a1) for the
summoning talent, a control without the talent (no spawn), then the first `fuse_spell` cast by the entry minus its
first spawn, judged against `expected_ms` in the G-19 band. No harness change.

## Consequences

- 279.0 fuse: the pilot (stamp 20261113-171035) read 5005 ms against 5000 ms (16 Rotlings spawned, the first at
  11836 ms, the first 500585 cast at 16841 ms). The damage part of the clause stays where it was (Q-b1-1).
- Templar has no entry of this kind; the shared tables are unchanged.
- Test: kinds/test_spawn_fuse.py (step order, band, control and mutant alerts, missing spawn or fuse).
