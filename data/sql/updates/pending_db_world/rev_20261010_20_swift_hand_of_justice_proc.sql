-- Swift Hand of Justice heals on a kill that yields experience or honor. Ascension's Spell.dbc gives its trigger aura 59906
-- no ProcFlags and the spell_proc row leaves them at 0 ("use the DBC"), so it never procs. PROC_FLAG_KILL, as Discerning
-- Eye of the Beast's row already sets for the same kind of item.
UPDATE `spell_proc` SET `ProcFlags` = 0x2 WHERE `SpellId` = 59906;
