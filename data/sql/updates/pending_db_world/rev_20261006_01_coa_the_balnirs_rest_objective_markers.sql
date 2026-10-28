-- CoA: 254054 'The Balnirs' Rest' had no objective markers - only its turn-in pin.
--
-- The quest is finished by killing Jorum Balnir 254936, Vara Balnir 254937 and Jarim Balnir 254938 at
-- the graves north of the Chapel of Final Grace, so a player carrying the open quest saw nothing on the
-- world map for any of the three. rev_20260926_14 gave the quest its turn-in marker (quest_poi id 0,
-- ObjectiveIndex -1, at 1911 -153).
--
-- All three objectives are creature objectives (RequiredNpcOrGo1-3 254936-254938, one kill each), so they
-- take ObjectiveIndex 0, 1 and 2 (NPC/object objectives are 0-3, item objectives 4-7; the convention
-- rev_20261001_08 uses for the Cain chain and stock 376 carries). Each of the three is a single spawn
-- (9010601-9010603), so each area is that one point, the same single-point style rev_20261001_08 uses for
-- the Cain family members.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (254054, 1), (254054, 2), (254054, 3));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(254054, 1, 0, 0, 20, 0, 0, 1),
(254054, 2, 1, 0, 20, 0, 0, 1),
(254054, 3, 2, 0, 20, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (254054, 1), (254054, 2), (254054, 3));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(254054, 1, 0, 2043, -460),
(254054, 2, 0, 1966, -464),
(254054, 3, 0, 1999, -348);
