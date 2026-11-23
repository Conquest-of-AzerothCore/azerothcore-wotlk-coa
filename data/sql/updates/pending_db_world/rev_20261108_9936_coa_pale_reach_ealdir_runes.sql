-- Runic Ealdir (164343) drop Ealdir Runic Pebble (559910) for Ealdir Runes (175115), one at a time and half the time;
-- fppvzzEmIX8_000228 corpse loot window lists the pebble.
DELETE FROM `creature_loot_template` WHERE `Entry` = 164343 AND `Item` = 559910;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(164343, 559910, 0, 50, 1, 1, 0, 1, 1, 'Runic Ealdir - Ealdir Runic Pebble');

-- The imported ground pebbles are replaced by eight placed in game, and one Runic Ealdir (9960710) is removed.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9980005 AND 9980026 AND `id` = 2300691;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9980005, 2300691, 0, 0, 0, 1, 1, -7577.450, 1295.320, 216.312, 2.7960, 0, 0, 0.985110, 0.171923, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980006, 2300691, 0, 0, 0, 1, 1, -7588.060, 1256.750, 210.086, 0.8404, 0, 0, 0.407931, 0.913013, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980007, 2300691, 0, 0, 0, 1, 1, -7593.110, 1259.840, 209.831, 1.1051, 0, 0, 0.524842, 0.851199, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980008, 2300691, 0, 0, 0, 1, 1, -7659.840, 1299.840, 206.588, 1.7255, 0, 0, 0.759637, 0.650347, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980009, 2300691, 0, 0, 0, 1, 1, -7672.130, 1301.810, 206.892, 1.6391, 0, 0, 0.730846, 0.682543, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980010, 2300691, 0, 0, 0, 1, 1, -7667.910, 1303.420, 208.163, 1.6022, 0, 0, 0.718126, 0.695914, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980011, 2300691, 0, 0, 0, 1, 1, -7639.900, 1331.660, 205.468, 3.8681, 0, 0, 0.934746, -0.355317, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)'),
(9980012, 2300691, 0, 0, 0, 1, 1, -7688.575, 1331.641, 206.160, 0.8011, 0, 0, 0.389925, 0.920847, 60, 100, 1, 'Ealdir Runic Pebble, Scadeald Barrows (placed in game)');

DELETE FROM `creature` WHERE `guid` = 9960710 AND `id` = 164343;
