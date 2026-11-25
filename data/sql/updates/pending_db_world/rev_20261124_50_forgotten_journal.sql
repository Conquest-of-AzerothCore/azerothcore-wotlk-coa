INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(501000, 9, 470, 'Forgotten Journal', '', '', 0.8, 501000, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(501001, 5, 4651, 'Rotting Plank', '', '', 0.3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(501002, 3, 1066612, 'Forgotten Amulet', '', '', 1, 1689, 501002, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'worldforged_pickup', 0),
(501003, 10, 499, 'Forgotten Grave', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data10` = VALUES(`Data10`), `Data12` = VALUES(`Data12`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `gameobject_template_addon` WHERE `entry` IN (501001, 501003);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`) VALUES
(501001, 0, 16, 0, 0),
(501003, 35, 0, 0, 0);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (254026, 501002);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254026, 254026, 0, 100, 0, 1, 0, 1, 1, 'Forgotten Flower'),
(501002, 254025, 0, 100, 0, 1, 0, 1, 1, 'Forgotten Amulet');

DELETE FROM `page_text` WHERE `ID` = 501000;
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`, `VerifiedBuild`) VALUES
(501000, 'I''ve seen that there is hope for the darkest beings. You taught me that, last time. If I could find you again maybe you could help, but I can''t find you, or her, or anyone else I''ve met before.\nThey''re the only one I can remember, but I don''t know what to do anymore. They fell so far into the darkness that I can no longer save them. Shouldn''t I be able to reach my own twin better than anyone?\n\nBut I can''t give up. I need to remember what I can, so I''m writing this down, and maybe even next time I''ll find this again.\nWe went into the cellar one time, they dropped a necklace there. There was a flower that used to grow by the lake, it was their favorite, even though it''s hard to find now. There was a grave for them, along the path...but it really wasn''t. I just didn''t know how to explain what happened back then.\n\nI still don''t...\nDidn''t it happen so long before this town though? So how was that them? It''s all so fuzzy...I need to remember more.', 0, 0);

DELETE FROM `gameobject` WHERE `guid` IN(12101051, 12101052, 12101053, 12101054);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(12101051, 501000, 0, 0, 0, 1, 1, -11192.8589, -1854.4430, 74.5552, 0.749978, 0, 0, -0.366262, -0.930512, 300, 100, 1, '', NULL, 'Forgotten Journal'),
(12101052, 501001, 0, 0, 0, 1, 1, -11192.1911, -1854.9317, 74.6146, 6.075526, -0.095949, -0.619531, -0.105676, 0.771886, 300, 100, 1, '', NULL, 'Rotting Plank over the Forgotten Journal'),
(12101053, 501002, 0, 0, 0, 1, 1, -11166.4275, -2110.9478, 31.2171, 1.935460, 0, 0, 0.8236, 0.567171, 300, 100, 1, '', NULL, 'Forgotten Amulet'),
(12101054, 501003, 0, 0, 0, 1, 1, -10412.1624, -2020.6039, 93.14, 2.851943, 0, 0, 0.989531, 0.144319, 300, 100, 1, '', NULL, 'Forgotten Grave');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 501003 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(501003, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -10874.535, -1685.5, 149, 0, 'Forgotten Grave - On Gossip Hello - Teleport Invoker to Deadwind Pass 34.1, 60.5');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 501003 AND `SourceId` = 1;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 501003, 1, 0, 2, 0, 254026, 1, 0, 0, 0, 0, '', 'Forgotten Grave - Invoker has Forgotten Flower'),
(22, 1, 501003, 1, 0, 2, 0, 254025, 1, 0, 0, 0, 0, '', 'Forgotten Grave - Invoker has Forgotten Amulet in bags or equipped');
