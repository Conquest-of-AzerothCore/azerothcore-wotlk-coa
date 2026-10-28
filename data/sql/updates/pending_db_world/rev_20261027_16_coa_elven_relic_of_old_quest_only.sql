-- Auction the Past (1660063): the seven Elven Relic of Old objects (2300551, 2300553-2300558) had no template addon,
-- so they lacked the interact-condition flag and stayed clickable after the player held all 7 relics. With the flag,
-- like the zone's Prairie Sap (2300552), the client lets a player open one only while the quest still needs a relic.
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (2300551, 2300553, 2300554, 2300555, 2300556, 2300557, 2300558);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(2300551, 0, 4, 0, 0, 0, 0, 0, 0),
(2300553, 0, 4, 0, 0, 0, 0, 0, 0),
(2300554, 0, 4, 0, 0, 0, 0, 0, 0),
(2300555, 0, 4, 0, 0, 0, 0, 0, 0),
(2300556, 0, 4, 0, 0, 0, 0, 0, 0),
(2300557, 0, 4, 0, 0, 0, 0, 0, 0),
(2300558, 0, 4, 0, 0, 0, 0, 0, 0);
