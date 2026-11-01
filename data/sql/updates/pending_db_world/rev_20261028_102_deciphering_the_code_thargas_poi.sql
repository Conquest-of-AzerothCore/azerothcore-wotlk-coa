-- Deciphering The Code (175135): Ambassador Thargas Anvilmar (164389) moved to the Dun Kazad throne room in #8051,
-- but the objective and turn-in POIs still pointed at his old spot near the clothier, about 210 yards away
DELETE FROM `quest_poi_points` WHERE `QuestID` = 175135;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(175135, 0, 0, -6453, -320, 0),
(175135, 0, 1, -6450, -327, 0),
(175135, 0, 2, -6443, -330, 0),
(175135, 0, 3, -6436, -327, 0),
(175135, 0, 4, -6433, -320, 0),
(175135, 0, 5, -6436, -313, 0),
(175135, 0, 6, -6443, -310, 0),
(175135, 0, 7, -6450, -313, 0),
(175135, 1, 0, -6443, -320, 0);
