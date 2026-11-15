-- Dire Maul East: Ironbark the Redeemed (14241) offers to open the door to Alzzin the Wildshaper only once Zevrim
-- Thornhoof and Hydrospawn are dead (instance data 0 = 1, set by instance_dire_maul). He is hidden before that, but a
-- game master sees hidden creatures, so the option itself now checks the progress too (#11379).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 5602 AND `SourceEntry` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 5602, 0, 0, 0, 13, 1, 0, 1, 0, 0, 0, 0, '', 'Ironbark the Redeemed - offer to open the door only once Zevrim Thornhoof and Hydrospawn are dead');
