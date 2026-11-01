-- The bosses had lootid 0, so their loot table was never read. Point them at it.
UPDATE `creature_template`
SET `lootid` = `entry`
WHERE `entry` IN (9916212, 9916213, 9916214);

-- The diploma is an epic scroll like the trophies.
UPDATE `item_template`
SET `Quality` = 4
WHERE `entry` = 1009100;
