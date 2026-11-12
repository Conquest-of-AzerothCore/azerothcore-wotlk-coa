-- Atal'zul, the Soulreaver (67532) in his boss map (890), the way Setis is fought: a shrine in the Eastern
-- Plaguelands by Zul'Mashar takes players in (Normal only), the portal he leaves where he falls and the shrine at
-- the entrance take them back, and players who die in his map rise at its start. The shrine's spot is taken in game.

-- Loot: one roll of his 8 items (item level 74, as the quick guide shows them; loot mode 2 holds their heroic
-- ones); atalzul_instance_death_coa gives one of them for every four players in his map (never none).
UPDATE `creature_template` SET `lootid` = 67532 WHERE `entry` = 67532;
DELETE FROM `creature_loot_template` WHERE `Entry` = 67532;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(67532, 11425, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Band of the Dead'),
(67532, 11429, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Desecrator'),
(67532, 11426, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Shroud of Sacrifice'),
(67532, 11330, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Signet of the Soulflayer'),
(67532, 11428, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Skullcrusher'),
(67532, 11430, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Soul Essence Vial'),
(67532, 11427, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Soulrender Rifle'),
(67532, 11329, 0, 0, 0, 1, 1, 1, 1, 'Atal''zul - Talisman of Soul Theft'),
(67532, 311425, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Band of the Dead'),
(67532, 311429, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Desecrator'),
(67532, 311426, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Shroud of Sacrifice'),
(67532, 311330, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Signet of the Soulflayer'),
(67532, 311428, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Skullcrusher'),
(67532, 311430, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Soul Essence Vial'),
(67532, 311427, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Soulrender Rifle'),
(67532, 311329, 0, 0, 0, 2, 1, 1, 1, 'Atal''zul (heroic) - Talisman of Soul Theft');

-- The Treasures of Azeroth chest every world boss gives (1615011) has a 5% roll at any world boss item (978060):
-- his items join that pool.
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978060, `l`.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', `i`.`name`)
FROM `creature_loot_template` `l` JOIN `item_template` `i` ON `i`.`entry` = `l`.`Item`
WHERE `l`.`Entry` = 67532 AND `l`.`LootMode` = 1 AND `l`.`GroupId` = 1 AND `l`.`Reference` = 0
  AND `i`.`Quality` = 4;

-- His health is per player in his map (10 to 40): each kill's pool over its players.
UPDATE `coa_world_boss_level` SET `health` = 1272231, `note` = 'per player; Atal''zul kill 01:28, 20 players'
WHERE `entry` = 67532 AND `difficulty` = 0;
UPDATE `coa_world_boss_level` SET `health` = 1272231, `note` = 'per player; Atal''zul kill 01:28, 20 players'
WHERE `entry` = 67532 AND `difficulty` = 2;

-- The shrine, the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978090, 10, 4076, 'Shrine of Atal''zul', '', '', '', 3, '', 'go_atalzul_altar_coa', 12340),
(978091, 10, 4396, 'Portal to Zul''Mashar', '', '', '', 1.5, '', 'go_atalzul_exit_coa', 12340),
(978092, 10, 4076, 'Shrine of Atal''zul', '', '', '', 3, '', 'go_atalzul_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780930, 9780931);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780930, 978090, 0, 0, 0, 1, 1, 3322.411, -4846.606, 167.1479, 5.1839, 0, 0, 0.522383, -0.852711, 300, 100, 1),
(9780931, 978092, 890, 10281, 10281, 15, 1, 3313, -4844.6, 168.2892, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6090.
DELETE FROM `game_graveyard` WHERE `ID` = 6090;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6090, 890, 3307.54, -4849.5786, 167.9613, 'Atalzulbossmap Boss map Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6090 AND `GhostZone` = 10281;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6090, 10281, 0, 'Zul''Mashar (Atal''zul boss map)');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978090;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978090, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above each shrine, the one outside and the one inside his map: ghostly (22650), rooted, and frozen in
-- place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978090, 'Atal''zul, the Soulreaver', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 7, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978090;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978090, 0, 6708, 1, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978090;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978090, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978090;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978090, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` IN (9780932, 9780938);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780932, 978090, 0, 0, 0, 1, 1, 3322.411, -4846.606, 172.1479, 5.1839, 300, 0, 0),
(9780938, 978090, 890, 10281, 10281, 15, 1, 3313, -4844.6, 173.2892, 0, 300, 0, 0);

-- In his map Atal'zul stands where the diagonals between the four altars cross. Zul'rogg starts on top of the
-- Zul'Mashar pyramid (198 high, where its guards stand) and jumps down to 3439.56, -4982.28, 195.727 when the Soul
-- Vessels wake him. Each Soul Vessel is a crystal (the creature) on an altar (978093, a goober players use to click
-- the vessel); breaking it hides the crystal and leaves the altar.
UPDATE `creature` SET `position_x` = 3363.6626, `position_y` = -4904.645, `position_z` = 159.2667,
  `orientation` = 1.9564 WHERE `guid` = 9780104 AND `id` = 67532;
UPDATE `creature` SET `position_x` = 3461.96, `position_y` = -4971.2, `position_z` = 197.948,
  `orientation` = 3.6 WHERE `guid` = 9780105 AND `id` = 67533;
UPDATE `creature` SET `position_x` = 3404.716, `position_y` = -4901.075, `position_z` = 161.5792
WHERE `guid` = 9780106;
UPDATE `creature` SET `position_x` = 3358.0588, `position_y` = -4949.7046, `position_z` = 161.5839
WHERE `guid` = 9780107;
UPDATE `creature` SET `position_x` = 3328.0198, `position_y` = -4888.4087, `position_z` = 161.4575
WHERE `guid` = 9780108;
UPDATE `creature` SET `position_x` = 3377.5986, `position_y` = -4873.0796, `position_z` = 161.4516
WHERE `guid` = 9780109;

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978093, 10, 1060152, 'Altar of the Soul Vessel', '', '', '', 0.6, '', 'go_atalzul_vessel_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9780941 AND 9780944;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780941, 978093, 890, 10281, 10281, 15, 1, 3404.716, -4901.075, 159.3792, 0, 0, 0, 0, 1, 300, 100, 1),
(9780942, 978093, 890, 10281, 10281, 15, 1, 3358.0588, -4949.7046, 159.3839, 0, 0, 0, 0, 1, 300, 100, 1),
(9780943, 978093, 890, 10281, 10281, 15, 1, 3328.0198, -4888.4087, 159.2575, 0, 0, 0, 0, 1, 300, 100, 1),
(9780944, 978093, 890, 10281, 10281, 15, 1, 3377.5986, -4873.0796, 159.2516, 0, 0, 0, 0, 1, 300, 100, 1);

-- Atal'zul and Zul'rogg are undead: both look ghostly (22650), as on Ascension.
DELETE FROM `creature_template_addon` WHERE `entry` IN (67532, 67533);
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (67532, '22650'), (67533, '22650');

-- Their models (DevModels gallery): Atal'zul the troll lich (79329), also for his hologram; Zul'rogg the dire troll
-- (79411), scaled to stand as tall as Atal'zul (2.5 on display scale 2 is 14 yards; his 1.5 display needs 2.95).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 79329 WHERE `CreatureID` IN (67532, 978090);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 79411, `DisplayScale` = 2.95 WHERE `CreatureID` = 67533;

-- Models, all checked in the client's own DBC and MPQs: the Damned Wights are the armored Risen Alliance Soldier
-- skeleton (27550), the Restless Spirits the green Terrordale ghost (10700) that flies, the Soul Vessel
-- crystal the floating purple crystal (47751) and his holograms are half as big again.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 27550, `DisplayScale` = 1 WHERE `CreatureID` = 67534;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 10700, `DisplayScale` = 1.5 WHERE `CreatureID` = 67535;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 67535;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(67535, 1, 0, 1, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 47751, `DisplayScale` = 1 WHERE `CreatureID` = 67536;
UPDATE `creature_template_model` SET `DisplayScale` = 1.5 WHERE `CreatureID` = 978090;

-- The shielded Soul Vessel carries a creature whose model is the state effect of Sinister Shield (55706), the Arcane
-- Bomb missile model (display 461865, a sphere 8.3 yards across, scaled to 30 round the altar and the
-- crystal), as auras
-- never showed; and an invisible stalker (display 11686) the beam to Atal'zul leaves from, at the middle of the
-- crystal.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(67537, 'Soul Vessel Barrier', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 10, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 67537;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(67537, 0, 461865, 3.6, 1, 12340);
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 67537;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(67537, 1, 0, 0, 1);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(67538, 'Soul Vessel Anchor', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 10, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 67538;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(67538, 0, 11686, 1, 1, 12340);
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 67538;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(67538, 1, 0, 0, 1);

-- World bosses give Ascension's own Treasures of Azeroth chest (1615011), which holds what 978059 holds;
-- 978059 keeps its loot for the chests players still hold.
DELETE FROM `item_loot_template` WHERE `Entry` = 1615011;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(1615011, 978059, 978059, 100, 0, 1, 0, 1, 1, 'Treasures of Azeroth - a Heroic Dungeon epic'),
(1615011, 978060, 978060, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item'),
(1615011, 400750, 0, 100, 0, 1, 0, 15, 15, 'Treasures of Azeroth - 15 Raider''s Commendations'),
(1615011, 978061, 978061, 100, 0, 1, 0, 4, 4, 'Treasures of Azeroth - 1000 Runes of Descension (250 x 4)');

-- The adds and the crystals are ordinary level 61 and 63 creatures; only the two bosses are skull level.
UPDATE `creature_template` SET `minlevel` = 61, `maxlevel` = 61, `rank` = 0 WHERE `entry` IN (67534, 67535);
UPDATE `creature_template` SET `minlevel` = 63, `maxlevel` = 63, `rank` = 0 WHERE `entry` IN (67536, 67538);

-- The core binds every player permanently to the instance the moment a creature with CREATURE_FLAG_EXTRA_INSTANCE_BIND
-- (flags_extra 1) dies, before the kill rewards run, so every player looked already locked. The rewards bind the
-- players themselves, so Atal'zul no longer carries the flag.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` & ~1 WHERE `entry` = 67532;

-- The world boss maps (880 to 890) reset weekly, as map 891 does: the lockout of their rewards follows it.
DELETE FROM `mapdifficulty_dbc` WHERE `MapID` BETWEEN 880 AND 890;
INSERT INTO `mapdifficulty_dbc` (`ID`, `MapID`, `Difficulty`, `Message_Lang_Mask`, `RaidDuration`, `MaxPlayers`,
  `Difficultystring`) VALUES
(691, 880, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(692, 880, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(693, 880, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(694, 880, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(695, 881, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(696, 881, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(697, 881, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(698, 881, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(699, 882, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(700, 882, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(701, 882, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(702, 882, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(703, 883, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(704, 883, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(705, 883, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(706, 883, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(707, 884, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(708, 884, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(709, 884, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(710, 884, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(711, 885, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(712, 885, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(713, 885, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(714, 885, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(715, 886, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(716, 886, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(717, 886, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(718, 886, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(719, 887, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(720, 887, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(721, 887, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(722, 887, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(723, 888, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(724, 888, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(725, 888, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(726, 888, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(734, 889, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(735, 889, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(736, 889, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(737, 889, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC'),
(741, 890, 0, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(742, 890, 1, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER'),
(743, 890, 2, 16712188, 604800, 40, 'RAID_DIFFICULTY_10PLAYER_HEROIC'),
(744, 890, 3, 16712188, 604800, 40, 'RAID_DIFFICULTY_25PLAYER_HEROIC');
