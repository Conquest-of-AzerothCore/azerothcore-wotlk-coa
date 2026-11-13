# 0403. A phase power and a counted primary

- Status: accepted
- Date: 2026-11-13

## Context

Mass Grave 803741 has two claims no existing shape reads. "While above 50 Runic Power this spell is instant cast"
(Unit::ModSpellCastTime, Unit.cpp:13029-13034, Runic Power above 500) needs the caster's Runic Power set to a
different value in each phase of one `metric_delta`, right before the cast; `cast_power` sets only the cast spell's own
power type, to one value. "Transform up to $i nearby enemies" is centred on the caster: `fixed_count` judges the
dummies after the nearest one and assumes the nearest is always hit, but Mass Grave picks any five of the Humanoids in
its radius. Pair 20261113-0122 run 1 read all five further dummies affected (the nearest not), an alert of the judge,
not of the server.

## Decision

- `metric_delta` takes `phase_power` `[power, before, after]`: that power is set to `before` right before the before
  phase's cast and to `after` right before the after phase's cast.
- `fixed_count` takes `count_primary`: the nearest dummy joins the judged dummies, so the count is of every dummy
  inside the radius, for a spell centred on the caster that picks its targets at random.

## Consequences

- Entries without the fields generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Mass Grave reads its cast state at 500 and 520 Runic Power, and counts five of seven Humanoids within 8 yd.
