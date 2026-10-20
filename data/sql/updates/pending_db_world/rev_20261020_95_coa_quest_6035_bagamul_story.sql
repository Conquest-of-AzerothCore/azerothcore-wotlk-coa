-- Stay a While (1660065): Bagamul Skyfang tells his story over gossip pages before the listen credit.
-- His option '<Stay a while and listen.>' (932516/0) credited the marker 162921 at once, with no story. It now
-- opens four pages; the first three continue with "What happened next?"-style options or offer
-- '<Skip the story.>', which credits 162921 at once. The last page's option credits 162921 and closes the gossip.
-- Every option shows only while 1660065 is taken.
--
-- WHERE EACH VALUE COMES FROM
--   greeting  npc_text 85189 and menu 932516 stay as rev_20260926_31 wrote them (cached greeting).
--   ids  gossip menus and npc_text 932517-932520: the next free ids in the 932515-932529 block rev_20260926_31
--     reserves for Razor Hill, whose highest id in use is 932516. Same-id npc_text follows rev_20260924_14.
--   flow  page chain as the report (#6035) describes: about three "what happened" options and a skip option.
--   texts  INFERRED, approved by the maintainer on 2026-10-20: all page and option texts. No source records
--     Bagamul's story (AscensionDB, CoA Tavern, client caches of all realms, addons, the db.exil.es dump and
--     Project Descension were searched). They follow his quest's own texts ('stay a while', the old orc who
--     murmurs as if to himself, 'Few bother to listen to this old orc') and his greeting on the Razor Hill tower.

DELETE FROM `npc_text` WHERE `ID` IN (932517, 932518, 932519, 932520);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(932517, 'I was barely more than a pup when the Horde first came through the Dark Portal. By the end of the Second War I sat behind the walls of a human internment camp, like most of our people, and the fire in me had gone cold.$B$BYears we lay in the mud. Then a young warchief broke the camps open, and the old blood remembered what it was to be free.', 'I was barely more than a pup when the Horde first came through the Dark Portal. By the end of the Second War I sat behind the walls of a human internment camp, like most of our people, and the fire in me had gone cold.$B$BYears we lay in the mud. Then a young warchief broke the camps open, and the old blood remembered what it was to be free.', 0, 0, 1),
(932518, '<Bagamul''s gaze drifts out over the sea.>$B$BThrall took ships from the humans and led us west, across the Great Sea. The storms nearly sank us all. When we reached this shore at last, the earth was red and dry and the sun beat down like a hammer.$B$BWe named the land Durotar, for the Warchief''s father, and we made it our own.', '<Bagamul''s gaze drifts out over the sea.>$B$BThrall took ships from the humans and led us west, across the Great Sea. The storms nearly sank us all. When we reached this shore at last, the earth was red and dry and the sun beat down like a hammer.$B$BWe named the land Durotar, for the Warchief''s father, and we made it our own.', 0, 0, 1),
(932519, 'We raised this tower before we raised a single hut. From up here a sentry sees the road, the hills and the waves all at once, and I stood many watches on these boards.$B$BThe sea did not stay quiet. Kul Tiran sails came over the horizon, and Proudmoore''s soldiers burned what we had built. Their keep still stands down the coast, a reminder that peace here was paid for in blood.', 'We raised this tower before we raised a single hut. From up here a sentry sees the road, the hills and the waves all at once, and I stood many watches on these boards.$B$BThe sea did not stay quiet. Kul Tiran sails came over the horizon, and Proudmoore''s soldiers burned what we had built. Their keep still stands down the coast, a reminder that peace here was paid for in blood.', 0, 0, 1),
(932520, '<The old orc is silent for a long moment.>$B$BNow the young ones hurry past this tower with their eyes on Orgrimmar and the glory beyond it. Let them hurry. But someone should remember why there is a Razor Hill at all.$B$BYou have been patient with an old orc''s memories, $N. Go on, then. The world will not wait for either of us.', '<The old orc is silent for a long moment.>$B$BNow the young ones hurry past this tower with their eyes on Orgrimmar and the glory beyond it. Let them hurry. But someone should remember why there is a Razor Hill at all.$B$BYou have been patient with an old orc''s memories, $N. Go on, then. The world will not wait for either of us.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932517, 932518, 932519, 932520);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932517, 932517),
(932518, 932518),
(932519, 932519),
(932520, 932520);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932516, 932517, 932518, 932519, 932520);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932516, 0, 0, '<Stay a while and listen.>', 0, 1, 1, 932517, 0, 0, 0, '', 0),
(932517, 0, 0, 'What happened next?', 0, 1, 1, 932518, 0, 0, 0, '', 0),
(932517, 1, 0, '<Skip the story.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932518, 0, 0, 'And then what happened?', 0, 1, 1, 932519, 0, 0, 0, '', 0),
(932518, 1, 0, '<Skip the story.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932519, 0, 0, 'What happened after that?', 0, 1, 1, 932520, 0, 0, 0, '', 0),
(932519, 1, 0, '<Skip the story.>', 0, 1, 1, 0, 0, 0, 0, '', 0),
(932520, 0, 0, '<Thank Bagamul for the story.>', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` IN (932516, 932517, 932518, 932519, 932520);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 932516, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932517, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932517, 1, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932518, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932518, 1, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932519, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932519, 1, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken'),
(15, 932520, 0, 0, 0, 9, 0, 1660065, 0, 0, 0, 0, 0, '', 'show only while quest 1660065 taken');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162841 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162841, 0, 0, 1, 62, 0, 100, 0, 932517, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - On Gossip 932517 Option 1 Selected - Close Gossip'),
(162841, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - Linked - Quest Credit Listen to Bagamul Skyfang (skipped on page 1)'),
(162841, 0, 2, 3, 62, 0, 100, 0, 932518, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - On Gossip 932518 Option 1 Selected - Close Gossip'),
(162841, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - Linked - Quest Credit Listen to Bagamul Skyfang (skipped on page 2)'),
(162841, 0, 4, 5, 62, 0, 100, 0, 932519, 1, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - On Gossip 932519 Option 1 Selected - Close Gossip'),
(162841, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - Linked - Quest Credit Listen to Bagamul Skyfang (skipped on page 3)'),
(162841, 0, 6, 7, 62, 0, 100, 0, 932520, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - On Gossip 932520 Option 0 Selected - Close Gossip'),
(162841, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bagamul Skyfang - Linked - Quest Credit Listen to Bagamul Skyfang (story finished)');
