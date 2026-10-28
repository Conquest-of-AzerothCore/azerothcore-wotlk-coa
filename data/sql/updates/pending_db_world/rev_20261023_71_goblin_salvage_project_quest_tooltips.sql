-- CoA Goblin Salvage Project: the creatures and the fuel canister that drop its quest items list them in the
-- creature and gameobject query, so their tooltips show the quest objective.
DELETE FROM `creature_questitem` WHERE `ItemId` IN (9707002, 9707003, 9707005, 9707007);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(921, 0, 9707002, 0),
(921, 1, 9707007, 0),
(1094, 0, 9707002, 0),
(1094, 1, 9707007, 0),
(1095, 0, 9707002, 0),
(1095, 1, 9707007, 0),
(1096, 1, 9707002, 0),
(1096, 2, 9707007, 0),
(1097, 0, 9707002, 0),
(1097, 1, 9707007, 0),
(4260, 0, 9707003, 0),
(9312003, 0, 9707005, 0);

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` = 9312002;
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(9312002, 0, 9707004, 0);
