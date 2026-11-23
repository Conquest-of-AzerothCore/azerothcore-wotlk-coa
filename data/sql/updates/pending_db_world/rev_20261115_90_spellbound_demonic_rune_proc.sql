-- Spellbound Demonic Rune (item 1414516) equips 23992: "Your damaging spells have a chance to increase your spell
-- damage by $24025s1 for $24025d. Can only occur once per min." 23992 has ProcFlags 0 in Spell.dbc and had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped it and the trinket never procced (#12432).
-- ProcFlags 65536: done negative magic spell; SpellTypeMask 1: damage; SpellPhaseMask 2: hit.
-- Chance 100 is 23992's Spell.dbc ProcChance; Cooldown 60000 is the tooltip's once per minute.
DELETE FROM `spell_proc` WHERE `SpellId` = 23992;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(23992, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 100, 60000, 0);
