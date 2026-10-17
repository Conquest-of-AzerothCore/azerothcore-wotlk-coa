-- Recovered Ascension Manastorm end-of-stage portal controller.
--
-- Evidence / runtime validation:
--
-- shutdown creaturecache.wdb:
--   entry          = 80910
--   name           = The Manastorm
--   subname        = <empty>
--   IconName       = vehichleCursor
--   type_flags     = 0
--   type           = 8
--   family         = 3
--   rank           = 0
--   KillCredit1/2  = 0 / 0
--   DisplayID      = 11686
--   HealthModifier = 0.009625
--   ManaModifier   = 1.0
--   RacialLeader   = 0
--   movementId     = 0
--
-- Live target-client validation:
--
--   80910 by itself is invisible.
--   Casting spell 93305 "Manastorm Portal Effect" on it produces the
--   recovered purple/black Manastorm stage portal visual.
--
-- Server-side compatibility choices that are NOT claimed as recovered:
--
--   * faction 35 keeps the controller neutral.
--   * level 1 is sufficient because it is a non-combat visual/controller.
--   * npcflag 1 (Gossip) makes the portal interactable so the module can
--     advance the shared run immediately when a player uses it.
--   * ScriptName binds the interaction to the shared Manastorm backend.
--
-- The C++ runtime still preserves the existing five-second automatic
-- transition. Portal interaction only provides an early transition path.

INSERT INTO `creature_template`
(
    `entry`,
    `name`,
    `subname`,
    `IconName`,
    `gossip_menu_id`,
    `minlevel`,
    `maxlevel`,
    `exp`,
    `faction`,
    `npcflag`,
    `speed_walk`,
    `speed_run`,
    `speed_swim`,
    `speed_flight`,
    `detection_range`,
    `rank`,
    `dmgschool`,
    `DamageModifier`,
    `BaseAttackTime`,
    `RangeAttackTime`,
    `BaseVariance`,
    `RangeVariance`,
    `unit_class`,
    `unit_flags`,
    `unit_flags2`,
    `dynamicflags`,
    `family`,
    `type`,
    `type_flags`,
    `AIName`,
    `MovementType`,
    `HoverHeight`,
    `HealthModifier`,
    `ManaModifier`,
    `ArmorModifier`,
    `ExperienceModifier`,
    `RacialLeader`,
    `movementId`,
    `RegenHealth`,
    `CreatureImmunitiesId`,
    `flags_extra`,
    `ScriptName`,
    `VerifiedBuild`
)
VALUES
(
    80910,
    'The Manastorm',
    '',
    'vehichleCursor',
    0,
    1,
    1,
    0,
    35,
    1,
    1,
    1.14286,
    1,
    1,
    20,
    0,
    0,
    1,
    2000,
    2000,
    1,
    1,
    1,
    0,
    0,
    0,
    3,
    8,
    0,
    '',
    0,
    1,
    0.009625,
    1.0,
    1,
    1,
    0,
    0,
    1,
    0,
    0,
    'npc_manastorm_stage_portal',
    0
)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `subname` = VALUES(`subname`),
    `IconName` = VALUES(`IconName`),
    `gossip_menu_id` = VALUES(`gossip_menu_id`),
    `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`),
    `exp` = VALUES(`exp`),
    `faction` = VALUES(`faction`),
    `npcflag` = VALUES(`npcflag`),
    `speed_walk` = VALUES(`speed_walk`),
    `speed_run` = VALUES(`speed_run`),
    `speed_swim` = VALUES(`speed_swim`),
    `speed_flight` = VALUES(`speed_flight`),
    `detection_range` = VALUES(`detection_range`),
    `rank` = VALUES(`rank`),
    `dmgschool` = VALUES(`dmgschool`),
    `DamageModifier` = VALUES(`DamageModifier`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`),
    `RangeAttackTime` = VALUES(`RangeAttackTime`),
    `BaseVariance` = VALUES(`BaseVariance`),
    `RangeVariance` = VALUES(`RangeVariance`),
    `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`),
    `unit_flags2` = VALUES(`unit_flags2`),
    `dynamicflags` = VALUES(`dynamicflags`),
    `family` = VALUES(`family`),
    `type` = VALUES(`type`),
    `type_flags` = VALUES(`type_flags`),
    `AIName` = VALUES(`AIName`),
    `MovementType` = VALUES(`MovementType`),
    `HoverHeight` = VALUES(`HoverHeight`),
    `HealthModifier` = VALUES(`HealthModifier`),
    `ManaModifier` = VALUES(`ManaModifier`),
    `ArmorModifier` = VALUES(`ArmorModifier`),
    `ExperienceModifier` = VALUES(`ExperienceModifier`),
    `RacialLeader` = VALUES(`RacialLeader`),
    `movementId` = VALUES(`movementId`),
    `RegenHealth` = VALUES(`RegenHealth`),
    `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
    `flags_extra` = VALUES(`flags_extra`),
    `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model`
WHERE `CreatureID` = 80910;

INSERT INTO `creature_template_model`
(
    `CreatureID`,
    `Idx`,
    `CreatureDisplayID`,
    `DisplayScale`,
    `Probability`,
    `VerifiedBuild`
)
VALUES
(
    80910,
    0,
    11686,
    1,
    1,
    0
);

-- Verification
SELECT
    `entry`,
    `name`,
    `IconName`,
    `npcflag`,
    `family`,
    `type`,
    `type_flags`,
    `rank`,
    `HealthModifier`,
    `ManaModifier`,
    `movementId`,
    `ScriptName`
FROM `creature_template`
WHERE `entry` = 80910;

SELECT
    `CreatureID`,
    `Idx`,
    `CreatureDisplayID`,
    `DisplayScale`,
    `Probability`
FROM `creature_template_model`
WHERE `CreatureID` = 80910;
