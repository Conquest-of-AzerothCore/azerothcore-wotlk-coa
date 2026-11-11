-- The Family Zealots (164310) stood bare but for a hood. Live footage shows them robed like the rest of the cult, so they
-- take The Family Cultist's (164312) outfit (shoulders, Shadowveil robe, boots, gloves and cloak) but keep their own
-- plainer purple Shadow Hood (11992), as their target portrait shows.
DELETE FROM `creature_display_preset` WHERE `entry` = 164310 AND `display_id` = 15476;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164310, 15476, 10, 0, 1, 24, 0, 1, 21, 3, 0, 11992,45136, 0, 74340, 0, 0, 74328, 0, 46011, 74310, 0);
