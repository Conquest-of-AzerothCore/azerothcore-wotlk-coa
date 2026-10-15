DELETE FROM `spell_script_names` WHERE `spell_id` IN (-534803, 805381, 500639)
    AND `ScriptName` = 'aura_ascension_damage_palm_sigil';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-534803, 'aura_ascension_damage_palm_sigil'),
(805381, 'aura_ascension_damage_palm_sigil'),
(500639, 'aura_ascension_damage_palm_sigil');

DELETE FROM `spell_proc` WHERE `SpellId` IN (-534803, 805381, 805382, 500639, 807013);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-534803, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 1),
(805381, 126, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 2, 0, 100, 0, 1),
(805382, 126, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 1),
(500639, 126, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 1),
(807013, 126, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 0, 0, 100, 0, 1);
