-- Runemaster Runic talents (#796, #862, #883, #905).
-- Stone Savant 520917 (#796): ProcFlags 0 in Spell.dbc, so no proc entry existed. A critical hit of Weapon
-- Engraving: Earth 653272 (family 38, mask1 0x20000, unique to it) while Earthen Fists 806982 is active casts
-- 520934 (extra attacks). The damage is usually triggered by the Earth Engraving proc, hence TRIGGERED_CAN_PROC.
-- Protective Warding 800756 (#905): ProcFlags 0; every critical damage hit taken casts 800753, whose effect 192
-- reduces the remaining cooldown of Guarding Rune 500464 by 10%.
DELETE FROM `spell_proc` WHERE `SpellId` IN (520917, 800756);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520917, 0, 38, 0, 131072, 0, 65536, 1, 2, 2, 2, 0, 0, 100, 0, 0),
(800756, 0, 0, 0, 0, 0, 664232, 1, 0, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 24 AND `SourceEntry` = 520917;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(24, 0, 520917, 0, 0, 1, 0, 806982, 0, 0, 0, 0, 0, '', 'Stone Savant only procs while Earthen Fists is active');

-- Granite Shield 806996 (#883) grants 520822 only while the caster's own Runic Tattoos: Earth is active.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (806996, 800753) AND `ScriptName` IN
    ('aura_ascension_runemaster_granite_shield', 'spell_ascension_runemaster_protective_warding');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(806996, 'aura_ascension_runemaster_granite_shield'),
(800753, 'spell_ascension_runemaster_protective_warding');
