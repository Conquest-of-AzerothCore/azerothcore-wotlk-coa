-- The class potion's menu header.
--
-- Drinking the Class Change Potion (97858) opens an item gossip menu listing the realm's own
-- classes.  The window's text is an `npc_text` row: the menu is sent with this id and the client
-- asks for the text itself (CMSG_NPC_TEXT_QUERY -> SMSG_NPC_TEXT_UPDATE, answered from this table
-- by ObjectMgr::GetGossipText), which is why a custom row is all the window needs.
--
-- No colour codes here on purpose.  The gossip window draws its own text and embedded colours fight
-- with it: the first version of this row was bright yellow (`|cffffff00`), which is the good colour
-- for a chat notice and a bad one in that frame - it came out almost unreadable against the
-- window's own background.  The default text colour is the readable one; keep it plain.
--
-- The id is 9000092, not 9000090 or 9000091.  The client caches the text it has been answered with
-- for an id, so a rewritten row under an id it already knows keeps showing the old string - the same
-- reason a rewritten DBC entry needs a client cache clear.  Both earlier ids are deleted here
-- instead of left behind, so nothing can answer a query with the superseded strings.
--
-- Written as DELETE + INSERT so re-applying it restores exactly this text and touches nothing else.
-- The id is also the constant GossipTextId in modules/mod-coa-change-potions/src/change_potions.cpp.

DELETE FROM `npc_text` WHERE `ID` IN (9000090, 9000091, 9000092);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES (9000092, 'Choose your new class. Your Class Change Potion is spent when you pick one.', 'Choose your new class. Your Class Change Potion is spent when you pick one.', 1);
