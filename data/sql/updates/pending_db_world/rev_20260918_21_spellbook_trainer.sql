-- The Books of Ascension are served by the spellbook module now, not by the compat layer's
-- gossip, and they have to look like trainers to the client.
--
-- The flag is not cosmetic. The client draws the trainer window only for a unit it believes is
-- a trainer, and the bit it reads is UNIT_NPC_FLAG_TRAINER (0x10). Flagging the books as
-- gossip (0x1) and vendor (0x80) instead - as this file first did - leaves the client treating
-- a book as an ordinary gossip NPC, and the trainer list the module sends it is dropped on the
-- floor: no window, no Lua error, and nothing in the server log, because nothing failed on the
-- server side.
--
-- 0x30 = trainer | class trainer, exactly what this realm's own class trainers carry, and
-- deliberately without the gossip bit: a trainer-flagged unit is asked for its list directly,
-- so right-clicking a book goes straight to the trainer window, the way the books behaved on
-- the live realm. The module still answers the gossip path as a fallback.
--
-- The script name is the whole link between the data and the module: `Spellbook.Enable = 0`
-- leaves the books inert, and moving the behaviour elsewhere is a change to this one column.
--
-- This list is every template the class-training books use, including the two companions the
-- book restore added (75118 Beginner's, 499992 Book of Ascension).

UPDATE `creature_template` SET `ScriptName` = 'npc_spellbook_trainer', `npcflag` = 48
WHERE `entry` IN (73427, 75115, 75118, 75119, 75136, 75137, 75139, 80054, 80890, 98499, 98500,
    98501, 98598, 108312, 108586, 108587, 499992, 988501);
