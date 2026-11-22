# 1161. After-trigger casts can run in the control phase and keep a running cooldown

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1028

## Context

`after_trigger_casts` makes real casts after the treatment trigger only, each with its cooldown reset first. Two
Witch Doctor claims need a cast after the trigger whose result depends on the gate, with the same cast in the control
phase, and one of them needs a second attempt of a spell whose cooldown the first cast started:

- A Price To Pay 705948: "Spirit Glaives used in this way will reduce the cooldown of Shadowstalker by 15 sec": a
  Glaive after Spirit Eclipse with 5 Spirits (tool gap of claim 232.0).
- Overflowing Juju 705844: "and cause your next cast to incur a 10 sec reduced cooldown": a Bad Juju after the proc,
  then a recast attempt timed against its reduced cooldown (claim 170.0, tool note "cost_gate cooldown waits").

## Decision

Each item of `after_trigger_casts` takes two optional booleans: `in_before` (also cast in the control phase, which
must then cast the trigger) and `reset_cooldown` (default true; false leaves the cooldown running, so the cast is an
attempt that the cooldown may refuse). The contract names both when either is used.

## Consequences

Opt-in only: without the fields the steps and the contract are unchanged, and classes 19 (with and without
`--stack`) and 23 generate byte-identical scenarios. Class 13 gains 705948 `stalker_cut` and 705844
`next_cut_early` and `next_cut_late`.
