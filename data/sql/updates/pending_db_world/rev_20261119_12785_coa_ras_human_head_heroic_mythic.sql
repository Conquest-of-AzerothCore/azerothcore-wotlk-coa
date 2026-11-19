-- Human Head of Ras Frostwhisper 13626 (#12785): The Lich, Ras Frostwhisper 5466 needs the head. His Normal loot 10508
-- pays it at 100% to players on the quest once the Soulbound Keepsake has turned him human (Scholomance instance data
-- 2 = 1), but the Heroic and Mythic lists 110508 and 210508 that rev_20261009_70 rewrote hold no quest item, so a
-- Heroic or Mythic kill never drops it. Mirror the Normal row and its human-form condition.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (110508, 210508) AND `Item` = 13626;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(110508, 13626, 0, 100, 1, 1, 0, 1, 1, 'Ras Frostwhisper (Heroic) - Human Head of Ras Frostwhisper'),
(210508, 13626, 0, 100, 1, 1, 0, 1, 1, 'Ras Frostwhisper (Mythic) - Human Head of Ras Frostwhisper');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 1 AND `SourceGroup` IN (110508, 210508) AND `SourceEntry` = 13626;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(1, 110508, 13626, 0, 0, 13, 0, 2, 1, 0, 0, 0, 0, '',
    'Instance - Get Data - Can only loot ''Human Head of Ras Frostwhisper'' (Heroic) if Ras is in human form'),
(1, 210508, 13626, 0, 0, 13, 0, 2, 1, 0, 0, 0, 0, '',
    'Instance - Get Data - Can only loot ''Human Head of Ras Frostwhisper'' (Mythic) if Ras is in human form');
