-- Stormbringer Storm Clouds 705686 (#2797): "Doubles the damage of Body of Lightning and it now
-- automatically casts on you when you cast it on an ally."
--
-- Only the second clause is missing. The first one is delivered by the engine: effect 1 of 705686 is
-- SPELL_AURA_ADD_PCT_MODIFIER with MiscValue 0 (SPELLMOD_DAMAGE), amount EffectBasePoints 99 +
-- EffectDieSides 1 = +100%, and a class mask of 4194304 on word 1, which is the SpellFamilyFlags[1] of
-- 800406 Body of Lightning (damage) - Unit::SpellDamageBonusDone applies it to every done-damage
-- computation.
--
-- Effect 0 is a SPELL_AURA_PROC_TRIGGER_SPELL (42) on 520843 "Cloudy", whose SPELL_EFFECT_TRIGGER_SPELL
-- casts 500041 Body of Lightning on TARGET_UNIT_CASTER - exactly the promised self-cast. As for
-- Conjuration Mastery the record has ProcFlags 0 and no `spell_proc` row existed, so
-- SpellMgr::LoadSpellProcs skipped it and Aura::GetProcEffectMask returned a zero mask: that clause never
-- ran. Same shape as rev_1789944986203842691.sql and rev_20260920_40_bloodmage_cast_proc_triggers.sql.
--
-- SpellFamilyMask1 32 is the SpellFamilyFlags[1] of 500041, the ally-targeted parent that the tooltip names.
-- 500041 has DmgClass 0 (SPELL_DAMAGE_CLASS_NONE) and is a positive ally buff, so Spell::cast raises
-- PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_POS 1024 at SpellPhaseMask 1 (PROC_SPELL_PHASE_CAST); HitMask stays 0,
-- which CAST phase with DONE flags skips. Chance 100 is the record's own ProcChance. The self-cast cannot
-- recurse: it arrives as a triggered cast and Aura::GetProcEffectMask rejects triggered casts unless
-- PROC_ATTR_TRIGGERED_CAN_PROC is set, which this row does not set.
--
-- Two authored oddities are left as they are, since the issue reports neither: the row also fires when Body
-- of Lightning is cast on the caster themselves, which re-applies the same buff, and 520843 carries a second
-- SPELL_EFFECT_DISPEL effect on nearby allies (Static 803102 has Dispel 0, so the class resource is not
-- affected).
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 705686;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705686, 0, 22, 0, 32, 0, 1024, 0, 1, 0, 0, 0, 0, 100, 0, 0);
COMMIT;
