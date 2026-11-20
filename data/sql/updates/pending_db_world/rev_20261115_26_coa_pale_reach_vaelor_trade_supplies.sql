-- Vaelor <Trade Supplies> (164283) in Namarien Sanctuary had no vendor flag or stock (#11845). The realm list is
-- unknown; he sells the same common trade supplies as Tholgrim Copperweigh, and keeps his quest.
UPDATE `creature_template` SET `npcflag` = 130 WHERE `entry` = 164283;

DELETE FROM `npc_vendor` WHERE `entry` = 164283;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(164283, 0, 2320, 0, 0, 0, 0),
(164283, 0, 2321, 0, 0, 0, 0),
(164283, 0, 2324, 0, 0, 0, 0),
(164283, 0, 2678, 0, 0, 0, 0),
(164283, 0, 2880, 0, 0, 0, 0),
(164283, 0, 2901, 0, 0, 0, 0),
(164283, 0, 3371, 0, 0, 0, 0),
(164283, 0, 3372, 0, 0, 0, 0),
(164283, 0, 3466, 0, 0, 0, 0),
(164283, 0, 3857, 0, 0, 0, 0),
(164283, 0, 4289, 0, 0, 0, 0),
(164283, 0, 4291, 0, 0, 0, 0),
(164283, 0, 4399, 0, 0, 0, 0),
(164283, 0, 4400, 0, 0, 0, 0),
(164283, 0, 5956, 0, 0, 0, 0),
(164283, 0, 6217, 0, 0, 0, 0),
(164283, 0, 6530, 0, 0, 0, 0),
(164283, 0, 6532, 0, 0, 0, 0),
(164283, 0, 39354, 0, 0, 0, 0),
(164283, 1, 2692, 0, 0, 0, 0),
(164283, 2, 3713, 0, 0, 0, 0);
