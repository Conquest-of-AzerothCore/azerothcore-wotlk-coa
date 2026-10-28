-- Sunspeaker Talethia 50327, Deathknell Sun Cleric trainer: CoA footage shows her in Elegant Robes 10215 (display
-- 23107, the yellow Robe_C_05 gown), identified in the client's appearance collection. The robe replaces the
-- stand-in Sunfire robe, belt, trousers and boots of rev_20260923_09.
UPDATE `creature_display_preset` SET `item_chest` = 23107, `item_waist` = 0, `item_legs` = 0, `item_feet` = 0
    WHERE `entry` = 50327;
