-- Stratholme: an Ash'ari Crystal reacts only after its ziggurat's boss died, so the lone courtyard
-- Thuzadin Acolyte killed before Baroness Anastari no longer destroys her crystal and leaves the gates shut (#10739)
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` IN (-53955, -53968, -53963) AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, -53955, 0, 0, 13, 1, 1, 1, 0, 0, 0, 0, '', 'Ash''ari Crystal (Baroness Anastari) - react only after the ziggurat boss died'),
(22, 1, -53968, 0, 0, 13, 1, 2, 1, 0, 0, 0, 0, '', 'Ash''ari Crystal (Nerub''enkan) - react only after the ziggurat boss died'),
(22, 1, -53963, 0, 0, 13, 1, 3, 1, 0, 0, 0, 0, '', 'Ash''ari Crystal (Maleki the Pallid) - react only after the ziggurat boss died');
