-- Warcraft Reborn Marked Detonation and Beastmaster's Gambit: dummy enchants driven by proc rules. Beastmaster's
-- Gambit rolls 20% per stack of the target aura (chance_per_combo with a target aura); its buff (1180511) is spent
-- by the next Barbed Shot.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1180510, 1181060, 1180511);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1180510, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1181060, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1180511, 0, 9, 0, 0, 0x400000, 0x10100, 1, 0x2, 0x0, 0x0, 0, 100, 0, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1180510, 1181060) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1180510, 'spell_ascension_mystic_enchant_proc'),
(1181060, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (1180510, 1181060);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(1181060, 0, 0, 'cast', 0, '1101130 1114323 1114324 1114325 1131615 1153338 1156303 2125948', 100, 0, '', '', 'target_health>75', '', '1181061', 0, 0, 'Marked Detonation (enchant 1365339): Hunter''s Mark on a target above 75% health marks it'),
(1181060, 0, 1, 'damage', 0, '1102643 1103044 1114281 1114282 1114283 1114284 1114285 1114286 1114287 1114288 1114289 1114290 1119434 1119597 1119676 1119677 1119678 1119679 1119680 1119681 1119682 1119683 1119684 1119685 1119686 1120900 1120901 1120902 1120903 1120904 1121004 1121010 1121011 1121012 1121013 1121014 1121015 1121016 1121017 1121018 1125294 1127019 1127021 1127065 1127632 1130100 1130103 1130104 1130614 1130647 1130648 1130652 1131623 1133044 1134829 1135401 1136293 1136609 1136623 1138370 1138807 1138861 1143337 1144271 1148871 1149044 1149045 1149047 1149048 1149049 1149050 1151742 1152718 1153209 1153214 1153351 1154615 1156641 1156644 1156645 1156646 1156647 1159243 1161005 1161006 1219434 1235340 1253209 1449548 1469434 1470900 1470901 1470902 1470903 1470904 1477065 1499049 1499050 1569208 1570396 1573846 1573847 1573848 1573849 1573850 1573851 1573852 1573853 1573854 1574987 1575013 1578125 1578129 1578130 1578131 1578132 1578133 1578134 1578135 1578136 1578137 1578138 1578142 1586443 1586444 1586448 1586449 1586453 1588414 1588415 1588416 1588417 1588418 1588419 1588420 1588421 1588422 1588423 1588424 1588894', 100, 0, '', '1181061', '', '1181061', '1181062', 0, 0, 'Marked Detonation (enchant 1365339): the marked ranged ability spends the mark and restores 15% base mana'),
(1180510, 0, 0, 'damage', 0, '1103044 1114281 1114282 1114283 1114284 1114285 1114286 1114287 1127019 1134829 1135401 1136293 1136609 1136623 1138807 1149044 1149045 1151742 2100512', 100, 0, '', '2304587', '', '', '1180512', 0, 20, 'Beastmaster''s Gambit (enchant 1466009): Arcane Shot, 20% per Barbed Shot stack on the target');
