-- #950 Aeromancy (705708) and #1155 Storm Bond (500580) ship ProcFlags = 0 in Spell.dbc, so
-- SpellMgr::LoadSpellProcs generates no proc entry for them and their SPELL_AURA_PROC_TRIGGER_SPELL
-- effects can never fire. Everything downstream of the proc is native.
-- 705708 echoes Updraft (family 22, SpellFamilyFlags[0] = 0x2000 = 8192, DmgClass magic) on the cast
-- phase; 16384 | 65536 = 81920 covers both magic-class done flags Spell::cast picks by positivity.
-- 500580 consumes the Air Elemental's damage, the same event the sibling 806020 row already uses.
DELETE FROM `spell_proc` WHERE `SpellId` IN (500580, 705708);
INSERT INTO `spell_proc` (`SpellId`, `SpellFamilyName`, `SpellFamilyMask0`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(500580, 0, 0, 332116, 1, 2, 3, 2, 100),
(705708, 22, 8192, 81920, 0, 1, 0, 0, 100);
