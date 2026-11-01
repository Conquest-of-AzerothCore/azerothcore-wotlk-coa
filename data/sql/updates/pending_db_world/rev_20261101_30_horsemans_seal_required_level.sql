-- The Horseman's Seal (49123) had RequiredLevel 80, above the realm's level-60 cap at the time of #10228, so
-- nobody who reached the Headless Horseman (lowered to level 63 by #8361) could ever equip it. Lower it to 60,
-- matching the cap the boss himself was fixed to be reachable at.
UPDATE `item_template` SET `RequiredLevel` = 60 WHERE `entry` = 49123;
