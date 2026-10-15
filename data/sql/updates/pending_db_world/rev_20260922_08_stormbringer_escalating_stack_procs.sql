-- Eye of the Tornado (706297) and Dark Skies (300593) are SPELL_AURA_PROC_TRIGGER_SPELL passives whose DBC
-- ProcFlags are 0, so SpellMgr skips proc-entry auto-generation and Aura::GetProcEffectMask never evaluates them.
-- ProcFlags 69972 is the done-damage set (melee auto, melee/ranged/none/magic spell damage classes, ranged auto),
-- SpellTypeMask 1 = PROC_SPELL_TYPE_DAMAGE, SpellPhaseMask 2 = PROC_SPELL_PHASE_HIT.
-- Eye of the Tornado refunds Static only on a critical strike, so HitMask 2 = PROC_HIT_CRITICAL.
-- Dark Skies needs both branches (gain on a non-critical hit, removal on a critical hit), so HitMask 3.
DELETE FROM `spell_proc` WHERE `SpellId` IN (706297, 300593);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706297, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(300593, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 0, 0, 0, 100, 0, 0);

-- Dark Skies also has to drop its own buff on a critical strike, which no spell_proc column expresses.
DELETE FROM `spell_script_names` WHERE `spell_id` = 300593 AND `ScriptName` = 'aura_ascension_dark_skies';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (300593, 'aura_ascension_dark_skies');
