-- Elder Wand (560129): "Your Wand attacks now have a $h% chance to increase the damage of Artificer's
-- Wand against the target by $560128s1% for $560128d, stacking $560128u times." Its effect 0 is aura 42
-- (proc trigger spell) triggering 560128 (a target debuff applying SPELL_AURA_MOD_DAMAGE_FROM_CASTER,
-- EffectBasePoints 2 / DieSides 1 -> +3%, StackAmount 10, EffectSpellClassMask word2 0x200 = 512, which
-- matches Artificer's Wand 561064's own SpellFamilyFlags [0, 0, 512] and no other family 28 spell), but
-- Spell.dbc gives 560129's record ProcFlags 0 and no `spell_proc` row existed, so 560128 could never be
-- applied. Proc on the ranged class damage of Wand of Time (family 28, word1 0x100000 = 1048576, the bit
-- carried by 520175 and every rank 520702-520707, 524960, 520165) and Artificer's Wand (family 28, word2
-- 0x200 = 512), which is the same definition of "Wand attacks" already shipped for Erode Armaments in
-- rev_20260918_38_chronomancer_erode_armaments_proc.sql. Both spells are Spell.dbc DmgClass 3 (RANGED),
-- so the proc flag is PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (SpellMgr.h:122), not the
-- 0x10000 magic-class flag the Discordance-driven Chronomancer rows use; Spell::prepareDataForTriggerSystem
-- (Spell.cpp:2278-2288) assigns exactly that flag to a DmgClass 3 spell without SPELL_ATTR2_AUTO_REPEAT.
-- Both spells carry SPELL_EFFECT_WEAPON_PERCENT_DAMAGE/SPELL_EFFECT_SCHOOL_DAMAGE effects, so the HIT
-- event reports real damage and Unit::ProcSkillsAndAuras computes SpellTypeMask PROC_SPELL_TYPE_DAMAGE
-- (1) (Unit.cpp:7121-7133); SpellPhaseMask is 2 (PROC_SPELL_PHASE_HIT) because the tooltip is about the
-- attack landing, not about casting. HitMask stays 0 so the default normal/critical/absorb set applies.
-- Chance is the record's own ProcChance (30), unchanged.
DELETE FROM `spell_proc` WHERE `SpellId` = 560129;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560129, 0, 28, 0, 1048576, 512, 256, 1, 2, 0, 0, 0, 0, 30, 0, 0);
