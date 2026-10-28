# 0004. Let gameplay-test raid bots opt in to the CoA rotation assist priorities

- Status: accepted
- Date: 2026-10-25

## Context

ADR 0002 made raid bots C++ role routines in the gameplay harness. Their damage and heal spells are hand-picked
lists in each scenario (`rotation`, `heal_spell`). The maintainers want raid fights to resemble real players of
the CoA classes (12-32), which means using CoA's own rotation priorities. The server already has them: the player
`.rotation` command (`src/server/coa/CoARotationAssist.cpp`) chooses a spell from 1,571 imported rules
(`CoARotationData.h`) for the player's active CoA specialization, with a generic fallback over learned spells.

## Considered options

1. Reuse the `.rotation` selection (`CoARotationAssist::ChooseSpell`), keyed by the bot's active specialization.
2. Keep hand-picked spell lists per scenario.
3. Drive bots with the Ghost Lua AI or mod-playerbots. ADR 0002 rejected both for the harness: Ghost's Lua AI
   provides class rotations for the ten stock classes only, and mod-playerbots is heavy to embed and brings no
   assertion framework. The CoA rules reused by option 1 already come from the Zyth45/mod-playerbots fork's CoA
   rotation data (`CoARotationData.h`, attribution in `docs/coa/rotation-assist.md`).

## Decision

Option 1, as an opt-in per player:

- A player with a `role` may set `rotation_assist: true`. When its active specialization has imported rules, its
  damage and heal choices come from `ChooseSpell`, asked only while the bot is idle (not casting, no queued cast)
  and cast through `CMSG_CAST_SPELL`. Otherwise it casts its scenario `rotation` or `heal_spell`, which stay
  required where they are today.
- Without the field nothing changes, so the Lucifron pilot and `raid-bots-tank-healer` keep their exact behavior.
- Roles, tank-first order, waiting for the tank, the threat floor, the taunt, movement and heal-target choice stay
  as ADR 0002 built them. The rotation never chooses a taunt, so the tank's `taunt_spell` keeps running first.
- Harness bots ignore `CoA.RotationAssist.Enable`. That realm setting gates the player command; a test fixture
  must not depend on it.
- Coverage: all 21 CoA classes have rules for all 70 of their specializations (1-63 and 95-101). A character
  without an active specialization, the ten stock classes and HERO (94) use the scenario spells. Rules existing does
  not mean each profile is tuned (Starcaller Hydromancy 45 has 9 rules, Spirit Mage Runic 61 has 10).
- The gameplay proof covers a rotation-driven ranged damage dealer (`raid-bots-rotation-assist`). Healer and tank
  rotations use the same dispatch and have unit tests only: no low-level healer or tank fixture with spells that
  separate the rotation from the fallback was established.

## Consequences

- A defect in the rotation data or in `ChooseSpell` can now fail raid scenarios that opt in.
- `ChooseSpell` rebuilds a name map of the bot's spellbook on every call, so each idle tick of an opted-in bot
  costs more than a scenario list lookup.
- Area-effect rules may pull nearby packs when bots fight in real instances.
- The scenario field must change together in the Python validator and the C++ loader.
