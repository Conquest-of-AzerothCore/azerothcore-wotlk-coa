-- Patriarch Khazemil (164455): the red-and-gold belt (154) is out of place on his robe; the user asked for it gone.
UPDATE `creature_display_preset` SET `item_waist` = 0 WHERE `entry` = 164455 AND `display_id` = 53;
