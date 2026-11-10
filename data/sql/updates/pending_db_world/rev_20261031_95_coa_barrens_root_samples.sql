-- Quest 866 "Root Samples" (Mebok Mizzyrix, Ratchet) needs 8x item 5056 Root Sample from herbs in The Barrens. The
-- Barrens herb nodes spawn as the ordinary variants (1617-1622) whose loot tables (1414-1419) never contained the
-- item, while the quest-loot variants that do carry it (3724-3730) have no Barrens spawns. Add it as a quest drop to
-- the six ordinary tables and require The Barrens zone (17) so every other zone's herbs stay unchanged.
-- QuestRequired=1 limits the drop to players whose quest still needs item 5056 (only quest 866 requires it).
DELETE FROM `gameobject_loot_template` WHERE (`Entry`, `Item`) IN ((1414, 5056), (1415, 5056), (1416, 5056),
    (1417, 5056), (1418, 5056), (1419, 5056));
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(1414, 5056, 0, 100, 1, 1, 0, 1, 1, 'Silverleaf - Root Sample'),
(1415, 5056, 0, 100, 1, 1, 0, 1, 1, 'Peacebloom - Root Sample'),
(1416, 5056, 0, 100, 1, 1, 0, 1, 1, 'Earthroot - Root Sample'),
(1417, 5056, 0, 100, 1, 1, 0, 1, 1, 'Mageroyal - Root Sample'),
(1418, 5056, 0, 100, 1, 1, 0, 1, 1, 'Briarthorn - Root Sample'),
(1419, 5056, 0, 100, 1, 1, 0, 1, 1, 'Bruiseweed - Root Sample');

-- Loot conditions are checked against the looting player. SourceTypeOrReferenceId 4 is the gameobject loot template
-- source, ConditionTypeOrReference 4 is the zone id condition, ConditionValue1 17 is The Barrens (AreaTable 17, a
-- top level zone with parent area 0). SourceGroup is the loot entry and SourceEntry the item the condition gates.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 4 AND `SourceGroup` IN (1414, 1415, 1416, 1417, 1418,
    1419) AND `SourceEntry` = 5056 AND `ConditionTypeOrReference` = 4;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(4, 1414, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens'),
(4, 1415, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens'),
(4, 1416, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens'),
(4, 1417, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens'),
(4, 1418, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens'),
(4, 1419, 5056, 0, 0, 4, 0, 17, 0, 0, 0, 0, 0, '', 'Root Sample - only drops in The Barrens');
