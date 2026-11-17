-- Paladin Abigail (164995) was a blue-skinned night elf; the earlier look read her headpiece as elf ears and the blue
-- light at the abbey bridge as skin and hair colour. On the live realm (Wo-WScrn-Shot-071226-220951, -072626-103037,
-- -072626-102418) she is a human woman with a grey ponytail in the Hallow Wind Initiates' armour, with small gold
-- shoulders and a gold Kyrian aspirant headpiece, holding a sword and a round metal shield. The shoulders, gloves and
-- headpiece colour are near matches; the sword is not identified and Scorpion Sting (1265) stands in for it.
DELETE FROM `creature_display_preset` WHERE `entry` = 164995;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164995, 50, 1, 1, 1, 0, 0, 8, 9, 0, 0, 71117, 19415, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 164995;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164995, 0, 50, 1, 1, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164995 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164995, 1, 1265, 4444, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960644 AND `id` = 164995;
