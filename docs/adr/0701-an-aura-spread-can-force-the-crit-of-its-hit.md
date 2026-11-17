# 0701. An aura spread can force the crit of its hit

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Strafing Shot 705515 (Witch Hunter) copies the caster's Tormentor 800162 from a unit struck by a ranged critical
hit to one nearby enemy (AscensionWitchHunterEvents.cpp:149-150, 272-297). `AuraSpreadSpec` had no crit fixture and
cast `target_rank` without a target. Mentor decision D-158 (design D-6).

## Options

- An optional `force_crit` on the spread entry: the crit rating fixture on the caster and `target_rank` cast at the
  primary dummy.
- A new kind: more code for the same shape.

## Decision

The first option, refused with `first_tick` or an unknown rating. Absent, the scenario is unchanged. The existing
count judge applies (one copy expected on one of two extra dummies, a placement at the hit's cast distance; a missing copy or a copy on both alerts).

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical.
- Witch Hunter use not proven (cycle 11 tool report): with Witchbane 800165 as the hit, every critical shot copies
  Tormentor to another dummy (pair 20261115-204044 / -204111: 0 of 2 before, 2 of 2 after), so the count of one per
  critical strike needs a single critical hit, and the seed Tormentor crits too under the same fixture.
