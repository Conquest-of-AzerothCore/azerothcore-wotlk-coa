-- Warcraft Reborn Mystic Enchants whose proc event lived only in the tooltip (more of them): the event and spells
-- each proc effect fires on (spell_ascension_mystic_enchant_proc). Aura 354 effects cast their trigger spell for
-- the effect amount in percent of the damage or healing that procced it.
DELETE FROM `spell_proc` WHERE `SpellId` IN (55441, 1568152, 1581647, 1584997, 1585312);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(55441, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1568152, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1581647, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1584997, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0),
(1585312, 0, 0, 0, 0, 0, 0x55550, 0, 0x3, 0x0, 0x2, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (55441, 1568152, 1581647, 1584997, 1585312) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(55441, 'spell_ascension_mystic_enchant_proc'),
(1568152, 'spell_ascension_mystic_enchant_proc'),
(1581647, 'spell_ascension_mystic_enchant_proc'),
(1584997, 'spell_ascension_mystic_enchant_proc'),
(1585312, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (55441, 1568152, 1581647, 1584997, 1585312);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `comment`) VALUES
(1568152, 0, 0, 'damage', 0, '15495 53301 53319 53320 53352 56298 60051 60052 60053 65866 67983 67984 67985 69975 71126 102939 200741 202939 992814 1153301 1153352 1156298 1160051 1160052 1160053 1253301 2100161 2100162 2100163 2100164 2150081 2150082 2150083 2150084 2150085 2150086 3015495', 100, 0, '', '', '', '', 'Explosive Charge (enchant 1235668): 25% of Explosive Shot damage to enemies around the target'),
(1581647, 0, 0, 'direct_damage', 0, '14517 14518 17281 31935 31947 32674 32699 32700 32774 35395 35509 36647 37554 38631 48826 48827 50773 52807 57799 59999 65166 66003 69927 71117 71549 100104 156586 156587 254602 355167 365127 383937 383938 831935 975170 992303 992850 1131935 1132699 1132700 1132774 1135395 1135402 1135403 1135404 1135405 1135406 1148826 1148827 1231935 1235395 1435895 2102023 2116571 2126523 2130635 2137028 2141855 2154507 10014517', 100, 0, '', '', '', '', 'Pious Strikes (enchant 1235875): 10% of Crusader Strike / Avenger''s Shield damage to nearby enemies'),
(1584997, 0, 0, 'direct_heal', 0, '2050 2052 2053 2054 2055 2060 6063 6064 10963 10964 10965 11447 22009 25210 25213 25314 29564 34119 35096 38580 41378 48062 48063 49348 57775 60003 61965 62334 62442 63760 69963 71131 71931 85309 120105 144124 145885 145887 148132 148133 340020 355248 371475 375483 375484 500198 908961 992932 993027 1002259 1102060 1110963 1110964 1110965 1122009 1125210 1125213 1125314 1129564 1134119 1135096 1138580 1141378 1148062 1148063 1149348 1157775 1160003 1161965 1162334 1162442 1163760 1171931 1402552 1402553 1402554 1402555 1406563 1406564 2100203 2100454 2101416 2106116 2118260 2125145 2125832 2130181 2130620 2132146 2136207 2137086 2145169 10002055 10006063 10006064', 100, 0, '', '', '', '', 'Holy Servitude (enchant 1235741): Greater Heal heals 12% more over 12 sec (3% a tick)'),
(1585312, 1, 0, 'cast', 0, '5405 10052 10057 10058 18385 27103 33394 42987 42988 71565 71574 283522 892163 1105405 1110052 1110057 1110058 1110061 1122352 1127103 1142987 1142988 1187551 1584868', 100, 0, '', '', '', '', 'Infused Gems (enchant 1235960): using a Mana Gem grants 10% spell haste and crit'),
(55441, 1, 0, 'cast', 0, '16190 39609 39610 120044 1116190 1139609 1139610 1216190', 100, 0, '', '', '', '', 'Glyph of Mana Tide (enchant 299): casting Mana Tide cuts your mana costs by 80% for 12 sec');
