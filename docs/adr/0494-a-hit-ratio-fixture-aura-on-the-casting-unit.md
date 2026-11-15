# 0494. A hit-ratio fixture aura on the casting unit

- Status: accepted
- Date: 2026-11-13

## Context

Corpse Wagon 503738 "by party and raid members" is read with a grouped ally casting Glacial Impact 707592 at the
dummy, with and without the Necromancer knowing the talent. In the merged pair 20261113-043355 / -044317 the entry was
`insufficient_trials` at its generated trial count: the ally's hits had partial resists (99% interval +0.98% to +5.21%
and -0.20% to +4.38%). The arms' `auras` are set on the caster by design (a Templar talent set on the Templar reaches
an ally's heal), so the spell-penetration fixture 823764 could not reach the casting ally.

## Decision

- `hit_ratio` takes `cast_unit_auras`: `[[spell, stacks], ...]` set with `set_aura` on the casting unit (`caster`, or
  the ally when it casts) before every cast in both arms. Swing entries refuse it. Arm `auras` keep their meaning.

## Consequences

- The party entry reads 153 -> 157 on every hit (+2.61%, the integer damage of 153 x 1.03) at the generated trials.
- Entries without the field are unchanged; Templar `generate --class 19` and `--stack` are byte-identical.
- Tests: `CastUnitAuraTests` (test_behaviours.py): the fixture lands on the casting ally before every cast; a swing
  entry refuses it.
