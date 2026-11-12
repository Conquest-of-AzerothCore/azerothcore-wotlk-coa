-- Scholar Enharon (164208) had solid green hands: his gloves (display 95315) use a DXT5 hand texture, which this
-- client cannot draw as a body texture. On the live realm (videos RIEMlZSgbQw 07:20:03, 9elvxh9Fct0 00:29:43;
-- Wo-WScrn-Shot-071226-230312) he wears dark fingerless gloves and plain tan shoes, where he was barefoot, and holds
-- a red feather quill. The gloves and shoes are near matches; the quill (Scribe's Talon) is the model seen. His face
-- is an older one, chosen by eye.
UPDATE `creature_display_preset` SET `face` = 10, `item_feet` = 3830, `item_hands` = 21720
WHERE `entry` = 164208 AND `display_id` = 49;

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164208 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164208, 1, 262617, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960638 AND `id` = 164208;
