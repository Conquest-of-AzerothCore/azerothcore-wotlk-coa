-- Road to De Other Side (map 937): Adlazin's quests, the entrance and exit in the Sinister Lair, and Normal health.

-- Adlazin gives and takes both quests.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 3, `gossip_menu_id` = 162933 WHERE `entry` = 162933;
DELETE FROM `npc_text` WHERE `ID` = 162933;
INSERT INTO `npc_text` (`ID`, `text0_0`, `BroadcastTextID0`, `lang0`, `Probability0`) VALUES
(162933, 'Ah, it be only a matter o\' time before someone else came.$b$bDo not fear. Me name be Adlazin, Priest of Bwonsamdi. Da Loa of Death himself sent me to cut down da dangerous ambitions of Hir\'eek, Dambala, and Elortha-no-Shadra.', 0, 0, 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 162933;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (162933, 162933);

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660083, 1660084);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (162933, 1660084), (162933, 1660083);
DELETE FROM `creature_questender` WHERE `quest` IN (1660083, 1660084);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (162933, 1660084), (162933, 1660083);

-- A Sinister Family: 8 hissers, 25 spiders, 5 bats. Bats and Lifedrinkers count for the bat credit 163814.
DELETE FROM `creature_template` WHERE `entry` = 163814;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `flags_extra`) VALUES
(163814, 'Bat of the Other Side', 15, 15, 35, 1, 1, 128);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 163814;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(163814, 0, 11686, 1, 1);
UPDATE `creature_template` SET `KillCredit1` = 163814 WHERE `entry` IN (162766, 162767);
UPDATE `creature_template` SET `KillCredit2` = 163814 WHERE `entry` IN (162979, 162980, 162981);

-- Entrance: the water pool in the Sinister Lair (AreaTrigger 8004) leads to the Dungeon Finder start point.
DELETE FROM `areatrigger_teleport` WHERE `ID` = 8004;
INSERT INTO `areatrigger_teleport` (`ID`, `Name`, `target_map`, `target_position_x`, `target_position_y`, `target_position_z`, `target_orientation`) VALUES
(8004, 'Sinister Lair - Road to De Other Side', 937, 480.61, -232.172, 173.47, 4.15317);

-- Exit: the start room's AreaTrigger 8005 leads back out of the pool.
DELETE FROM `areatrigger_teleport` WHERE `ID` = 8005;
INSERT INTO `areatrigger_teleport` (`ID`, `Name`, `target_map`, `target_position_x`, `target_position_y`, `target_position_z`, `target_orientation`) VALUES
(8005, 'Road to De Other Side - Sinister Lair', 1, -198.149, -4182.969, 56.760, 6.27215);

-- Road to De Other Side (map 937): Normal health at level 60. The classic dungeons' Normal bosses sit at about
-- 230-330k there with the dungeon multiplier of 2.5 (CoA.CreatureScaling). Spawned creatures take that multiplier,
-- summons (the Chimeric Embryo, its spiders) do not. Vol'zeen keeps the Normal log's ratio to the bosses (about 0.7).
UPDATE `creature_template` SET `HealthModifier` = 39.3 WHERE `entry` = 162711;  -- Muzah, about 300k
UPDATE `creature_template` SET `HealthModifier` = 47.5 WHERE `entry` = 162715;  -- Drak'math (caster), about 290k
UPDATE `creature_template` SET `HealthModifier` = 101.6 WHERE `entry` = 162716; -- Chimeric Embryo (summoned), about 310k
UPDATE `creature_template` SET `HealthModifier` = 27.5 WHERE `entry` = 162988;  -- Vol'zeen, about 210k

-- Trash: the Mythic log's ratios to an Interstitial Wanderer, with the Wanderer at the Normal log's
-- 1/6.9 of Muzah (about 44k at level 60). Spawned creatures take the dungeon multiplier of 2.5, summons do not.
UPDATE `creature_template` SET `HealthModifier` = 6.36 WHERE `entry` = 162743; -- Spider, about 19k
UPDATE `creature_template` SET `HealthModifier` = 5.73 WHERE `entry` = 162765; -- Interstitial Wanderer, about 44k
UPDATE `creature_template` SET `HealthModifier` = 5.73 WHERE `entry` = 162769; -- Deathweaver Matriarch, about 44k
UPDATE `creature_template` SET `HealthModifier` = 2.15 WHERE `entry` = 162770; -- Spider of the Other Side, about 16k
UPDATE `creature_template` SET `HealthModifier` = 16.32 WHERE `entry` = 162773; -- Gutdevourer, about 125k
UPDATE `creature_template` SET `HealthModifier` = 5.73 WHERE `entry` = 162775; -- Gutdevourer, about 44k
UPDATE `creature_template` SET `HealthModifier` = 5.73 WHERE `entry` = 162776; -- Interstitial Wanderer, about 44k
UPDATE `creature_template` SET `HealthModifier` = 20.40 WHERE `entry` = 162780; -- Risen Cultist, about 125k
UPDATE `creature_template` SET `HealthModifier` = 7.16 WHERE `entry` = 162782; -- Hisser of the Other Side, about 44k
UPDATE `creature_template` SET `HealthModifier` = 7.16 WHERE `entry` = 162783; -- Interstitial Wanderer, about 44k
UPDATE `creature_template` SET `HealthModifier` = 2.15 WHERE `entry` = 162784; -- Violent Swarm, about 16k
UPDATE `creature_template` SET `HealthModifier` = 9.67 WHERE `entry` = 162785; -- Watcher of the Path, about 59k
UPDATE `creature_template` SET `HealthModifier` = 2.15 WHERE `entry` = 162979; -- Lifedrinker, about 16k
UPDATE `creature_template` SET `HealthModifier` = 2.15 WHERE `entry` = 162980; -- Lifedrinker, about 16k
UPDATE `creature_template` SET `HealthModifier` = 1.43 WHERE `entry` = 162981; -- Lifedrinker, about 11k
UPDATE `creature_template` SET `HealthModifier` = 16.32 WHERE `entry` = 162982; -- Risen Cultist, about 125k
UPDATE `creature_template` SET `HealthModifier` = 5.73 WHERE `entry` = 162983; -- Risen Cultist, about 44k
