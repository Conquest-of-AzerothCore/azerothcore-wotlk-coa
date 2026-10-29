-- Pale Reach NPC looks rebuilt from realm footage and screenshots (Redthedeer VODs, playthrough videos, AscenSS):
-- Ealdir Dark Druids, Injured Andraste Soldier, The Family Cultist, Mekgineer Naudin Screwdriver, Innkeeper Stonebraid,
-- Durakh, Haldji, Dagna, Gormo Bouldertoe, Dorim Snowforge, Ergrain Tattersail and the Blood Elf Knight's staff.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164081, 164312, 164414, 164467);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164081, 0, 50, 1, 1, 0),
(164312, 0, 15476, 1, 1, 0),
(164414, 0, 53, 1, 1, 0),
(164467, 0, 53, 1, 1, 0);

DELETE FROM `creature_display_preset` WHERE `entry` IN (164033, 164081, 164153, 164312, 164393, 164404, 164414, 164436, 164457, 164467, 164565, 164998);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164033, 50, 1, 1, 1, 8, 0, 0, 0, 0, 0, 136561, 136582, 0, 9674, 0, 0, 0, 0, 0, 0, 0),
(164081, 50, 1, 1, 1, 8, 0, 0, 0, 0, 0, 136561, 136582, 0, 9674, 0, 0, 0, 0, 0, 0, 0),
(164153, 50, 1, 1, 1, 0, 0, 6, 17, 0, 0, 0, 4916, 0, 4628, 4629, 4630, 4656, 0, 5063, 0, 16657),
(164312, 15476, 10, 0, 1, 24, 0, 1, 21, 3, 0, 48193, 45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0),
(164393, 1563, 7, 0, 1, 0, 0, 2, 13, 5, 0, 10195, 83012, 0, 83009, 83007, 83011, 83008, 83013, 0, 0, 0),
(164404, 53, 3, 0, 1, 5, 0, 1, 6, 2, 0, 0, 0, 10038, 136002, 0, 1338, 136003, 0, 135999, 0, 0),
(164414, 53, 3, 0, 1, 2, 0, 1, 12, 8, 0, 0, 0, 0, 580, 13430, 17832, 17833, 0, 13390, 0, 0),
(164436, 53, 3, 0, 1, 2, 0, 6, 8, 7, 0, 0, 0, 39222, 17624, 5028, 146, 1405, 0, 623, 0, 0),
(164457, 54, 3, 1, 1, 1, 2, 1, 6, 0, 0, 0, 0, 0, 6371, 0, 1174, 3000, 0, 0, 0, 0),
(164467, 53, 3, 0, 1, 2, 0, 6, 4, 0, 0, 11951, 0, 7889, 6010, 0, 13188, 11071, 0, 10735, 0, 0),
(164565, 54, 3, 1, 1, 3, 6, 9, 2, 0, 0, 0, 0, 0, 9385, 0, 43819, 8931, 121832, 0, 0, 0),
(164998, 54, 3, 1, 1, 7, 0, 6, 7, 0, 0, 0, 0, 0, 97595, 0, 0, 97109, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164033, 164081, 164307);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164033, 1, 262787, 0, 0, 0),
(164081, 1, 262787, 0, 0, 0),
(164307, 1, 15275, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164033, 164081);
