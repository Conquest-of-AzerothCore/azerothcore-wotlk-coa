-- CoA: 1660018 'Those Who Fell' had no objective marker - only its turn-in pin.
--
-- The quest is finished by casting 256708 'Distilling Spiritual Unrest' (the provided stone 559158)
-- on the Uneasy Citizens (161791) in the Valley of Trials. rev_20260926_35 gave the quest its
-- turn-in marker (quest_poi id 0, ObjectiveIndex -1, at Swa'li 161733, -372 -4123), so a player
-- carrying the open quest saw nothing on the world map for the objective itself.
--
-- The objective is RequiredItemId1 559155 'Spiritual Unrest' x5 - item slot 1, so ObjectiveIndex 4
-- (NPC/object objectives are 0-3, item objectives 4-7; the convention rev_20261001_08 uses for the
-- Cain chain and stock 376/639 carries). The points are the outline of the 15 Uneasy Citizen
-- spawns (creature 161791, map 1), the same way 1660029 outlines its three spawn areas, so the
-- client draws the quest area over the camp in the Valley of Trials.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE `QuestID` = 1660018 AND `id` = 1;

INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES (1660018, 1, 4, 1, 4, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` = 1660018 AND `Idx1` = 1;

INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(1660018, 1, 0, -643, -4226),
(1660018, 1, 1, -626, -4262),
(1660018, 1, 2, -621, -4268),
(1660018, 1, 3, -572, -4257),
(1660018, 1, 4, -568, -4243),
(1660018, 1, 5, -559, -4190),
(1660018, 1, 6, -586, -4102),
(1660018, 1, 7, -599, -4112),
(1660018, 1, 8, -641, -4210);
