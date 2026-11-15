-- Rose of Remembrance (Passive) 23994: "Healing an ally has a chance to increase your spell power ...".
-- Spell.dbc gives it ProcFlags 0x4000 (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS) and ProcChance 35 with no spell_proc row,
-- so every helpful magic spell rolled it, including Mark of Order's once-a-second "Add stack" 806270.
-- SpellTypeMask 2 (PROC_SPELL_TYPE_HEAL) limits it to casts that heal; SpellPhaseMask 2 is the hit phase.
DELETE FROM `spell_proc` WHERE `SpellId` = 23994;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(23994, 0, 0, 0, 0, 0, 16384, 2, 2, 0, 0, 0, 0, 35, 0, 0);
