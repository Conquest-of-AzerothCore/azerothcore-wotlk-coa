-- Zul'Gurub, tester feedback round 5 (2026-11-12).
-- Health per player, measured where a live combat log exists, otherwise on the ZG ladder x1.44/x1.88/x2.32:
-- Heart of Hakkar: Normal CoA 2026-08 kills (211,669 at 10, 285,597 at 15, 413,079 at 21 players: mean 19,959);
--   Heroic, Mythic and Ascended on Hakkar's ladder (user decision 2026-11-12): the Ascended log's 95,396 per player
--   came with a Hakkar at about 5x his Normal health, while ours is x2.32.
-- Arlokk's Zulian Prowlers: Normal CoA 2026-08-02 (36,342 at 11 players).
-- Bloodseeker Bats (Jeklik's waves and the temple trash) and Frenzied Bloodseeker Bats: CoA and Bronzebeard Mythic and
--   Ascended logs.
-- Spawn of Mar'li: Mythic 8,431 (tester value); Ascended = Normal x3.2325, the Bronzebeard Ascended/Normal ratio
--   (4,490 / 1,389), so Ascended stays above Mythic.
DELETE FROM `coa_boss_flex` WHERE `entry` IN (92005, 15101, 11368, 14965);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(92005, 19959, 28741, 37523, 46305, 'ZG Heart of Hakkar: Normal measured, then the ladder'),
(15101, 3304, 4758, 6212, 7665, 'ZG Zulian Prowler (Arlokk): live 36,342 at 11 players (measured), ZG ladder'),
(11368, 1430, 2059, 3100, 6300, 'ZG Bloodseeker Bat: Normal, Mythic and Ascended measured'),
(14965, 0, 0, 33403, 69252, 'ZG Frenzied Bloodseeker Bat: Mythic and Ascended measured');

UPDATE `coa_boss_flex` SET `hp_d2` = 8431, `hp_d3` = 10680 WHERE `entry` = 15041;

-- Spawn of Mar'li's Mythic melee swing at the tester's 322 (Normal median 327 at DamageModifier 4.85).
UPDATE `creature_template` SET `DamageModifier` = 4.776 WHERE `entry` = 215041;

-- CoA creature scaling multiplies raid health by 2.2 on Normal only, so the Heroic, Mythic and Ascended templates
-- carry it themselves. Creatures with a coa_boss_flex row skip that scaling on every difficulty.
DROP TEMPORARY TABLE IF EXISTS `zg_base`;
CREATE TEMPORARY TABLE `zg_base` ENGINE=InnoDB
AS SELECT `entry`, `HealthModifier` FROM `creature_template` WHERE `entry` IN (
    11338, 11339, 11340, 11347, 11348, 11350, 11351, 11352, 11353, 11356, 11357, 11359,
    11360, 11361, 11365, 11368, 11370, 11371, 11372, 11373, 11374, 11380, 11382, 11387,
    11388, 11389, 11390, 11391, 11830, 11831, 14507, 14509, 14510, 14515, 14517, 14532,
    14750, 14821, 14825, 14826, 14834, 14880, 14882, 14883, 14884, 14965, 14986, 14988,
    15041, 15043, 15067, 15068, 15082, 15083, 15084, 15085, 15101, 15111, 15114, 15117,
    15163
) AND `entry` NOT IN (SELECT `entry` FROM `coa_boss_flex`);
UPDATE `creature_template` `t` JOIN `zg_base` `b` ON `t`.`entry` = `b`.`entry` + 100000
   SET `t`.`HealthModifier` = `b`.`HealthModifier` * 1.44 * 2.2;
UPDATE `creature_template` `t` JOIN `zg_base` `b` ON `t`.`entry` = `b`.`entry` + 200000
   SET `t`.`HealthModifier` = `b`.`HealthModifier` * 1.88 * 2.2;
UPDATE `creature_template` `t` JOIN `zg_base` `b` ON `t`.`entry` = `b`.`entry` + 300000
   SET `t`.`HealthModifier` = `b`.`HealthModifier` * 2.32 * 2.2;
DROP TEMPORARY TABLE `zg_base`;
