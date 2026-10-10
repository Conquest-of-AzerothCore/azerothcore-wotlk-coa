-- Ethereal Bazaar, Convenience: Thermal Anvil and Portable Sawmill at 500 Bazaar Tokens each (#4822, live list in #4751).
DELETE FROM `npc_vendor` WHERE `entry` = 900008 AND `item` IN (1777028, 1777064);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(900008, 27, 1777028, 0, 0, 3016),
(900008, 28, 1777064, 0, 0, 3016);
