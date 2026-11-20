-- Voice of Bwonsamdi 801716 explodes on periodic damage, and its event handler counts each Shadow Puppet
-- hit 802745 as periodic. Those hits are direct magic-class damage, so the row's periodic-only ProcFlags
-- never offered them to the handler. Add PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000).
UPDATE `spell_proc` SET `ProcFlags` = 327680 WHERE `SpellId` = 801716;
