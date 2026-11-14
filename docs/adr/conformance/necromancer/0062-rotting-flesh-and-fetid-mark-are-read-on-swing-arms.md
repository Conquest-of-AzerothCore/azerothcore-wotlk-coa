# 0062. Rotting Flesh and Fetid Mark are read on swing arms

- Status: accepted
- Date: 2026-11-13

## Context

Claims 147.1, Rotting Flesh 574138 "increasing their damage dealt by $573131s1% per stack for $/1000;s1 sec.", and
198.0, Fetid Mark 706948 "increases the damage the target takes from your Skeletal Warriors by $706949s1%", were data
only (mentor ruling, cycle 8). Server DBC set: 573131 Effect[0] 190 SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS aura
79 MiscValue 127, BasePoints 1 + DieSides 1 = 2, StackAmount 10; 706949 Effect[0] BasePoints 0 + DieSides 1 = 1,
StackAmount 10, DurationIndex 1 (10 s), ProcFlags 0. Server paths: Plague() casts 573131 on the caster
(AscensionNecromancer.cpp:276-289); `Mark()` scales a 50065/51065 melee hit by 1 + stacks x 1 / 100
(AscensionNecromancerContracts.cpp:499-510).

## Decision

Two `minion_swing_arms` entries (ADR 0630), 20000 caster spell power: 574138 with 573131 at 10 stacks on the caster,
read on a Ghoul 50073, 30 windows per arm, expected +20%; 706948 with 706949 at 10 stacks on the dummy from the
caster, a Skeletal Warrior 50065 (Raise: Skeletal Warrior 500970), 24 windows per arm, expected +10%. Each label is
added to its claim; the existing readbacks stay.

## Consequences

- 147.1's "for 5 sec" stays the 574138 SPELLMOD_DURATION readback; the in-game bracket (4.4 to 5.6 s) is unchanged.
- Uncounted pilot 20261113-205142 (raw): +20.1% and +9.6%.
- Observation, not changed: one stack is below the 2-point band (+2% and +1%), so the per-stack slope is read only
  through the 10-stack arm.
