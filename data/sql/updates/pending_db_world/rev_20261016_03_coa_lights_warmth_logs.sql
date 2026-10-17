-- "Light's Warmth", continued from the user's live screenshots:
-- * the Exhausted Refugees are human (bald men in plain clothes), not dwarves: back to the human body, still hatless;
-- * logs: three Dry Stump piles in the watchtower give a Dry Stump, and clicking a Cozy Fire while carrying one tosses it
--   in ("Logs tossed into the fire", 5 needed). On live the stump is used from the bags; the client has no spell for that,
--   so the fire takes it when clicked. The step now counts a helper the fire credits, and a click with no stump does nothing.
UPDATE `creature_display_preset` SET `race` = 1, `display_id` = 49 WHERE `entry` IN (164068, 164069) AND `display_id` = 53;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 49 WHERE `CreatureID` IN (164068, 164069) AND `CreatureDisplayID` = 53;

INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `bonding`, `maxcount`, `stackable`, `description`) VALUES
(560400, 12, 0, -1, 'Dry Stump', 929, 1, 4, 5, 5, 'Dry enough to burn.') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data1`) VALUES
(2300802, 3, 1248, 'Dry Stump', '', '', '', 1, 2300802) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `Data1` = VALUES(`Data1`);
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300802;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2300802, 560400, 0, 100, 1, 1, 0, 1, 1, 'Dry Stump - Dry Stump (Light''s Warmth)');

INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_flags`, `flags_extra`) VALUES
(164540, '[KC] Logs tossed into the fire', 1, 1, 35, 33554432, 128) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `flags_extra` = VALUES(`flags_extra`);
UPDATE `quest_template` SET `RequiredNpcOrGo2` = 164540 WHERE `ID` = 175056 AND `RequiredNpcOrGo2` = -2300668;
UPDATE `gameobject_template` SET `Data1` = 0, `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2300668;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300668 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300668, 1, 0, 1, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 57, 560400, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Cozy Fire - On Use - Remove Item ''Dry Stump'''),
(2300668, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 164540, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Cozy Fire - Linked - Quest Credit ''Logs tossed into the fire''');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 2300668 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 2300668, 1, 0, 2, 0, 560400, 1, 0, 0, 0, 0, '', 'Cozy Fire takes a log only from a player carrying a Dry Stump');
