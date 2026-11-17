-- The Farewell Ceremony: Patriarch Khazemil (164455) speaks his eulogy before "Khazemil informed" (RIEMlZSgbQw
-- 08:52:31-08:53:02); Bishop Beorn (164454) gains his missing "His fist..." line and his footage spacing
-- (MD0GT_RsHQs 01:58:00-01:58:30). Both start about 1 s after the gossip closes and credit 2 s after the last line.
DELETE FROM `creature_text` WHERE `CreatureID` IN (164454, 164455);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
    `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164454, 0, 0, 'We are gathered here to bid farewell to the soul of Holdor Stonefist, champion of Dun Kazad.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bishop Beorn - Farewell Ceremony sermon'),
(164454, 1, 0, 'His fist may have been of stone, but his heart was as light as a feather.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bishop Beorn - Farewell Ceremony sermon'),
(164454, 2, 0, 'Therefore, just as the Light lifts his spirit to the empyrean heights, we lift our prayers to accompany him.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bishop Beorn - Farewell Ceremony sermon'),
(164454, 3, 0, 'Beyond pain and sorrow. To that place where all is bliss and contentment.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bishop Beorn - Farewell Ceremony sermon'),
(164454, 4, 0, 'By the grace of the Light, he is now one with the Holy.', 12, 0, 100, 0, 0, 0, 0, 0, 'Bishop Beorn - Farewell Ceremony sermon'),
(164455, 0, 0, 'Holdor, son of Hangor, son of Hornagor. You have been a worthy heir to the Stonefist name.', 12, 0, 100, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Farewell Ceremony eulogy'),
(164455, 1, 0, 'Your successors mourn your passing. Your ancestors receive you with open arms in the halls of our Fathers, where we all shall one day reunite.', 12, 0, 100, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Farewell Ceremony eulogy'),
(164455, 2, 0, 'Those who live will treasure your memory until the end of their days, until the end of the world...', 12, 0, 100, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Farewell Ceremony eulogy'),
(164455, 3, 0, 'Or until those who created us return, and forge new bodies for the living and the dead alike.', 12, 0, 100, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Farewell Ceremony eulogy'),
(164455, 4, 0, 'Until then, Holdor, son of Hangor, son of Hornagor. May your legacy endure.', 12, 0, 100, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Farewell Ceremony eulogy');

DELETE FROM `smart_scripts` WHERE (`entryorguid`,`source_type`) IN ((16445400,9),(164455,0),(16445500,9));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(16445400, 9, 0, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Say Line 0'),
(16445400, 9, 1, 0, 0, 0, 100, 0, 8000, 8000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Say Line 1'),
(16445400, 9, 2, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Say Line 2'),
(16445400, 9, 3, 0, 0, 0, 100, 0, 8000, 8000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Say Line 3'),
(16445400, 9, 4, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Say Line 4'),
(16445400, 9, 5, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 33, 164454, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bishop Beorn - Sermon - Credit Beorn informed'),
(164455, 0, 0, 0, 62, 0, 100, 0, 100711, 0, 0, 0, 0, 0, 33, 164455, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - On Gossip Option 0 - Credit Creed of the Pantheon'),
(164455, 0, 1, 0, 62, 0, 100, 0, 100711, 1, 0, 0, 0, 0, 33, 164534, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - On Gossip Option 1 - Credit tenets of the Creed'),
(164455, 0, 2, 3, 62, 0, 100, 0, 100711, 2, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - On Gossip Option 2 - Close Gossip'),
(164455, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16445500, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Linked - Run Farewell Ceremony eulogy'),
(16445500, 9, 0, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Say Line 0'),
(16445500, 9, 1, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Say Line 1'),
(16445500, 9, 2, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Say Line 2'),
(16445500, 9, 3, 0, 0, 0, 100, 0, 8000, 8000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Say Line 3'),
(16445500, 9, 4, 0, 0, 0, 100, 0, 6000, 6000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Say Line 4'),
(16445500, 9, 5, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 33, 164455, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Patriarch Khazemil - Eulogy - Credit Khazemil informed');
