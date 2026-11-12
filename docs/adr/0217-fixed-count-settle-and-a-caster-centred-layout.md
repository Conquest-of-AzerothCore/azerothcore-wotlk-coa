# 0217. fixed_count: a settle after each cast and a caster-centred layout

- Status: accepted
- Date: 2026-11-12

## Context

Pulverizing 524620, claim 88: "Damage dealt by Condemn now has a $h% chance to consecrate the earth around you ...
to nearby enemies." The pulse 524619 is cast at the Templar's own position (AscensionTemplarEvents.cpp:174-175) when a
periodic tick of Condemn rolls 15%. A `fixed_count` cast at a dummy placed the other dummies around that dummy and read
them right after the cast, before any tick. Norgannon's Wrath 524739 (claim 89) strikes 1500 ms after its cast.

## Decision

Two optional fields. `settle_ms` (default 0, no step) waits after each cast, and the scenario's timeout then covers its
waits. `layout: "caster"` places the dummies around the caster, as a cast at the caster does, while the cast still
targets the primary dummy. Entries without them regenerate byte-identical.

## Consequences

- Pulverizing on build 861e0e1e6bee: five Condemns at the dummy 1 yd away, 21500 ms each: the four dummies within 5 yd
  of the Templar hit 5 times each, the one at 10 yd never.
- Norgannon's Wrath: the primary and five dummies within 5 yd of it hit by each of two casts, the one beyond never.
- Seeded tests: the settle follows every cast; the caster layout puts every candidate inside the radius of the caster;
  an unknown layout is refused.
