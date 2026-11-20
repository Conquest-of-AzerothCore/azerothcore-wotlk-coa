-- Ellerdin <Fruit Seller> (164411) had no vendor flag or stock. The realm list is unknown; he sells the common
-- fruit of the other fruit sellers (Homer Stonefield 894), which matches the apples and bananas on his table.
UPDATE `creature_template` SET `npcflag` = 128 WHERE `entry` = 164411;

DELETE FROM `npc_vendor` WHERE `entry` = 164411;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(164411, 0, 4536, 0, 0, 0, 0),
(164411, 0, 4537, 0, 0, 0, 0),
(164411, 0, 4538, 0, 0, 0, 0),
(164411, 0, 4539, 0, 0, 0, 0),
(164411, 0, 4602, 0, 0, 0, 0),
(164411, 0, 8953, 0, 0, 0, 0);
