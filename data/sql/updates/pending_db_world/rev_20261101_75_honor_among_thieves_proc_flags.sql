-- Honor Among Thieves (51698, 51700, 51701) procs on a party member's critical strikes, but neither its row nor
-- Spell.dbc carries proc flags, so it never procced. Its row takes the damaging and healing hits its spell type mask
-- already admits.
UPDATE `spell_proc` SET `ProcFlags` = 0x15554 WHERE `SpellId` IN (51698, 51700, 51701) AND `ProcFlags` = 0;
