-- Rancher Ivor (164138) at the Windswept Summit dairy pasture wore the import's placeholder cook outfit. On the realm
-- he is a dark-haired, bearded rancher in a white shirt under blue bib overalls and black boots, holding a pitchfork
-- (video RIEMlZSgbQw 2:34:19-2:34:28 under his nameplate; U9OM4ZKDXb4 0:02:53-0:03:03). Skin, face and hair style
-- are too small in the footage to be sure of.
DELETE FROM `creature_display_preset` WHERE `entry` = 164138;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164138, 49, 1, 0, 1, 2, 0, 5, 0, 4, 0, 0, 0, 7889, 8233, 0, 0, 17833, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164138 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164138, 1, 124040, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960427 AND `id` = 164138;
