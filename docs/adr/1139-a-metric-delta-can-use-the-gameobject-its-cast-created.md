# 1139. A metric-delta can use the gameobject its cast created

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582

## Context

Mojo Cauldron 807908 creates gameobject 129364 (type 22 spellcaster, Data0 spell 572413 that creates Major
Rejuvenating Mojo 576135, Data1 25 charges, Data2 party only). The harness reads `owned_gameobject_count` and
`gameobject_remaining_ms` and has `use_gameobject` and `destroy_item`, but the reads had no coverage row and no entry
could use the object (tool note T-b17-1).

## Decision

The option `use_gameobject_after` uses the caster's own object after the treatment cast a stated number of times,
optionally destroying each created item. The module carries the METRIC_EVIDENCE rows (`owned_gameobject_count` event,
`gameobject_remaining_ms` state with the promise `lasts?|duration`).

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
807908 `created`, `lasts`, `mojo_item`, `mojo_cast`, `charges_left` and `charges_spent`. A use by another raid member
needs a harness `owner` field on `use_gameobject` (not built).
