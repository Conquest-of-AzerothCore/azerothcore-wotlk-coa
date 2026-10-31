-- creature_questitem is what the server puts into SMSG_CREATURE_QUERY_RESPONSE
-- (QueryHandler.cpp, MAX_CREATURE_QUEST_ITEMS slots). That is how the client knows a
-- creature drops a quest item, and it is what draws the quest marker and the ground
-- ring. Quest 33's wolves all have a row for item 750; our bosses had none.
DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (9916212, 9916213, 9916214);
INSERT INTO `creature_questitem` (`CreatureEntry`, `ItemId`, `Idx`) VALUES
(9916212, 1009302, 0),
(9916213, 1009303, 0),
(9916214, 1009304, 0);
