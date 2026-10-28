-- The Dignity of the Dead: show one Weed and one Snow Pile per spot, the version matching the player's quest
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 1 AND `SourceEntry` IN (2300710, 2300711, 2300712, 2300713);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(30, 1, 2300710, 0, 0, 9, 0, 175171, 0, 0, 1, 0, 0, '', 'Weed (175170, Holy Light) - hidden while The Dignity of the Dead (175171, Pantheon) is taken'),
(30, 1, 2300711, 0, 0, 9, 0, 175171, 0, 0, 1, 0, 0, '', 'Snow Pile (175170, Holy Light) - hidden while The Dignity of the Dead (175171, Pantheon) is taken'),
(30, 1, 2300712, 0, 0, 9, 0, 175171, 0, 0, 0, 0, 0, '', 'Weed (175171, Pantheon) - visible only while The Dignity of the Dead (175171, Pantheon) is taken'),
(30, 1, 2300713, 0, 0, 9, 0, 175171, 0, 0, 0, 0, 0, '', 'Snow Pile (175171, Pantheon) - visible only while The Dignity of the Dead (175171, Pantheon) is taken');
