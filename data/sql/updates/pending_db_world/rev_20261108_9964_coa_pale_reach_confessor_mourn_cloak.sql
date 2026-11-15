-- Confessor Mourn (164556) on the live realm (video RIEMlZSgbQw 06:44:37-06:44:41, in-world views from the front, side
-- and back) wears a short white cloak with a gold scroll border over the robe, is clean-shaven and has bright white
-- hair. The earlier look was built from the dialogue model view, which hides the back, and gave him a painted goatee.
UPDATE `creature_display_preset` SET `haircolor` = 14, `facialhair` = 8, `item_back` = 11755
WHERE `entry` = 164556 AND `display_id` = 49;
