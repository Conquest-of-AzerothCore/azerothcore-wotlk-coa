-- Shrine of Lord Kazzak (Tainted Scar, Blasted Lands): on Ascension Kazzak was fought on his own map
-- (882, Throne of the Doom Lord), reached through this shrine's "Challenge Kazzak". Entry and model as
-- Ascension had them (280137, BlackrockAltarRitual); the gossip text is Ascension's.
-- Landing point: the map's graveyard (WorldSafeLocs 6082) until the exact spot is measured. Map 882 had no
-- instance_template row, so the server treated it as an invalid map and refused every teleport there.
DELETE FROM `gameobject_template` WHERE `entry` = 280137;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(280137, 2, 4076, 'Shrine of Lord Kazzak', '', '', '', 1.5, 0, 0, 0, 9780137, 'SmartGameObjectAI', '', 0);

DELETE FROM `npc_text` WHERE `ID` = 9780137;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`) VALUES
(9780137, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.', '', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 9780137;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (9780137, 9780137);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9780137;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9780137, 0, 9, 'Challenge Kazzak', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9780137, 1, 0, 'Take your hands off the shrine.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 280137 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(280137, 1, 0, 1, 62, 0, 100, 0, 9780137, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Shrine of Lord Kazzak - On Gossip Select Challenge - Close Gossip'),
(280137, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 882, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -12569.814, -2373.242, 53.649, 2.5682476, 'Shrine of Lord Kazzak - Linked - Teleport Invoker to Throne of the Doom Lord'),
(280137, 1, 2, 0, 62, 0, 100, 0, 9780137, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Shrine of Lord Kazzak - On Gossip Select Leave - Close Gossip');

DELETE FROM `gameobject` WHERE `guid` = 9780137;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9780137, 280137, 0, 4, 73, 1, 1, -11665.856, -2371.7654, 0.5489, 0.6004158, 0, 0, 0.2957188, 0.955275, 0, 100, 1, '', 0, 'Shrine of Lord Kazzak');

DELETE FROM `instance_template` WHERE `map` = 882;
INSERT INTO `instance_template` (`map`, `parent`, `script`, `allowMount`) VALUES (882, 0, '', 0);
