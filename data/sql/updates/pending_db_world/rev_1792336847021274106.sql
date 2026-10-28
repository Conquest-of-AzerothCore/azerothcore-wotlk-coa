-- Wondrous Wisdomball: prevent vendor resale and a possible repeatable-acquisition gold loop.
UPDATE `item_template` SET `SellPrice` = 0 WHERE `entry` = 101169;
