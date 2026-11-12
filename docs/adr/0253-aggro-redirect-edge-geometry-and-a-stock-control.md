# 0253. Aggro-redirect edge geometry and a stock area-taunt control

- Status: accepted; the control's placement and the edge formula of its consequences are superseded by ADR 0255
- Date: 2026-11-12

## Context

Claim 279, Absolution 800424 "Taunt all enemies within 8 yds": rooted dummies at 8.5, 10.5 and 11.5 yd are taunted, one
at 12.5 yd is not (ADR 0244, FN-r2b-3). The owner ruling of 2026-11-12 asks for the edge bracketed to 0.5 yd centre to
centre, with the combat reach of the caster and the dummy read from the server, and for a control: a stock, non-CoA area
spell of known radius around the caster, on the same dummies. The same extension means general engine behaviour; a
different one points at Absolution's own targeting.

## Decision

- `aggro_redirect` gains `geometry` (rooted entries only). Before the cast it reads each dummy's `combat_reach` and
  `position_z`, and the caster's `combat_reach`, `position_z` and `run_speed_rate`, beside the existing `distance_2d`.
  The reads carry no expectation. Entries without it regenerate byte-identical.
- Absolution `edge`: four rooted dummies at 11.6, 11.85, 12.1 and 12.35 yd, fewer than its MaxAffectedTargets 5, each
  expected untaunted by the tooltip. Absolution `cap`: six rooted dummies at 2-7 yd, each expected taunted by "all
  enemies".
- Control: Challenging Shout 1161, stock Warrior data with no CoA code naming it, with the same shape as Absolution
  (Effect[0] aura 11 on TARGET_SRC_CASTER / TARGET_UNIT_SRC_AREA_ENEMY), SpellRadius 13 (10 yd) and no target cap. One
  dummy at 9.5 yd guards the cast; four at 13.6-14.35 yd bracket its edge. The entry lives in the Templar class file
  because that file is the tool's only input; it is the first behaviour entry for a spell outside the class, and no
  ledger row cites it.

## Consequences

- The engine's edge for a caster-centred enemy area cast by a player is radius + 2.66 (Spell.cpp:1391-1395,
  Object.cpp:1786-1806, ObjectDefines.h:51) + the target's combat reach (Spell.cpp:9431-9438), measured on the exact
  distance; lean/radius.md has the bracket and the arithmetic.
- Seeded tests: the geometry reads precede the cast, an entry without roots refuses geometry, the range entry reads no
  geometry, and the control has its guard inside the radius.
