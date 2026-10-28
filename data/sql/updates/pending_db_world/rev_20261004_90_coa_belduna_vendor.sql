-- Belduna keeps the food bowls of Three Totem Village; CoA names her and nothing more. She sells food and drink,
-- the meats of Kaga Mistrunner 3025 and the drinks of Moodan Sungrain 3883, to whoever the village takes for one
-- of its own: her Grimtotem faction serves only players in the Grimtotem Disguise. Heading her list, as a treat for
-- those who get that far, are two foods that leave the eater Well Fed: Roasted Kodo Meat 5474 and Strider Stew 5477.
UPDATE `creature_template` SET `subname` = 'Food & Drink', `npcflag` = 640 WHERE `entry` = 161838;

DELETE FROM `npc_vendor` WHERE `entry` = 161838;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(161838, 0, 5474, 0, 0, 0),
(161838, 1, 5477, 0, 0, 0),
(161838, 2, 117, 0, 0, 0),
(161838, 3, 159, 0, 0, 0),
(161838, 4, 2287, 0, 0, 0),
(161838, 5, 1179, 0, 0, 0),
(161838, 6, 3770, 0, 0, 0),
(161838, 7, 772068, 0, 0, 0),
(161838, 8, 1205, 0, 0, 0),
(161838, 9, 3771, 0, 0, 0),
(161838, 10, 772071, 0, 0, 0),
(161838, 11, 1708, 0, 0, 0),
(161838, 12, 4599, 0, 0, 0),
(161838, 13, 1645, 0, 0, 0),
(161838, 14, 8952, 0, 0, 0),
(161838, 15, 772061, 0, 0, 0),
(161838, 16, 772062, 0, 0, 0),
(161838, 17, 8766, 0, 0, 0),
(161838, 18, 27854, 0, 0, 0),
(161838, 19, 33454, 0, 0, 0),
(161838, 20, 35953, 0, 0, 0);
