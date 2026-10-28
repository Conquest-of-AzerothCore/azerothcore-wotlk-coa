-- The Unimbued Mystic Scroll moves from the Guardian of Time's General Goods, open on every realm, to his Altars
-- store, which opens only where Mystic Enchants are played (free-pick and Warcraft Reborn realms, not Wildcard).
DELETE FROM `npc_vendor` WHERE `entry` IN (9781000, 9781012) AND `item` = 992720;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(9781012, 17, 992720, 0, 0, 0);
