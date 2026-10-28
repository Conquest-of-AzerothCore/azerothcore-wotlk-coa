-- CoA: 254053 'A Humble Duty' had no objective markers - only its turn-in pin.
--
-- The quest is finished by using six of the seventeen Gravestones 254677 and the single Invincible's
-- Gravestone 254678 in the Chapel of Final Grace graveyard, Tirisfal Glades, so a player carrying the
-- open quest saw nothing on the world map for either objective. rev_20260926_14 gave the quest its
-- turn-in marker (quest_poi id 0, ObjectiveIndex -1, at 1910 -153).
--
-- Both objectives are gameobject objectives (RequiredNpcOrGo1 -254677 x6, RequiredNpcOrGo2 -254678 x1),
-- so they take ObjectiveIndex 0 and 1 (NPC/object objectives are 0-3, item objectives 4-7; the convention
-- rev_20261001_08 uses for the Cain chain and stock 376 carries). The points are DERIVED: the area of the
-- 17 Gravestones is the outline of their spawns, the same way 1660029 outlines its bear, ghoul and zombie
-- spawns and 1660018 its Uneasy Citizens, so the client draws the quest area over the graveyard. The
-- single Invincible's Gravestone is one point.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (254053, 1), (254053, 2));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(254053, 1, 0, 0, 20, 0, 0, 1),
(254053, 2, 1, 0, 20, 0, 0, 1);
DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (254053, 1), (254053, 2));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(254053, 1, 0, 1909, -136),
(254053, 1, 1, 1915, -140),
(254053, 1, 2, 1925, -145),
(254053, 1, 3, 1929, -147),
(254053, 1, 4, 1936, -133),
(254053, 1, 5, 1931, -130),
(254053, 1, 6, 1916, -122),
(254053, 1, 7, 1911, -131),
(254053, 1, 8, 1910, -134),
(254053, 2, 0, 2043, -520);
