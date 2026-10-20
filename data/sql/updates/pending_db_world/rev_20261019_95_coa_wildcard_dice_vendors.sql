-- Dice of Destiny (777992) is the Wildcard reroll item, but rev_20260929_91 put it on six general goods vendors on every
-- realm. It now sells only while the internal Wildcard season event 194 runs, which worldserver starts only on a realm
-- that plays Wildcard. Each vendor has one spawn: Brother Danil, Adlin Pridedrift, Joshua Kien, Kawnie Softbreeze,
-- Duokna and Lyrai.
DELETE FROM `npc_vendor` WHERE `item` = 777992 AND `entry` IN (152, 829, 2115, 3072, 3158, 3587);

DELETE FROM `game_event_npc_vendor` WHERE `eventEntry` = 194 AND `item` = 777992;
INSERT INTO `game_event_npc_vendor` (`eventEntry`, `guid`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(194, 79950, 1, 777992, 0, 0, 0),
(194, 349, 1, 777992, 0, 0, 0),
(194, 28461, 1, 777992, 0, 0, 0),
(194, 24667, 1, 777992, 0, 0, 0),
(194, 7282, 1, 777992, 0, 0, 0),
(194, 46171, 1, 777992, 0, 0, 0);
