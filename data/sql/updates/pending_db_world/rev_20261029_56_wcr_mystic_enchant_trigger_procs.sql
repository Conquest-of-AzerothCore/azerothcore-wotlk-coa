-- Warcraft Reborn Mystic Enchants whose proc-trigger (or dummy) effect had no proc wiring: Sword of Vengeance,
-- Wraithweaver: Echoing Shadows, Tethered Power, Sudden Aftermath, Inferno (spell_ascension_mystic_enchant_proc).
DELETE FROM `spell_proc` WHERE `SpellId` IN (1180940, 1181250, 1577465, 1588250, 1590816);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1180940, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1181250, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1577465, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1588250, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1590816, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1180940, 1181250, 1577465, 1588250, 1590816) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1180940, 'spell_ascension_mystic_enchant_proc'),
(1181250, 'spell_ascension_mystic_enchant_proc'),
(1577465, 'spell_ascension_mystic_enchant_proc'),
(1588250, 'spell_ascension_mystic_enchant_proc'),
(1590816, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (1180940, 1181250, 1577465, 1588250, 1590816);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(1590816, 0, 0, 'damage', 0, '1131804', 100, 0, '', '', 'target_stacks:1131803>=5', '', '', 0, 0, 'Sword of Vengeance (enchant 1236075): Judgement of Vengeance on 5 Holy Vengeance stacks strikes around the target'),
(1590816, 0, 1, 'damage', 0, '1153733', 100, 0, '', '', 'target_stacks:1153742>=5', '', '', 0, 0, 'Sword of Vengeance (enchant 1236075): Judgement of Corruption on 5 Blood Corruption stacks strikes around the target'),
(1181250, 0, 0, 'cast', 0, '1108092 1108102 1108103 1108104 1108105 1108106 1110945 1110946 1110947 1125372 1125375 1148126 1148127 1411446 1411447 2100198 2100199 2100200 2100201 2102721 2102722 2102723 2125192 2125193 2125194 2125195 2137800 2137801 2137802 2137803 2145156 2145157 2145158 2154916 2154917', 100, 0, '', '', 'stacks:1544913>=3', '', '', 0, 0, 'Wraithweaver: Echoing Shadows (enchant 1644910): Mind Blast with 3 Shadow Orbs resets its cooldown'),
(1181250, 0, 1, 'cast', 0, '1100589 1100594 1100970 1100992 1102767 1102944 1110892 1110893 1110894 1119276 1119277 1119278 1119279 1119280 1125367 1125368 1125467 1127605 1134914 1134916 1134917 1148124 1148125 1148159 1148160 1148299 1148300 1164085 1234914 1401089 1401094 1401470 1401492 1403267 1411394 2090023 2100149 2100150 2100151 2100152 2100262 2101556 2101557 2101558 2101559 2102724 2102725 2102726 2102727 2104025 2106112 2106113 2106200 2106201 2106202 2106203 2118305 2118306 2125580 2125581 2125582 2125583 2125836 2125837 2125838 2125839 2130616 2130617 2130618 2130619 2131402 2131403 2131404 2131405 2132388 2132389 2132390 2132391 2135118 2135119 2135120 2135121 2142311 2142312 2142313 2142314 2145152 10000970 10002767 10011639 10014032 10383454', 100, 0, '', '', '', '', '1544912', 0, 0, 'Wraithweaver: Echoing Shadows (enchant 1644910): Shadow Word: Pain, Devouring Plague and Vampiric Touch grant a Shadow Orb'),
(1577465, 1, 0, 'cast', 0, '1954807 1954891 1954892 1954893 1954894 1954895 2304807 2304891 2304892 2304893 2304894 2304895', 100, 0, '', '', '', '', '', 0, 0, 'Tethered Power (enchant 1235609): Elemental Blast grants Elemental Synergy'),
(1180940, 0, 0, 'cast', 0, '1100348 1100707 1101094 1102941 1111665 1111667 1111668 1125309 1127215 1144267 1146191 1147810 1147811 1400848 1401207 1401594 1403441 1412167 2090037 2100036 2100037 2100038 2100039 2100392 2100393 2100394 2100395 2101234 2101235 2101236 2101237 2102534 2102535 2102536 2102537 2105429 2105430 2125575 2125576 2125577 2125578 2126549 2126550 2126551 2126552 2130155 10002941 10011962 10037668', 100, 0, '', '', 'target_out_of_combat', '', '', 0, 0, 'Sudden Aftermath (enchant 1564922): Immolate on a monster not in combat triggers Aftermath'),
(1588250, 0, 0, 'damage', 0, '1105857 1111681 1111682 1127214 1130860 1147822', 20, 0, '', '', '', '', '1588255', 50, 0, 'Inferno (enchant 1235825): Hellfire hits have a 20% chance of an extra explosion for 50% of the damage');
