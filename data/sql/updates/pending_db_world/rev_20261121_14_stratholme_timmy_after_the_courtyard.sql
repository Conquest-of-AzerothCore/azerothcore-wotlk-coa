DELETE FROM `smart_scripts` WHERE `entryorguid` = 10808 AND `source_type` = 0 AND `id` IN (3, 4, 5, 6);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (10808, 0, 3, 4, 60, 0, 100, 0, 1000, 1000, 1000, 1000, 0, 0, 47, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Timmy the Cruel - On Update - Set Invisible while Crimson guards of King''s Square live'),
    (10808, 0, 4, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 2, 35, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Timmy the Cruel - On Update - Set Faction Friendly'),
    (10808, 0, 5, 6, 60, 0, 100, 768, 5000, 5000, 5000, 5000, 0, 0, 47, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Timmy the Cruel - On Update - Set Visible once the Crimson guards of King''s Square are dead'),
    (10808, 0, 6, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 2, 21, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Timmy the Cruel - On Update - Set Faction Hostile');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 10808 AND `SourceId` = 0 AND `SourceGroup` IN (4, 6);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
    (22, 6, 10808, 0, 0, 29, 1, 10418, 75, 0, 1, 0, 0, '', 'Timmy the Cruel appears once no Crimson Guardsman is alive within 75 yd'),
    (22, 6, 10808, 0, 0, 29, 1, 10419, 75, 0, 1, 0, 0, '', 'Timmy the Cruel appears once no Crimson Conjuror is alive within 75 yd'),
    (22, 6, 10808, 0, 0, 29, 1, 10424, 75, 0, 1, 0, 0, '', 'Timmy the Cruel appears once no Crimson Gallant is alive within 75 yd'),
    (22, 4, 10808, 0, 0, 29, 1, 10418, 75, 0, 0, 0, 0, '', 'Timmy the Cruel hides while a Crimson Guardsman is alive within 75 yd'),
    (22, 4, 10808, 0, 1, 29, 1, 10419, 75, 0, 0, 0, 0, '', 'Timmy the Cruel hides while a Crimson Conjuror is alive within 75 yd'),
    (22, 4, 10808, 0, 2, 29, 1, 10424, 75, 0, 0, 0, 0, '', 'Timmy the Cruel hides while a Crimson Gallant is alive within 75 yd');
