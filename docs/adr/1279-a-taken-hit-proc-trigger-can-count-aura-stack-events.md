# 1279. A taken-hit proc trigger can count aura stack events

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

Demonic Fortitude 805245: "While Demonic Will or Hateforged Barrier are active, all damage taken or avoided now has a
$h% chance to generate 1 Felfury." Its proc gains a Felfury 800058 stack (`Gain(player, 1)`,
AscensionFelswornEvents.cpp:173-175) and casts no spell, so its events are stack changes (ADR 1254). The avoided leg
uses an avoided trigger with stack events (ADR 1261). The damage-taken leg needs the `taken_hit` trigger (a striker's
spell hits the caster), which refused both `aura_stacks` events and `attempt_auras`, so the condition (Demonic Will
800209) could not be held and the gain could not be read.

## Considered options

- A new kind for stack gains on hits taken: duplicates the proc rate judge.
- `aura_stacks` and `attempt_auras` accepted on `taken_hit`, with the avoided trigger's constraints (chosen).

## Decision

- `proc_stacks.counts_stacks` accepts a `taken_hit` trigger with `stack_per_cast` 0 and a whole `stack_cap` above
  `stack_set`, as for the avoided trigger; the stack model carries the cap (`proc_stacks.CAPPED_TRIGGERS`).
- `procs.attempt_auras` accepts a `taken_hit` trigger only with `aura_stacks` events; the auras are set before every
  strike (`procs.taken_hit_attempts`), and the stack aura is read after every strike interval and after the drain.
- The baseline strikes before the passive is learned hold the same fixtures and reads; their landed hits stand in for
  the completed casts in the baseline stack model (the term is 0).
- `compare.py` is not changed: events = the sum of the reads - `stack_set` x the intervals; the trials stay the
  striker's landed hits on the caster; a read at the cap voids the part (ADR 1261).
- Opt-in: a `taken_hit` entry without `aura_stacks` generates the same scenario as before.

## Consequences

- Classes 15, 19, 19 --stack, 23 and 27 regenerate byte-identical (Witch Hunter keeps its `taken_hit` entry
  unchanged).
- Felsworn: `805245 proc_rate` reads the damage-taken leg while Demonic Will 800209 is held. Hateforged
  Barrier 705129 as the condition is not read.
- Tests in `test_procs.py`: `TakenHitStackEventsTest` (fixtures before and reads after every strike in both arms, the
  refusals, `attempt_auras` refused without stack events) and `TakenHitStackCompareTest` (stack gains are the events;
  seeded servers at 30% and 10% and a baseline gain alert; a capped read voids the part).
