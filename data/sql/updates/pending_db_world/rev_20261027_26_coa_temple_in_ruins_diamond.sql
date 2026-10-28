-- A Temple in Ruins (175154): the Temple of the Snow Leopard is entered through the Avatar of Anzuldin's gossip,
-- which teleports the player inside, but the quest diamond for the Sickly Slimes pointed at the temple door, sealed by
-- the temple model's collision, so players walked into an invisible wall. The slime objective now tracks the Avatar
-- (SuperTrack 21616) or, once inside, Anzuldin (21619); the client follows the nearest node.
DELETE FROM `coa_client_quest_super_track` WHERE `ID` = 33103;
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`, `AllowableRaces`) VALUES
(33103, 175154, -1, 0, 21619, 0),
(33103, 175154, 0, 0, 21616, 0),
(33103, 175154, 0, 1, 21619, 0),
(33103, 175154, 1, 0, 21619, 0);
