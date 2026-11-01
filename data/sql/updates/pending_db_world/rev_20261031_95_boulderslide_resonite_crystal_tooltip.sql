-- Boulderslide Ravine (6421): the Gogger Rock Keeper, Geomancer and Stonepounder drop Resonite Crystal from their own
-- loot, but their creature query listed no quest item, so the client never marked them as quest drops
DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (11915, 11917, 11918) AND `Idx` = 0;
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`, `VerifiedBuild`) VALUES
(11915, 0, 16581, 0),
(11917, 0, 16581, 0),
(11918, 0, 16581, 0);
