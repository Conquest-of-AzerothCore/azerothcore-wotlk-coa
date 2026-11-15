-- Hallow Wind Initiates 164200-164203 wore a green and blue plate set and no weapon, unlike Initiates 164197-164199
-- and 164204. All eight wear the same gold plate chest, mail legs, boots and gloves and carry the same longsword
-- (outfit confirmed in game).
UPDATE `creature_display_preset` SET `item_shoulders` = 0, `item_chest` = 24528, `item_legs` = 2038, `item_feet` = 7504,
`item_hands` = 16726 WHERE `entry` IN (164200, 164201, 164202, 164203) AND `display_id` = 49;

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164200, 164201, 164202, 164203, 164204) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164200, 1, 869, 0, 0, 0),
(164201, 1, 869, 0, 0, 0),
(164202, 1, 869, 0, 0, 0),
(164203, 1, 869, 0, 0, 0),
(164204, 1, 869, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164200, 164201, 164202, 164203, 164204);
