-- Deciphering The Code (175135): the quest diamond still led to Thargas Anvilmar's old spot near the clothier.
-- The client takes it from QuestSuperTrack 33057 -> SuperTrack 21552 (objective 0) and 21553 (turn-in), both at
-- (-6651.3, -295.7, 579.0). Ambassador Thargas Anvilmar (164389, guid 9962261) stands in the Dun Kazad throne room
-- since #8051; both nodes now point at his spawn. Radius, NextID and Flags keep the client's values (0).
-- Only quest 175135 references these nodes. The player must relog to receive them.
DELETE FROM `coa_client_super_track` WHERE `ID` IN (21552, 21553);
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(21552, 0, -6443.07, -319.93, 576.763, 0, 0, 0),
(21553, 0, -6443.07, -319.93, 576.763, 0, 0, 0);
