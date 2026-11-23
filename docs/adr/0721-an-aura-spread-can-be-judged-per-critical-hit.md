# 0721. An aura spread can be judged per critical hit

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Strafing Shot 705515 (Witch Hunter): "Critical strikes with ranged abilities now spread Tormentor to a nearby enemy".
The aura spread count with `force_crit` (ADR 0701) saw every critical shot copy Tormentor (0 of 2 before, 2 of 2
after), which a count of afflicted dummies cannot tell from "one copy per cast", and the seed Tormentor crits under the
same fixture (c11-tool stop on claim 265.0). Mentor decision D-173 (c12 tool batch item 14): copies per crit ratio 1.0,
talent learned after the seed, control 0, a crit-count read.

## Options

- A kind that reads the crits on the primary and the copies on free spare dummies around one forced-crit cast per arm.
- A harness crit counter: `spell_damage_count` already filters `critical`, so no harness change is needed.

## Decision

`kinds/spread_per_crit.py`: the seed before the learn in both arms, crits of `hit_spells` and spare auras read before
and after the cast; new copies must equal new crits, the control none. No harness C++ was changed.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (a new kind).
- Seeded tests: one copy for several crits and a copy without the talent alert; a saturated or crit-less arm is
  unmeasured.
- Witch Hunter: `705515 behaviour_metric_delta spread_per_crit`.
