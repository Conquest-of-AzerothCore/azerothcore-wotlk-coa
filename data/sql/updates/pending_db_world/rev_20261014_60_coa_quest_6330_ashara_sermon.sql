-- Stay a While (1660054): Dark Priestess Ashara gives her sermon before the listen credit.
-- Her option '<Stay a while and listen.>' credited the marker 162921 at once, with no words. She now speaks
-- five lines, then credits the listener, as Aliscar Lend's lesson does for 1660060 (actionlist 16280600).
-- The option is hidden while she speaks.
--
-- WHERE EACH VALUE COMES FROM
--   flow  copied from Aliscar's lesson: talk groups with the same pacing, then credit the invoker.
--   lines  INFERRED: no source records Ashara's sermon (AscensionDB, CoA Tavern, client caches of all realms,
--     addons, the db.exil.es dump and Project Descension were searched). They follow her quest's own texts:
--     the 'banshee's sermon', the Cult of the Forgotten Shadow and its Three Virtues (offer reward), and
--     'Say goodbye to Ashara' (completion log).

DELETE FROM `creature_text` WHERE `CreatureID` = 162847;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(162847, 0, 0, 'Sit, $N. The living fill their chapels to beg the Light for comfort. We gather here to remember that it never answered us.', 12, 100, 'Dark Priestess Ashara - sermon 0 (INFERRED)'),
(162847, 1, 0, 'When the plague took us, the Light did not stir. What raised us from the Scourge was our own will, and the shadow that remembered us when the Light forgot.', 12, 100, 'Dark Priestess Ashara - sermon 1 (INFERRED)'),
(162847, 2, 0, 'The Cult of the Forgotten Shadow keeps Three Virtues. You will learn them in time, if you endure long enough to deserve them.', 12, 100, 'Dark Priestess Ashara - sermon 2 (INFERRED)'),
(162847, 3, 0, 'Until then, remember this: the dead owe nothing to those who abandoned them. Our faith is what we make of ourselves.', 12, 100, 'Dark Priestess Ashara - sermon 3 (INFERRED)'),
(162847, 4, 0, 'You have listened longer than most. Go now, $N, and say goodbye before you leave.', 12, 100, 'Dark Priestess Ashara - sermon 4 (INFERRED)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162847 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162847, 0, 0, 1, 62, 0, 100, 0, 932415, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - On Gossip Option 0 Selected - Close Gossip'),
(162847, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - Linked - Hide the option during the sermon'),
(162847, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16284700, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara - Linked - Start the sermon');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 16284700 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(16284700, 9, 0, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Say 0'),
(16284700, 9, 1, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Say 1'),
(16284700, 9, 2, 0, 0, 0, 100, 0, 12000, 12000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Say 2'),
(16284700, 9, 3, 0, 0, 0, 100, 0, 12000, 12000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Say 3'),
(16284700, 9, 4, 0, 0, 0, 100, 0, 12000, 12000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Say 4'),
(16284700, 9, 5, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Credit listening to her'),
(16284700, 9, 6, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Priestess Ashara sermon - Show the option again');
