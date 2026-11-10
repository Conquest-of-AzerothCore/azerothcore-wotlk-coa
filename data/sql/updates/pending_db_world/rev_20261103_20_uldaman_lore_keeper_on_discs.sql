-- Uldaman: The Discs of Norgannon summoned the Lore Keeper of Norgannon (7172) only on the first acceptance of The
-- Platinum Discs (2278) in an instance (event flags 257: no repeat, kept over resets), so a group member accepting it
-- later, or a player who already carried the quest into a new instance, found no Lore Keeper to talk to (#5409).
-- Any acceptance or use of the discs by a player with the quest now summons him when he is not already there.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 131474 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(131474, 1, 0, 0, 19, 0, 100, 0, 2278, 0, 0, 0, 0, 0, 12, 7172, 8, 0, 0, 0, 0, 8, 0, 0, 0, 0, 148.65, 310.073, -52.19, 5.124, 'The Discs of Norgannon - On Quest Accept - Summon Lore Keeper of Norgannon'),
(131474, 1, 1, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 7172, 8, 0, 0, 0, 0, 8, 0, 0, 0, 0, 148.65, 310.073, -52.19, 5.124, 'The Discs of Norgannon - On Gossip Hello - Summon Lore Keeper of Norgannon');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 131474 AND `SourceId` = 1 AND `SourceGroup` IN (1, 2);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 131474, 1, 0, 29, 1, 7172, 50, 0, 1, 0, 0, '', 'The Discs of Norgannon - summon the Lore Keeper only when he is not already there'),
(22, 2, 131474, 1, 0, 9, 0, 2278, 0, 0, 0, 0, 0, '', 'The Discs of Norgannon - on use, only for a player on The Platinum Discs'),
(22, 2, 131474, 1, 0, 29, 1, 7172, 50, 0, 1, 0, 0, '', 'The Discs of Norgannon - on use, only when the Lore Keeper is not already there');
