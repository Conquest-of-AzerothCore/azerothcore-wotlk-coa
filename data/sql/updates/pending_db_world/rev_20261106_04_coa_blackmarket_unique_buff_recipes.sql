DELETE FROM `npc_vendor` WHERE (`entry`, `item`) IN ((970029, 967366), (970030, 967363), (970040, 967405));
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(970029, 1, 967366, 0, 0, 0),
(970030, 1, 967363, 0, 0, 0),
(970040, 1, 967405, 0, 0, 0);
