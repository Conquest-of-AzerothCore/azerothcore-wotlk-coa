-- The eight Hallow Wind Initiates (164197-164204) were nearly all the same bearded man. Live footage of the A Crisis of
-- Faith duels shows seven different Initiates (videos 9elvxh9Fct0 00:10:24-00:12:00, SGUWwezq2Z0 00:19:00-00:26:36,
-- i5vATMYui0I 01:49:16-01:50:36): three women, three men and a dwarf. Each entry gets one of them, in the outfit they
-- share; 164199 is a plain eighth man, as only seven are seen. Which entry is which person is a choice, and faces are
-- not readable from the portraits.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164197, 164198, 164199, 164200, 164201, 164202, 164203, 164204);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164197, 49, 1, 0, 1, 4, 0, 6, 4, 4, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164198, 49, 1, 0, 1, 4, 5, 1, 4, 4, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164199, 49, 1, 0, 1, 2, 7, 5, 1, 8, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164200, 53, 3, 0, 1, 1, 0, 0, 6, 0, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164201, 50, 1, 1, 1, 1, 0, 6, 21, 0, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164202, 50, 1, 1, 1, 0, 2, 7, 22, 0, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164203, 49, 1, 0, 1, 3, 3, 7, 5, 7, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0),
(164204, 50, 1, 1, 1, 1, 12, 15, 13, 0, 0, 0, 0, 0, 24528, 0, 2038, 7504, 0, 16726, 0, 0);

UPDATE `creature_template_model` SET `CreatureDisplayID` = 53 WHERE `CreatureID` = 164200 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 50 WHERE `CreatureID` IN (164201, 164202) AND `Idx` = 0;
