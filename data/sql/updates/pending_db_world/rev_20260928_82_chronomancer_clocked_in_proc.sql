-- Clocked In (520168): "Your next Artificer's Wand within $520168d is instant cast and generates an
-- additional Echo Fragment." Effect 1 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) triggering 520170
-- (Caverns of Time Trigger, itself SPELL_EFFECT_TRIGGER_SPELL -> 804455 Echo Fragment) and effect 2 is
-- aura 108 (ADD_PCT_MODIFIER, MiscValue 10 = SPELLMOD_CASTING_TIME, the instant-cast half). Spell.dbc
-- gives 520168 ProcFlags 0 and ProcCharges 0, and no spell_proc row existed anywhere in the tree, so
-- SpellMgr::LoadSpellProcs skipped it entirely: neither the extra fragment nor the consumption ever
-- happened, and the buff only expired on its own short duration. The tooltip names Artificer's Wand only
-- (not Wand of Time), so the row is keyed to family 28 word2 0x200 = 512, Artificer's Wand 561064's own
-- SpellFamilyFlags [0, 0, 512] and no other family 28 record - narrower than the generic "Wand attacks"
-- rows (Discovery, Elder Wand), which also admit Wand of Time. Both spells sharing this family flag are
-- Spell.dbc DmgClass 3 (RANGED), so ProcFlags = PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 256, SpellTypeMask
-- 1 = damage, SpellPhaseMask 2 = hit, matching every other Artificer's Wand-hit proc in this tree. Chance
-- is the record's own ProcChance (100). Charges 1 overwrites ProcCharges so the aura is removed after its
-- first successful proc, matching "your next Artificer's Wand" and SpellMgr.h's own Charges comment
-- ("defines how many times proc can occur before aura remove").
DELETE FROM `spell_proc` WHERE `SpellId` = 520168;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520168, 0, 28, 0, 0, 512, 256, 1, 2, 0, 0, 0, 0, 100, 0, 1);
