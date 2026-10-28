-- Pelts drop only while the hunt is active. QuestRequired cannot express that once
-- the quest no longer lists them as required items, so the loot row is a normal
-- 100% drop gated by a loot condition instead.
UPDATE `creature_loot_template` SET `QuestRequired` = 0
WHERE `Entry` IN (9916212, 9916213, 9916214);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 1 AND `SourceGroup` IN (9916212, 9916213, 9916214)
  AND `SourceEntry` IN (1009302, 1009303, 1009304);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(1, 9916212, 1009302, 0, 0, 9, 0, 17839, 0, 0, 0, 0, 0, '', 'Stormfang Pelt only while the hunt is taken (Alliance)'),
(1, 9916212, 1009302, 0, 1, 9, 0, 17844, 0, 0, 0, 0, 0, '', 'Stormfang Pelt only while the hunt is taken (Horde)'),
(1, 9916213, 1009303, 0, 0, 9, 0, 17839, 0, 0, 0, 0, 0, '', 'Scarred Owlcat Pelt only while the hunt is taken (Alliance)'),
(1, 9916213, 1009303, 0, 1, 9, 0, 17844, 0, 0, 0, 0, 0, '', 'Scarred Owlcat Pelt only while the hunt is taken (Horde)'),
(1, 9916214, 1009304, 0, 0, 9, 0, 17839, 0, 0, 0, 0, 0, '', 'Tide-Warped Hide only while the hunt is taken (Alliance)'),
(1, 9916214, 1009304, 0, 1, 9, 0, 17844, 0, 0, 0, 0, 0, '', 'Tide-Warped Hide only while the hunt is taken (Horde)');
