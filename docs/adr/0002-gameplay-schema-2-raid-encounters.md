# 0002. Extend the in-repo gameplay harness with scenario schema 2 for raid encounters

- Status: accepted
- Date: 2026-10-25

## Context

The in-process gameplay harness (`src/server/coa/CoAGameplayTest.cpp`, `apps/coa-gameplay-test/run.py`) runs
scenarios of up to eight players and ten minutes. Testing a raid boss encounter needs a 10 to 25 player raid, a
fight that lasts up to twenty minutes, scripted role behavior (tank, healer, damage) and assertions on how the
fight unfolds over time.

## Considered options

1. Extend the in-repo harness with a second scenario schema.
2. Drive encounters with mod-playerbots.
3. Drive encounters with the Ghost protocol bot.

## Decision

Option 1. Scenario `"schema": 2` is accepted next to schema 1:

- Schema 2 allows 1..25 players and `timeout_ms` up to 1200000 (20 minutes). Creature fixtures stay at eight and
  steps at 10,000. Schema 1 keeps 1..8 players and 600000 ms, with unchanged messages except the player count
  message, which now names the limit of the scenario's schema.
- Bots are C++ role routines inside the harness, selected by name from the scenario. Scenario JSON stays
  declarative and gains no control flow (loops, conditions, variables).
- Timeline checks reuse the existing `assert` and snapshot machinery; no second assertion framework is added.

- A living tank bot holds a threat floor on the boss (110 percent of the highest non-tank threat plus 100, each
  tick). It is a test fixture, not threat realism: it makes the tank the victim deterministically and masks
  threat-wipe mechanics while the tank lives. It stops when no tank is alive, so a tank death still shows.
- A case with `encounter_start` runs exclusively, because the timeline recorder is process-wide; batching puts such
  cases on exclusive lanes.

Option 2 is heavy to embed and brings no assertion framework. Option 3 was rejected for reasons read in
`~/Projects/ConquestOfAzerothGhost` (head `ee9c9cc`): its README states the goal as E2E testing of classes, talents
and features; its Go client library has no role routines, and its Lua AI (`scripts/ai/`) provides class rotations
for the ten stock classes only, not the CoA classes; its Molten Core raid tests (`e2e/zzmcraid/`) drive a raid with
raw opcodes and GM commands such as `.modify hp`, and read server state by parsing chat output (for example
`.npc info` health and position), so `enter_combat`, evade and boss state transitions are inferred from chat and
server logs rather than recorded as timestamped events. Ghost stays the end-to-end network test.

## Consequences

- Schema 2 scenarios cannot run on a harness built before this change; the Python validator and the C++ loader
  mirror the same limits and must change together.
- Raid role routines and timeline metrics become C++ surface that needs its own tests.
- Longer scenarios raise the cost of each gameplay batch.
