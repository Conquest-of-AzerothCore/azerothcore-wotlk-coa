# 0737. A cost gate dummy can be another creature

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 18.1 (Vishas' Memoir 300795, "the cooldown of Brand of the Unworthy") has no reading: Brand of
the Unworthy 501380 is refused with `SPELL_FAILED_BAD_TARGETS` unless its target is a Humanoid, Demon or Undead
(`AscensionWitchHunterAbilities.cpp:235-236`), and the `cost_gate` dummy is Harvest Golem 36 (Mechanical), so every
arm was refused. Gap design P3 (c13 gap designs), mentor ruling D-201.

## Options

- An optional `target_entry` on `cost_gate`, which replaces the dummy's creature entry, as `metric_delta` and
  `hit_ratio` already allow.
- A second creature in the scenario: the arms cast at the dummy id, so a swap is enough.

## Decision

`target_entry`, for a dummy target only. The read stays the cooldown gate's `cast_failure`.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the entry changes only the dummy's creature entry and the contract (same steps and models); an entry
  without the dummy target or with a non-positive entry is refused. It adds no check, so there is no mutant.
- Witch Hunter: `300795 cost_gate 501380 unworthy` (without, with, beyond) on Kobold Vermin 6.
