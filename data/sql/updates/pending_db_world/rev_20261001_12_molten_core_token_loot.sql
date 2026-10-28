-- Maps each Molten Core boss's exact creature entry (one row per difficulty,
-- since Heroic/Mythic/Ascended each keep their own Tier 1 token reference) to
-- the reference_loot_template id already used for its guaranteed token picks
-- in creature_loot_template, so FlexLoot.cpp can draw the raid-size bonus pick
-- from the same pool without a hard-coded item list.

CREATE TABLE IF NOT EXISTS `coa_mc_token_loot` (
    `creature_entry` INT UNSIGNED NOT NULL,
    `reference_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`creature_entry`)
) ENGINE=InnoDB;

DELETE FROM `coa_mc_token_loot`;
INSERT INTO `coa_mc_token_loot` (`creature_entry`, `reference_id`) VALUES
(11502, 4090030),
(111502, 4090031),
(211502, 4090032),
(311502, 4090033),
(11982, 4090013),
(111982, 4090034),
(211982, 4090035),
(311982, 4090036),
(11988, 4090028),
(111988, 4090037),
(211988, 4090038),
(311988, 4090039),
(12056, 4090027),
(112056, 4090040),
(212056, 4090041),
(312056, 4090042),
(12057, 4090015),
(112057, 4090043),
(212057, 4090044),
(312057, 4090045),
(12098, 4090029),
(112098, 4090046),
(212098, 4090047),
(312098, 4090048),
(12118, 4090012),
(112118, 4090049),
(212118, 4090050),
(312118, 4090051),
(12259, 4090014),
(112259, 4090052),
(212259, 4090053),
(312259, 4090054),
(12264, 4090026),
(112264, 4090055),
(212264, 4090056),
(312264, 4090057);
