-- War's True Ambition: the Freed Hostage (164065) wore only plate_common_b_02 shoulders, boots and gloves, a
-- Cataclysm model the client lacks (the shoulders drew as cubes), over her underwear. She now wears the shirt and
-- trousers of the Captured Farmer (display 3683) and keeps her belt.
UPDATE `creature_display_preset` SET `item_shoulders` = 0, `item_body` = 7888, `item_legs` = 5586, `item_feet` = 0, `item_hands` = 0 WHERE `entry` = 164065 AND `display_id` = 50;
