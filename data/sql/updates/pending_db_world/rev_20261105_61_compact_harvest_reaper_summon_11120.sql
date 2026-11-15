-- #11120: Compact Harvest Reaper (7979), cast by Venture Co. Machine Smith 3993, Tinkerer 677 and Engineer
-- Whirleygig 5836, names creature 267600 in SPELL_EFFECT_SUMMON. That entry has no creature_template row, so
-- Creature::Create refuses it and the cast succeeds with nothing appearing, as in #9990. Clone the stock 2676
-- "Compact Harvest Reaper", the creature the stock summon 4078 names, with its model, addon and evade despawn.
DROP TEMPORARY TABLE IF EXISTS `_compact_harvest_reaper_267600`;
CREATE TEMPORARY TABLE `_compact_harvest_reaper_267600` AS SELECT * FROM `creature_template` WHERE `entry` = 2676;
UPDATE `_compact_harvest_reaper_267600` SET `entry` = 267600;
INSERT INTO `creature_template` SELECT * FROM `_compact_harvest_reaper_267600`
ON DUPLICATE KEY UPDATE `creature_template`.`entry` = `creature_template`.`entry`;
DROP TEMPORARY TABLE `_compact_harvest_reaper_267600`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 267600;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 267600, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 2676;

DELETE FROM `creature_template_addon` WHERE `entry` = 267600;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
SELECT 267600, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras` FROM `creature_template_addon` WHERE `entry` = 2676;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 267600 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
SELECT 267600, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment` FROM `smart_scripts` WHERE `entryorguid` = 2676 AND `source_type` = 0;
