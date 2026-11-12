-- Blood and Duty (175049): War Medic Soryn's progress and turn-in texts were empty; transcribed from the live realm
-- (video HIbr82QgX6w 01:27:36-01:28:01).
DELETE FROM `quest_request_items` WHERE `ID` = 175049;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175049, 0, 0, 'Have you tended to them? Any help is vital right now.', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` = 175049;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175049, 0, 0, 0, 0, 0, 0, 0, 0, '<Soryn''s gaze betrays a sense of shame.>$B$BYou''ve done well. Forgive me for earlier, for speaking to you so curtly. The war, the trolls, all this death... I am overwhelmed. And I often take it out on the wrong person.$B$BAccept this as my thanks; at the very least, it might make me feel a little less ashamed.', 0);

-- Wounded Graysky Soldiers (164055, 164056) gave credit the moment the 8 s First Aid channel (365018) began, and gave
-- it again on every recast. Credit now comes when the channel has run its course (the soldier still carries the
-- bandage aura 7.5 s in), the soldier is healed to full and cannot be tended again until it is wounded again a minute
-- later.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164055, 164056) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164055, 0, 0, 1, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Respawn - Set Phase 1 (wounded)'),
(164055, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Health 5%'),
(164055, 0, 2, 4, 8, 1, 100, 0, 365018, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Spellhit First Aid (wounded) - Store Bandager'),
(164055, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 2, 7500, 7500, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Check Bandage In 7.5 s'),
(164055, 0, 5, 6, 59, 1, 100, 0, 2, 0, 0, 0, 0, 0, 33, 164055, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Bandage Check (still bandaged) - Quest Credit Wounded soldiers tended'),
(164055, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Health 100%'),
(164055, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Say Line 0'),
(164055, 0, 8, 9, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Phase 2 (tended)'),
(164055, 0, 9, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 3, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Wounded Again In 60 s'),
(164055, 0, 10, 11, 59, 0, 100, 0, 3, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Timed Event 3 - Set Health 5%'),
(164055, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Phase 1 (wounded)'),
(164056, 0, 0, 1, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Respawn - Set Phase 1 (wounded)'),
(164056, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Health 5%'),
(164056, 0, 2, 4, 8, 1, 100, 0, 365018, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Spellhit First Aid (wounded) - Store Bandager'),
(164056, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 2, 7500, 7500, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Check Bandage In 7.5 s'),
(164056, 0, 5, 6, 59, 1, 100, 0, 2, 0, 0, 0, 0, 0, 33, 164055, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Bandage Check (still bandaged) - Quest Credit Wounded soldiers tended'),
(164056, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Health 100%'),
(164056, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Say Line 0'),
(164056, 0, 8, 9, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Phase 2 (tended)'),
(164056, 0, 9, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 3, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Wounded Again In 60 s'),
(164056, 0, 10, 11, 59, 0, 100, 0, 3, 0, 0, 0, 0, 0, 142, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - On Timed Event 3 - Set Health 5%'),
(164056, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wounded Graysky Soldier - Linked - Set Phase 1 (wounded)');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 6 AND `SourceEntry` IN (164055, 164056) AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 6, 164055, 0, 0, 1, 1, 365018, 0, 0, 0, 0, 0, '', 'Wounded Graysky Soldier: credit only while the First Aid channel is still on it'),
(22, 6, 164056, 0, 0, 1, 1, 365018, 0, 0, 0, 0, 0, '', 'Wounded Graysky Soldier: credit only while the First Aid channel is still on it');
