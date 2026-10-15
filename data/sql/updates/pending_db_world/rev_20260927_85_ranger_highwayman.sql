-- Highwayman (#925): "Direct critical strikes while behind your target increase your haste by 15% for 5 sec, or for
-- your next 2 attacks." 707744 is a SPELL_AURA_PROC_TRIGGER_SPELL on 705063, whose SPELL_EFFECT_TRIGGER_SPELL casts
-- the 704545 haste buff on the Ranger, but Spell.dbc gives 707744 ProcFlags 0 and no spell_proc row existed, so it
-- never fired. The row admits damaging direct critical hits (melee and ranged autos and abilities, negative
-- none-class and magic spells; no periodic flag) at the HIT phase. aura_ascension_ranger_highwayman adds the
-- behind-the-target gate that spell_proc cannot express. 704545's two charges are already in
-- rev_20260921_40_ranger_dead_procs.sql.
DELETE FROM `spell_script_names` WHERE `spell_id` = 707744 AND `ScriptName` = 'aura_ascension_ranger_highwayman';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707744, 'aura_ascension_ranger_highwayman');
DELETE FROM `spell_proc` WHERE `SpellId` = 707744;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707744, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 0, 0, 0);
