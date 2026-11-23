-- #13152 Divine Ferocity (299956): the elemental Mongoose Bite and Counterattack variants ("uses Mongoose Bite /
-- Counterattack modifiers"), the CoA ranks 901003/901004 and the Reborn ranks were missing from the name-only list.
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 299956;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `comment`) VALUES
(299956, 0, 0, 'cast', 0, '1495 1496 14269 14270 14271 19306 19308 20909 20910 27067 36916 48998 48999 53339 901003 901004 1101495 1114269 1114270 1114271 1136916 1153339 1119306 1120909 1120910 1127067 1148998 1148999 904480 904481 904482 904483 904484 904485 904486 904500 904501 904502 904503 904504 904505 904506 904520 904521 904522 904523 904524 904525 904526 904540 904541 904542 904543 904544 904545 904546 904560 904561 904562 904563 904564 904565 904566 904580 904581 904582 904583 904584 904585 904586 911740 911741 911742 911743 911744 911745 911746 911760 911761 911762 911763 911764 911765 911766 911780 911781 911782 911783 911784 911785 911786 911800 911801 911802 911803 911804 911805 911806 911820 911821 911822 911823 911824 911825 911826 911840 911841 911842 911843 911844 911845 911846', 100, 0, '', '', '', '', '', 'Divine Ferocity (enchant 4823)');

-- #13222 Revengeful Sentinel (299130): the elemental and Reborn Shield Slams were missing from the list, and the buff
-- 299131 had DBC ProcFlags 0 and no spell_proc row, so a Revenge never cast the Shield Wall reduction 299132. The
-- buff now fires on the damaging hit of a spell with the Revenge class flag. Melee damage spell mods are not recorded
-- on the spell, so the row cannot require the spell mod (PROC_ATTR_REQ_SPELLMOD).
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 299130;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `comment`) VALUES
(299130, 0, 0, 'cast', 0, '23922 23923 23924 23925 25258 30356 47487 47488 1123922 1123923 1123924 1123925 1125258 1130356 1147487 1147488 910900 910901 910902 910903 910904 910905 910906 910907 910920 910921 910922 910923 910924 910925 910926 910927 910940 910941 910942 910943 910944 910945 910946 910947 910960 910961 910962 910963 910964 910965 910966 910967 910980 910981 910982 910983 910984 910985 910986 910987 911000 911001 911002 911003 911004 911005 911006 911007', 100, 0, '', '', '', '', '', 'Revengeful Sentinel (enchant 1725409)');
DELETE FROM `spell_proc` WHERE `SpellId` = 299131;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(299131, 0, 4, 0x400, 0, 0, 0x10, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 1);

-- #13263 Fiery Bash (284690): the generated DBC proc kept the Shield Bash class mask, so Shield Slam and Shield of
-- Righteousness never unleashed it.
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 284690;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `comment`) VALUES
(284690, 0, 0, 'damage', 0, '23922 23923 23924 23925 25258 30356 47487 47488 1123922 1123923 1123924 1123925 1125258 1130356 1147487 1147488 910900 910901 910902 910903 910904 910905 910906 910907 910920 910921 910922 910923 910924 910925 910926 910927 910940 910941 910942 910943 910944 910945 910946 910947 910960 910961 910962 910963 910964 910965 910966 910967 910980 910981 910982 910983 910984 910985 910986 910987 911000 911001 911002 911003 911004 911005 911006 911007 53600 61411 1153600 1161411 72 1671 1672 29704 1100072 1101671 1101672 1129704', 100, 0, '', '', '', '', '', 'Fiery Bash');
DELETE FROM `spell_proc` WHERE `SpellId` = 284690;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(284690, 0, 0, 0, 0, 0, 0x15550, 0, 0x3, 0x0, 0x2, 0, 0, 0, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 284690 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(284690, 'spell_ascension_mystic_enchant_proc');

-- #13218 Shield Finesse (285548): only the Shield Block half was implemented; Shield Wall now casts the existing
-- Shield Block reset 285551.
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 285548 AND `effect` = 0 AND `rule` = 1;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `comment`) VALUES
(285548, 0, 1, 'cast', 0, '871 1100871', 100, 0, '', '', '', '', '285551', 'Shield Finesse: Shield Wall resets Shield Block');
