-- Warcraft Reborn Mystic Enchants whose effect is a one-off mechanic (AscensionMysticEnchantMechanics.cpp): Abjurer's
-- Ward, Holy Radiance, Armor of Faith, Purgation by Light, Frugal Disposition, Consecrated Zeal, Glyph of Impact,
-- Elemental Equilibrium; and the enchants a pet or guardian procs, through a listener aura the minion carries while the
-- owner has the enchant (Savage Momentum, Elemental Torrent, Tethered Power).
DELETE FROM `spell_proc` WHERE `SpellId` IN (1180421, 1181270, 1556010, 1571400, 1577466, 1581956, 1582341, 1582342, 1584023, 1589159, 1590891);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1571400, 0, 6, 0x1c00, 0x0, 0x0, 0x4000, 2, 0x2, 0x0, 0x0, 0, 100, 0, 0),
(1582342, 0, 0, 0x0, 0x0, 0x0, 0x222a8, 1, 0x2, 0x0, 0x0, 0, 100, 0, 1),
(1181270, 0, 6, 0x100000, 0x0, 0x0, 0x10000, 1, 0x2, 0x0, 0x0, 0, 100, 0, 0),
(1581956, 0, 11, 0xc0, 0x0, 0x0, 0x4000, 2, 0x2, 0x0, 0x0, 0, 100, 0, 0),
(1584023, 0, 10, 0x20, 0x0, 0x0, 0x40000, 1, 0x2, 0x0, 0x2, 0, 100, 0, 0),
(1590891, 0, 3, 0x2, 0x0, 0x0, 0x10000, 0, 0x1, 0x0, 0x0, 0, 100, 0, 0),
(1180421, 0, 3, 0x0, 0x0, 0x80, 0x10000, 1, 0x2, 0x0, 0x0, 0, 100, 0, 0),
(1556010, 0, 0, 0x0, 0x0, 0x0, 0x10, 1, 0x2, 0x2, 0x0, 0, 100, 0, 0),
(1577466, 0, 0, 0x0, 0x0, 0x0, 0x10014, 1, 0x2, 0x2, 0x0, 0, 100, 0, 0),
(1582341, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1589159, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((1100543, 'spell_ascension_mystic_abjurers_ward'), (1106143, 'spell_ascension_mystic_abjurers_ward'), (1108457, 'spell_ascension_mystic_abjurers_ward'), (1108458, 'spell_ascension_mystic_abjurers_ward'), (1108461, 'spell_ascension_mystic_abjurers_ward'), (1108462, 'spell_ascension_mystic_abjurers_ward'), (1110177, 'spell_ascension_mystic_abjurers_ward'), (1110223, 'spell_ascension_mystic_abjurers_ward'), (1110225, 'spell_ascension_mystic_abjurers_ward'), (1115041, 'spell_ascension_mystic_abjurers_ward'), (1115044, 'spell_ascension_mystic_abjurers_ward'), (1125641, 'spell_ascension_mystic_abjurers_ward'), (1127128, 'spell_ascension_mystic_abjurers_ward'), (1128609, 'spell_ascension_mystic_abjurers_ward'), (1132796, 'spell_ascension_mystic_abjurers_ward'), (1137844, 'spell_ascension_mystic_abjurers_ward'), (1143010, 'spell_ascension_mystic_abjurers_ward'), (1143012, 'spell_ascension_mystic_abjurers_ward'), (1571400, 'spell_ascension_mystic_holy_radiance'), (1582342, 'spell_ascension_mystic_armor_of_faith'), (1181270, 'spell_ascension_mystic_purgation_by_light'), (1581956, 'spell_ascension_mystic_frugal_disposition'), (1584023, 'spell_ascension_mystic_consecrated_zeal'), (1590891, 'spell_ascension_mystic_glyph_of_impact'), (1582341, 'spell_ascension_mystic_enchant_proc'), (1589159, 'spell_ascension_mystic_enchant_proc'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1100543, 'spell_ascension_mystic_abjurers_ward'),
(1106143, 'spell_ascension_mystic_abjurers_ward'),
(1108457, 'spell_ascension_mystic_abjurers_ward'),
(1108458, 'spell_ascension_mystic_abjurers_ward'),
(1108461, 'spell_ascension_mystic_abjurers_ward'),
(1108462, 'spell_ascension_mystic_abjurers_ward'),
(1110177, 'spell_ascension_mystic_abjurers_ward'),
(1110223, 'spell_ascension_mystic_abjurers_ward'),
(1110225, 'spell_ascension_mystic_abjurers_ward'),
(1115041, 'spell_ascension_mystic_abjurers_ward'),
(1115044, 'spell_ascension_mystic_abjurers_ward'),
(1125641, 'spell_ascension_mystic_abjurers_ward'),
(1127128, 'spell_ascension_mystic_abjurers_ward'),
(1128609, 'spell_ascension_mystic_abjurers_ward'),
(1132796, 'spell_ascension_mystic_abjurers_ward'),
(1137844, 'spell_ascension_mystic_abjurers_ward'),
(1143010, 'spell_ascension_mystic_abjurers_ward'),
(1143012, 'spell_ascension_mystic_abjurers_ward'),
(1571400, 'spell_ascension_mystic_holy_radiance'),
(1582342, 'spell_ascension_mystic_armor_of_faith'),
(1181270, 'spell_ascension_mystic_purgation_by_light'),
(1581956, 'spell_ascension_mystic_frugal_disposition'),
(1584023, 'spell_ascension_mystic_consecrated_zeal'),
(1590891, 'spell_ascension_mystic_glyph_of_impact'),
(1582341, 'spell_ascension_mystic_enchant_proc'),
(1589159, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (1582341, 1589159);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(1582341, 0, 0, 'direct_heal', 0, '1102054 1102055 1102060 1102061 1106063 1106064 1109472 1109473 1109474 1110915 1110916 1110917 1110963 1110964 1110965 1117137 1117138 1117843 1122009 1125210 1125213 1125233 1125235 1125314 1127608 1129564 1134119 1135096 1138580 1138588 1140972 1141378 1142420 1143431 1143516 1143575 1147540 1147666 1147750 1147757 1147758 1148062 1148063 1148070 1148071 1149348 1152983 1152984 1152985 1152986 1152987 1152988 1152998 1152999 1153000 1153001 1153002 1153003 1153005 1153006 1153007 1156331 1156919 1157775 1160003 1161965 1162334 1162442 1163760 1171931 1247540 1402552 1402553 1402554 1402555 1406563 1406564 1409973 1411417 1590305 1590306 1590307 1590308 1590309 1590310 1590311 1590312 1590313 1590314 2100203 2100454 2100483 2101416 2101417 2106116 2118260 2125145 2125832 2125833 2126528 2130181 2130620 2131564 2131565 2132144 2132145 2132146 2136207 2137086 2140100 2141874 2145169 2145170 2150058', 100, 0, '', '1106788 1585529', '', '', '1582342', 15, 0, 'Armor of Faith (enchant 1235895): healing an ally with Weakened Soul grants Armor of Faith (15% of the heal)'),
(1589159, 0, 0, 'direct_damage', 4, '', 100, 0, '', '', '', '', '1589162', 0, 0, 'Elemental Equilibrium (enchant 1236024): Fire essence'),
(1589159, 0, 1, 'direct_damage', 16, '', 100, 0, '', '', '', '', '1589163', 0, 0, 'Elemental Equilibrium (enchant 1236024): Frost essence'),
(1589159, 0, 2, 'direct_damage', 8, '', 100, 0, '', '', '', '', '1589164', 0, 0, 'Elemental Equilibrium (enchant 1236024): Nature essence');

DROP TABLE IF EXISTS `coa_mystic_enchant_minion_aura`;
CREATE TABLE `coa_mystic_enchant_minion_aura` (
  `enchant_spell` INT UNSIGNED NOT NULL,
  `minion_entry` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0: any pet or guardian of the player',
  `aura` INT UNSIGNED NOT NULL COMMENT 'the listener aura the minion carries',
  `comment` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`enchant_spell`, `minion_entry`, `aura`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Mystic Enchant pet and guardian listener auras (AscensionMysticEnchantProcs.cpp)';
DELETE FROM `coa_mystic_enchant_minion_aura`;
INSERT INTO `coa_mystic_enchant_minion_aura` (`enchant_spell`, `minion_entry`, `aura`, `comment`) VALUES
(1556008, 0, 1556010, 'Savage Momentum (enchant 1376224): the pet carries the listener'),
(1180420, 0, 1180421, 'Elemental Torrent (enchant 1345806): the Water Elemental carries the listener'),
(1577465, 0, 1577466, 'Tethered Power (enchant 1235609): the Tethered Elemental carries the listener');
