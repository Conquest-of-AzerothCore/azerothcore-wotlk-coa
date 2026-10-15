-- Mining Pick, Blacksmith Hammer and Skinning Knife carried placeholder stats (artifact quality 6, required
-- level 10) from the imported item data, so level 1 characters could not use them. Restore AzerothCore's
-- starter tool stats; display and subclass keep the client Item.dbc values and vendor prices are unchanged.
UPDATE `item_template` SET `Quality` = 1, `ItemLevel` = 4, `RequiredLevel` = 1,
    `dmg_min1` = 2, `dmg_max1` = 4, `delay` = 2000 WHERE `entry` = 2901;
UPDATE `item_template` SET `Quality` = 1, `ItemLevel` = 1, `RequiredLevel` = 1,
    `dmg_min1` = 1, `dmg_max1` = 2, `delay` = 2000 WHERE `entry` = 5956;
UPDATE `item_template` SET `Quality` = 1, `ItemLevel` = 4, `RequiredLevel` = 1,
    `dmg_min1` = 1, `dmg_max1` = 3, `delay` = 1600 WHERE `entry` = 7005;
