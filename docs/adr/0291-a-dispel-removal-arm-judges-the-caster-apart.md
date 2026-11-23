# 0291. A dispel-removal arm judges the caster apart from its target

- Status: accepted
- Date: 2026-11-12

## Context

A `dispel_removal` entry with `arms` casts its spell at each arm's target and reads the debuffs on the caster and on
that target. Each arm carries one `removed` flag, and both units are judged against it.

The owner ruled on Silverhand Incantation 801465 ("and removing Sacred Restraint from you and them if they are an
ally", status-5 Q4, option (a)): Sacred Restraint 102208 leaves the caster on every cast that goes through, and leaves
the target only when the target is an ally. A cast at a hostile unit therefore removes the debuff from one unit and
keeps it on the other, which a single flag cannot state.

## Considered options

1. Split the hostile arm into two entries, one per unit. Rejected: both entries would cast and read both units, and
   only one of their labels would be meant.
2. Give each arm an optional `caster_removed` that defaults to `removed`. Chosen.

## Decision

- `DispelArm.caster_removed` is optional. When it is set, the caster's labels of that arm expect it; the target's
  labels keep `removed`.
- The scenario contract names both outcomes when they differ ("removed on the caster, kept on the target").
- Entries without `caster_removed` generate exactly what they generated before.

## Consequences

- The Silverhand Incantation hostile arm can state the ruling: `removed` false, `caster_removed` true.
- Every scenario of the class regenerates byte-identical until an entry sets the field.
- Test: `test_behaviours.DispelArmsTests.test_a_caster_removal_is_judged_apart_from_the_target`.
