# 0050. Command: Bonefreeze casts once at its target

- Status: accepted
- Date: 2026-11-13

## Context

Claim 86.2, Command: Bonefreeze 504489 "freeze enemies at target location for $504845d (8 sec vs players)". The
Skeletal Mage answered the Command with one cast of Bonefreeze 504845 per valid enemy within 8 yd of the Command's
target (AscensionNecromancerSummons.cpp, `DoAction`). 504845 is itself an 8 yd area at its target (every effect
EffectImplicitTargetA 16 TARGET_UNIT_DEST_AREA_ENEMY, EffectRadiusIndex 14), so an enemy player near the target was
hit by the cast at the target and again by the cast at itself. The freeze is a root (DIMINISHING_ROOT, DRTYPE_PLAYER,
SpellMgr.cpp:304-327) and the Mage is player-owned, so the second hit was diminished: 8000 ms (the cap on players,
AscensionNecromancerAbilities.cpp:233-234) became 4000 ms. The c6 pilot read 3694 ms left 300 ms after the Command.
Criterion: the tooltip (8 sec vs players). Live logs hold no Bonefreeze line, so no live reference exists.

## Options

- Keep the loop and skip enemies already frozen: the area still double-hits the enemies around the target.
- Cast 504845 once at the Command's target and let its own area select the enemies.

## Decision

One `Cast(me, target, 504845)` replaces the loop. The area's enemy check is now the Mage's instead of the player's
`IsValidAttackTarget`; the area, area_held and area_ends entries still freeze the dummies around the target.

## Consequences

- Regression `504489 behaviour_metric_delta player_duration`: an enemy player beside the Commanded dummy keeps the
  freeze 7700 ms (+- 400) 300 ms after the Command, not about 3700.
- Control `504489 behaviour_metric_delta one_cast`: the enemy player sees one 504845 SMSG_SPELL_GO from the Mage per
  Command (the loop sent two), so each enemy is hit once.
