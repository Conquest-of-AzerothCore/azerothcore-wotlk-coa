-- Five Scadeald Trees (lumber) the user placed around the Dun Kazad side of Pale Reach, three of them resized.
DELETE FROM `gameobject` WHERE `guid` IN (9963065, 9963067, 9963069, 9963070, 9963071);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9963065, 244642, 0, 0, 0, 1, 1, -6666.7, -529.056, 596.915, 4.71607, 0, 0, 0.705805, -0.708406, 300, 0, 1, '', NULL, 'Scadeald Tree (placed in game)'),
(9963067, 244641, 0, 0, 0, 1, 1, -6550.45, -558.557, 563.205, 5.42686, 0, 0, 0.415201, -0.90973, 300, 0, 1, '', NULL, 'Scadeald Tree (placed in game)'),
(9963069, 244642, 0, 0, 0, 1, 1, -6289.76, -500.715, 640.736, 5.40089, 0, 0, 0.426979, -0.904261, 300, 0, 1, '', NULL, 'Scadeald Tree (placed in game)'),
(9963070, 244642, 0, 0, 0, 1, 1, -6260.5, -340.655, 633.734, 1.1079, 0, 0, 0.526051, 0.850453, 300, 0, 1, '', NULL, 'Scadeald Tree (placed in game)'),
(9963071, 244642, 0, 0, 0, 1, 1, -6196.47, -279.098, 578.347, 1.71422, 0, 0, 0.755954, 0.654625, 300, 0, 1, '', NULL, 'Scadeald Tree (placed in game)');
DELETE FROM `gameobject_scale` WHERE `guid` IN (9963065, 9963069, 9963071);
INSERT INTO `gameobject_scale` (`guid`, `scale`) VALUES
(9963065, 0.729),
(9963069, 0.43),
(9963071, 0.729);

-- The Kerebor Guard drops Horns of Nez'ra (8%) like the other Kerebor mobs.
DELETE FROM `creature_loot_template` WHERE `Entry` = 164271 AND `Item` = 7906;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164271, 7906, 0, 8, 0, 1, 0, 1, 1, 'Kerebor Guard - Horns of Nez''ra');
