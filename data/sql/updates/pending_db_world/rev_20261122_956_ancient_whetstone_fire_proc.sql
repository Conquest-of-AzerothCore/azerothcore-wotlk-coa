-- Ancient Whetstone (410189) enchants a weapon with 1005, whose equip aura 201174 has a 10% proc chance in Spell.dbc
-- but no proc flags, so its Fire damage (201175) never triggered. It now procs on melee hits (0x14, the flags stock
-- chance-on-hit equip auras use, on the damage hit phase) with the DBC chance.
DELETE FROM `spell_proc` WHERE `SpellId` = 201174;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(201174, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0);
