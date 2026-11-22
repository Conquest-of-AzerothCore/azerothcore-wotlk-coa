# 0017. Amphibimorph makes a frogged unit a Beast

- Status: accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

The contributor decided this change on 2026-11-22. Guide section 7 criteria 3 and 4 do not
hold: the cause is the shared `Unit::GetCreatureType`, and the change is in `src/server/game/Entities/Unit/Unit.cpp`,
an `ENGINE_FILES` entry, not in the class's own code.

Amphibimorph 500952: "While transformed into a frog the enemy is considered a Beast." (aura text "Polymorphed.
Beast."). Effect 0 is aura 56 SPELL_AURA_TRANSFORM (creature 216377). The only server meaning of a creature type is a
target check such as TargetCreatureType, and `Unit::GetCreatureType` read the creature template type for a creature
and ignored the frog, so Scare Beast 1513 (TargetCreatureType 1) stayed refused with SPELL_FAILED_BAD_TARGETS (12) at
a frogged Kobold Vermin 6 (Humanoid) in the cycle 9 sweep.

## Decision

- `Unit::GetCreatureType` returns CREATURE_TYPE_BEAST while the unit carries 500952, next to the CoA class
  checks already in that function.

## Consequences

- Regression: catalog `witch-doctor-amphibimorph-frog-is-beast`: Scare Beast at the unfrogged humanoid is refused
  (12); after a real Amphibimorph lands, the same attempt is accepted. It passed in 20261121-062124.
- The edit touches an engine file, so the source stage prints the finished-class rerun of guide section 14.5
  (ADR 0591).
