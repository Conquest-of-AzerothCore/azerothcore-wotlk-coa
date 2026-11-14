-- Characters who prestiged before #12261 kept Book of Ascension upgrades whose base spell the prestige removed. The
-- Book then showed the base as known and refused to sell it. Forget each orphaned upgrade so both can be bought
-- again in order. These are the SpellbookTrainerData offers other than Wasp Form, which
-- rev_20261113_01_venomancer_orphaned_wasp_form_10453 already covers.
DROP TEMPORARY TABLE IF EXISTS `book_upgrade`;
CREATE TEMPORARY TABLE `book_upgrade` (
    `class` TINYINT UNSIGNED NOT NULL,
    `base` INT UNSIGNED NOT NULL,
    `upgrade` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`class`, `upgrade`)
) ENGINE=InnoDB;
DELETE FROM `book_upgrade`;
INSERT INTO `book_upgrade` (`class`, `base`, `upgrade`) VALUES
(12, 300886, 300887), -- Brutal Shout
(13, 572336, 572337), -- Malefic Wrath
(13, 707676, 707677), -- Power Wuju
(20, 504134, 504135), -- Crimson Tide
(20, 504135, 504136), -- Crimson Tide
(20, 572403, 707340), -- Sanguinary Offering
(21, 807959, 808075), -- Heartwood Key
(21, 804794, 804795), -- Cure Knothide Leather
(21, 804794, 804796), -- Cure Borean Leather
(22, 802829, 802830), -- Chromie's Wisdom
(24, 572890, 572891), -- Firefall
(24, 572891, 572161), -- Firefall
(24, 707645, 707646), -- Phoenix Rebirth
(24, 707646, 707647), -- Phoenix Rebirth
(26, 575051, 575052), -- Silverstream
(26, 573345, 573346), -- Arcane Protection
(26, 573346, 573347), -- Arcane Protection
(27, 300865, 300866), -- Devotion of Grace
(27, 575043, 575044), -- Devotion of Radiance
(28, 803663, 803664), -- Mana Module
(28, 802691, 575027), -- Emergency Heal
(29, 520848, 520849), -- Prayer Beads
(29, 520849, 520850), -- Prayer Beads
(32, 807838, 807839), -- Runic Tattoos: Frost
(32, 803752, 803753), -- Runic Tattoos: Fire
(32, 803762, 803763); -- Runic Tattoos: Arcane

-- The second pass reaches the top of a three-step ladder whose middle rung the first pass removed.
DELETE `orphan` FROM `character_spell` AS `orphan`
INNER JOIN `characters` AS `c` ON `c`.`guid` = `orphan`.`guid`
INNER JOIN `book_upgrade` AS `pair` ON `pair`.`class` = `c`.`class` AND `pair`.`upgrade` = `orphan`.`spell`
INNER JOIN `character_settings` AS `prestige` ON `prestige`.`guid` = `orphan`.`guid`
    AND `prestige`.`source` = 'core.coa_prestige'
    AND CAST(SUBSTRING_INDEX(TRIM(`prestige`.`data`), ' ', 1) AS UNSIGNED) > 0
LEFT JOIN `character_spell` AS `known` ON `known`.`guid` = `orphan`.`guid` AND `known`.`spell` = `pair`.`base`
WHERE `known`.`guid` IS NULL;

DELETE `orphan` FROM `character_spell` AS `orphan`
INNER JOIN `characters` AS `c` ON `c`.`guid` = `orphan`.`guid`
INNER JOIN `book_upgrade` AS `pair` ON `pair`.`class` = `c`.`class` AND `pair`.`upgrade` = `orphan`.`spell`
INNER JOIN `character_settings` AS `prestige` ON `prestige`.`guid` = `orphan`.`guid`
    AND `prestige`.`source` = 'core.coa_prestige'
    AND CAST(SUBSTRING_INDEX(TRIM(`prestige`.`data`), ' ', 1) AS UNSIGNED) > 0
LEFT JOIN `character_spell` AS `known` ON `known`.`guid` = `orphan`.`guid` AND `known`.`spell` = `pair`.`base`
WHERE `known`.`guid` IS NULL;

DROP TEMPORARY TABLE `book_upgrade`;
