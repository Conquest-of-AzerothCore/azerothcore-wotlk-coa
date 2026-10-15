-- Lesser Skeletal Warrior (50065, Raise: Lesser Skeletal Warrior 500970) and Greater Skeletal Warrior
-- (51065, Raise: Greater Skeletal Warrior 504901) had no equipment row, so the summons fought bare-handed.
-- Summons load equipment ID 1: a Worn Shortsword (25) and a Worn Battleaxe (12282).
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50065, 51065) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(50065, 1, 25, 0, 0, 0),
(51065, 1, 12282, 0, 0, 0);
