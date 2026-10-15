-- Wonders of Time: only direct healing can grant Endless Sands.
-- 17408 = DONE_SPELL_NONE_DMG_CLASS_POS | DONE_SPELL_MAGIC_DMG_CLASS_POS.
UPDATE `spell_proc` SET `ProcFlags` = 17408 WHERE `SpellId` = 560541;
