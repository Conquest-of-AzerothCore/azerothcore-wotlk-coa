DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 352 AND `SourceId` = 0 AND `SourceGroup` = 4;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 4, 352, 0, 0, 47, 0, 100466, 8, 0, 0, 0, 0, '', 'Dungar Longdrink - Westfall taxi and credit only while ''Path to Ascension: Westfall'' is in progress');
