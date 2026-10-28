-- Every Raven spawn becomes a Possessed Crow (user 2026-10-16): no frame or screenshot names a Raven, every
-- targeted bird is a Possessed Crow. The export's captured kneel and cannibalize spawns and the standing wanderer keep
-- their poses and gain the possession aura. Possessed Crows are levels 18-21 as targeted in 2r0PE1dBarE, DuWTvw19xtg
-- and F5g2uzWFLqA.
UPDATE `creature` SET `id` = 164944, `spawntimesecs` = 120 WHERE `id` = 164371;

DELETE FROM `creature_addon` WHERE `guid` IN (9960029, 9960647, 9961725, 9961860, 9961872, 9961932);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960029, 0, 0, 8, 1, 0, 0, '365403'),
(9960647, 0, 0, 0, 1, 398, 0, '365403'),
(9961725, 0, 0, 0, 1, 398, 0, '365403'),
(9961860, 0, 0, 0, 1, 398, 0, '365403'),
(9961872, 0, 0, 0, 1, 0, 0, '365403'),
(9961932, 0, 0, 8, 1, 0, 0, '365403');

-- Frost Elementals (164461) thinned from 27 to 11 and four placed with CoAWorldEdit (playtest 2026-10-16).
DELETE FROM `creature` WHERE `guid` IN (9965032, 9965033, 9965034, 9965035, 9965036, 9965037, 9965039, 9965040, 9988006, 9988008, 9988009, 9988011, 9988012, 9988013, 9988015, 9988016, 9988017, 9988018, 9988019, 9988020) AND `id` = 164461;
DELETE FROM `creature` WHERE `guid` IN (9999213, 9999214, 9999215, 9999216);
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(9999213, 164461, 0, 1, 1, 0, -6656.362, -216.458, 720.884, 3.2341, 300, 0, 0, 'Frost Elemental, user world edit 2026-10-16'),
(9999214, 164461, 0, 1, 1, 0, -6683.326, -284.978, 726.521, 3.8624, 300, 0, 0, 'Frost Elemental, user world edit 2026-10-16'),
(9999215, 164461, 0, 1, 1, 0, -6615.374, -344.740, 765.469, 5.8926, 300, 0, 0, 'Frost Elemental, user world edit 2026-10-16'),
(9999216, 164461, 0, 1, 1, 0, -6380.148, -177.655, 797.633, 3.5490, 300, 0, 0, 'Frost Elemental, user world edit 2026-10-16');

-- Ergrain Tattersail's two gossip options and their pages: option texts from V10AMkhYl6c at 1:25:00-1:25:04, pages
-- wdb_npccache 1200447 and 1200448 verbatim (1200448 is the page on screen at 1:25:04).
DELETE FROM `npc_text` WHERE `ID` IN (1200447, 1200448);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(1200447, '<Ergrain nods, her chest swelling with pride.>$B$BI have studied the history of this city from the very moment Erydna Stonesong left Ironforge, two hundred and thirty years ago, to yesterday. I have memorized every name in every family tree of the founding fathers who followed her, and of every dwarf who came after.$B$BEvery grudge, every gift, every exchange... It is my duty to remember all that concerns Dun Kazad, no matter how trifling.', '<Ergrain nods, her chest swelling with pride.>$B$BI have studied the history of this city from the very moment Erydna Stonesong left Ironforge, two hundred and thirty years ago, to yesterday. I have memorized every name in every family tree of the founding fathers who followed her, and of every dwarf who came after.$B$BEvery grudge, every gift, every exchange... It is my duty to remember all that concerns Dun Kazad, no matter how trifling.', 1),
(1200448, 'The woman who... How can ye possibly...?$B$B<Ergrain swallows the sharp reply she was about to unleash, and waits one more second before answering.>$B$BThat woman is the founder of Dun Kazad. Erydna Stonesong, mother of Azaghal Stonesong, our current Thane.$B$BWhen the War of the Three Hammers broke out in Ironforge, Erydna took command of all those who fled the city, and led the refugees to these mountains, where they founded Dun Kazad.$B$BThis city is filled with depictions of Erydna: holding a brazier, wielding a hammer, or extending her hand in welcome, as she does here upon this tower.', 'The woman who... How can ye possibly...?$B$B<Ergrain swallows the sharp reply she was about to unleash, and waits one more second before answering.>$B$BThat woman is the founder of Dun Kazad. Erydna Stonesong, mother of Azaghal Stonesong, our current Thane.$B$BWhen the War of the Three Hammers broke out in Ironforge, Erydna took command of all those who fled the city, and led the refugees to these mountains, where they founded Dun Kazad.$B$BThis city is filled with depictions of Erydna: holding a brazier, wielding a hammer, or extending her hand in welcome, as she does here upon this tower.', 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (9997020, 9997021);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9997020, 1200447),
(9997021, 1200448);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 1200446;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(1200446, 0, 0, 'Keeper of Lore?', 0, 1, 1, 9997020, 0, 0, 0, '', 0, 0),
(1200446, 1, 0, 'Who is the woman carved at the foot of this tower?', 0, 1, 1, 9997021, 0, 0, 0, '', 0, 0);

-- Playtest 2026-10-17: Jagged Cave Ealdir shouted their aggro line on every pull.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164043 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164043, 0, 0, 0, 4, 0, 15, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Jagged Cave Ealdir - On Aggro - Say Line 0'),
(164043, 0, 100, 0, 0, 0, 100, 0, 3000, 6000, 10000, 14000, 0, 0, 11, 365120, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Jagged Cave Ealdir - In Combat - Cast Mortal Wound'),
(164043, 0, 101, 0, 0, 0, 100, 0, 5000, 9000, 12000, 16000, 0, 0, 11, 365072, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jagged Cave Ealdir - In Combat - Cast Thrash');

-- When the Days Grow Short (175008): Durghain's progress and completion texts (AscensionES export pEN/cEN, matching
-- Redthedeer's turn-in in HIbr82QgX6w 21:30-22:06).
DELETE FROM `quest_request_items` WHERE `ID` = 175008;
INSERT INTO `quest_request_items` (`ID`, `CompletionText`) VALUES
(175008, '<Durghain scrutinizes the bags you\'re carrying before shifting his gaze to your face.>');
DELETE FROM `quest_offer_reward` WHERE `ID` = 175008;
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(175008, 'Yes, yes, don\'t tell me. Hilma sent you.$B$BYou\'re the fourth this month. She could afford an escort and come herself, but since our last spat, she prefers to keep her distance. It\'s her way of punishing me.$B$BRegardless, you are not to blame. Here, take this; the payment for your services.$B$B<Durghain bows his head politely.>$B$BThese are lean times for Scadeald, and for my pockets as well; I cannot offer you work. But the guard is always eager to recruit new blood. If you have the stomach for war, I suggest you report to Sir Draewyn, Commander of the Guard.');

-- Playtest 2026-10-17: seated NPCs floated a chair's height above their seats. A sit-on-chair stand state raises the
-- body by the seat height itself, so the spawn belongs on the floor under the chair, not on the seat.
UPDATE `creature` SET `position_z` = 311.162 WHERE `guid` = 9920749 AND `id` = 164634;
UPDATE `creature` SET `position_z` = 126.932 WHERE `guid` IN (9920200, 9920201, 9920202, 9920203, 9920204);

-- Possessed Statue of the Cardinal (164999) stood permanently in the Hallow Wind crypt with 5500x health and no AI.
-- The realm announced it as a temporary spawn and the spawn dump saw it once; removed until its event is reconstructed.
DELETE FROM `creature_addon` WHERE `guid` = 9960668;
DELETE FROM `creature` WHERE `guid` = 9960668 AND `id` = 164999;

-- Samara (164268) wears her realm-captured SI:7 outfit, including the boots (54054) the earlier row left out; #8051 gave
-- her the Dunshire Guard uniform. The capture carries no customization, so skin, face and hair stay as main had them.
DELETE FROM `creature_display_preset` WHERE `entry` = 164268;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164268, 50, 1, 1, 1, 16, 0, 1, 8, 0, 0, 35721, 140983, 5260, 54269, 54003, 54266, 54054, 51621, 54242, 0, 0);
