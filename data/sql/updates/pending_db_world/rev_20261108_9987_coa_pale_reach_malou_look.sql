-- Malou (164246) at Arathel's camp near Kerebor Fort wore the import's placeholder cook outfit on a man. On the realm
-- she is a woman in the Stormwind Guard plate set with sword and shield, kneeling north of Arathel (her realm display
-- 652818 is the female "Hombres de Arathel - F" variant beside Viktor's and Thearin's; Wo-WScrn-Shot-071226-035429,
-- video hxdp8nA91RA 2:16:29-2:16:36, SGUWwezq2Z0 1:19:27-1:19:31). The helm, shoulders, chest, legs and feet are seen;
-- her face is never seen under the helm, and the belt, gauntlets and tabard complete the set.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164246;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164246, 0, 50, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` = 164246;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164246, 50, 1, 1, 1, 1, 1, 1, 1, 0, 0, 11653, 4916, 0, 4628, 4629, 4630, 4656, 0, 5063, 0, 3734);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164246 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164246, 1, 1899, 143, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960745 AND `id` = 164246;

DELETE FROM `creature_addon` WHERE `guid` = 9960745;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960745, 0, 0, 8, 1, 0, 0, '');
