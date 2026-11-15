-- Frostmane Ambushers (164061, 164073) fought bare-handed; on the live realm they hold blades (videos pEoiXrErJ6w
-- 02:46:24 and F4ZLp4Ihz4o 02:03). They carry a Copper Dagger (7166) in each hand, picked in game.
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164061, 164073) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164061, 1, 7166, 7166, 0, 0),
(164073, 1, 7166, 7166, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164061, 164073);
