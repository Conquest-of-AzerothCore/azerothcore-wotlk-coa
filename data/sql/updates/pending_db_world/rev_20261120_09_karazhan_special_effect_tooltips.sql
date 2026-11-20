-- Describe the rescaled server effects on the items that carry them.
CREATE TEMPORARY TABLE `_coa_karazhan_effect_text` (
    `entry` INT UNSIGNED PRIMARY KEY,
    `description` VARCHAR(128) NOT NULL
) ENGINE=InnoDB;

DELETE FROM `_coa_karazhan_effect_text`;
INSERT INTO `_coa_karazhan_effect_text` VALUES
(28523, 'CoA effect: Silverstream base healing +69.'),
(28528, 'CoA effect: +238 dodge rating on use.'),
(28568, 'CoA effect: Hand of Elune base healing +111.'),
(28592, 'CoA effect: Shine base healing +73.'),
(28767, 'CoA effect: 446 base damage on use, plus the attack power contribution.'),
(228523, '@Ascended Raid@ CoA effect: Silverstream base healing +85.'),
(228528, '@Ascended Raid@ CoA effect: +261 dodge rating on use.'),
(228568, '@Ascended Raid@ CoA effect: Hand of Elune base healing +125.'),
(228592, '@Ascended Raid@ CoA effect: Shine base healing +91.'),
(228767, '@Ascended Raid@ CoA effect: 457 base damage on use, plus the attack power contribution.'),
(328523, '@Heroic Raid@ CoA effect: Silverstream base healing +76.'),
(328528, '@Heroic Raid@ CoA effect: +249 dodge rating on use.'),
(328568, '@Heroic Raid@ CoA effect: Hand of Elune base healing +122.'),
(328592, '@Heroic Raid@ CoA effect: Shine base healing +81.'),
(328767, '@Heroic Raid@ CoA effect: 453 base damage on use, plus the attack power contribution.'),
(1328523, '@Mythic Raid@ CoA effect: Silverstream base healing +81.'),
(1328528, '@Mythic Raid@ CoA effect: +257 dodge rating on use.'),
(1328568, '@Mythic Raid@ CoA effect: Hand of Elune base healing +122.'),
(1328592, '@Mythic Raid@ CoA effect: Shine base healing +85.'),
(1328767, '@Mythic Raid@ CoA effect: 463 base damage on use, plus the attack power contribution.');

UPDATE `item_template` AS `item`
JOIN `_coa_karazhan_effect_text` AS `effect` ON `effect`.`entry` = `item`.`entry`
SET `item`.`description` = `effect`.`description`;

DROP TEMPORARY TABLE `_coa_karazhan_effect_text`;
