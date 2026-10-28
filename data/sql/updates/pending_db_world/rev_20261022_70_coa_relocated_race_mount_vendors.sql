-- Blood Elves start beside the Forsaken and Draenei beside the Night Elves, so Zachariah Post and Lelanai sell them
-- mounts without Exalted reputation, as Velma Warnam and Jartsam already teach them riding
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` | 512
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 4005 AND `SourceTypeOrReferenceId` IN (14, 15);
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` | 1024
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 3185 AND `SourceTypeOrReferenceId` IN (14, 15);
