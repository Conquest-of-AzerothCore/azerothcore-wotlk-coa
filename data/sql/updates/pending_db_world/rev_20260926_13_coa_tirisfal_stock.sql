-- CoA Tirisfal Glades: open-zone stock rows, Deathguard Simmer, graveyards 6075 and 6079 with Spirit
-- Healers, the Night Web's Hollow graveyard link, stranded holiday rows and CoA props.
-- Creature guids 9010850-9010899, gameobject guids 7916400-7916429.

-- ---------------------------------------------------------------------------
-- 1. Open-zone rows on the CoA ground
-- ---------------------------------------------------------------------------
-- Greater Duskbat (29929): Brightwater shore; CoA lowered the ground 3.3.
UPDATE `creature` SET `position_z` = 31.452 WHERE `guid` = 29929 AND `id` = 1553;
-- Greater Duskbat (43689): Brightwater shore; CoA lowered the ground 2.4.
UPDATE `creature` SET `position_z` = 29.478 WHERE `guid` = 43689 AND `id` = 1553;
-- Greater Duskbat (44492): Brightwater shore; floated 1.6.
UPDATE `creature` SET `position_z` = 34.51 WHERE `guid` = 44492 AND `id` = 1553;
-- Cursed Darkhound (44584): west of the plague field; sank 0.8.
UPDATE `creature` SET `position_z` = 53.62 WHERE `guid` = 44584 AND `id` = 1548;
-- Greater Duskbat (44812): west of Brill; floated 3.1.
UPDATE `creature` SET `position_z` = 45.793 WHERE `guid` = 44812 AND `id` = 1553;
-- Greater Duskbat (44871): plague field; floated 1.2.
UPDATE `creature` SET `position_z` = 51.036 WHERE `guid` = 44871 AND `id` = 1553;
-- Greater Duskbat (45005): plague field; floated 1.1.
UPDATE `creature` SET `position_z` = 57.354 WHERE `guid` = 45005 AND `id` = 1553;
-- Greater Duskbat (45009): plague field; floated 0.7.
UPDATE `creature` SET `position_z` = 50.616 WHERE `guid` = 45009 AND `id` = 1553;
-- Greater Duskbat (45012): plague field rise; sank 1.0.
UPDATE `creature` SET `position_z` = 67.451 WHERE `guid` = 45012 AND `id` = 1553;
-- Greater Duskbat (45190): west of Brill; floated 2.3.
UPDATE `creature` SET `position_z` = 41.489 WHERE `guid` = 45190 AND `id` = 1553;

-- Peacebloom (201535): pool 20103, plague field; floated 1.0.
UPDATE `gameobject` SET `position_z` = 61.125 WHERE `guid` = 201535 AND `id` = 1618;

-- Decrepit Darkhound (41896): its wander covered the new Fields of Grief graveyard; open field north of the
-- garden arches, 33 yd off.
UPDATE `creature` SET `position_x` = 2432, `position_y` = 1285, `position_z` = 31.213 WHERE `guid` = 41896 AND `id` = 1547;
-- Vile Fin Minor Oracle (44834): stood inside the recorded Murloc Hut 1; dry sand 4 yd south of it, facing the
-- huts.
UPDATE `creature` SET `position_x` = 3002, `position_y` = 283, `position_z` = 0.6, `orientation` = 6.23 WHERE `guid` = 44834 AND `id` = 1544;

-- ---------------------------------------------------------------------------
-- 2. Deathguard Simmer
-- ---------------------------------------------------------------------------
-- Deathguard Simmer (29794): Deathknell gate road inside the gate (Questie), facing the road between the
-- Deathguard Elites.
UPDATE `creature` SET `position_x` = 2155.8, `position_y` = 1280, `position_z` = 53.656, `orientation` = 5.35 WHERE `guid` = 29794 AND `id` = 1519;

-- ---------------------------------------------------------------------------
-- 3. Graveyards
-- ---------------------------------------------------------------------------
DELETE FROM `game_graveyard` WHERE `ID` IN (6075, 6079);
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`)
VALUES
(6075, 0, 1793.98, 1937.75, 155.878, 'Deathknell, Cain family Graveyard'),
(6079, 0, 2400.57, 1296.65, 30.984, 'Tirisfal Glades, Fields of Grief');

DELETE FROM `creature` WHERE `guid` IN (9010850, 9010851) OR `guid` BETWEEN 9010850 AND 9010899;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010850, 6491, 0, 0, 0, 1, 4294967295, 0, 1798.5, 1938.5, 156.181, 3.306, 60, 0, 0, 4120, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: Cain family graveyard: open ground north of the grave frames, facing the WorldSafeLocs point'),
(9010851, 6491, 0, 0, 0, 1, 4294967295, 0, 2396, 1297.5, 30.984, 6.1, 60, 0, 0, 4120, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tirisfal: Fields of Grief: between the hearse and the coffin, facing the WorldSafeLocs point');

-- Area links win over zone links; 6079 joins the Horde graveyards of zone 85.
DELETE FROM `graveyard_zone` WHERE (`ID`, `GhostZone`) IN ((6075, 10198), (6075, 10199), (6075, 10200), (6079, 85), (94, 10118));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(6075, 10198, 0, 'Cain Family Estate - Deathknell, Cain family Graveyard'),
(6075, 10199, 0, 'Cain Family Manor - Deathknell, Cain family Graveyard'),
(6075, 10200, 0, 'Cain Family Crypt - Deathknell, Cain family Graveyard'),
(6079, 85, 67, 'Tirisfal Glades - Tirisfal Glades, Fields of Grief'),
(94, 10118, 0, 'Night Web''s Hollow - Tirisfal Glades, Deathknell');

-- ---------------------------------------------------------------------------
-- 4. Holiday rows
-- ---------------------------------------------------------------------------
-- Pilgrim's Bounty turkeys and a Hallow's End effigy that CoA's ground left floating or buried.
-- Wild Turkey (242775): plague field; floated 0.9.
UPDATE `creature` SET `position_z` = 48.599 WHERE `guid` = 242775 AND `id` = 32820;
-- Wild Turkey (242791): west of Brill; floated 1.1.
UPDATE `creature` SET `position_z` = 55.058 WHERE `guid` = 242791 AND `id` = 32820;
-- Wild Turkey (242801): plague field; floated 2.0.
UPDATE `creature` SET `position_z` = 65.507 WHERE `guid` = 242801 AND `id` = 32820;
-- Wild Turkey (242826): west of Brill; floated 5.3.
UPDATE `creature` SET `position_z` = 38.422 WHERE `guid` = 242826 AND `id` = 32820;
-- Wild Turkey (242859): west of Brill; floated 5.0.
UPDATE `creature` SET `position_z` = 36.891 WHERE `guid` = 242859 AND `id` = 32820;
-- Wild Turkey (242908): Brightwater shore; floated 3.6.
UPDATE `creature` SET `position_z` = 31.175 WHERE `guid` = 242908 AND `id` = 32820;
-- Wild Turkey (243121): below the Rosewalk; floated 0.6.
UPDATE `creature` SET `position_z` = 34.861 WHERE `guid` = 243121 AND `id` = 32820;
-- Wild Turkey (243137): below the Rosewalk; floated 4.5.
UPDATE `creature` SET `position_z` = 29.963 WHERE `guid` = 243137 AND `id` = 32820;
-- Wild Turkey (243167): below the Rosewalk; floated 2.7.
UPDATE `creature` SET `position_z` = 33.62 WHERE `guid` = 243167 AND `id` = 32820;
-- Wild Turkey (243155): Fields of Grief; sank 0.4.
UPDATE `creature` SET `position_z` = 30.791 WHERE `guid` = 243155 AND `id` = 32820;

-- Wild Turkey (242907): was inside CoA's ruined guard tower; open plague-field ground west of its knoll.
UPDATE `creature` SET `position_x` = 2196, `position_y` = 478, `position_z` = 62.547 WHERE `guid` = 242907 AND `id` = 32820;
-- Headless Horseman - Fire (DND) (12735): buried 11 yd in CoA's ruined-tower knoll; north edge of the effigy
-- field between effigies 66922 and 43057.
UPDATE `creature` SET `position_x` = 2244, `position_y` = 480, `position_z` = 35.767 WHERE `guid` = 12735 AND `id` = 23537;

-- Fire Effigy (310): with its fire 12735.
UPDATE `gameobject` SET `position_x` = 2244, `position_y` = 480, `position_z` = 35.767 WHERE `guid` = 310 AND `id` = 186720;

-- ---------------------------------------------------------------------------
-- 5. CoA props
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(224, 5, 75323, 'Terokkar Web 04', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(65802, 5, 10, 'Gunther''s Lockbox', '', 'Looting', 0.6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(95699, 5, 1044953, 'Skeleton Hand RPG Prop', '', '', 0.35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515003, 5, 7517, 'Murloc Hut 1', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515419, 5, 7517, 'Murloc Hut 01', '', '', 3, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515420, 5, 7518, 'Murloc Hut 02', '', '', 3, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515422, 5, 7518, 'Murloc Hut 2', '', '', 1, 43, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(515458, 5, 39, 'Wooden Chair, no sit', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(515459, 5, 39, 'Chair', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject` WHERE `guid` IN (7916400, 7916401, 7916402, 7916403, 7916404, 7916405, 7916409, 7916410, 7916411, 7916412) OR `guid` BETWEEN 7916400 AND 7916429;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916400, 515003, 0, 0, 0, 1, 1, 3009.436, 282.566, -0.018, 4.17, 0, 0, 0.870685, -0.491842, 180, 100, 1, '', 'CoA Tirisfal: north-coast murloc camp, facing the camp'),
(7916401, 515420, 0, 0, 0, 1, 1, 3011.87, 278.924, -0.49, 3.8, 0, 0, 0.9463, -0.32329, 180, 100, 1, '', 'CoA Tirisfal: north-coast murloc camp, facing the camp'),
(7916402, 515422, 0, 0, 0, 1, 1, 3013.66, 266.318, -0.225, 2.65, 0, 0, 0.969944, 0.243329, 180, 100, 1, '', 'CoA Tirisfal: north-coast murloc camp, facing the camp'),
(7916403, 515419, 0, 0, 0, 1, 1, 3012.54, 262.572, 0.04, 2.36, 0, 0, 0.924606, 0.380925, 180, 100, 1, '', 'CoA Tirisfal: north-coast murloc camp, facing the camp'),
(7916404, 515458, 0, 0, 0, 1, 1, 1788.37, 721.435, 48.988, 0.38, 0, 0, 0.188859, 0.982004, 180, 100, 1, '', 'CoA Tirisfal: Captain Perrine''s tower floor, as recorded'),
(7916405, 515459, 0, 0, 0, 1, 1, 1789.01, 723.343, 48.988, 5.72, 0, 0, 0.277886, -0.960614, 180, 100, 1, '', 'CoA Tirisfal: Captain Perrine''s tower floor, as recorded'),
(7916409, 95699, 0, 0, 0, 1, 1, 2552.57, 544.416, 12.755, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Tirisfal: in the open grave'),
(7916410, 65802, 0, 0, 0, 1, 1, 2569.52, -38.582, 33.38, 2.39, 0, 0, 0.930216, 0.367013, 180, 100, 1, '', 'CoA Tirisfal: Gunther''s table, beside his books'),
(7916411, 224, 0, 0, 0, 1, 1, 2123.95, -716.879, 66.794, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Tirisfal: spider web on the canopy tree'),
(7916412, 179977, 0, 0, 0, 1, 1, 2272.08, 488.53, 33.553, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Tirisfal: by taxi node 417 (Brill)');
