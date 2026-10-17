-- Mine Egg (128, Jasperlode Mine in Elwynn Forest): the eggs players destroy for Extravagant Order (17001) did not
-- exist. Eleven eggs now lie beside the mine's Mine Spiders (43); destroying one hatches a Mine Spider that attacks
-- the player and drops Gem Encrusted Spider Silk (157001) like the others.
--
-- WHERE EACH VALUE COMES FROM
--   gameobject_template 128  AscensionDB WDB gameobjectcache (captured 2026-09-08, 91 sources, all CoA modes):
--     type 10 (goober), display 378, name 'Mine Egg', castBarCaption 'Destroying', size 1, Data0 lock 1691,
--     Data1 quest 17001 (usable only while Extravagant Order is incomplete), Data3 auto close 30000 ms, Data5
--     consumable 1 and Data14 open text 24585. They match stock Nerubian Scourge Egg 193051 except display and
--     quest (data/sql/base/db_world/gameobject_template.sql:19627).
--   AIName 'SmartGameObjectAI'  the egg hatches through the SmartAI row below.
--   gameobject_template_addon flags 4 (interact only when the quest condition holds)  as stock quest eggs 193051
--     and 184867 (data/sql/base/db_world/gameobject_template_addon.sql:19543, 13530).
--   smart_scripts  stock Nether Drake Egg 184867 (data/sql/base/db_world/smart_scripts.sql:39321): on gossip hello
--     summon a creature at the egg with summon type 4 (despawn 30 s after it leaves combat). Two changes:
--     event_param1 1 reacts only to the use itself, not to the client's later CMSG_GAMEOBJ_REPORT_USE, which also
--     raises gossip hello (SmartScript.cpp SMART_EVENT_GOSSIP_HELLO filter 1, SpellHandler.cpp
--     HandleGameobjectReportUse), so one egg hatches one spider; action_param4 2 makes the spider attack the player
--     who broke the egg (SmartScript.cpp SMART_ACTION_SUMMON_CREATURE, attackInvoker 2).
--   gameobject 7911400-7911410  INFERRED positions approved by the user for #6395: no capture records where the
--     eggs stand. One egg per Mine Spider spawn in the mine (creature 80987-80995 and 9002290-9002292), 1.5 yards in
--     front of the spider along its facing, at the spider's height and facing. Each is at least 3.5 yards from the
--     mine's other objects. The guids continue the Elwynn quest block (rev_20260923_01_coa_elwynn_quests.sql uses
--     7911200-7911250).
--   spawntimesecs 180, animprogress 0, state 1  the stock Nerubian Scourge Egg 193051 spawns.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(128, 10, 378, 'Mine Egg', '', 'Destroying', '', 1, 1691, 17001, 0, 30000, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 24585, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI', '', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `gameobject_template_addon` WHERE `entry` = 128;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(128, 0, 4, 0, 0, 0, 0, 0, 0);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 128 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(128, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 43, 4, 30000, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mine Egg - On Gossip Hello - Summon Creature \'Mine Spider\' And Attack Invoker');

DELETE FROM `gameobject` WHERE `guid` BETWEEN 7911400 AND 7911410;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(7911400, 128, 0, 0, 0, 1, 1, -9050.07, -617.56, 53.02, 3.73, 0, 0, 0.957033, -0.289978, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80987 (INFERRED)'),
(7911401, 128, 0, 0, 0, 1, 1, -9067.35, -549.28, 58.43, 4.03, 0, 0, 0.902953, -0.429739, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80988 (INFERRED)'),
(7911402, 128, 0, 0, 0, 1, 1, -9032.48, -585.44, 56.34, 0, 0, 0, 0, 1, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80990 (INFERRED)'),
(7911403, 128, 0, 0, 0, 1, 1, -9036.57, -608.9, 53.52, 5.63, 0, 0, 0.320818, -0.947141, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80991 (INFERRED)'),
(7911404, 128, 0, 0, 0, 1, 1, -9039.65, -552.73, 55.67, 1.1, 0, 0, 0.522687, 0.852525, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80992 (INFERRED)'),
(7911405, 128, 0, 0, 0, 1, 1, -9029.36, -612.27, 56.61, 1, 0, 0, 0.479426, 0.877583, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80993 (INFERRED)'),
(7911406, 128, 0, 0, 0, 1, 1, -9025.14, -604.28, 56.22, 4.73, 0, 0, 0.700853, -0.713306, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80994 (INFERRED)'),
(7911407, 128, 0, 0, 0, 1, 1, -9023.62, -565.59, 54.98, 0, 0, 0, 0, 1, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 80995 (INFERRED)'),
(7911408, 128, 0, 0, 0, 1, 1, -9030, -589.5, 56.38, 1.57, 0, 0, 0.706825, 0.707388, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 9002290 (INFERRED)'),
(7911409, 128, 0, 0, 0, 1, 1, -9046.09, -611.03, 52.5, 3.9, 0, 0, 0.92896, -0.370181, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 9002291 (INFERRED)'),
(7911410, 128, 0, 0, 0, 1, 1, -9030.02, -559.5, 55.16, 4.7, 0, 0, 0.711473, -0.702713, 180, 0, 1, '', 'CoA Elwynn: Jasperlode Mine, beside Mine Spider 9002292 (INFERRED)');
