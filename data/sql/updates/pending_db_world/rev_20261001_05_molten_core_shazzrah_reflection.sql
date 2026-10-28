-- Reflection of Shazzrah (11504), the clone Shazzrah's Blink (2105611, boss_shazzrah_coa.cpp) leaves
-- behind at his pre-teleport spot. Model (display 13032) and spell (2105650, "Mirrored Arcane
-- Explosion") are the export's own (db.exil.es creature.csv.gz); the export record itself is a
-- placeholder stub (level 1, health_min/max 1, faction/combat stats all 0 -- the same shape as
-- Sacrificial Chains and the Son of Flame variants before this branch gave them real templates), so
-- faction/level/health here are designed off Shazzrah's own row and the lightest existing MC trash
-- health figure (Flame Imp, rev_20260930_81), not invented from nothing. Difficulty variants follow
-- the live DB's own difficulty_entry_1..3 convention (as on every other MC trash entry). AIName
-- SmartAI casts its one spell on spawn and the summon's own timed despawn removes it shortly after --
-- cadence is "1 per Blink" (no corpus evidence for more).
INSERT INTO `creature_template`
  (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`,
     `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`,
     `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`,
     `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`,
     `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`,
     `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`,
     `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`,
     `flags_extra`, `ScriptName`)
VALUES
(11504, 111504, 211504, 311504, 0, 0, 'Reflection of Shazzrah', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.71429, 1, 1,
 20, 0, 0, 1, 2000, 2000, 1, 1, 2, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 4.95, 1, 1, 1, 0, 0,
 1, 0, 0x40000000, ''),
(111504, 0, 0, 0, 0, 0, 'Reflection of Shazzrah', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.71429, 1, 1, 20, 0, 0, 1,
 2000, 2000, 1, 1, 2, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 7.1279, 1, 1, 1, 0, 0, 1, 0,
 0x40000000, ''),
(211504, 0, 0, 0, 0, 0, 'Reflection of Shazzrah', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.71429, 1, 1, 20, 0, 0, 1,
 2000, 2000, 1, 1, 2, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 9.3059, 1, 1, 1, 0, 0, 1, 0,
 0x40000000, ''),
(311504, 0, 0, 0, 0, 0, 'Reflection of Shazzrah', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.71429, 1, 1, 20, 0, 0, 1,
 2000, 2000, 1, 1, 2, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 11.4839, 1, 1, 1, 0, 0, 1, 0,
 0x40000000, '')
ON DUPLICATE KEY UPDATE
  `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`),
  `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `name` = VALUES(`name`), `faction` = VALUES(`faction`),
  `AIName` = VALUES(`AIName`), `HealthModifier` = VALUES(`HealthModifier`), `flags_extra` = VALUES(`flags_extra`);

-- Model: export display_id 13032.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (11504, 111504, 211504, 311504);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(11504, 0, 13032, 1, 1),
(111504, 0, 13032, 1, 1),
(211504, 0, 13032, 1, 1),
(311504, 0, 13032, 1, 1);

-- Casts Mirrored Arcane Explosion (2105650) on itself once, as soon as it is summoned.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (11504, 111504, 211504, 311504) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11504, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2105650, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Reflection of Shazzrah - On Summon - Cast \'Mirrored Arcane Explosion\''),
(111504, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2105650, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Reflection of Shazzrah - On Summon - Cast \'Mirrored Arcane Explosion\''),
(211504, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2105650, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Reflection of Shazzrah - On Summon - Cast \'Mirrored Arcane Explosion\''),
(311504, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 2105650, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Reflection of Shazzrah - On Summon - Cast \'Mirrored Arcane Explosion\'');
