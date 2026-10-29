-- QuestSuperTrack rows are keyed by the QUEST id: the client looks the quest up by
-- row id, so arbitrary group ids were invisible. One row per quest, nodes placed in
-- objective slots 0..2 and slot 4 (objective -1, the turn in).
DELETE FROM `coa_client_quest_super_track` WHERE `ID` IN (9916201, 9916211);
DELETE FROM `coa_client_quest_super_track` WHERE `ID` BETWEEN 10576 AND 10583;

INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(9916201, 9916201, 0, 0, 9259), (9916201, 9916201, 0, 1, 9260), (9916201, 9916201, 0, 2, 9261),
(9916201, 9916201, 1, 0, 9262), (9916201, 9916201, 1, 1, 9263), (9916201, 9916201, 1, 2, 9264), (9916201, 9916201, 1, 3, 9265),
(9916201, 9916201, 2, 0, 9266), (9916201, 9916201, 2, 1, 9267), (9916201, 9916201, 2, 2, 9268), (9916201, 9916201, 2, 3, 9269),
(9916201, 9916201, -1, 0, 9270),
(9916211, 9916211, 0, 0, 9259), (9916211, 9916211, 0, 1, 9260), (9916211, 9916211, 0, 2, 9261),
(9916211, 9916211, 1, 0, 9262), (9916211, 9916211, 1, 1, 9263), (9916211, 9916211, 1, 2, 9264), (9916211, 9916211, 1, 3, 9265),
(9916211, 9916211, 2, 0, 9266), (9916211, 9916211, 2, 1, 9267), (9916211, 9916211, 2, 2, 9268), (9916211, 9916211, 2, 3, 9269),
(9916211, 9916211, -1, 0, 9271);
