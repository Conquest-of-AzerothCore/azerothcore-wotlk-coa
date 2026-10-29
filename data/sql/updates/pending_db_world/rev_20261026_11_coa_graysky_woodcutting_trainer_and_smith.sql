-- Graysky, Pale Reach.
-- Torvald Palin (164492), "Woodcutting Trainer", had no trainer flag and no trainer: he now teaches the Woodcutting
-- ranks (the SKILL 118 rows of skill 732 in SkillLineAbility.dbc).
DELETE FROM `trainer` WHERE `Id` = 900033;
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`) VALUES
(900033, 2, 0, 'Need help with your woodcutting?');
DELETE FROM `trainer_spell` WHERE `TrainerId` = 900033;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`) VALUES
(900033, 13977859,   100,   0,   0,        0, 0, 0,  5),
(900033, 13977882,   500, 732,  50, 13977859, 0, 0, 10),
(900033, 13977883, 10000, 732, 125, 13977882, 0, 0, 20),
(900033, 13977884, 50000, 732, 200, 13977883, 0, 0, 35);
DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 164492;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (164492, 900033);
UPDATE `creature_template` SET `npcflag` = 80 WHERE `entry` = 164492;

-- Brokkar Dun (164176) keeps his gossip and now sells blacksmithing supplies and repairs.
UPDATE `creature_template` SET `npcflag` = 4225 WHERE `entry` = 164176;
DELETE FROM `npc_vendor` WHERE `entry` = 164176;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(164176, 0,  2901, 0, 0, 0),
(164176, 1,  5956, 0, 0, 0),
(164176, 2,  2880, 0, 0, 0),
(164176, 3,  3466, 0, 0, 0),
(164176, 4,  3857, 0, 0, 0),
(164176, 5, 18567, 0, 0, 0);

-- Alina Mouren (164634): one yard higher, out of the floor.
UPDATE `creature` SET `position_z` = 312.162 WHERE `guid` = 9920749 AND `id` = 164634;
