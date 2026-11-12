-- The undead of the Hallow Wind crypts were unarmed. On the live realm a Fallen Crusader (164997) holds a long plain
-- sword in one hand (video V10AMkhYl6c 01:00:12, 01:02:12; Wo-WScrn-Shot-071226-220951) and a Reanimated Devotee
-- (164313) swings a long plain staff (V10AMkhYl6c 01:02:07; fppvzzEmIX8 00:54:56). The footage shows the kind of weapon,
-- not the item: Scratched Claymore (2128) and Rough Wooden Staff (1515) were picked from renders. Cardinal Royce is
-- unarmed on the realm as well.
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164997, 164313) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164997, 1, 2128, 0, 0, 0),
(164313, 1, 1515, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164997, 164313);
