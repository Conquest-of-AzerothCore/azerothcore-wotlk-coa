# 0224. A floor on a hit scenario's casts

- Status: accepted
- Date: 2026-11-12

## Context

Sacred Swing 572769, claims 206 and 207: "dealing $s2% High Threat Weapon Damage plus ${$m1+0}". The max-rank hit
scenario sizes its casts from the model's own spread (`casts_needed`: a 99% half-width of 1% of the mean). The weapon
model's sigma is about 1.9 on a mean of 472.6, so it asked for 2 casts and scheduled 3; the first counted pair rested
on 3 hits each. The controller asked for more hits on both claims.

## Decision

A class-file section `hit_casts` lists `{"spell", "casts", "reason"}`; `conformance.add_hit` takes the larger of the
model's casts and the floor (`hits.floored_casts`). A floor below one cast is refused. Ranks without an entry, and
every class file without the section, generate as before.

## Consequences

- Sacred Swing schedules 60 casts and needs 40 hits for its mean.
- `conformance.py scaffold` writes an empty `hit_casts` section, as for the other list sections.
- Seeded tests: the floor raises the casts, a larger model count is kept, other ranks are untouched, a floor of 0 is
  refused.
