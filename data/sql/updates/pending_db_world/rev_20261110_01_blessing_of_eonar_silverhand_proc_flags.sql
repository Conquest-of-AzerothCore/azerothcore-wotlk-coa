-- Blessing of Eonar 705290 also grants its proc from casting Silverhand Incantation, a harmful magic-class
-- cast (AscensionTemplarTemporaryLibramProcs.cpp, SPELL_SILVERHAND branch), so its spell_proc row also needs
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000) on top of the Librams' positive-cast flags from
-- rev_20260909_04_templar_completion.sql. That row only ever matched a positive cast, so the Silverhand
-- branch never fired (round10 r10/proc-chains: confirmed by a trial-based measurement, 0/273 events).
UPDATE `spell_proc` SET `ProcFlags` = 81936 WHERE `SpellId` = 705290;
