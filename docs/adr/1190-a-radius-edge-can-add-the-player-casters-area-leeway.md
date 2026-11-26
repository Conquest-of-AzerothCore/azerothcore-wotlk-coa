# 1190. A radius edge can add the player caster's area leeway

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Builds on: [ADR 0592](0592-an-area-radius-is-bracketed-by-dummies-at-its-edge.md), [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md);
  guide section 5, "Effective radius" (G-29)

## Context

Glare 807870 states "and stuns enemies within $a1 yds" ($a1 = 8, EffectRadiusIndex 14). Effect[0] is aura 12 with
TargetA 22 (SRC_CASTER) and TargetB 15 (`TARGET_UNIT_SRC_AREA_ENEMY`). The area search of a player caster measures
from the source position, centre to centre, against three terms:

- the radius, `SpellEffectInfo::CalcRadius` (8 yd, no `SPELLMOD_RADIUS` here);
- the leeway, `Spell.cpp:1388-1394`: for `TARGET_UNIT_SRC_AREA_ENEMY`, `TARGET_UNIT_CASTER_AREA_PARTY` and
  `TARGET_UNIT_CASTER_AREA_RAID` the radius gains `GetLeewayBonusRadius()`. `Object.cpp:1787-1808` returns
  `LEEWAY_BONUS_RANGE` (2.66, `ObjectDefines.h:51`) for a player that is jumping or falling, or whose speed exceeds
  `LEEWAY_MIN_MOVE_SPEED` (4.97, `ObjectDefines.h:50`). The speed is the jump speed while jumping, otherwise the walk
  speed when the player walks and the run speed when it does not. A standing player in run mode at the base rate
  has 1.0 x 7.0 yd/s (`playerBaseMoveSpeed[MOVE_RUN]`, `Unit.cpp:107-110`), so the leeway applies without movement.
  The constants come from upstream AzerothCore (`git log -L`: 2e1f848f09 #22566, 7a66aa94c1 #25958);
- the target's combat reach, `Spell.cpp:9434-9442`: a SRC/DEST/TARGET reference, a player-controlled caster and a
  non-player target add `unitTarget->GetCombatReach()`; the caster's own size is not added.

The predicted edge is 8 + 2.66 + 1.275 = 11.935 yd, inside the measured bracket (stunned at about 11.4 yd, not at
12.5 yd; Sun Cleric b7a review, I4). `radius_edge` could not express it: its `center_reach` adds a size of the
primary, not a leeway, and an entry that placed the dummies with a measured edge would prove nothing.

## Options

1. A free `leeway_yd` number on the entry: the class author writes 2.66. A wrong or measured number passes as easily
   as the right one.
2. An opt-in `leeway: true` whose value the tool computes from the engine rule above, checked against the spell's
   implicit targets and the caster, with the caster's run speed rate read in the run.
3. A harness read of the caster's leeway (`GetLeewayBonusRadius`): a readback of the term under test, and a harness
   C++ change.

## Decision

Option 2, in `kinds/radius_edge.py` only.

- `leeway: true` is refused unless the caster is the player (no `caster_entry`) and an effect of `cast_spell` has
  TargetA or TargetB 15, 20 or 56. The dummies are placed on radius + 2.66 + the dummy's reach (+ a centre size, as
  before).
- The scenario reads the caster's `run_speed_rate` with the geometry. The judge takes the leeway as 2.66 when
  rate x 7.0 > 4.97, else 0, and adds it to each dummy's edge; the verdict text names the leeway, the rate and the
  speed.
- Run mode is required by construction, not read: no harness metric reads `MOVEMENTFLAG_WALKING` or the jumping
  state, the kind emits no movement step, and the harness writes no walking flag (its only movement-flag writer,
  `set_moving`, sets forward, backward, strafe or falling). Jumping or falling would only give the same 2.66. The
  verdict text and the contract say so. This rests on code reading.
- Without the key nothing changes: no new label, no model key, no contract text.

## Consequences

- A wrong leeway does not pass: with 0 the inside dummy (0.5 yd inside 11.935) stands beyond the read edge and the
  layout is unmeasured, or, if the engine lost its leeway, the inside dummy is not struck and the verdict alerts; a
  larger leeway strikes the outside dummy and alerts. The unit tests seed a run speed rate under the threshold and a
  wrong module constant.
- The leeway is this core's rule, inherited from upstream; it is not evidence about the original server (guide
  section 5).
- Templar, Necromancer and Witch Hunter generate byte-identical output; only Sun Cleric's 807870 radius entry uses
  the key.
- Limit: with `cast_at: caster` the judge measures the dummies from the primary, which stands `primary_yd` from the
  caster (0.1 yd for 807870), not from the caster itself; the margin of 0.5 yd covers that offset.
