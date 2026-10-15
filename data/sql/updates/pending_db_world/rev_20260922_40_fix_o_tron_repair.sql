-- The Fix-o-Tron 5000, a repair bot that could not be right clicked.
--
-- 92981 summons creature 80879 as a companion, and the item that teaches it describes a
-- portable repair robot: the point of it is repairing inside a raid or a dungeon without
-- leaving. The row carries npcflag 0, so a right click on the summoned pet has nothing to
-- answer with and the bot is decoration.
--
-- This is the gap mod-treasure-keeper documented for CoA's two bank companions, with a
-- different flag. A repair bot carries UNIT_NPC_FLAG_VENDOR = 0x80 and
-- UNIT_NPC_FLAG_REPAIR = 0x1000, which is 4224 together - the same pair Field Repair Bot
-- 110G (24780) and Field Repair Bot 74A (14337) carry in this database. The client then opens
-- the merchant window on the click and draws the repair button in it; the bot sells nothing,
-- so the window is the repair button and an empty list.
--
-- The gossip flag is deliberately absent. A unit that carries it is read by the client as a
-- gossip NPC and never sends the merchant click, which is the trap the bank companions and the
-- Book of Artisans both hit.
--
-- unit_flags 768 (IMMUNE_TO_PC | IMMUNE_TO_NPC) is this realm's convention for interactable
-- companions and props - the bank keepers and the restored Destiny Weavers carry it - so the
-- pet cannot be attacked or spell-targeted out from under the window.

UPDATE `creature_template`
SET `npcflag` = 4224, `unit_flags` = 768
WHERE `entry` = 80879;
