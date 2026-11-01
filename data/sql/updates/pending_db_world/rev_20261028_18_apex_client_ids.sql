-- The client's DBCs are fixed-size tables: an inserted row must land inside the
-- id space the client already has. ItemDisplayInfo ends at 171126, SuperTrack at
-- 21632 and QuestSuperTrack at 33141, so the ids used before (990002 and 9930xxx)
-- could never be inserted.

-- ---- item display ids move into the client's range ------------------------
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` IN (990002, 990003, 990004, 990005);
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` IN (68757, 68758, 68759, 68760);
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `InventoryIcon_1`) VALUES
(68757, '', 'trade_archaeology_apexisscroll'),
(68758, '', 'inv_misc_pelt_07'),
(68759, '', 'inv_misc_pelt_08'),
(68760, '', 'inv_misc_scales_reptileviolet03');

UPDATE `item_template` SET `displayid` = 68757 WHERE `entry` = 1009100;
UPDATE `item_template` SET `displayid` = 68758 WHERE `entry` = 1009101;
UPDATE `item_template` SET `displayid` = 68759 WHERE `entry` = 1009102;
UPDATE `item_template` SET `displayid` = 68760 WHERE `entry` = 1009103;

UPDATE `item_dbc` SET `DisplayInfoID` = 68757 WHERE `ID` = 1009100;
UPDATE `item_dbc` SET `DisplayInfoID` = 68758 WHERE `ID` = 1009101;
UPDATE `item_dbc` SET `DisplayInfoID` = 68759 WHERE `ID` = 1009102;
UPDATE `item_dbc` SET `DisplayInfoID` = 68760 WHERE `ID` = 1009103;

-- ---- super track nodes move into the client's range -----------------------
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9259 AND 9271;
INSERT INTO `coa_client_super_track` (`ID`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Radius`, `NextID`, `Flags`) VALUES
(9259, 1, 2267.21, -6787.11, 125.24, 25, 0, 0),
(9260, 1, 2310.67, -6875.93, 121.74, 25, 0, 0),
(9261, 1, 2353.55, -6880.87, 121.21, 25, 0, 0),
(9262, 0, 138.558, -4523.49, 126.401, 25, 0, 0),
(9263, 0, 201.369, -4492.76, 119.737, 25, 0, 0),
(9264, 0, 156.261, -4482.47, 125.652, 25, 0, 0),
(9265, 0, 194.693, -4465.27, 110.869, 25, 0, 0),
(9266, 1, -3887.07, 1958.59, 75.3706, 25, 0, 0),
(9267, 1, -3815.15, 2018.34, 69.0198, 25, 0, 0),
(9268, 1, -3836.58, 1913.61, 81.4929, 25, 0, 0),
(9269, 1, -3870.56, 1991.62, 72.962, 25, 0, 0),
(9270, 0, -9168.72, 768.735, 154.275, 15, 0, 0),
(9271, 1, 2003.64, -4645.85, 25.9132, 15, 0, 0);

DELETE FROM `coa_client_quest_super_track` WHERE `ID` BETWEEN 10576 AND 10583;
INSERT INTO `coa_client_quest_super_track` (`ID`, `QuestID`, `ObjectiveIndex`, `NodeIndex`, `SuperTrackID`) VALUES
(10576, 9916201, 0, 0, 9259), (10576, 9916201, 0, 1, 9260), (10576, 9916201, 0, 2, 9261),
(10577, 9916201, 1, 0, 9262), (10577, 9916201, 1, 1, 9263), (10577, 9916201, 1, 2, 9264), (10577, 9916201, 1, 3, 9265),
(10578, 9916201, 2, 0, 9266), (10578, 9916201, 2, 1, 9267), (10578, 9916201, 2, 2, 9268), (10578, 9916201, 2, 3, 9269),
(10579, 9916201, -1, 0, 9270),
(10580, 9916211, 0, 0, 9259), (10580, 9916211, 0, 1, 9260), (10580, 9916211, 0, 2, 9261),
(10581, 9916211, 1, 0, 9262), (10581, 9916211, 1, 1, 9263), (10581, 9916211, 1, 2, 9264), (10581, 9916211, 1, 3, 9265),
(10582, 9916211, 2, 0, 9266), (10582, 9916211, 2, 1, 9267), (10582, 9916211, 2, 2, 9268), (10582, 9916211, 2, 3, 9269),
(10583, 9916211, -1, 0, 9271);

-- remove the out of range leftovers
DELETE FROM `coa_client_super_track` WHERE `ID` BETWEEN 9930001 AND 9930032;
DELETE FROM `coa_client_quest_super_track` WHERE `ID` BETWEEN 9930100 AND 9930119;
