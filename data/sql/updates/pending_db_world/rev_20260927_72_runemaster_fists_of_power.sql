-- Runemaster Fists of Power (805796, #663): its Spell.dbc record carries ProcFlags 0, so SpellMgr::LoadSpellProcs
-- generates no entry and the SPELL_AURA_PROC_TRIGGER_SPELL effect never casts Earthen Fists (806982).
-- "Engrave your fists for 15 sec, causing auto attacks to grant Earthen Fists": done melee auto attack hits, 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 805796;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(805796, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 100, 0, 0);
