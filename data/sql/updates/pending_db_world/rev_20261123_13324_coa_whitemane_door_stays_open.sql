-- High Inquisitor Whitemane: her respawn closes the High Inquisitor's Door (guid 11877) only while the
-- Mograine and Whitemane event (instance data 1) is not FAIL (2). A failed fight after Mograine died leaves
-- the door open, since its only opener is Mograine's 1% action list.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 11 AND `SourceEntry` = 3977 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 11, 3977, 0, 0, 13, 1, 1, 2, 0, 1, 0, 0, '', 'High Inquisitor Whitemane - On Respawn closes her door only while the Mograine and Whitemane event is not FAIL');
