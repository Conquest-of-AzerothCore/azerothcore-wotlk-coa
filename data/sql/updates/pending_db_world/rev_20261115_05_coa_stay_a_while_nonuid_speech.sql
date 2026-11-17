-- Stay a While (1660080): Gravedigger Nonuid credited the listener from his first option without a word. On the
-- realm (Redthedeer Day 1, YEYz6HGpq4k 4:27:50-4:31:30) he tells it in three parts, each started from his menu, at
-- the pacing recorded there. As in the other Stay a While quests, "heard enough" credits at once; it appears after
-- his first two lines and ends any part still running. After the third part he waits for that choice, so the credit
-- always goes to the player who makes it.
DELETE FROM `creature_text` WHERE `CreatureID` = 162901;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(162901, 0, 0, 'A mountaineer. Died in a frost troll ambush. I''ve heard it said the trolls see us as foreigners, invaders. That these lands were theirs before we drove them back.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 1'),
(162901, 1, 0, 'Since then and to this very day, we keep on killing each other. We call them “savages,” but if you’ll take an old dwarf’s word for it, we’re world-class hypocrites.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 1'),
(162901, 2, 0, 'In near four hundred years I’ve buried many dwarves—more than I can count. Plenty fell to trolls. To troggs. To the cold. To sickness...', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 1'),
(162901, 3, 0, 'But no one has slain more dwarves than dwarves themselves. And by the Titans, we’re good at it; brother against brother, son against father, grudge upon grudge ... The War of the Three Hammers was a terrible thing.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 1'),
(162901, 4, 0, 'I buried warriors from every side. The war killed a few who lusted for the throne, but above all it killed dwarves with nothing to gain; no power, no claim, no crown in reach.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 2'),
(162901, 5, 0, 'The statue that watches over this graveyard is a carving of Modimus Anvilmar, once High King of Ironforge. In his reign he tried to soothe rising tensions among the three great clans: Bronzebeard, Wildhammer, and Dark Iron.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 3'),
(162901, 6, 0, 'He failed. When age took Modimus, a vicious quarrel broke out among the clans. Each wanted the throne for itself. The war that followed took thousands of lives and drove tens of thousands into exile.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 3'),
(162901, 7, 0, 'The Wildhammer withdrew north. The Dark Iron ventured south. And the Bronzebeard kept the mountain, and the glory.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 3'),
(162901, 8, 0, 'In time, the Wildhammer learned to forgive and forget. The Dark Iron, though... they never let go of their ambition.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 3'),
(162901, 9, 0, 'What are trolls and their skirmishes by comparison?', 12, 0, 100, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Stay a While, part 3');

-- 932241 greets with "Did you know the deceased?" (85161) while the quest is open; 932245-932248 are the menus
-- during the speech. The unused <Clear your throat.> step (932242) is removed.
DELETE FROM `gossip_menu` WHERE `MenuID` IN (932241, 932242, 932245, 932246, 932247, 932248);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(932241, 85161),
(932241, 85191),
(932245, 85191),
(932246, 85191),
(932247, 85191),
(932248, 85191);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932241, 932242, 932245, 932246, 932247, 932248);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(932241, 0, 0, '|cFF0000FF(Quest)|rNo. I''ve just arrived in Kharanos.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(932246, 0, 0, '<You decide you''ve heard enough. You have more important things to do.>', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(932247, 0, 0, '|cFF0000FF(Quest)|rYou lived through the War of the Three Hammers?', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(932247, 1, 0, '<You decide you''ve heard enough. You have more important things to do.>', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(932248, 0, 0, '|cFF0000FF(Quest)|rWhat set it off?', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(932248, 1, 0, '<You decide you''ve heard enough. You have more important things to do.>', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `conditions` WHERE (`SourceTypeOrReferenceId` = 14 AND `SourceGroup` = 932241)
    OR (`SourceTypeOrReferenceId` = 15 AND `SourceGroup` IN (932241, 932242, 932245, 932246, 932247, 932248));
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
    `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(14, 932241, 85161, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - asks about the deceased while Stay a While is open'),
(14, 932241, 85191, 0, 0, 47, 0, 1660080, 8, 0, 1, 0, 0, '', 'Gravedigger Nonuid - weary greeting otherwise'),
(15, 932241, 0, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - start the story while Stay a While is open'),
(15, 932246, 0, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - heard enough while Stay a While is open'),
(15, 932247, 0, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - ask about the war while Stay a While is open'),
(15, 932247, 1, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - heard enough while Stay a While is open'),
(15, 932248, 0, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - ask what set it off while Stay a While is open'),
(15, 932248, 1, 0, 0, 47, 0, 1660080, 8, 0, 0, 0, 0, '', 'Gravedigger Nonuid - heard enough while Stay a While is open');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162901 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(162901, 0, 0, 1, 62, 0, 100, 0, 932241, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On just arrived - Close Gossip'),
(162901, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 240, 932245, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Quiet menu while he starts'),
(162901, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290100, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Start part 1'),
(162901, 0, 3, 4, 62, 0, 100, 0, 932246, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On heard enough - Close Gossip'),
(162901, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Quest Credit Listen to Gravedigger Nonuid'),
(162901, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290103, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - End the story and restore the greeting menu'),
(162901, 0, 6, 7, 62, 0, 100, 0, 932247, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On ask about the war - Close Gossip'),
(162901, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 240, 932246, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Offer heard enough'),
(162901, 0, 8, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290101, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Start part 2'),
(162901, 0, 9, 10, 62, 0, 100, 0, 932247, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On heard enough - Close Gossip'),
(162901, 0, 10, 11, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Quest Credit Listen to Gravedigger Nonuid'),
(162901, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290103, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - End the story and restore the greeting menu'),
(162901, 0, 12, 13, 62, 0, 100, 0, 932248, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On ask what set it off - Close Gossip'),
(162901, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 240, 932246, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Offer heard enough'),
(162901, 0, 14, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290102, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Start part 3'),
(162901, 0, 15, 16, 62, 0, 100, 0, 932248, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - On heard enough - Close Gossip'),
(162901, 0, 16, 17, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - Quest Credit Listen to Gravedigger Nonuid'),
(162901, 0, 17, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16290103, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid - Linked - End the story and restore the greeting menu');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (16290100, 16290101, 16290102, 16290103) AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(16290100, 9, 0, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Say 0'),
(16290100, 9, 1, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Say 1'),
(16290100, 9, 2, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 240, 932246, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Offer heard enough'),
(16290100, 9, 3, 0, 0, 0, 100, 0, 8000, 8000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Say 2'),
(16290100, 9, 4, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Say 3'),
(16290100, 9, 5, 0, 0, 0, 100, 0, 8000, 8000, 0, 0, 0, 0, 240, 932247, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Offer the war question'),
(16290100, 9, 6, 0, 0, 0, 100, 0, 60000, 60000, 0, 0, 0, 0, 240, 932241, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 1 - Restore the greeting menu if nobody asks'),
(16290101, 9, 0, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 2 - Say 4'),
(16290101, 9, 1, 0, 0, 0, 100, 0, 9000, 9000, 0, 0, 0, 0, 240, 932248, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 2 - Offer what set it off'),
(16290101, 9, 2, 0, 0, 0, 100, 0, 60000, 60000, 0, 0, 0, 0, 240, 932241, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 2 - Restore the greeting menu if nobody asks'),
(16290102, 9, 0, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Say 5'),
(16290102, 9, 1, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 0, 0, 1, 6, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Say 6'),
(16290102, 9, 2, 0, 0, 0, 100, 0, 11000, 11000, 0, 0, 0, 0, 1, 7, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Say 7'),
(16290102, 9, 3, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 8, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Say 8'),
(16290102, 9, 4, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 9, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Say 9'),
(16290102, 9, 5, 0, 0, 0, 100, 0, 60000, 60000, 0, 0, 0, 0, 240, 932241, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid part 3 - Restore the greeting menu if nobody has heard enough'),
(16290103, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 240, 932241, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gravedigger Nonuid story ended - Restore the greeting menu');
