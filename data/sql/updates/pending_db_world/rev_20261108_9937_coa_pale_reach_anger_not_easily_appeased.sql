-- Furious Gilded Treants (164301) cannot be killed: on the live realm (video i5vATMYui0I 09:25-09:36) the treant's
-- health holds at a sliver while it keeps taking hits, until the Magic Crystal's Golden Tranquility pacifies it.
-- The 1% floor is set only against attackers on the quest; anyone else can kill it.
-- A pacified treant calms down: its enrage fades, it stops fighting and turns friendly, then fades away after 4 s.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164301 AND `source_type` = 0 AND `id` IN (0, 1, 2, 3, 4, 5, 102, 103, 104);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164301, 0, 0, 1, 8, 0, 100, 0, 365042, 0, 3000, 3000, 0, 0, 33, 445304, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - On Spellhit Golden Tranquility - Quest Credit'),
(164301, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 365144, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Remove Enrage'),
(164301, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Stop Combat'),
(164301, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 35, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Set Faction Friendly'),
(164301, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Set Passive'),
(164301, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 4000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - Linked - Fade Away In 4 s'),
(164301, 0, 102, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - On Reset - Clear Invincibility'),
(164301, 0, 103, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 42, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - On Aggro - Set Invincibility Hp 1% (quest)'),
(164301, 0, 104, 0, 32, 0, 100, 0, 1, 1000000000, 0, 0, 0, 0, 42, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Furious Gilded Treant - On Damaged - Set Invincibility Hp 1% (quest)');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` IN (104, 105) AND `SourceEntry` = 164301 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 104, 164301, 0, 0, 47, 0, 175096, 8, 0, 0, 0, 0, '', 'Furious Gilded Treant: unkillable only against a player on Anger Not Easily Appeased (aggro)'),
(22, 105, 164301, 0, 0, 47, 0, 175096, 8, 0, 0, 0, 0, '', 'Furious Gilded Treant: unkillable only against a player on Anger Not Easily Appeased (damage)');
