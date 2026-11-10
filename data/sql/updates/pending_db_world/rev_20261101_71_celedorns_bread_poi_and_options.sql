-- Celedorn's Bread (quest 175105), #10294 follow-up: the four quest_poi circles added in
-- rev_20261014_10_pale_reach_quest_markers.sql all point at ObjectiveIndex 0, so the client hides id1-3 once
-- Aldaria's objective completes. Point each circle at the inhabitant it actually marks: id0 Findan (index 2),
-- id1 Remmos (index 3), id3 Sylana (index 1); id2 Aldaria already matches index 0.
DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN ((175105, 0), (175105, 1), (175105, 3));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`,
    `Flags`) VALUES
(175105, 0, 2, 0, 2062, 0, 0, 1),
(175105, 1, 3, 0, 2062, 0, 0, 1),
(175105, 3, 1, 0, 2062, 0, 0, 1);

-- Each bread gossip option (1200398 Aldaria, 1200399 Sylana, 1200400 Findan, 1200401 Remmos) stayed clickable
-- after that inhabitant already had their loaf, since the existing conditions only check the quest is taken
-- and incomplete. Add each inhabitant's own objective counter so the option drops once that slot is credited.
DELETE FROM `conditions` WHERE (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
    `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`) IN
    ((15,1200398,0,0,0,48,0,175105,0,0),(15,1200399,0,0,0,48,0,175105,1,0),(15,1200400,0,0,0,48,0,175105,2,0),
    (15,1200401,0,0,0,48,0,175105,3,0));
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 1200398, 0, 0, 0, 48, 0, 175105, 0, 0, 0, 0, 0, '', 'Aldaria bread option: not yet credited'),
(15, 1200399, 0, 0, 0, 48, 0, 175105, 1, 0, 0, 0, 0, '', 'Sylana bread option: not yet credited'),
(15, 1200400, 0, 0, 0, 48, 0, 175105, 2, 0, 0, 0, 0, '', 'Findan bread option: not yet credited'),
(15, 1200401, 0, 0, 0, 48, 0, 175105, 3, 0, 0, 0, 0, '', 'Remmos bread option: not yet credited');
