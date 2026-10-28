-- Mythical Discharge (823746), Mythical Missiles (823747), Mythical Volley (823697), Mythical Throw (823699),
-- Mythical Corruption (823751) and Mythical Rot (823752) deal damage to enemies in combat per their tier bonus
-- tooltips (823730, 823710, 823716, 823726, 823714, 823722) (issue 7238).
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_tier_set_mythical_volley';
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
    AND `SourceEntry` IN (823746, 823747, 823697, 823699, 823751, 823752) AND `ConditionTypeOrReference` = 106;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
`ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
`NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(13, 1, 823746, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Discharge - target must be in combat'),
(13, 1, 823747, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Missiles - target must be in combat'),
(13, 1, 823697, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Volley - target must be in combat'),
(13, 1, 823699, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Throw - target must be in combat'),
(13, 1, 823751, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Corruption - target must be in combat'),
(13, 1, 823752, 0, 0, 106, 0, 0, 0, 0, 0, 0, 0, '', 'Mythical Rot - target must be in combat');
