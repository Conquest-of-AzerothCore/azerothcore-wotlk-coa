CREATE TABLE IF NOT EXISTS `coa_reputation_item_budget` (
    `entry` INT UNSIGNED NOT NULL,
    `faction_id` SMALLINT UNSIGNED NOT NULL,
    `original_item_level` SMALLINT UNSIGNED NOT NULL,
    `item_level` SMALLINT UNSIGNED NOT NULL,
    `pve_power` SMALLINT UNSIGNED NOT NULL,
    `pvp_power` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB;

START TRANSACTION;

DELETE FROM `coa_reputation_item_budget` WHERE `entry` IN (
    15040, 29115, 29116, 29117, 29119, 29121, 29122, 29123, 29124, 29125, 29126, 29127, 29128, 29129, 29130, 29131,
    29132, 29133, 29134, 29135, 29136, 29137, 29138, 29139, 29140, 29141, 29142, 29145, 29146, 29147, 29148, 29175,
    29176, 29177, 29179, 29180, 29181, 29182, 29183, 29184, 29185, 29294, 29295, 29296, 29297, 29298, 29299, 29300,
    29301, 29302, 29303, 29304, 29305, 29306, 29307, 29308, 29309, 29456, 29457, 30830, 30832, 30834, 30835, 30836,
    30841, 32485, 32486, 32487, 32488, 32489, 32490, 32491, 32492, 32493, 32538, 32539, 32645, 32647, 32648, 32650,
    32651, 32652, 32653, 32654, 32694, 32695, 32770, 32771, 32863, 32864, 34665, 34666, 34667, 34670, 34671, 34672,
    34673, 34674, 34675, 34676, 34677, 34678, 34679, 34680, 35328, 35329, 35330, 35331, 35333, 35334, 35335, 35336,
    35338, 35340, 35341, 35342, 35344, 35345, 35346, 35347, 35356, 35357, 35358, 35359, 35361, 35362, 35363, 35365,
    35367, 35368, 35369, 35370, 35372, 35373, 35374, 35375, 35376, 35378, 35379, 35380, 35381, 35382, 35384, 35385,
    35387, 35388, 35389, 35390, 35391, 35393, 35394, 35395, 35402, 35403, 35404, 35405, 35407, 35408, 35410, 35411,
    35412, 35414, 35415, 35416);
INSERT INTO `coa_reputation_item_budget`
    (`entry`, `faction_id`, `original_item_level`, `item_level`, `pve_power`, `pvp_power`)
VALUES
(15040, 990, 154, 77, 20, 0),
(29115, 933, 123, 71, 45, 0),
(29116, 933, 123, 71, 38, 0),
(29117, 933, 123, 71, 38, 0),
(29119, 933, 127, 77, 20, 0),
(29121, 933, 127, 77, 48, 0),
(29122, 933, 127, 77, 38, 0),
(29123, 932, 127, 77, 20, 0),
(29124, 932, 127, 77, 48, 0),
(29125, 934, 127, 77, 48, 0),
(29126, 934, 127, 77, 20, 0),
(29127, 932, 123, 71, 38, 0),
(29128, 932, 123, 71, 20, 0),
(29129, 932, 115, 60, 38, 0),
(29130, 932, 123, 71, 96, 0),
(29131, 934, 123, 60, 38, 0),
(29132, 934, 123, 60, 20, 0),
(29133, 934, 123, 60, 96, 0),
(29134, 934, 123, 60, 25, 0),
(29135, 941, 127, 77, 38, 0),
(29136, 978, 127, 77, 38, 0),
(29137, 941, 127, 77, 96, 0),
(29138, 978, 127, 77, 96, 0),
(29139, 941, 127, 77, 20, 0),
(29140, 978, 127, 77, 20, 0),
(29141, 941, 123, 60, 38, 0),
(29142, 978, 123, 60, 38, 0),
(29145, 941, 123, 60, 20, 0),
(29146, 978, 123, 60, 20, 0),
(29147, 941, 123, 60, 25, 0),
(29148, 978, 123, 60, 25, 0),
(29175, 935, 127, 77, 48, 0),
(29176, 935, 127, 77, 48, 0),
(29177, 935, 127, 77, 20, 0),
(29179, 935, 123, 71, 20, 0),
(29180, 935, 123, 71, 25, 0),
(29181, 989, 127, 77, 20, 0),
(29182, 989, 127, 77, 48, 0),
(29183, 989, 127, 77, 20, 0),
(29184, 989, 123, 71, 38, 0),
(29185, 989, 123, 71, 48, 0),
(29294, 990, 134, 60, 20, 0),
(29295, 990, 141, 66, 20, 0),
(29296, 990, 147, 71, 20, 0),
(29297, 990, 154, 77, 20, 0),
(29298, 990, 134, 60, 20, 0),
(29299, 990, 141, 66, 20, 0),
(29300, 990, 147, 71, 20, 0),
(29301, 990, 154, 77, 20, 0),
(29302, 990, 134, 60, 20, 0),
(29303, 990, 141, 66, 20, 0),
(29304, 990, 147, 71, 20, 0),
(29305, 990, 154, 77, 20, 0),
(29306, 990, 141, 66, 20, 0),
(29307, 990, 134, 60, 20, 0),
(29308, 990, 147, 71, 20, 0),
(29309, 990, 154, 77, 20, 0),
(29456, 933, 115, 60, 48, 0),
(29457, 933, 115, 60, 48, 0),
(30830, 1011, 127, 77, 96, 0),
(30832, 1011, 127, 77, 48, 0),
(30834, 1011, 127, 77, 20, 0),
(30835, 1011, 123, 71, 38, 0),
(30836, 1011, 123, 71, 38, 0),
(30841, 1011, 123, 71, 20, 0),
(32485, 1012, 134, 69, 20, 0),
(32486, 1012, 134, 69, 20, 0),
(32487, 1012, 134, 69, 20, 0),
(32488, 1012, 134, 69, 20, 0),
(32489, 1012, 134, 69, 20, 0),
(32490, 1012, 134, 69, 20, 0),
(32491, 1012, 134, 69, 20, 0),
(32492, 1012, 134, 69, 20, 0),
(32493, 1012, 134, 69, 20, 0),
(32538, 1031, 123, 60, 20, 0),
(32539, 1031, 123, 60, 20, 0),
(32645, 1038, 127, 77, 45, 0),
(32647, 1038, 127, 77, 20, 0),
(32648, 1038, 127, 77, 25, 0),
(32650, 1038, 123, 60, 45, 0),
(32651, 1038, 127, 77, 48, 0),
(32652, 1038, 123, 60, 48, 0),
(32653, 1038, 123, 60, 20, 0),
(32654, 1038, 123, 60, 20, 0),
(32694, 1015, 100, 71, 20, 0),
(32695, 1015, 110, 75, 20, 0),
(32770, 1031, 127, 77, 20, 0),
(32771, 1031, 127, 77, 20, 0),
(32863, 1015, 70, 60, 20, 0),
(32864, 1015, 115, 77, 20, 0),
(34665, 1077, 125, 60, 48, 0),
(34666, 1077, 125, 60, 48, 0),
(34667, 1077, 125, 60, 48, 0),
(34670, 1077, 125, 60, 48, 0),
(34671, 1077, 125, 60, 48, 0),
(34672, 1077, 125, 60, 48, 0),
(34673, 1077, 125, 60, 96, 0),
(34674, 1077, 125, 60, 45, 0),
(34675, 1077, 134, 77, 48, 0),
(34676, 1077, 134, 77, 48, 0),
(34677, 1077, 134, 77, 20, 0),
(34678, 1077, 134, 77, 20, 0),
(34679, 1077, 134, 77, 20, 0),
(34680, 1077, 134, 77, 20, 0),
(35328, 989, 115, 60, 25, 36),
(35329, 942, 115, 69, 38, 42),
(35330, 935, 115, 60, 38, 42),
(35331, 1011, 115, 60, 25, 36),
(35333, 935, 115, 60, 38, 42),
(35334, 989, 115, 60, 38, 42),
(35335, 1011, 115, 60, 25, 36),
(35336, 942, 115, 69, 25, 36),
(35338, 989, 115, 60, 25, 36),
(35340, 1011, 115, 60, 38, 42),
(35341, 935, 115, 60, 25, 36),
(35342, 942, 115, 69, 38, 42),
(35344, 1011, 115, 60, 38, 42),
(35345, 935, 115, 60, 25, 36),
(35346, 989, 115, 60, 38, 42),
(35347, 942, 115, 69, 38, 42),
(35356, 989, 115, 60, 25, 36),
(35357, 1011, 115, 60, 38, 42),
(35358, 942, 115, 69, 38, 42),
(35359, 935, 115, 60, 25, 36),
(35361, 1011, 115, 60, 25, 36),
(35362, 935, 115, 60, 38, 42),
(35363, 989, 115, 60, 38, 42),
(35365, 942, 115, 69, 38, 42),
(35367, 942, 115, 69, 38, 42),
(35368, 935, 115, 60, 38, 42),
(35369, 989, 115, 60, 25, 36),
(35370, 1011, 115, 60, 38, 42),
(35372, 989, 115, 60, 38, 42),
(35373, 1011, 115, 60, 38, 42),
(35374, 942, 115, 69, 25, 36),
(35375, 935, 115, 60, 38, 42),
(35376, 989, 115, 60, 38, 42),
(35378, 1011, 115, 60, 38, 42),
(35379, 942, 115, 69, 38, 42),
(35380, 935, 115, 60, 25, 36),
(35381, 935, 115, 60, 38, 42),
(35382, 1011, 115, 60, 25, 36),
(35384, 989, 115, 60, 38, 42),
(35385, 942, 115, 69, 25, 36),
(35387, 942, 115, 69, 25, 36),
(35388, 935, 115, 60, 38, 42),
(35389, 1011, 115, 60, 38, 42),
(35390, 989, 115, 60, 25, 36),
(35391, 1011, 115, 60, 38, 42),
(35393, 989, 115, 60, 38, 42),
(35394, 942, 115, 69, 38, 42),
(35395, 935, 115, 60, 25, 36),
(35402, 989, 115, 60, 38, 42),
(35403, 942, 115, 69, 25, 36),
(35404, 935, 115, 60, 38, 42),
(35405, 1011, 115, 60, 38, 42),
(35407, 935, 115, 60, 38, 42),
(35408, 942, 115, 69, 25, 36),
(35410, 989, 115, 60, 38, 42),
(35411, 1011, 115, 60, 25, 36),
(35412, 1011, 115, 60, 38, 42),
(35414, 989, 115, 60, 38, 42),
(35415, 942, 115, 69, 38, 42),
(35416, 935, 115, 60, 25, 36);

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 75, `stat_value1` = 14, `stat_value2` = 22,
    `stat_value3` = 30, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185062, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 15040;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 4, `stat_value3` =
    15, `stat_value4` = 6, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 85.947, `dmg_max1` = 159.754, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101645, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 29115;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 22, `stat_value2` = 18, `stat_value3`
    = 8, `stat_value4` = 9, `stat_value5` = 38, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 335, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29116;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 16, `stat_value2` = 14, `stat_value3`
    = 9, `stat_value4` = 10, `stat_value5` = 9, `stat_value6` = 32, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 298, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29117;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 17, `stat_value2` = 10, `stat_value3`
    = 17, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29119;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 29, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 86.462, `dmg_max1` = 121.918,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29121;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 2910, `stat_value1` = 30, `stat_value2` = 23,
    `stat_value3` = 13, `stat_value4` = 35, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 324, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29122;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 12, `stat_value3`
    = 13, `stat_value4` = 8, `stat_value5` = 21, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29123;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 33, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 115.475, `dmg_max1` = 185.518,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29124;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 14, `stat_value3`
    = 14, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 67.478, `dmg_max1` = 94.595,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29125;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 14, `stat_value3`
    = 27, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29126;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 24, `stat_value2` = 18, `stat_value3`
    = 15, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 566, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29127;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 13, `stat_value2` = 12, `stat_value3`
    = 22, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29128;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2881, `stat_value1` = 12, `stat_value2` = 16,
    `stat_value3` = 7, `stat_value4` = 17, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 247, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29129;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 22, `stat_value2` = 20, `stat_value3`
    = 14, `stat_value4` = 18, `stat_value5` = 9, `stat_value6` = 101, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 48.799, `dmg_max1` = 77.831,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29130;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 16, `stat_value2` = 15, `stat_value3`
    = 8, `stat_value4` = 9, `stat_value5` = 26, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29131;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 15, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 35337, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29132;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 23, `stat_value3`
    = 16, `stat_value4` = 13, `stat_value5` = 84, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 40.467, `dmg_max1` = 64.543,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29133;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 9, `stat_value2` = 12, `stat_value3`
    = 9, `stat_value4` = 8, `stat_value5` = 6, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 301, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101625, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29134;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 2875, `stat_value1` = 26, `stat_value2` = 17,
    `stat_value3` = 23, `stat_value4` = 36, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 487, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29135;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 2875, `stat_value1` = 26, `stat_value2` = 17,
    `stat_value3` = 23, `stat_value4` = 36, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 487, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29136;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 28, `stat_value3`
    = 10, `stat_value4` = 67, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 222.801, `dmg_max1` = 333.554,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29137;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 28, `stat_value3`
    = 10, `stat_value4` = 67, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 222.868, `dmg_max1` = 333.654,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29138;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 10, `stat_value2` = 23, `stat_value3`
    = 21, `stat_value4` = 5, `stat_value5` = 16, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 194, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29139;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 17, `stat_value2` = 10, `stat_value3`
    = 10, `stat_value4` = 9, `stat_value5` = 5, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 194, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29140;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2881, `stat_value1` = 11, `stat_value2` = 10,
    `stat_value3` = 7, `stat_value4` = 8, `stat_value5` = 15, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29141;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2881, `stat_value1` = 11, `stat_value2` = 10,
    `stat_value3` = 7, `stat_value4` = 8, `stat_value5` = 15, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29142;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 8, `stat_value3` =
    6, `stat_value4` = 11, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29145;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 8, `stat_value3` =
    6, `stat_value4` = 11, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29146;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 9, `stat_value3`
    = 8, `stat_value4` = 27, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 242, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101625, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29147;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 9, `stat_value3`
    = 8, `stat_value4` = 27, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 242, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101625, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29148;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 22, `stat_value3`
    = 8, `stat_value4` = 10, `stat_value5` = 131, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 45.979, `dmg_max1` = 84.421,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29175;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 2926, `stat_value1` = 12, `stat_value2` = 22,
    `stat_value3` = 14, `stat_value4` = 27, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 2466, `block` = 71, `spellid_1` = 0, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101648, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29176;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 21, `stat_value2` = 14, `stat_value3`
    = 12, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29177;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 35337, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29179;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 9, `stat_value3`
    = 11, `stat_value4` = 33, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 255, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101625, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29180;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 12, `stat_value3`
    = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29181;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 17, `stat_value2` = 14, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 86.509, `dmg_max1` = 121.871,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 35353, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29182;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 13, `stat_value2` = 16, `stat_value3`
    = 10, `stat_value4` = 23, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 172, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29183;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 25182, `stat_value1` = 26, `stat_value2` = 12,
    `stat_value3` = 10, `stat_value4` = 8, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 497, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29184;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 5, `stat_value2` = 12, `stat_value3`
    = 4, `stat_value4` = 5, `stat_value5` = 93, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 32.526, `dmg_max1` = 59.529,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29185;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 12, `stat_value3`
    = 8, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29294;

UPDATE `item_template`
SET `ItemLevel` = 66, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 20, `stat_value2` = 14, `stat_value3`
    = 9, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29295;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 22, `stat_value2` = 15, `stat_value3`
    = 10, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185053, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29296;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 72, `stat_value1` = 22, `stat_value2` = 15,
    `stat_value3` = 10, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185053, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29297;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 18, `stat_value3`
    = 8, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29298;

UPDATE `item_template`
SET `ItemLevel` = 66, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 13, `stat_value2` = 20, `stat_value3`
    = 9, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29299;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 22, `stat_value3`
    = 10, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185056, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29300;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 69, `stat_value1` = 14, `stat_value2` = 22,
    `stat_value3` = 10, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185056, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29301;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 10, `stat_value4` = 14, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29302;

UPDATE `item_template`
SET `ItemLevel` = 66, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 11, `stat_value4` = 16, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29303;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 12, `stat_value3`
    = 12, `stat_value4` = 17, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185058, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29304;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 207, `stat_value1` = 14, `stat_value2` = 12,
    `stat_value3` = 12, `stat_value4` = 17, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185058, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29305;

UPDATE `item_template`
SET `ItemLevel` = 66, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 8, `stat_value4` = 19, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29306;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 7, `stat_value4` = 17, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29307;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 12, `stat_value3`
    = 10, `stat_value4` = 20, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185060, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29308;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 207, `stat_value1` = 14, `stat_value2` = 12,
    `stat_value3` = 10, `stat_value4` = 20, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 2185060, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29309;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 11, `stat_value2` = 8, `stat_value3`
    = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 75.342, `dmg_max1` = 120.958,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 29456;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 9, `stat_value2` = 8, `stat_value3` =
    83, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 26.446, `dmg_max1` = 48.485, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 29457;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 25, `stat_value2` = 36, `stat_value3`
    = 24, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 231.869, `dmg_max1` = 324.487,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30830;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 11, `stat_value2` = 9, `stat_value3`
    = 16, `stat_value4` = 124, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 64.782, `dmg_max1` = 120.525,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30832;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 16, `stat_value2` = 14, `stat_value3`
    = 12, `stat_value4` = 22, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30834;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 16, `stat_value2` = 14, `stat_value3`
    = 20, `stat_value4` = 43, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 444, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30835;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 14, `stat_value2` = 20, `stat_value3`
    = 9, `stat_value4` = 27, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 261, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101638, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30836;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 25, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 37877, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 30841;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823936, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32485;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823931, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32486;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823935, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32487;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823932, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32488;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823938, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32489;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823930, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32490;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823937, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32491;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823933, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32492;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 823934, `spellid_2` = 0, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32493;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 6, `stat_value2` = 10, `stat_value3`
    = 6, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 119, `block` = 0, `spellid_1` = 0, `spellid_2` = 12438,
    `spellid_3` = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32538;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 9, `stat_value3` =
    7, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 119, `block` = 0, `spellid_1` = 0, `spellid_2` = 12438, `spellid_3` = 0, `spellid_4`
    = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32539;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 9, `stat_value2` = 11, `stat_value3`
    = 17, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 118.455, `dmg_max1` = 221.43,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101645,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32645;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 699933, `stat_value1` = 14, `stat_value2` = 12,
    `stat_value3` = 28, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 310, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32647;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 69, `stat_value1` = 20, `stat_value2` = 20,
    `stat_value3` = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 521, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101625, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32648;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 5, `stat_value2` = 7, `stat_value3` =
    7, `stat_value4` = 7, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 60.535, `dmg_max1` = 112.879, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101645, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 32650;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 12, `stat_value3`
    = 6, `stat_value4` = 24, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0,
    `spellid_4` = 101648, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32651;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 3017, `stat_value1` = 23, `stat_value2` = 13,
    `stat_value3` = 30, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 1511, `block` = 44, `spellid_1` = 0, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101648, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32652;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 8, `stat_value2` = 6, `stat_value3` =
    7, `stat_value4` = 15, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 119, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32653;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 40724, `spellid_2` = 40723, `spellid_3` = 0,
    `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32654;

UPDATE `item_template`
SET `ItemLevel` = 71, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 40811, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32694;

UPDATE `item_template`
SET `ItemLevel` = 75, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 40815, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32695;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 41260, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32770;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 41262, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32771;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 0, `stat_value2` = 0, `stat_value3` =
    0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 48776, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` =
    101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32863;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 32, `stat_value2` = 0, `stat_value3`
    = 0, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 40815, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 32864;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 7, `stat_value2` = 5, `stat_value3` =
    6, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 56.533, `dmg_max1` = 79.367, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 34665;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 7, `stat_value2` = 5, `stat_value3` =
    6, `stat_value4` = 13, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 75.279, `dmg_max1` = 121.021, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 34666;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 10, `stat_value2` = 5, `stat_value3`
    = 6, `stat_value4` = 63, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 36.325, `dmg_max1` = 67.462,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34667;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 5, `stat_value2` = 4, `stat_value3` =
    15, `stat_value4` = 63, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 36.031, `dmg_max1` = 66.917,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34670;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 6, `stat_value2` = 8, `stat_value3` =
    4, `stat_value4` = 6, `stat_value5` = 61, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 36.031, `dmg_max1` = 66.917, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 34671;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 10, `stat_value2` = 5, `stat_value3`
    = 3, `stat_value4` = 6, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 46.326, `dmg_max1` = 74.474,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101648,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34672;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 21, `stat_value2` = 12, `stat_value3`
    = 14, `stat_value4` = 7, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 137.572, `dmg_max1` = 206.356,
    `dmg_min2` = 0.0, `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101696,
    `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34673;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 5, `stat_value2` = 6, `stat_value3` =
    3, `stat_value4` = 10, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0, `stat_value9`
    = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0,
    `arcane_res` = 0, `armor` = 0, `block` = 0, `dmg_min1` = 72.541, `dmg_max1` = 135.166, `dmg_min2` = 0.0,
    `dmg_max2` = 0.0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` = 0, `spellid_4` = 101645, `spellid_5` = 0,
    `spelltrigger_4` = 1
WHERE `entry` = 34674;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 11, `stat_value3`
    = 8, `stat_value4` = 16, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 2466, `block` = 71, `spellid_1` = 0, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101648, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34675;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 11, `stat_value3`
    = 8, `stat_value4` = 40, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 2466, `block` = 71, `spellid_1` = 0, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101648, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34676;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 9, `stat_value3`
    = 26, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 45484, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34677;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 22, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 45481, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34678;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 11, `stat_value3`
    = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 45482, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34679;

UPDATE `item_template`
SET `ItemLevel` = 77, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 29, `stat_value2` = 6, `stat_value3`
    = 11, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 0, `block` = 0, `spellid_1` = 45483, `spellid_2` = 0, `spellid_3`
    = 0, `spellid_4` = 101620, `spellid_5` = 0, `spelltrigger_4` = 1
WHERE `entry` = 34680;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 17, `stat_value2` = 11, `stat_value3`
    = 0, `stat_value4` = 14, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 192, `block` = 0, `spellid_1` = 33063, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35328;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2859, `stat_value1` = 31, `stat_value2` = 9,
    `stat_value3` = 0, `stat_value4` = 18, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 22, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 236, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35329;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 26, `stat_value2` = 12, `stat_value3`
    = 0, `stat_value4` = 21, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 217, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35330;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 10, `stat_value2` = 8,
    `stat_value3` = 0, `stat_value4` = 3, `stat_value5` = 14, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 189, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35331;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 21, `stat_value2` = 15,
    `stat_value3` = 0, `stat_value4` = 10, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 200, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35333;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 15, `stat_value3`
    = 0, `stat_value4` = 19, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 217, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35334;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 8, `stat_value3`
    = 0, `stat_value4` = 14, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 192, `block` = 0, `spellid_1` = 23044, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35335;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 19, `stat_value2` = 12,
    `stat_value3` = 0, `stat_value4` = 9, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 16, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 219, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35336;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 8, `stat_value3`
    = 0, `stat_value4` = 14, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 192, `block` = 0, `spellid_1` = 44297, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35338;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 25, `stat_value2` = 12, `stat_value3`
    = 0, `stat_value4` = 19, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 217, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35340;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 9,
    `stat_value3` = 0, `stat_value4` = 8, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 189, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35341;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2859, `stat_value1` = 29, `stat_value2` = 10,
    `stat_value3` = 0, `stat_value4` = 17, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 22, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 291, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35342;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 21, `stat_value2` = 9,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 200, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35344;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 6, `stat_value3`
    = 9, `stat_value4` = 0, `stat_value5` = 10, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 192, `block` = 0, `spellid_1` = 44301, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35345;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 23, `stat_value2` = 8,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 247, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35346;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 27, `stat_value2` = 14, `stat_value3`
    = 14, `stat_value4` = 0, `stat_value5` = 21, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 22, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 255, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35347;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 13, `stat_value2` = 7, `stat_value3`
    = 6, `stat_value4` = 8, `stat_value5` = 0, `stat_value6` = 11, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 13, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 203, `block` = 0, `spellid_1` = 0, `spellid_2` = 61252,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35356;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 11, `stat_value2` = 9,
    `stat_value3` = 8, `stat_value4` = 10, `stat_value5` = 0, `stat_value6` = 10, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 257, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35357;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 11, `stat_value3`
    = 14, `stat_value4` = 12, `stat_value5` = 0, `stat_value6` = 19, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 20, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 326, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35358;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 13, `stat_value2` = 7,
    `stat_value3` = 8, `stat_value4` = 8, `stat_value5` = 0, `stat_value6` = 6, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 13, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 242, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35359;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 12, `stat_value2` = 12, `stat_value3`
    = 0, `stat_value4` = 4, `stat_value5` = 16, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 13, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 203, `block` = 0, `spellid_1` = 0, `spellid_2` = 33830,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35361;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 16, `stat_value2` = 10,
    `stat_value3` = 0, `stat_value4` = 6, `stat_value5` = 15, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 257, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35362;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 15, `stat_value3`
    = 0, `stat_value4` = 8, `stat_value5` = 21, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35363;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2859, `stat_value1` = 21, `stat_value2` = 11,
    `stat_value3` = 0, `stat_value4` = 6, `stat_value5` = 16, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 23, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 372, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35365;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2859, `stat_value1` = 23, `stat_value2` = 13,
    `stat_value3` = 0, `stat_value4` = 6, `stat_value5` = 13, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 20, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 302, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35367;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 15, `stat_value3`
    = 8, `stat_value4` = 0, `stat_value5` = 15, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35368;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 17, `stat_value2` = 7,
    `stat_value3` = 6, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 13, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 242, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35369;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 23, `stat_value2` = 11,
    `stat_value3` = 0, `stat_value4` = 5, `stat_value5` = 6, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 316, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35370;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 11, `stat_value2` = 10,
    `stat_value3` = 0, `stat_value4` = 5, `stat_value5` = 20, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 257, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35372;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 12, `stat_value3`
    = 0, `stat_value4` = 8, `stat_value5` = 24, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 277, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35373;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 21, `stat_value2` = 10,
    `stat_value3` = 0, `stat_value4` = 3, `stat_value5` = 10, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 279, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35374;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 9,
    `stat_value3` = 0, `stat_value4` = 5, `stat_value5` = 13, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 19, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 316, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35375;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 23, `stat_value2` = 11,
    `stat_value3` = 6, `stat_value4` = 0, `stat_value5` = 8, `stat_value6` = 6, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 19, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 368, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35376;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 16, `stat_value2` = 11,
    `stat_value3` = 8, `stat_value4` = 0, `stat_value5` = 8, `stat_value6` = 15, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 301, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35378;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 27, `stat_value2` = 18, `stat_value3`
    = 9, `stat_value4` = 0, `stat_value5` = 5, `stat_value6` = 18, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 383, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35379;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 17, `stat_value2` = 8,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 2, `stat_value6` = 12, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 284, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35380;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 23, `stat_value2` = 24,
    `stat_value3` = 8, `stat_value4` = 0, `stat_value5` = 6, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 19, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 368, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35381;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 18, `stat_value2` = 23, `stat_value3`
    = 10, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 238, `block` = 0, `spellid_1` = 33020, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35382;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 24, `stat_value3`
    = 15, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 325, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35384;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 21, `stat_value2` = 16,
    `stat_value3` = 11, `stat_value4` = 0, `stat_value5` = 5, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 327, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35385;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 21, `stat_value2` = 8, `stat_value3`
    = 9, `stat_value4` = 0, `stat_value5` = 16, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 275, `block` = 0, `spellid_1` = 32973, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35387;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 19, `stat_value2` = 9,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 301, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35388;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 10, `stat_value3`
    = 12, `stat_value4` = 0, `stat_value5` = 4, `stat_value6` = 19, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 325, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35389;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 7,
    `stat_value3` = 6, `stat_value4` = 0, `stat_value5` = 4, `stat_value6` = 10, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 284, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35390;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 18, `stat_value2` = 12,
    `stat_value3` = 10, `stat_value4` = 0, `stat_value5` = 5, `stat_value6` = 10, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 19, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 368, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35391;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 11,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 12, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 15, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 301, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35393;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 23, `stat_value2` = 15, `stat_value3`
    = 14, `stat_value4` = 0, `stat_value5` = 5, `stat_value6` = 23, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 18, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 383, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35394;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 15, `stat_value2` = 10,
    `stat_value3` = 6, `stat_value4` = 0, `stat_value5` = 4, `stat_value6` = 10, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 284, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35395;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 20, `stat_value2` = 13,
    `stat_value3` = 11, `stat_value4` = 0, `stat_value5` = 5, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 469, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35402;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 12, `stat_value3`
    = 12, `stat_value4` = 0, `stat_value5` = 13, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 348, `block` = 0, `spellid_1` = 0, `spellid_2` = 38522,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35403;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 12,
    `stat_value3` = 11, `stat_value4` = 0, `stat_value5` = 10, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 381, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35404;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 21, `stat_value2` = 14, `stat_value3`
    = 13, `stat_value4` = 0, `stat_value5` = 15, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 412, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35405;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 25, `stat_value2` = 6,
    `stat_value3` = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 469, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35407;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 19, `stat_value2` = 14, `stat_value3`
    = 13, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 12, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 348, `block` = 0, `spellid_1` = 22778, `spellid_2` = 0,
    `spellid_3` = 0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35408;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 25, `stat_value2` = 15, `stat_value3`
    = 15, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 412, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35410;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 20, `stat_value2` = 8,
    `stat_value3` = 9, `stat_value4` = 0, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 11, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 360, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35411;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2857, `stat_value1` = 23, `stat_value2` = 6,
    `stat_value3` = 7, `stat_value4` = 15, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 469, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35412;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 16, `stat_value2` = 9,
    `stat_value3` = 7, `stat_value4` = 15, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 14, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 381, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35414;

UPDATE `item_template`
SET `ItemLevel` = 69, `RequiredLevel` = 60, `socketBonus` = 0, `stat_value1` = 27, `stat_value2` = 10, `stat_value3`
    = 10, `stat_value4` = 23, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` = 0,
    `stat_value9` = 0, `stat_value10` = 17, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 485, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101742, `spellid_5` = 101638, `spelltrigger_5` = 1
WHERE `entry` = 35415;

UPDATE `item_template`
SET `ItemLevel` = 60, `RequiredLevel` = 60, `socketBonus` = 2867, `stat_value1` = 18, `stat_value2` = 4,
    `stat_value3` = 5, `stat_value4` = 14, `stat_value5` = 0, `stat_value6` = 0, `stat_value7` = 0, `stat_value8` =
    0, `stat_value9` = 0, `stat_value10` = 11, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0,
    `shadow_res` = 0, `arcane_res` = 0, `armor` = 360, `block` = 0, `spellid_1` = 0, `spellid_2` = 0, `spellid_3` =
    0, `spellid_4` = 101736, `spellid_5` = 101625, `spelltrigger_5` = 1
WHERE `entry` = 35416;

UPDATE `item_template` SET `RequiredLevel` = 60
WHERE `RequiredLevel` > 60 AND `entry` IN (
    24417, 28878, 28881, 28882, 28885, 28886, 28887, 28888, 28889, 28903, 28904, 28907, 28908, 28909, 28910, 28911,
    28912, 29186, 29189, 29190, 29191, 29192, 29193, 29194, 29195, 29196, 29197, 29198, 29199, 30846, 31735, 31737,
    31949, 32314, 32316, 32317, 32318, 32319, 32722, 32783, 32784, 32857, 32858, 32859, 32860, 32861, 32862, 32882,
    32883, 33999, 34780, 37504);

UPDATE `quest_template` SET `MinLevel` = 60
WHERE `MinLevel` BETWEEN 61 AND 254 AND `ID` IN (
    9884, 9885, 9886, 9887, 9893, 9957, 10020, 10021, 10169, 10189, 10193, 10194, 10197, 10198, 10202, 10204, 10241,
    10243, 10245, 10246, 10299, 10313, 10321, 10322, 10323, 10328, 10329, 10330, 10338, 10341, 10365, 10380, 10381,
    10407, 10409, 10410, 10431, 10432, 10460, 10461, 10462, 10463, 10464, 10465, 10468, 10469, 10472, 10473, 10475,
    10507, 10508, 10509, 10560, 10568, 10571, 10574, 10575, 10587, 10619, 10637, 10640, 10650, 10651, 10652, 10683,
    10684, 10685, 10686, 10687, 10688, 10689, 10691, 10692, 10807, 10816, 10817, 10969, 10970, 10971, 10973, 10982,
    11026, 11027, 11031, 11032, 11033, 11034, 11038, 11053, 11054, 11055, 11060, 11063, 11064, 11067, 11068, 11069,
    11070, 11071, 11075, 11076, 11077, 11081, 11083, 11084, 11086, 11089, 11090, 11091, 11092, 11094, 11095, 11097,
    11099, 11100, 11101, 11103, 11104, 11105, 11106, 11107, 11108, 11109, 11110, 11111, 11112, 11113, 11114, 11549,
    11554, 11555, 11556, 11557);

DELETE FROM `coa_zone_property_mapping` WHERE `zone_id` = 3520 AND `entry` = 32694;
INSERT INTO `coa_zone_property_mapping`
    (`zone_id`, `entry`, `original_property`, `scaled_property`)
VALUES
(3520, 32694, 311, 313),
(3520, 32694, 313, 313),
(3520, 32694, 340, 343),
(3520, 32694, 343, 343),
(3520, 32694, 361, 364),
(3520, 32694, 364, 364),
(3520, 32694, 391, 395),
(3520, 32694, 395, 395),
(3520, 32694, 420, 423),
(3520, 32694, 423, 423),
(3520, 32694, 451, 457),
(3520, 32694, 457, 457),
(3520, 32694, 540, 540),
(3520, 32694, 795, 801),
(3520, 32694, 801, 801),
(3520, 32694, 876, 882),
(3520, 32694, 882, 882),
(3520, 32694, 1049, 1052),
(3520, 32694, 1052, 1052),
(3520, 32694, 1216, 1216),
(3520, 32694, 8513, 19644),
(3520, 32694, 8531, 8631),
(3520, 32694, 8532, 8632),
(3520, 32694, 8533, 8633),
(3520, 32694, 8534, 8634),
(3520, 32694, 8535, 8635),
(3520, 32694, 8536, 8636),
(3520, 32694, 8537, 8637),
(3520, 32694, 8538, 8638),
(3520, 32694, 8539, 8639),
(3520, 32694, 8540, 8640),
(3520, 32694, 8541, 8641),
(3520, 32694, 8542, 8642),
(3520, 32694, 8543, 8643),
(3520, 32694, 8544, 8644),
(3520, 32694, 8545, 8645),
(3520, 32694, 8546, 8646),
(3520, 32694, 8547, 8647),
(3520, 32694, 8548, 8648),
(3520, 32694, 8549, 8649),
(3520, 32694, 8550, 8650),
(3520, 32694, 8551, 8651),
(3520, 32694, 8552, 8652),
(3520, 32694, 8553, 8653),
(3520, 32694, 8554, 8654),
(3520, 32694, 8555, 8655),
(3520, 32694, 8557, 8557),
(3520, 32694, 8558, 8558),
(3520, 32694, 8559, 8659),
(3520, 32694, 8560, 8560),
(3520, 32694, 8561, 8561),
(3520, 32694, 8562, 8662),
(3520, 32694, 8563, 8663),
(3520, 32694, 8564, 8664),
(3520, 32694, 8565, 8665),
(3520, 32694, 8566, 8666),
(3520, 32694, 8567, 8667),
(3520, 32694, 8568, 8668),
(3520, 32694, 8569, 8669),
(3520, 32694, 8570, 8570),
(3520, 32694, 8571, 8571),
(3520, 32694, 8572, 8672),
(3520, 32694, 8631, 8631),
(3520, 32694, 8632, 8632),
(3520, 32694, 8633, 8633),
(3520, 32694, 8634, 8634),
(3520, 32694, 8635, 8635),
(3520, 32694, 8636, 8636),
(3520, 32694, 8637, 8637),
(3520, 32694, 8638, 8638),
(3520, 32694, 8639, 8639),
(3520, 32694, 8640, 8640),
(3520, 32694, 8641, 8641),
(3520, 32694, 8642, 8642),
(3520, 32694, 8643, 8643),
(3520, 32694, 8644, 8644),
(3520, 32694, 8645, 8645),
(3520, 32694, 8646, 8646),
(3520, 32694, 8647, 8647),
(3520, 32694, 8648, 8648),
(3520, 32694, 8649, 8649),
(3520, 32694, 8650, 8650),
(3520, 32694, 8651, 8651),
(3520, 32694, 8652, 8652),
(3520, 32694, 8653, 8653),
(3520, 32694, 8654, 8654),
(3520, 32694, 8655, 8655),
(3520, 32694, 8659, 8659),
(3520, 32694, 8662, 8662),
(3520, 32694, 8663, 8663),
(3520, 32694, 8664, 8664),
(3520, 32694, 8665, 8665),
(3520, 32694, 8666, 8666),
(3520, 32694, 8667, 8667),
(3520, 32694, 8668, 8668),
(3520, 32694, 8669, 8669),
(3520, 32694, 8672, 8672),
(3520, 32694, 8700, 395),
(3520, 32694, 8701, 801),
(3520, 32694, 8702, 882),
(3520, 32694, 8703, 19634),
(3520, 32694, 8704, 19735),
(3520, 32694, 8705, 19736),
(3520, 32694, 8706, 19737),
(3520, 32694, 8707, 19738),
(3520, 32694, 8708, 19739),
(3520, 32694, 8709, 19740),
(3520, 32694, 8710, 19741),
(3520, 32694, 8711, 19642),
(3520, 32694, 8712, 19643),
(3520, 32694, 8713, 19644),
(3520, 32694, 8714, 19645),
(3520, 32694, 8715, 19746),
(3520, 32694, 8716, 19747),
(3520, 32694, 8717, 19648),
(3520, 32694, 8718, 19649),
(3520, 32694, 8719, 19650),
(3520, 32694, 8720, 19651),
(3520, 32694, 8721, 19652),
(3520, 32694, 8722, 19653),
(3520, 32694, 8723, 19654),
(3520, 32694, 8724, 19655),
(3520, 32694, 8725, 19656),
(3520, 32694, 8726, 19657),
(3520, 32694, 8727, 19658),
(3520, 32694, 8728, 19659),
(3520, 32694, 8729, 423),
(3520, 32694, 8730, 1052),
(3520, 32694, 8731, 8631),
(3520, 32694, 8732, 8632),
(3520, 32694, 8733, 8633),
(3520, 32694, 8734, 8634),
(3520, 32694, 8735, 8635),
(3520, 32694, 8736, 8636),
(3520, 32694, 8737, 8637),
(3520, 32694, 8738, 8638),
(3520, 32694, 8739, 8639),
(3520, 32694, 8740, 8640),
(3520, 32694, 8741, 8641),
(3520, 32694, 8742, 8642),
(3520, 32694, 8743, 8643),
(3520, 32694, 8744, 8644),
(3520, 32694, 8745, 8645),
(3520, 32694, 8746, 8646),
(3520, 32694, 8747, 8647),
(3520, 32694, 8748, 8648),
(3520, 32694, 8749, 8649),
(3520, 32694, 8750, 8650),
(3520, 32694, 8751, 8651),
(3520, 32694, 8752, 8652),
(3520, 32694, 8753, 8653),
(3520, 32694, 8754, 8654),
(3520, 32694, 8755, 8655),
(3520, 32694, 8756, 343),
(3520, 32694, 8757, 8557),
(3520, 32694, 8758, 8558),
(3520, 32694, 8759, 8659),
(3520, 32694, 8760, 8560),
(3520, 32694, 8761, 8561),
(3520, 32694, 8762, 8662),
(3520, 32694, 8763, 8663),
(3520, 32694, 8764, 8664),
(3520, 32694, 8765, 8665),
(3520, 32694, 8766, 8666),
(3520, 32694, 8767, 8667),
(3520, 32694, 8768, 8668),
(3520, 32694, 8769, 8669),
(3520, 32694, 8770, 8570),
(3520, 32694, 8771, 8571),
(3520, 32694, 8772, 8672),
(3520, 32694, 8773, 19760),
(3520, 32694, 8774, 19661),
(3520, 32694, 8775, 19662),
(3520, 32694, 8776, 19763),
(3520, 32694, 8777, 19764),
(3520, 32694, 8778, 19765),
(3520, 32694, 8779, 19666),
(3520, 32694, 8780, 19767),
(3520, 32694, 8781, 20768),
(3520, 32694, 8782, 20769),
(3520, 32694, 9517, 19617),
(3520, 32694, 9528, 19628),
(3520, 32694, 9626, 9626),
(3520, 32694, 9700, 364),
(3520, 32694, 9701, 19701),
(3520, 32694, 9702, 21702),
(3520, 32694, 9703, 457),
(3520, 32694, 9704, 540),
(3520, 32694, 9705, 19705),
(3520, 32694, 9706, 19606),
(3520, 32694, 9707, 19707),
(3520, 32694, 9708, 19708),
(3520, 32694, 9709, 19609),
(3520, 32694, 9710, 19710),
(3520, 32694, 9711, 19711),
(3520, 32694, 9712, 19612),
(3520, 32694, 9713, 19713),
(3520, 32694, 9714, 19614),
(3520, 32694, 9715, 19715),
(3520, 32694, 9716, 19616),
(3520, 32694, 9717, 19617),
(3520, 32694, 9718, 19718),
(3520, 32694, 9719, 19619),
(3520, 32694, 9720, 19620),
(3520, 32694, 9721, 19721),
(3520, 32694, 9722, 19722),
(3520, 32694, 9723, 19623),
(3520, 32694, 9724, 19724),
(3520, 32694, 9725, 19625),
(3520, 32694, 9726, 9626),
(3520, 32694, 9727, 19627),
(3520, 32694, 9728, 19628),
(3520, 32694, 9729, 19729),
(3520, 32694, 9730, 19630),
(3520, 32694, 9768, 19768),
(3520, 32694, 9769, 19769),
(3520, 32694, 9770, 19770),
(3520, 32694, 9771, 19671),
(3520, 32694, 9772, 19772),
(3520, 32694, 9773, 19673),
(3520, 32694, 9774, 19774),
(3520, 32694, 9775, 19775),
(3520, 32694, 9776, 19676),
(3520, 32694, 9777, 19777),
(3520, 32694, 9778, 19678),
(3520, 32694, 9779, 19779),
(3520, 32694, 9780, 19780),
(3520, 32694, 9781, 19681),
(3520, 32694, 9782, 19782),
(3520, 32694, 10517, 20617),
(3520, 32694, 10570, 20770),
(3520, 32694, 10571, 20671),
(3520, 32694, 10573, 20673),
(3520, 32694, 10575, 20775),
(3520, 32694, 10576, 20676),
(3520, 32694, 10578, 10578),
(3520, 32694, 10579, 10679),
(3520, 32694, 10580, 20680),
(3520, 32694, 10581, 20681),
(3520, 32694, 10582, 10682),
(3520, 32694, 10679, 10679),
(3520, 32694, 10682, 10682),
(3520, 32694, 10701, 313),
(3520, 32694, 10713, 1216),
(3520, 32694, 10714, 20714),
(3520, 32694, 10715, 20715),
(3520, 32694, 10716, 20616),
(3520, 32694, 10717, 20617),
(3520, 32694, 10718, 20718),
(3520, 32694, 10719, 20619),
(3520, 32694, 10720, 20620),
(3520, 32694, 10721, 20721),
(3520, 32694, 10722, 20722),
(3520, 32694, 10723, 20623),
(3520, 32694, 10724, 20724),
(3520, 32694, 10770, 20770),
(3520, 32694, 10771, 20671),
(3520, 32694, 10772, 20772),
(3520, 32694, 10773, 20673),
(3520, 32694, 10774, 20774),
(3520, 32694, 10775, 20775),
(3520, 32694, 10776, 20676),
(3520, 32694, 10777, 20677),
(3520, 32694, 10778, 10578),
(3520, 32694, 10779, 10679),
(3520, 32694, 10780, 20680),
(3520, 32694, 10781, 20681),
(3520, 32694, 10782, 10682),
(3520, 32694, 11509, 21609),
(3520, 32694, 11556, 21656),
(3520, 32694, 11558, 21658),
(3520, 32694, 11559, 11559),
(3520, 32694, 11560, 21760),
(3520, 32694, 11561, 21661),
(3520, 32694, 11562, 21662),
(3520, 32694, 11571, 21671),
(3520, 32694, 11582, 21682),
(3520, 32694, 11680, 11680),
(3520, 32694, 11701, 21701),
(3520, 32694, 11703, 21703),
(3520, 32694, 11704, 21704),
(3520, 32694, 11709, 21609),
(3520, 32694, 11710, 21710),
(3520, 32694, 11713, 21713),
(3520, 32694, 11714, 21614),
(3520, 32694, 11726, 21726),
(3520, 32694, 11727, 21727),
(3520, 32694, 11728, 21728),
(3520, 32694, 11729, 21729),
(3520, 32694, 11730, 21730),
(3520, 32694, 11731, 21631),
(3520, 32694, 11732, 21632),
(3520, 32694, 11733, 21633),
(3520, 32694, 11734, 21634),
(3520, 32694, 11735, 21635),
(3520, 32694, 11736, 21736),
(3520, 32694, 11738, 21738),
(3520, 32694, 11741, 21741),
(3520, 32694, 11742, 21742),
(3520, 32694, 11745, 21645),
(3520, 32694, 11746, 21646),
(3520, 32694, 11748, 21648),
(3520, 32694, 11749, 21649),
(3520, 32694, 11750, 21650),
(3520, 32694, 11751, 21751),
(3520, 32694, 11752, 21752),
(3520, 32694, 11753, 21653),
(3520, 32694, 11754, 21654),
(3520, 32694, 11755, 21655),
(3520, 32694, 11756, 21656),
(3520, 32694, 11758, 21658),
(3520, 32694, 11759, 11559),
(3520, 32694, 11760, 21760),
(3520, 32694, 11761, 21661),
(3520, 32694, 11762, 21662),
(3520, 32694, 11763, 21763),
(3520, 32694, 11764, 21664),
(3520, 32694, 11765, 21765),
(3520, 32694, 11766, 21666),
(3520, 32694, 11767, 21767),
(3520, 32694, 11768, 21668),
(3520, 32694, 11769, 21769),
(3520, 32694, 11770, 21670),
(3520, 32694, 11771, 21671),
(3520, 32694, 11772, 21772),
(3520, 32694, 11773, 21673),
(3520, 32694, 11774, 21674),
(3520, 32694, 11775, 21775),
(3520, 32694, 11776, 21776),
(3520, 32694, 11777, 21677),
(3520, 32694, 11778, 21778),
(3520, 32694, 11779, 21679),
(3520, 32694, 11780, 11680),
(3520, 32694, 11781, 21681),
(3520, 32694, 11782, 21682),
(3520, 32694, 19601, 19701),
(3520, 32694, 19602, 21702),
(3520, 32694, 19604, 540),
(3520, 32694, 19605, 19705),
(3520, 32694, 19606, 19606),
(3520, 32694, 19607, 19707),
(3520, 32694, 19608, 19708),
(3520, 32694, 19609, 19609),
(3520, 32694, 19610, 19710),
(3520, 32694, 19611, 19711),
(3520, 32694, 19612, 19612),
(3520, 32694, 19613, 19713),
(3520, 32694, 19614, 19614),
(3520, 32694, 19615, 19715),
(3520, 32694, 19616, 19616),
(3520, 32694, 19617, 19617),
(3520, 32694, 19618, 19718),
(3520, 32694, 19619, 19619),
(3520, 32694, 19620, 19620),
(3520, 32694, 19621, 19721),
(3520, 32694, 19622, 19722),
(3520, 32694, 19623, 19623),
(3520, 32694, 19624, 19724),
(3520, 32694, 19625, 19625),
(3520, 32694, 19626, 9626),
(3520, 32694, 19627, 19627),
(3520, 32694, 19628, 19628),
(3520, 32694, 19629, 19729),
(3520, 32694, 19630, 19630),
(3520, 32694, 19634, 19634),
(3520, 32694, 19635, 19735),
(3520, 32694, 19636, 19736),
(3520, 32694, 19637, 19737),
(3520, 32694, 19638, 19738),
(3520, 32694, 19639, 19739),
(3520, 32694, 19640, 19740),
(3520, 32694, 19641, 19741),
(3520, 32694, 19642, 19642),
(3520, 32694, 19643, 19643),
(3520, 32694, 19644, 19644),
(3520, 32694, 19645, 19645),
(3520, 32694, 19646, 19746),
(3520, 32694, 19647, 19747),
(3520, 32694, 19648, 19648),
(3520, 32694, 19649, 19649),
(3520, 32694, 19650, 19650),
(3520, 32694, 19651, 19651),
(3520, 32694, 19652, 19652),
(3520, 32694, 19653, 19653),
(3520, 32694, 19654, 19654),
(3520, 32694, 19655, 19655),
(3520, 32694, 19656, 19656),
(3520, 32694, 19657, 19657),
(3520, 32694, 19658, 19658),
(3520, 32694, 19659, 19659),
(3520, 32694, 19660, 19760),
(3520, 32694, 19661, 19661),
(3520, 32694, 19662, 19662),
(3520, 32694, 19663, 19763),
(3520, 32694, 19664, 19764),
(3520, 32694, 19665, 19765),
(3520, 32694, 19666, 19666),
(3520, 32694, 19667, 19767),
(3520, 32694, 19668, 19768),
(3520, 32694, 19669, 19769),
(3520, 32694, 19670, 19770),
(3520, 32694, 19671, 19671),
(3520, 32694, 19672, 19772),
(3520, 32694, 19673, 19673),
(3520, 32694, 19674, 19774),
(3520, 32694, 19675, 19775),
(3520, 32694, 19676, 19676),
(3520, 32694, 19677, 19777),
(3520, 32694, 19678, 19678),
(3520, 32694, 19679, 19779),
(3520, 32694, 19680, 19780),
(3520, 32694, 19681, 19681),
(3520, 32694, 19682, 19782),
(3520, 32694, 19701, 19701),
(3520, 32694, 19705, 19705),
(3520, 32694, 19707, 19707),
(3520, 32694, 19708, 19708),
(3520, 32694, 19710, 19710),
(3520, 32694, 19711, 19711),
(3520, 32694, 19713, 19713),
(3520, 32694, 19715, 19715),
(3520, 32694, 19718, 19718),
(3520, 32694, 19721, 19721),
(3520, 32694, 19722, 19722),
(3520, 32694, 19724, 19724),
(3520, 32694, 19729, 19729),
(3520, 32694, 19735, 19735),
(3520, 32694, 19736, 19736),
(3520, 32694, 19737, 19737),
(3520, 32694, 19738, 19738),
(3520, 32694, 19739, 19739),
(3520, 32694, 19740, 19740),
(3520, 32694, 19741, 19741),
(3520, 32694, 19746, 19746),
(3520, 32694, 19747, 19747),
(3520, 32694, 19760, 19760),
(3520, 32694, 19763, 19763),
(3520, 32694, 19764, 19764),
(3520, 32694, 19765, 19765),
(3520, 32694, 19767, 19767),
(3520, 32694, 19768, 19768),
(3520, 32694, 19769, 19769),
(3520, 32694, 19770, 19770),
(3520, 32694, 19772, 19772),
(3520, 32694, 19774, 19774),
(3520, 32694, 19775, 19775),
(3520, 32694, 19777, 19777),
(3520, 32694, 19779, 19779),
(3520, 32694, 19780, 19780),
(3520, 32694, 19782, 19782),
(3520, 32694, 20613, 1216),
(3520, 32694, 20614, 20714),
(3520, 32694, 20615, 20715),
(3520, 32694, 20616, 20616),
(3520, 32694, 20617, 20617),
(3520, 32694, 20618, 20718),
(3520, 32694, 20619, 20619),
(3520, 32694, 20620, 20620),
(3520, 32694, 20621, 20721),
(3520, 32694, 20622, 20722),
(3520, 32694, 20623, 20623),
(3520, 32694, 20624, 20724),
(3520, 32694, 20668, 20768),
(3520, 32694, 20669, 20769),
(3520, 32694, 20671, 20671),
(3520, 32694, 20672, 20772),
(3520, 32694, 20673, 20673),
(3520, 32694, 20674, 20774),
(3520, 32694, 20676, 20676),
(3520, 32694, 20677, 20677),
(3520, 32694, 20680, 20680),
(3520, 32694, 20681, 20681),
(3520, 32694, 20714, 20714),
(3520, 32694, 20715, 20715),
(3520, 32694, 20718, 20718),
(3520, 32694, 20721, 20721),
(3520, 32694, 20722, 20722),
(3520, 32694, 20724, 20724),
(3520, 32694, 20768, 20768),
(3520, 32694, 20769, 20769),
(3520, 32694, 20770, 20770),
(3520, 32694, 20772, 20772),
(3520, 32694, 20774, 20774),
(3520, 32694, 20775, 20775),
(3520, 32694, 21601, 21701),
(3520, 32694, 21603, 21703),
(3520, 32694, 21604, 21704),
(3520, 32694, 21609, 21609),
(3520, 32694, 21610, 21710),
(3520, 32694, 21613, 21713),
(3520, 32694, 21614, 21614),
(3520, 32694, 21626, 21726),
(3520, 32694, 21627, 21727),
(3520, 32694, 21628, 21728),
(3520, 32694, 21629, 21729),
(3520, 32694, 21630, 21730),
(3520, 32694, 21631, 21631),
(3520, 32694, 21632, 21632),
(3520, 32694, 21633, 21633),
(3520, 32694, 21634, 21634),
(3520, 32694, 21635, 21635),
(3520, 32694, 21636, 21736),
(3520, 32694, 21638, 21738),
(3520, 32694, 21641, 21741),
(3520, 32694, 21642, 21742),
(3520, 32694, 21645, 21645),
(3520, 32694, 21646, 21646),
(3520, 32694, 21648, 21648),
(3520, 32694, 21649, 21649),
(3520, 32694, 21650, 21650),
(3520, 32694, 21651, 21751),
(3520, 32694, 21652, 21752),
(3520, 32694, 21653, 21653),
(3520, 32694, 21654, 21654),
(3520, 32694, 21655, 21655),
(3520, 32694, 21656, 21656),
(3520, 32694, 21658, 21658),
(3520, 32694, 21661, 21661),
(3520, 32694, 21662, 21662),
(3520, 32694, 21663, 21763),
(3520, 32694, 21664, 21664),
(3520, 32694, 21665, 21765),
(3520, 32694, 21666, 21666),
(3520, 32694, 21667, 21767),
(3520, 32694, 21668, 21668),
(3520, 32694, 21669, 21769),
(3520, 32694, 21670, 21670),
(3520, 32694, 21671, 21671),
(3520, 32694, 21672, 21772),
(3520, 32694, 21673, 21673),
(3520, 32694, 21674, 21674),
(3520, 32694, 21675, 21775),
(3520, 32694, 21676, 21776),
(3520, 32694, 21677, 21677),
(3520, 32694, 21678, 21778),
(3520, 32694, 21679, 21679),
(3520, 32694, 21680, 11680),
(3520, 32694, 21681, 21681),
(3520, 32694, 21682, 21682),
(3520, 32694, 21701, 21701),
(3520, 32694, 21702, 21702),
(3520, 32694, 21703, 21703),
(3520, 32694, 21704, 21704),
(3520, 32694, 21710, 21710),
(3520, 32694, 21713, 21713),
(3520, 32694, 21726, 21726),
(3520, 32694, 21727, 21727),
(3520, 32694, 21728, 21728),
(3520, 32694, 21729, 21729),
(3520, 32694, 21730, 21730),
(3520, 32694, 21736, 21736),
(3520, 32694, 21738, 21738),
(3520, 32694, 21741, 21741),
(3520, 32694, 21742, 21742),
(3520, 32694, 21751, 21751),
(3520, 32694, 21752, 21752),
(3520, 32694, 21760, 21760),
(3520, 32694, 21763, 21763),
(3520, 32694, 21765, 21765),
(3520, 32694, 21767, 21767),
(3520, 32694, 21769, 21769),
(3520, 32694, 21772, 21772),
(3520, 32694, 21775, 21775),
(3520, 32694, 21776, 21776),
(3520, 32694, 21778, 21778);

DELETE FROM `item_enchantment_template` WHERE `entry` = 6032694;
INSERT INTO `item_enchantment_template` (`entry`, `ench`, `chance`)
VALUES
(6032694, 313, 0.471699),
(6032694, 343, 0.471699),
(6032694, 364, 0.471699),
(6032694, 395, 0.471699),
(6032694, 423, 0.471699),
(6032694, 457, 0.471699),
(6032694, 540, 0.471699),
(6032694, 801, 0.471699),
(6032694, 882, 0.471699),
(6032694, 1052, 0.471699),
(6032694, 1216, 0.471699),
(6032694, 8557, 0.471699),
(6032694, 8558, 0.471699),
(6032694, 8560, 0.471699),
(6032694, 8561, 0.471699),
(6032694, 8570, 0.471699),
(6032694, 8571, 0.471699),
(6032694, 8631, 0.471699),
(6032694, 8632, 0.471699),
(6032694, 8633, 0.471699),
(6032694, 8634, 0.471699),
(6032694, 8635, 0.471699),
(6032694, 8636, 0.471699),
(6032694, 8637, 0.471699),
(6032694, 8638, 0.471699),
(6032694, 8639, 0.471699),
(6032694, 8640, 0.471699),
(6032694, 8641, 0.471699),
(6032694, 8642, 0.471699),
(6032694, 8643, 0.471699),
(6032694, 8644, 0.471699),
(6032694, 8645, 0.471699),
(6032694, 8646, 0.471699),
(6032694, 8647, 0.471699),
(6032694, 8648, 0.471699),
(6032694, 8649, 0.471699),
(6032694, 8650, 0.471699),
(6032694, 8651, 0.471699),
(6032694, 8652, 0.471699),
(6032694, 8653, 0.471699),
(6032694, 8654, 0.471699),
(6032694, 8655, 0.471699),
(6032694, 8659, 0.471699),
(6032694, 8662, 0.471699),
(6032694, 8663, 0.471699),
(6032694, 8664, 0.471699),
(6032694, 8665, 0.471699),
(6032694, 8666, 0.471699),
(6032694, 8667, 0.471699),
(6032694, 8668, 0.471699),
(6032694, 8669, 0.471699),
(6032694, 8672, 0.471699),
(6032694, 9626, 0.471699),
(6032694, 10578, 0.471699),
(6032694, 10679, 0.471699),
(6032694, 10682, 0.471699),
(6032694, 11559, 0.471699),
(6032694, 11680, 0.471699),
(6032694, 19606, 0.471699),
(6032694, 19609, 0.471699),
(6032694, 19612, 0.471699),
(6032694, 19614, 0.471699),
(6032694, 19616, 0.471699),
(6032694, 19617, 0.471699),
(6032694, 19619, 0.471699),
(6032694, 19620, 0.471699),
(6032694, 19623, 0.471699),
(6032694, 19625, 0.471699),
(6032694, 19627, 0.471699),
(6032694, 19628, 0.471699),
(6032694, 19630, 0.471699),
(6032694, 19634, 0.471699),
(6032694, 19642, 0.471699),
(6032694, 19643, 0.471699),
(6032694, 19644, 0.471699),
(6032694, 19645, 0.471699),
(6032694, 19648, 0.471699),
(6032694, 19649, 0.471699),
(6032694, 19650, 0.471699),
(6032694, 19651, 0.471699),
(6032694, 19652, 0.471699),
(6032694, 19653, 0.471699),
(6032694, 19654, 0.471699),
(6032694, 19655, 0.471699),
(6032694, 19656, 0.471699),
(6032694, 19657, 0.471699),
(6032694, 19658, 0.471699),
(6032694, 19659, 0.471699),
(6032694, 19661, 0.471699),
(6032694, 19662, 0.471699),
(6032694, 19666, 0.471699),
(6032694, 19671, 0.471699),
(6032694, 19673, 0.471699),
(6032694, 19676, 0.471699),
(6032694, 19678, 0.471699),
(6032694, 19681, 0.471699),
(6032694, 19701, 0.471699),
(6032694, 19705, 0.471699),
(6032694, 19707, 0.471699),
(6032694, 19708, 0.471699),
(6032694, 19710, 0.471699),
(6032694, 19711, 0.471699),
(6032694, 19713, 0.471699),
(6032694, 19715, 0.471699),
(6032694, 19718, 0.471699),
(6032694, 19721, 0.471699),
(6032694, 19722, 0.471699),
(6032694, 19724, 0.471699),
(6032694, 19729, 0.471699),
(6032694, 19735, 0.471699),
(6032694, 19736, 0.471699),
(6032694, 19737, 0.471699),
(6032694, 19738, 0.471699),
(6032694, 19739, 0.471699),
(6032694, 19740, 0.471699),
(6032694, 19741, 0.471699),
(6032694, 19746, 0.471699),
(6032694, 19747, 0.471699),
(6032694, 19760, 0.471699),
(6032694, 19763, 0.471699),
(6032694, 19764, 0.471699),
(6032694, 19765, 0.471699),
(6032694, 19767, 0.471699),
(6032694, 19768, 0.471699),
(6032694, 19769, 0.471699),
(6032694, 19770, 0.471699),
(6032694, 19772, 0.471699),
(6032694, 19774, 0.471699),
(6032694, 19775, 0.471699),
(6032694, 19777, 0.471699),
(6032694, 19779, 0.471699),
(6032694, 19780, 0.471699),
(6032694, 19782, 0.471699),
(6032694, 20616, 0.471699),
(6032694, 20617, 0.471699),
(6032694, 20619, 0.471699),
(6032694, 20620, 0.471699),
(6032694, 20623, 0.471699),
(6032694, 20671, 0.471699),
(6032694, 20673, 0.471699),
(6032694, 20676, 0.471699),
(6032694, 20677, 0.471699),
(6032694, 20680, 0.471699),
(6032694, 20681, 0.471699),
(6032694, 20714, 0.471699),
(6032694, 20715, 0.471699),
(6032694, 20718, 0.471699),
(6032694, 20721, 0.471699),
(6032694, 20722, 0.471699),
(6032694, 20724, 0.471699),
(6032694, 20768, 0.471699),
(6032694, 20769, 0.471699),
(6032694, 20770, 0.471699),
(6032694, 20772, 0.471699),
(6032694, 20774, 0.471699),
(6032694, 20775, 0.471699),
(6032694, 21609, 0.471699),
(6032694, 21614, 0.471699),
(6032694, 21631, 0.471699),
(6032694, 21632, 0.471699),
(6032694, 21633, 0.471699),
(6032694, 21634, 0.471699),
(6032694, 21635, 0.471699),
(6032694, 21645, 0.471699),
(6032694, 21646, 0.471699),
(6032694, 21648, 0.471699),
(6032694, 21649, 0.471699),
(6032694, 21650, 0.471699),
(6032694, 21653, 0.471699),
(6032694, 21654, 0.471699),
(6032694, 21655, 0.471699),
(6032694, 21656, 0.471699),
(6032694, 21658, 0.471699),
(6032694, 21661, 0.471699),
(6032694, 21662, 0.471699),
(6032694, 21664, 0.471699),
(6032694, 21666, 0.471699),
(6032694, 21668, 0.471699),
(6032694, 21670, 0.471699),
(6032694, 21671, 0.471699),
(6032694, 21673, 0.471699),
(6032694, 21674, 0.471699),
(6032694, 21677, 0.471699),
(6032694, 21679, 0.471699),
(6032694, 21681, 0.471699),
(6032694, 21682, 0.471699),
(6032694, 21701, 0.471699),
(6032694, 21702, 0.471699),
(6032694, 21703, 0.471699),
(6032694, 21704, 0.471699),
(6032694, 21710, 0.471699),
(6032694, 21713, 0.471699),
(6032694, 21726, 0.471699),
(6032694, 21727, 0.471699),
(6032694, 21728, 0.471699),
(6032694, 21729, 0.471699),
(6032694, 21730, 0.471699),
(6032694, 21736, 0.471699),
(6032694, 21738, 0.471699),
(6032694, 21741, 0.471699),
(6032694, 21742, 0.471699),
(6032694, 21751, 0.471699),
(6032694, 21752, 0.471699),
(6032694, 21760, 0.471699),
(6032694, 21763, 0.471699),
(6032694, 21765, 0.471699),
(6032694, 21767, 0.471699),
(6032694, 21769, 0.471699),
(6032694, 21772, 0.471699),
(6032694, 21775, 0.471699),
(6032694, 21776, 0.471699),
(6032694, 21778, 0.471699);

UPDATE `item_template` SET `RandomProperty` = 6032694 WHERE `entry` = 32694;

COMMIT;
