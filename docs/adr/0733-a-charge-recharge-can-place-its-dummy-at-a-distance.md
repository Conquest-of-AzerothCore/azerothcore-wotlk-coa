# 0733. A charge recharge can place its dummy at a distance

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claims 314.0 ("2 Charges,") and 315.0 ("25 sec recharge", Hunt 802006) have no reading: Hunt is a
charge with a 5 yd minimum range, and `charge_recharge` places the dummy at the 3 yd melee distance, so every cast was
refused with TOO_CLOSE and the charges stayed 2 (c12-inq). Only an ally target stepped away between casts. Gap design
P2 (c13 gap designs), mentor ruling D-201.

## Options

- An optional `dummy_distance` through `dummy_placement` (as cast_gate D-1), and for a distance-closing spell a step
  back of that distance before every cast after the first.
- A dummy placed by the spell's range alone: Hunt's range is not flagged ranged, so `cast_distance` keeps 3 yd.
- A fixed step back before every cast: the first cast would start at twice the distance.

## Decision

The optional distance with the step back after a charge. A return farther than one relocate step is refused.

## Consequences

- Absent by default: Templar 19 (one charge_recharge entry, an ally target, no distance) and Necromancer 23
  regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the dummy stands at the distance and the caster steps back before the second cast and the over-cast
  only; without a distance nothing moves; a distance needs a dummy target and a return of at most 20 yd. It adds no
  check, so there is no mutant; the existing seeded wrong-value tests of the judge still apply.
- Witch Hunter: `802006 behaviour_charge_recharge` at 15 yd.
