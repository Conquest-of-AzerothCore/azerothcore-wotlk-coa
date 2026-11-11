-- Snowgrave (64627) in his boss map (889), the way Setis is fought: a shrine in
-- Winterspring takes players in (Normal only), the portal he leaves at its fixed spot and the shrine at
-- the entrance take them back, and players who die in his map rise at its start. The shrine's spot is taken in game.

-- Loot: one roll of his ten items (the drops seen on Ascension; loot mode 2 holds their heroic ones);
-- snowgrave_instance_death_coa gives one of them for every four players in his map (never none), and every
-- player gets the runes and the Treasures of Azeroth chest.
UPDATE `creature_template` SET `lootid` = 64627 WHERE `entry` = 64627;
DELETE FROM `creature_loot_template` WHERE `Entry` = 64627;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(64627, 17913, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Frostbite Warcloak'),
(64627, 17912, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Glacierwoven Legwraps'),
(64627, 18065, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Frostwoven Spiritbinder Gloves'),
(64627, 18084, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Glacierbound Wristguards'),
(64627, 17664, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Glaciermind Spellfocus'),
(64627, 17304, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Crystalized Water Spike'),
(64627, 18064, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Band of Winter''s Grasp'),
(64627, 17663, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Frostbound Bulwark'),
(64627, 18085, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Frostbite Spellhammer'),
(64627, 17665, 0, 0, 0, 1, 1, 1, 1, 'Snowgrave - Glacierborn Greatsword'),
(64627, 318085, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Frostbite Spellhammer'),
(64627, 317665, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Glacierborn Greatsword'),
(64627, 317663, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Frostbound Bulwark'),
(64627, 318064, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Band of Winter''s Grasp'),
(64627, 317304, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Crystalized Water Spike'),
(64627, 317664, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Glaciermind Spellfocus'),
(64627, 318084, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Glacierbound Wristguards'),
(64627, 318065, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Frostwoven Spiritbinder Gloves'),
(64627, 317912, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Glacierwoven Legwraps'),
(64627, 317913, 0, 0, 0, 2, 1, 1, 1, 'Snowgrave (heroic) - Frostbite Warcloak');

-- The Treasures of Azeroth chest every world boss gives (978059) has a 5% roll at any world boss item (978060):
-- his items join that pool.
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 978060, `l`.`Item`, 0, 0, 0, 1, 1, 1, 1, CONCAT('Treasures of Azeroth - World Boss - ', `i`.`name`)
FROM `creature_loot_template` `l` JOIN `item_template` `i` ON `i`.`entry` = `l`.`Item`
WHERE `l`.`Entry` = 64627 AND `l`.`LootMode` = 1 AND `l`.`GroupId` = 1 AND `l`.`Reference` = 0
  AND `i`.`Quality` = 4;

-- His health is per player in his map (10 to 40): each kill's pool over its players.
UPDATE `coa_world_boss_level` SET `health` = 1120094, `note` = 'per player; kills 23:24/23:36, 22/24 players'
WHERE `entry` = 64627 AND `difficulty` = 0;
UPDATE `coa_world_boss_level` SET `health` = 1307460, `note` = 'per player; kills 23:24/23:36, 22/24 players'
WHERE `entry` = 64627 AND `difficulty` = 2;

-- The shrine, the portal out and the shrine at the entrance of his map.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978095, 10, 4076, 'Shrine of Snowgrave', '', '', '', 3, '', 'go_snowgrave_altar_coa', 12340),
(978096, 10, 4396, 'Portal to Winterspring', '', '', '', 1.5, '', 'go_snowgrave_exit_coa', 12340),
(978097, 10, 4076, 'Shrine of Snowgrave', '', '', '', 3, '', 'go_snowgrave_leave_coa', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `gameobject` WHERE `guid` IN (9780935, 9780936);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`) VALUES
(9780935, 978095, 1, 0, 0, 1, 1, 5190.9443, -4909.031, 752.0395, 1.7423, 0, 0, 0.765070, 0.643947, 300, 100, 1),
(9780936, 978097, 889, 10280, 10280, 15, 1, 4746.10, -4929.99, 695.78, 0, 0, 0, 0, 1, 300, 100, 1);

-- Players who die in his map rise at its start: WorldSafeLocs.dbc 6089.
DELETE FROM `game_graveyard` WHERE `ID` = 6089;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(6089, 889, 4741.1, -4934.99, 695.78, 'Frostgiantnbossmap Boss map Graveyard');
DELETE FROM `graveyard_zone` WHERE `ID` = 6089 AND `GhostZone` = 10280;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(6089, 10280, 0, 'Snowgrave''s Cavern (Snowgrave boss map)');

-- The shrine's words.
DELETE FROM `npc_text` WHERE `ID` = 978095;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`) VALUES
(978095, 'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.',
  'The shrine seems to notice your presence as you place your hand on its surface to attune to its power.');

-- His hologram above the shrine: ghostly (22650), rooted, and frozen in place (16245).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `type_flags`, `AIName`, `ScriptName`,
  `VerifiedBuild`) VALUES
(978095, 'Snowgrave', '', 63, 63, 35, 0, 1, 1, 1, 33554434, 7, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
  `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 978095;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(978095, 0, 142079, 0.1, 1, 12340);
DELETE FROM `creature_template_addon` WHERE `entry` = 978095;
INSERT INTO `creature_template_addon` (`entry`, `auras`) VALUES (978095, '22650 16245');
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 978095;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(978095, 1, 0, 0, 1);
DELETE FROM `creature` WHERE `guid` = 9780937;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780937, 978095, 1, 0, 0, 1, 1, 5190.9443, -4909.031, 757.04, 1.7423, 300, 0, 0);

-- In his cavern he stands where Ascension has him (spot taken in game).
UPDATE `creature` SET `position_x` = 4687.2383, `position_y` = -4801.878, `position_z` = 676.87, `orientation` = 5.5009
WHERE `guid` = 9780103 AND `id` = 64627;

-- His frost giant mace (18085, mace_1h_frostgiant_boss) and his shield (Frostbound Bulwark, shield_frostgiant_01),
-- as Ascension shows him, at his scale.
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 64627;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(64627, 1, 18085, 17663, 0, 12340);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9780103;

-- He is just "Snowgrave", as on Ascension.
UPDATE `creature_template` SET `name` = 'Snowgrave' WHERE `entry` = 64627;

-- The icicles his Massive Stomp brings down stay where they fall until the fight ends.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
  `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978098, 5, 9227, 'Fallen Icicle', '', '', '', 1, '', '', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
  `size` = VALUES(`size`);

-- The icicles look like his hail shards, bigger: a cluster of ice crystals.
UPDATE `gameobject_template` SET `displayId` = 8324, `size` = 0.5 WHERE `entry` = 978098;

-- His hitbox is as wide as he is.
UPDATE `creature_model_info` SET `BoundingRadius` = 10, `CombatReach` = 15 WHERE `DisplayID` = 142079;

-- His selection circle as wide as his hitbox: his model's collision width, sent to the
-- client.
REPLACE INTO `creaturemodeldata_dbc` (`ID`, `Flags`, `ModelName`, `SizeClass`, `ModelScale`, `BloodID`, `FootprintTextureID`,
  `FootprintTextureLength`, `FootprintTextureWidth`, `FootprintParticleScale`, `FoleyMaterialID`,
  `FootstepShakeSize`, `DeathThudShakeSize`, `SoundID`, `CollisionWidth`, `CollisionHeight`, `MountHeight`,
  `GeoBoxMinX`, `GeoBoxMinY`, `GeoBoxMinZ`, `GeoBoxMaxX`, `GeoBoxMaxY`, `GeoBoxMaxZ`, `WorldEffectScale`,
  `AttachedEffectScale`, `MissileCollisionRadius`, `MissileCollisionPush`, `MissileCollisionRaise`) VALUES
(113990, 0, 'Creature\\korrim\\korrim.m2', 3, 1.0, 3, 1, 18.0, 12.0, 1.0, 0, 2, 11, 193, 4.0, 2.083, 0.0, -2.2947, -4.1475, -0.0213, 2.4742, 4.0076, 7.679, 1.0, 0.75, 0.0, 0.0, 0.0);

-- World bosses give Ascension's own Treasures of Azeroth chest (1615011), which holds what 978059 holds;
-- 978059 keeps its loot for the chests players still hold.
DELETE FROM `item_loot_template` WHERE `Entry` = 1615011;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(1615011, 978059, 978059, 100, 0, 1, 0, 1, 1, 'Treasures of Azeroth - a Heroic Dungeon epic'),
(1615011, 978060, 978060, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item'),
(1615011, 400750, 0, 100, 0, 1, 0, 15, 15, 'Treasures of Azeroth - 15 Raider''s Commendations'),
(1615011, 978061, 978061, 100, 0, 1, 0, 4, 4, 'Treasures of Azeroth - 1000 Runes of Descension (250 x 4)');

-- A player still in his map (and Setis's, 880) when it closes (a server restart or a reset, dead or alive) logs back in at its
-- entrance instead of at their hearthstone: the map's entrance trigger, at a spot no one can reach, points there.
DELETE FROM `areatrigger` WHERE `entry` IN (978889, 978880);
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`) VALUES
(978889, 889, 0, 0, -10000, 0, 0, 0, 0, 0),
(978880, 880, 0, 0, -10000, 0, 0, 0, 0, 0);
DELETE FROM `areatrigger_teleport` WHERE `ID` IN (978889, 978880);
INSERT INTO `areatrigger_teleport` (`ID`, `Name`, `target_map`, `target_position_x`, `target_position_y`,
  `target_position_z`, `target_orientation`) VALUES
(978889, 'Snowgrave - boss map entrance', 889, 4750.57, -4936.066, 695.831, 0.6205),
(978880, 'Setis - boss map entrance', 880, -8093.0, 1663.6, 12.9, 0.0);
