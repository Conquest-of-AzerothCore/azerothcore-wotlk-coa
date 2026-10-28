-- Items the user added to two Pale Reach vendors: three fishing recipes for Edrin Salmear and two spices for Lamar Ryback.
DELETE FROM `npc_vendor` WHERE (`entry` = 164022 AND `item` IN (6326, 6369, 17062)) OR (`entry` = 164943 AND `item` IN (2692, 3713));
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(164022, 15, 6326, 0, 0, 0, 0),
(164022, 16, 6369, 0, 0, 0, 0),
(164022, 17, 17062, 0, 0, 0, 0),
(164943, 5, 2692, 0, 0, 0, 0),
(164943, 6, 3713, 0, 0, 0, 0);
