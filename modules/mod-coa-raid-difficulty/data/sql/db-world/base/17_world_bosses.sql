-- Azuregos and Lord Kazzak as Ascension ran them (boss_world_coa.cpp), and the
-- four dragons of Nightmare as Ascension rebuilt them (boss_emerald_dragons_coa.cpp).
--
-- Health. One Ascension kill of each is in the combat logs, and both ended at
-- the same pool: 38,760,524 with 24 players and 38,775,140 with 23. Flex would
-- have put them 4% apart; they are 0.04% apart. So the pool is fixed by
-- default. Setting per_player > 0 switches a boss to that times the players
-- within `radius` yards on the pull, clamped to min_players..max_players.
--
-- Lord Kazzak had a template but no spawn in this world database. Ascension
-- keeps him at the Shrine of Lord Kazzak in the south of the Tainted Scar; the
-- spawn below sits in the middle of the Doomguard Commanders that guard that
-- spot (four of them within 25 yards), at their height. Respawn: 3 days.
--
-- The dragons have no logs. Their pool is Azuregos' measured one times their
-- stock share of his health (1802 / 3200 HealthModifier): 21,827,020.
--
-- Undo: SET `ScriptName` = 'boss_azuregos' on 6109, '' on 12397, the stock
-- boss_ysondre / boss_taerar / boss_lethon / boss_emeriss on 14887-14890 and ''
-- on 15260 and 15302.

CREATE TABLE IF NOT EXISTS `coa_world_boss` (
  `entry`       INT UNSIGNED NOT NULL,
  `health`      INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'fixed pool, used when per_player is 0',
  `per_player`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '> 0: health per player around him on pull',
  `radius`      FLOAT NOT NULL DEFAULT 100,
  `min_players` INT UNSIGNED NOT NULL DEFAULT 10,
  `max_players` INT UNSIGNED NOT NULL DEFAULT 40,
  `comment`     VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`entry`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_world_boss` WHERE `entry` IN (6109, 12397, 14887, 14888, 14889, 14890);
INSERT INTO `coa_world_boss` VALUES
(6109,  38760524, 0, 100, 10, 40, 'Azuregos: Ascension kill, 24 players'),
(12397, 38775140, 0, 100, 10, 40, 'Lord Kazzak: Ascension kill, 23 players'),
(14887, 21827020, 0, 100, 10, 40, 'Ysondre: Azuregos x 1802/3200 (built)'),
(14888, 21827020, 0, 100, 10, 40, 'Lethon: Azuregos x 1802/3200 (built)'),
(14889, 21827020, 0, 100, 10, 40, 'Emeriss: Azuregos x 1802/3200 (built)'),
(14890, 21827020, 0, 100, 10, 40, 'Taerar: Azuregos x 1802/3200 (built)');

UPDATE `creature_template` SET `ScriptName` = 'boss_azuregos_coa' WHERE `entry` = 6109;
UPDATE `creature_template` SET `ScriptName` = 'boss_kazzak_coa'   WHERE `entry` = 12397;
UPDATE `creature_template` SET `ScriptName` = 'boss_ysondre_coa'      WHERE `entry` = 14887;
UPDATE `creature_template` SET `ScriptName` = 'boss_lethon_coa'       WHERE `entry` = 14888;
UPDATE `creature_template` SET `ScriptName` = 'boss_emeriss_coa'      WHERE `entry` = 14889;
UPDATE `creature_template` SET `ScriptName` = 'boss_taerar_coa'       WHERE `entry` = 14890;
UPDATE `creature_template` SET `ScriptName` = 'npc_ysondre_druid_coa' WHERE `entry` = 15260;
UPDATE `creature_template` SET `ScriptName` = 'npc_taerar_shade_coa'  WHERE `entry` = 15302;

DELETE FROM `creature` WHERE `id` = 12397;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`,
    `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`)
VALUES (9780100, 12397, 0, 4, 73, 1, 1, 0, -12213.0, -2740.0, 15.3, 1.57, 259200, 0, 0, 0, 0, 0, 0, 0, 0);
