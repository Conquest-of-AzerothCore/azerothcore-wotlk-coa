# 0560. A fixed count may set auras right after its cast

- Status: accepted
- Date: 2026-11-13

## Context

Command: Bonefreeze (area) 504489 (claim 86.0) flipped ok / alert in the cycle 2 pair (20261113-114711 / -114853).
The `fixed_count` scenario reads every dummy's freeze 500 ms after the Command. In 60 diagnostic copies
(20261113-115218) the Skeletal Mage cast Bonefreeze 504845 at all four dummies every time, but in 31 its first splash
landed before the read and broke every freeze (504845 ends on damage since F-b3b-1). The claim is the freeze, not the
Mage's damage; the mentor approved a passive Mage to remove the race.

## Decision

- `fixed_count` takes optional `post_cast_auras` (`[[spell, stacks]]`, at least one stack) set on the caster right
  after each cast, before the read wait. Omitted, every generated scenario is unchanged.
- The Bonefreeze area entry sets Undead: Pacify 500983 (a precondition fixture): the Mage stays passive and minion
  damage is blocked while it holds (AscensionNecromancerEvents.cpp:350-355). With it 60 of 60 copies read four frozen
  dummies and no Mage damage (20261113-115902).

## Consequences

- Seeded tests (FixedCountPostCastAuraTests): the aura step follows every cast; without the field the wait follows
  the cast; a zero stack is refused. The mutant (the field ignored) fails the first test.
- Templar `generate --class 19` and `--stack` byte-identical (no Templar entry sets the field).
