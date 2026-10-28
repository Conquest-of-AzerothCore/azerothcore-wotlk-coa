-- Pet kit spells match their tooltips.

-- Rushing Charge: "inflicts an additional $s2 damage on its first attack". Its one charge was spent by its own cast;
-- only a damaging melee attack spends it.
DELETE FROM `spell_proc` WHERE `SpellId` = 80220;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(80220, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 100, 0, 1);

-- Treant Rejuvenation and Renew: "heals up to the three lowest health allies".
DELETE FROM `spell_script_names` WHERE `spell_id` IN (93717, 93726);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93717, 'spell_ascension_pet_lowest_health_allies'),
(93726, 'spell_ascension_pet_lowest_health_allies');
