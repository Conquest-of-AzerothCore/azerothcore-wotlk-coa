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

Option 2 is heavy to embed and brings no assertion framework. Option 3 has no raid or encounter opcodes.

## Consequences

- Schema 2 scenarios cannot run on a harness built before this change; the Python validator and the C++ loader
  mirror the same limits and must change together.
- Raid role routines and timeline metrics become C++ surface that needs its own tests.
- Longer scenarios raise the cost of each gameplay batch.
