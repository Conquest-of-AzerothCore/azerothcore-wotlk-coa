-- Warcraft Reborn rogue Mystic Enchants Murder Rush (enchant 1237001) and Rush of Blood (enchant 1236001), #10890.
-- Murder Rush's kill proc cast only its damage aura, which refreshed rank 1 Sprint and gave nothing without Sprint;
-- it now gives Sprint for 5 sec or refreshes it, and its damage aura lasts while Sprint does. Rush of Blood had no
-- proc or script: it now counts consecutive Hemorrhages on every ability the rogue casts.
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 1180880;

DELETE FROM `coa_mystic_enchant_aura_link` WHERE `enchant_spell` = 1180880;
INSERT INTO `coa_mystic_enchant_aura_link` (`enchant_spell`, `aura`, `grant_spell`, `comment`) VALUES
(1180880, '1102983 1108696 1111305', 1180881, 'Murder Rush (enchant 1237001): damage while Sprint is active');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1180880, 1180881, 1587050);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1180880, 'spell_ascension_mystic_murder_rush'),
(1180881, 'spell_ascension_mystic_murder_rush_refresh'),
(1587050, 'spell_ascension_mystic_rush_of_blood');

DELETE FROM `spell_proc` WHERE `SpellId` = 1587050;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1587050, 0, 0, 0, 0, 0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0x6, 0, 100, 0, 0);
