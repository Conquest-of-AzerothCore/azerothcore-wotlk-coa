-- Mirror the shape CoA ships for its own custom quests: the QuestSuperTrack row id
-- sits beyond the client's max (their 9915004 uses 33213), and the nodes are ids the
-- client already carries. Nothing here invents an id the table cannot hold.
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (105, 137, 33213, 33214, 33215);

INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(33214, 9916201, 0, 0, 2), (33214, 9916201, 0, 1, 3), (33214, 9916201, 0, 2, 27),
(33214, 9916201, 1, 0, 53), (33214, 9916201, 1, 1, 78), (33214, 9916201, 1, 2, 107), (33214, 9916201, 1, 3, 108),
(33214, 9916201, 2, 0, 109), (33214, 9916201, 2, 1, 110), (33214, 9916201, 2, 2, 111), (33214, 9916201, 2, 3, 116),
(33214, 9916201, -1, 0, 146),
(33215, 9916211, 0, 0, 2), (33215, 9916211, 0, 1, 3), (33215, 9916211, 0, 2, 27),
(33215, 9916211, 1, 0, 53), (33215, 9916211, 1, 1, 78), (33215, 9916211, 1, 2, 107), (33215, 9916211, 1, 3, 108),
(33215, 9916211, 2, 0, 109), (33215, 9916211, 2, 1, 110), (33215, 9916211, 2, 2, 111), (33215, 9916211, 2, 3, 116),
(33215, 9916211, -1, 0, 202);
