# 0012. Shadow Effigy slows every enemy in its field radius

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Shadow Effigy 505339 summons creature 50119; the tooltip says enemies within $504761a1 yds (504761 has
EffectRadiusIndex 10, 30 yd) have their casting speed reduced by 20% and movement speed by 40%. The effigy AI applies
504761 and 504909 to every enemy `Nearby()` returns. Two blocks (cycle 9 author D):
- the scan was `Nearby(me, 10.0f)`;
- 504761 carries SPELL_ATTR5_LIMIT_N (AttributesEx5 1576), so a second enemy given 504761 removed it from the first
  (`Unit::_AddAura`, single-cast auras of the doctor). A trial build with the 30 yd scan alone left a dummy 29.78 yd
  out without 504761 (cycle 8, 20261121-020314).

## Decision

- The effigy scans `Radius(ShadowField)`.
- `ApplyContracts` clears SPELL_ATTR5_LIMIT_N on 504761, whose own target is already rewritten to one enemy per cast.

## Consequences

- Regression: catalog `witch-doctor-shadow-effigy-field-radius`: an enemy 5 yd out is affected in both builds, one
  inside 20 yd only after the fix. It passed in 20261121-050156.
