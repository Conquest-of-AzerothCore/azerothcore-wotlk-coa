-- Worldforged items: Cowl of the Stone Summoner, Blight Bomber, Sandstorm Shaper procs; two Worldforged objects moved.

-- Cowl of the Stone Summoner
DELETE FROM `spell_proc` WHERE `SpellId` IN (200999, 312206, 316206, 320206);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(200999, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 75000, 0),
(312206, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 75000, 0),
(316206, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 75000, 0),
(320206, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 75000, 0);

-- Blight Bomber
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(304252, 0, 0, 0, 0, 0, 'Plaguehound', NULL, NULL, 0, 55, 56, 0, 35, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1,
  1, 1, 0, 2048, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.584, 1, 1, 1, 0, 0, 1, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 304252;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(304252, 0, 7891, 1, 1, 0);

DELETE FROM `creature_template_spell` WHERE `CreatureID` = 304252;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES
(304252, 0, 3427, 0);

-- Base Blight Bomber (410158) and Sandstorm Shaper (410074) rolled the CoA fallback (about 1 PPM); their upgrade tiers
-- use 0.5 PPM.
UPDATE `item_template` SET `spellppmRate_1` = 0.5 WHERE `entry` IN (410158, 410074);

-- Worldforged object placements (Azeroth World Editor 0.10.0, 2026-11-27)
-- 6940831 Old Dragonmaw Cleaver (387882), 6941742 Flower of Tranquility (254222)
UPDATE `gameobject` SET
  `position_x` = CASE `guid` WHEN 6940831 THEN -3415.8270935539254 WHEN 6941742 THEN 2620.434907740776 END,
  `position_y` = CASE `guid` WHEN 6940831 THEN -3073.340454074676 WHEN 6941742 THEN 1339.4560349653627 END,
  `position_z` = CASE `guid` WHEN 6940831 THEN 23.83972930057409 WHEN 6941742 THEN 260.1748362502452 END,
  `orientation` = CASE `guid` WHEN 6940831 THEN 5.096250641364397 WHEN 6941742 THEN 0.62312 END,
  `rotation0` = CASE `guid` WHEN 6940831 THEN 0.17780774560313614 WHEN 6941742 THEN 0 END,
  `rotation1` = CASE `guid` WHEN 6940831 THEN 0.28539597258425564 WHEN 6941742 THEN 0 END,
  `rotation2` = CASE `guid` WHEN 6940831 THEN 0.52306058338736 WHEN 6941742 THEN 0.306544 END,
  `rotation3` = CASE `guid` WHEN 6940831 THEN -0.783161011888802 WHEN 6941742 THEN 0.951857 END
WHERE `guid` IN (6940831, 6941742);
