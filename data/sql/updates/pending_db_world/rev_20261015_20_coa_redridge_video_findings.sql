-- Redridge Mountains: what Roman Murashoff's Ascension Redridge videos (2026-08-02, playlist PLMeDZ00QsunU) show
-- beyond the restore in rev_20261010_98: request and reward texts, gossip texts, the Minervia's Legacy credits,
-- says, levels and positions. Video ids and times are named per block; spots read from the videos are estimated.

-- Request and reward texts of The Rookery and Lost Secrets: video KfIRjSeLn4Y at 04:22-04:24 and 04:54-04:56.
DELETE FROM `quest_request_items` WHERE `ID` IN (254070,254071);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(254070, 0, 0, 'Have you dealt with the orc? More importantly, do you have my missing page? I can feel its absence like a splinter in my spine. If you carry it now, bring it forth at once. If not, then what exactly are you waiting for?', 0),
(254071, 0, 0, 'Have you gotten an egg yet? Jasper is still fast asleep, so it doesn''t look like there''s any rush.', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254070,254071);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`,
  `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(254070, 0, 0, 0, 0, 0, 0, 0, 0, 'I am whole once more!$B$BYou have done me a great service, and so it is only fair I reward you with a small portion of my secrets, but only a taste, for now. You are inexperienced yet, and I do not wish to damage your mind.$B$BWe shall meet again, perhaps not soon, for I have much left to share with the others of this tower, but the time will come, of that I am now certain.', 0),
(254071, 0, 0, 0, 0, 0, 0, 0, 0, 'Yes, that will work perfectly. You have a good eye.$B$BJasper woke up briefly but he fell asleep again before I could get halfway through explaining the basic principles of Arcane Missiles.$B$BThe only good thing about having such a lazy student is that it gives me plenty of time for my own research, as long as I can focus through his snoring.', 0);

-- Gossip texts: videos hTDhaiodOwE (Red Mage Tower, 00:02-02:32), _wYlrKFtuNw (Magistrate Solomon, 01:16) and
-- y03LWvmfnXM (Lady Idelia Solomon 03:22, Luca Tyndall 04:34). Solomon's text keeps his quest greeting's wording
-- with the video's 'Lakeshire'.
DELETE FROM `npc_text` WHERE `ID` BETWEEN 60072 AND 60082;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(60072, 'Does Jasper think magic just happens because he naps through it all? Does the power of a mage simply appear in his dreams, perhaps? I can hardly get through a single incantation without hearing the sound of snoring. It''s as if the very mention of ''mana'' induces a deep slumber!$B$BI''ve tried every method - enchantments, gentle encouragement, even a well-timed splash of cold water. Nothing works!$B$BHow can anyone be so blissfully unaware while I''m trying to instill the secrets of the arcane into their thick skull?', 'Does Jasper think magic just happens because he naps through it all? Does the power of a mage simply appear in his dreams, perhaps? I can hardly get through a single incantation without hearing the sound of snoring. It''s as if the very mention of ''mana'' induces a deep slumber!$B$BI''ve tried every method - enchantments, gentle encouragement, even a well-timed splash of cold water. Nothing works!$B$BHow can anyone be so blissfully unaware while I''m trying to instill the secrets of the arcane into their thick skull?', 1),
(60073, 'Do you see it? That''s the famous Archmage Minervia, the one who defended Lakeshire from a dragon attack when I was just a child!$B$BI''ve read so many scrolls and tomes about her achievements, but standing before her likeness... it''s like I can feel the echoes of her power still lingering in the air.$B$BImagine being able to weave magic with such precision, to command arcane energies as if they were mere tools! Her feats are the stuff of legends, and yet—here, in this quiet moment—I can''t help but wonder if I will ever reach such heights.', 'Do you see it? That''s the famous Archmage Minervia, the one who defended Lakeshire from a dragon attack when I was just a child!$B$BI''ve read so many scrolls and tomes about her achievements, but standing before her likeness... it''s like I can feel the echoes of her power still lingering in the air.$B$BImagine being able to weave magic with such precision, to command arcane energies as if they were mere tools! Her feats are the stuff of legends, and yet—here, in this quiet moment—I can''t help but wonder if I will ever reach such heights.', 1),
(60074, 'Please... don''t encourage him.', 'Please... don''t encourage him.', 1),
(60075, '<Jasper slouches in the chair, his eyes wide and unblinking as he stares vacantly at the wall. His mouth hangs slightly open, the silence broken only by the sudden eruption of a deafening snore that shakes his body.>$B$BIt might be best to leave him undisturbed.', '<Jasper slouches in the chair, his eyes wide and unblinking as he stares vacantly at the wall. His mouth hangs slightly open, the silence broken only by the sudden eruption of a deafening snore that shakes his body.>$B$BIt might be best to leave him undisturbed.', 1),
(60076, '<Jasper doesn''t respond. The only sound that fills the room is the faint rustling of breath.>', '<Jasper doesn''t respond. The only sound that fills the room is the faint rustling of breath.>', 1),
(60077, 'Ah, another curious soul.$B$BDo you feel the pulse of the world''s magic, the way it shifts and ebbs like the tides? I spend my days tracking these subtle currents, seeking out wellsprings of arcane energy that will fuel my studies and strengthen my craft.$B$BIt''s a never-ending journey, one that requires focus and patience... something my students could use a bit more of. Don''t get me wrong, they have potential, but some of them have the attention span of a firefly on a summer night.$B$BStill, their chaos is a small price to pay for the knowledge we''re uncovering here.', 'Ah, another curious soul.$B$BDo you feel the pulse of the world''s magic, the way it shifts and ebbs like the tides? I spend my days tracking these subtle currents, seeking out wellsprings of arcane energy that will fuel my studies and strengthen my craft.$B$BIt''s a never-ending journey, one that requires focus and patience... something my students could use a bit more of. Don''t get me wrong, they have potential, but some of them have the attention span of a firefly on a summer night.$B$BStill, their chaos is a small price to pay for the knowledge we''re uncovering here.', 1),
(60078, 'Let me guess, Alexandria asked you?$B$BI''ll tell you the same thing I told her. I got my start here training under Minervia, she was always a bit odd, I guess we all are to be here.$B$BAfter that attack on Lakeshire, she was never quite the same, she shut herself in research for days on end until one day she just wasn''t there anymore.$B$BOh, I did learn something rather odd about her, apparently she had a son in Lakeshire, she never seemed like the type to settle down with a family, I guess she didn''t in the end. I never did get his name, felt a bit intrusive to pry into her family matters like this. Still, I doubt Alexandria will drop this until she gets some answers, so maybe you can find him.', 'Let me guess, Alexandria asked you?$B$BI''ll tell you the same thing I told her. I got my start here training under Minervia, she was always a bit odd, I guess we all are to be here.$B$BAfter that attack on Lakeshire, she was never quite the same, she shut herself in research for days on end until one day she just wasn''t there anymore.$B$BOh, I did learn something rather odd about her, apparently she had a son in Lakeshire, she never seemed like the type to settle down with a family, I guess she didn''t in the end. I never did get his name, felt a bit intrusive to pry into her family matters like this. Still, I doubt Alexandria will drop this until she gets some answers, so maybe you can find him.', 1),
(60079, 'Who is this $c who goes before the Court of Lakeshire in the Kingdom of Stormwind? State your business within this township, $r. The orc threat to the Kingdom is far too great to squander time in idle conversation.', 'Who is this $c who goes before the Court of Lakeshire in the Kingdom of Stormwind? State your business within this township, $r. The orc threat to the Kingdom is far too great to squander time in idle conversation.', 1),
(60080, 'My husband has been kept busy with the orc threat as of late... I had to convert the lower levels of our house into a makeshift barracks to house them all. It''s not much, but it''s the best building we have here.', 'My husband has been kept busy with the orc threat as of late... I had to convert the lower levels of our house into a makeshift barracks to house them all. It''s not much, but it''s the best building we have here.', 1),
(60081, 'I got all my recipes from Miss. Boughman over northside... <Luca sighs> One day I''ll find out what it is...', 'I got all my recipes from Miss. Boughman over northside... <Luca sighs> One day I''ll find out what it is...', 1),
(60082, '<Though your voice grows louder, more insistent, there is still nothing. Jasper''s chest rises and falls in a slow, rhythmic motion, his mouth slightly ajar.>$B$B<A single, rumbling snore breaks the silence, as if to answer the call with nothing but pure disregard.>$B$BIt''s clear: waking him will take more than just a few shouts.', '<Though your voice grows louder, more insistent, there is still nothing. Jasper''s chest rises and falls in a slow, rhythmic motion, his mouth slightly ajar.>$B$B<A single, rumbling snore breaks the silence, as if to answer the call with nothing but pure disregard.>$B$BIt''s clear: waking him will take more than just a few shouts.', 1);

DELETE FROM `gossip_menu` WHERE `MenuID` BETWEEN 60072 AND 60082;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(60072, 60072),
(60073, 60073),
(60074, 60074),
(60075, 60075),
(60076, 60076),
(60077, 60077),
(60078, 60078),
(60079, 60079),
(60080, 60080),
(60081, 60081),
(60082, 60082);

DELETE FROM `gossip_menu_option` WHERE `MenuID` BETWEEN 60072 AND 60082;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
  `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
  `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(60075, 0, 0, 'Call his name.', 0, 1, 1, 60076, 0, 0, 0, '', 0, 0),
(60075, 1, 0, 'Disturb him. Violently.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(60076, 0, 0, 'Call his name. LOUDER.', 0, 1, 1, 60082, 0, 0, 0, '', 0, 0),
(60082, 0, 0, 'JASPERRRRRRR!!!', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(60077, 0, 0, 'I''m looking into Archmage Minervia, do you happen to know anything?', 0, 1, 1, 60078, 0, 0, 0, '', 0, 0),
(60078, 0, 0, 'Thank you, I''ll look into him.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(60079, 0, 0, 'I''m looking into an Archmage Minervia, supposedly she''d saved this town some years back?', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

-- Lady Idelia Solomon and Luca Tyndall keep their quests next to the gossip.
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 60072, `AIName` = 'SmartAI' WHERE `entry` = 991474;
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 60073 WHERE `entry` = 991476;
UPDATE `creature_template` SET `npcflag` = 1, `gossip_menu_id` = 60074, `AIName` = 'SmartAI' WHERE `entry` = 991482;
UPDATE `creature_template` SET `npcflag` = 1, `gossip_menu_id` = 60075, `AIName` = 'SmartAI' WHERE `entry` = 991475;
UPDATE `creature_template` SET `gossip_menu_id` = 60077 WHERE `entry` = 991477;
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 60079, `AIName` = 'SmartAI' WHERE `entry` = 344;
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 60080 WHERE `entry` = 255206;
UPDATE `creature_template` SET `npcflag` = 3, `gossip_menu_id` = 60081 WHERE `entry` = 255204;

-- Minervia's Legacy: the videos show each credit only after the gossip option is chosen (hTDhaiodOwE 02:12 for
-- Hestlor's 'Thank you, I'll look into him.'); opening Solomon's gossip alone leaves his objective at 0/1
-- (_wYlrKFtuNw 01:16-01:24, y03LWvmfnXM 08:48). The outcome of Solomon's option is not shown and is estimated.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (991477,344) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(991477, 0, 0, 1, 62, 0, 100, 0, 60078, 0, 0, 0, 0, 0, 33, 991477, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ley-Tracker Hestlor - On Gossip Option 0 Selected - Quest Credit ''Minervia''s Legacy'''),
(991477, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ley-Tracker Hestlor - On Link - Close Gossip'),
(344, 0, 0, 1, 62, 0, 100, 0, 60079, 0, 0, 0, 0, 0, 33, 344, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magistrate Solomon - On Gossip Option 0 Selected - Quest Credit ''Minervia''s Legacy'''),
(344, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Magistrate Solomon - On Link - Close Gossip');

DELETE FROM `conditions` WHERE (`SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (991477,344) AND `SourceId` = 0)
  OR (`SourceTypeOrReferenceId` = 15 AND `SourceGroup` IN (60077,60079));
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 60077, 0, 0, 0, 9, 0, 254067, 0, 0, 0, 0, 0, '', 'Ley-Tracker Hestlor - option only on ''Minervia''s Legacy'''),
(15, 60079, 0, 0, 0, 9, 0, 254067, 0, 0, 0, 0, 0, '', 'Magistrate Solomon - option only on ''Minervia''s Legacy''');

-- Levels shown in y03LWvmfnXM and 3qfdpW_xSb0. Luca Tyndall, Lady Idelia Solomon and Father Norice replace the
-- levels from the live world export used in rev_20261010_98.
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` IN (255204,255206);
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 35 WHERE `entry` = 255207;
UPDATE `creature_template` SET `minlevel` = 10, `maxlevel` = 10 WHERE `entry` IN (255469,255470);

-- Jasper Gilleon's gossip chain, Meria Crastlor's complaint and Corwin Branwick's remarks: video hTDhaiodOwE.
-- Calling Jasper a third time makes the player shout and wakes him; Meria answers about 3 s later. Disturbing him
-- violently starts the exchange with Corwin and Meria at the times the video shows. The number of R in the shout,
-- when Jasper falls asleep again, the gaps between Corwin's remarks and Meria's interval (54-63 s observed) are
-- estimated. Jasper keeps his chair and gets the Cosmetic - Sleep Zzz aura the videos show above him.
DELETE FROM `acore_string` WHERE `entry` = 991475;
INSERT INTO `acore_string` (`entry`, `content_default`) VALUES
(991475, 'JASPERRRRR!!!');

DELETE FROM `creature_text` WHERE `CreatureID` IN (991474,991475,991482);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(991474, 0, 0, 'Jasper, would you mind helping me with- Oh. You''re asleep....again. *Sighs* Sometimes I''m not sure why I even bother...', 12, 0, 100, 0, 0, 0, 0, 0, 'Meria Crastlor - Out of Combat'),
(991474, 1, 0, 'Oh FINALLY...!', 12, 0, 100, 0, 0, 0, 0, 0, 'Meria Crastlor - Jasper Gilleon woken'),
(991474, 2, 0, 'Please, we all know you weren''t ''meditating''.', 12, 0, 100, 0, 0, 0, 0, 0, 'Meria Crastlor - Jasper Gilleon disturbed'),
(991475, 0, 0, 'Huh? What- what''s going on? Did I miss something? Was I supposed to be doing something?', 12, 0, 100, 0, 0, 0, 0, 0, 'Jasper Gilleon - Woken'),
(991475, 1, 0, 'OW! What was that for?!', 12, 0, 100, 0, 0, 0, 0, 0, 'Jasper Gilleon - Disturbed'),
(991475, 2, 0, 'Can''t a guy meditate in peace around here?', 12, 0, 100, 0, 0, 0, 0, 0, 'Jasper Gilleon - Disturbed'),
(991482, 0, 0, 'Will you stop...', 12, 0, 100, 0, 0, 0, 0, 0, 'Corwin Branwick - Jasper Gilleon disturbed'),
(991482, 1, 0, 'Don''t do it!', 12, 0, 100, 0, 0, 0, 0, 0, 'Corwin Branwick - Out of Combat'),
(991482, 1, 1, 'I can''t take this anymore...', 12, 0, 100, 0, 0, 0, 0, 0, 'Corwin Branwick - Out of Combat');

UPDATE `creature_addon` SET `auras` = '55474' WHERE `guid` = 9950405;

-- Meria channels a blue beam into the ground-floor rune circle, aimed at a World Trigger on the circle; the beam
-- spell and the trigger's height are estimated. Silas Figner and Dorian Firehart channel beside the Portal to
-- Stormwind (Arcane Channeling, estimated). Sah'kihnu has a mana bar and casts Shadow Bolt in video wDFvkGqByQI at
-- 04:32; his class, combat values and spells are copied from the Blackrock Shadowcaster (436) and are estimated.
UPDATE `creature_template` SET `unit_class` = 8, `HealthModifier` = 3.7726, `ArmorModifier` = 2.834,
  `DamageModifier` = 2.8, `AIName` = 'SmartAI' WHERE `entry` = 254976;

DELETE FROM `smart_scripts` WHERE (`entryorguid` IN (991474,991475,991482,991479,991480,254976) AND `source_type` = 0)
  OR (`entryorguid` IN (99147500,99147501) AND `source_type` = 9);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(991474, 0, 0, 0, 1, 0, 100, 0, 50000, 60000, 50000, 60000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Meria Crastlor - Out of Combat - Say Line 0'),
(991474, 0, 1, 0, 1, 0, 100, 0, 1000, 1000, 10000, 10000, 0, 0, 11, 30945, 32, 0, 0, 0, 0, 19, 21252, 30, 0, 0, 0, 0, 0, 0, 'Meria Crastlor - Out of Combat - Cast ''Blue Beam'' on World Trigger'),
(991475, 0, 0, 1, 62, 0, 100, 0, 60075, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Gossip Option 1 Selected - Say Line 1'),
(991475, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Close Gossip'),
(991475, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 99147501, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Run Script'),
(991475, 0, 3, 4, 62, 0, 100, 0, 60082, 0, 0, 0, 0, 0, 220, 991475, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Gossip Option 0 Selected - Invoker Yell'),
(991475, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 55474, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Remove Aura ''Cosmetic - Sleep Zzz'''),
(991475, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Say Line 0'),
(991475, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Close Gossip'),
(991475, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 99147500, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - On Link - Run Script'),
(99147500, 9, 0, 0, 0, 0, 100, 0, 3000, 3000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 991474, 40, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - Actionlist - Meria Crastlor Say Line 1'),
(99147500, 9, 1, 0, 0, 0, 100, 0, 57000, 57000, 0, 0, 0, 0, 75, 55474, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - Actionlist - Add Aura ''Cosmetic - Sleep Zzz'''),
(99147501, 9, 0, 0, 0, 0, 100, 0, 3500, 3500, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 991482, 80, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - Actionlist - Corwin Branwick Say Line 0'),
(99147501, 9, 1, 0, 0, 0, 100, 0, 1500, 1500, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - Actionlist - Say Line 2'),
(99147501, 9, 2, 0, 0, 0, 100, 0, 7000, 7000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 19, 991474, 40, 0, 0, 0, 0, 0, 0, 'Jasper Gilleon - Actionlist - Meria Crastlor Say Line 2'),
(991482, 0, 0, 0, 1, 0, 100, 0, 60000, 180000, 180000, 300000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Corwin Branwick - Out of Combat - Say Line 1'),
(991479, 0, 0, 0, 1, 0, 100, 0, 1000, 1000, 10000, 10000, 0, 0, 11, 32783, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Silas Figner - Out of Combat - Cast ''Arcane Channeling'''),
(991480, 0, 0, 0, 1, 0, 100, 0, 1000, 1000, 10000, 10000, 0, 0, 11, 32783, 32, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dorian Firehart - Out of Combat - Cast ''Arcane Channeling'''),
(254976, 0, 0, 0, 0, 0, 100, 0, 0, 0, 3000, 3800, 0, 0, 11, 9613, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Sah''kihnu - In Combat - Cast ''Shadow Bolt'''),
(254976, 0, 1, 0, 0, 0, 100, 0, 3700, 4500, 8400, 28100, 0, 0, 11, 11639, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Sah''kihnu - In Combat - Cast ''Shadow Word: Pain''');

-- NPCs the videos show that main lacks; names, subnames, types, type flags and HealthModifier follow their
-- creaturecache rows (WDB captures up to 2026-09-08). Levels are read from the videos where shown (Adelise 25,
-- Roland Branwick 15) and estimated otherwise; factions and flags follow the Red Mage Tower and Lakeshire NPCs, Tirig
-- those of the Blackrock orcs. Enchanter Veridan teaches what the other Enchanting trainers teach and keeps the model
-- and display preset of rev_20260927. Roland Branwick (1502) and Tirig (6037) keep their client displays; Adelise
-- (255205), Silas Figner (811479) and Dorian Firehart (811480) carry Ascension displays the client lacks, so they
-- wear the stand-ins 9255, 1484 and 1491. Ley-Tracker Hestlor wears the captured mirror-image display 49 again
-- (rev_20260927_00_captured_mirror_models), which his display preset of rev_20260927_01 dresses; rev_20261010_98
-- had replaced it with 1484.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
  `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
  `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`,
  `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
  `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
  `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
  `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(991478, 0, 0, 0, 0, 0, 'Enchanter Veridan', 'Enchanting Trainer', NULL, 4161, 30, 30, 0, 12, 81, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(991479, 0, 0, 0, 0, 0, 'Silas Figner', 'Mage Adept', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(991480, 0, 0, 0, 0, 0, 'Dorian Firehart', 'Mage Adept', NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(991481, 0, 0, 0, 0, 0, 'Roland Branwick', 'Novice Mage', NULL, 0, 15, 15, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(254978, 0, 0, 0, 0, 0, 'Tirig', 'Blackrock Dragon Tender', NULL, 0, 18, 20, 0, 40, 0, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 254978, 0, 0, 0, 0, 0, 0, '', 0, 1, 3, 1, 1, 1, 0, 0, 1, 0, 0, '', 0),
(255205, 0, 0, 0, 0, 0, 'Adelise', NULL, NULL, 0, 25, 25, 0, 12, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 512, 2048, 0, 0, 7, 134217728, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1.312, 1, 1, 1, 0, 0, 1, 0, 2, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`),
  `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`),
  `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`),
  `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`),
  `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`),
  `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`),
  `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`),
  `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`),
  `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
  `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`),
  `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`),
  `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`),
  `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`),
  `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`),
  `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`),
  `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`),
  `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`),
  `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`),
  `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`),
  `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
  `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`),
  `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (991477,991479,991480,991481,254978,255205);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
  `VerifiedBuild`) VALUES
(991477, 0, 49, 1, 1, 0),
(991479, 0, 1484, 1, 1, 0),
(991480, 0, 1491, 1, 1, 0),
(991481, 0, 1502, 1, 1, 0),
(254978, 0, 6037, 1, 1, 0),
(255205, 0, 9255, 1, 1, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 991478;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(991478, 96);

-- Tirig's loot: SUB archive table creature_loot (db.exil.es dump, 2026-10-04), chances as listed there.
DELETE FROM `creature_loot_template` WHERE `Entry` = 254978;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`,
  `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254978, 7906, 0, 8, 0, 1, 0, 1, 1, 'Tirig - Horns of Nez''ra'),
(254978, 9771, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Greenweave Gloves'),
(254978, 14127, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Ritual Shroud'),
(254978, 14133, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Ritual Tunic'),
(254978, 14165, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Pagan Britches'),
(254978, 14179, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Watcher''s Cape'),
(254978, 14373, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Sanguine Belt'),
(254978, 14374, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Sanguine Sandals'),
(254978, 14375, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Sanguine Cuffs'),
(254978, 14566, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Prospector''s Pads'),
(254978, 14572, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Bristlebark Gloves'),
(254978, 14742, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Hulking Boots'),
(254978, 14748, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Hulking Leggings'),
(254978, 15117, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Rigid Leggings'),
(254978, 15122, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Robust Bracers'),
(254978, 15124, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Robust Cloak'),
(254978, 15329, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Wrangler''s Belt'),
(254978, 15330, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Wrangler''s Boots'),
(254978, 15500, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Outrunner''s Chestguard'),
(254978, 15511, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Grunt''s Legguards'),
(254978, 15512, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Grunt''s Shield'),
(254978, 15513, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Grunt''s Pauldrons'),
(254978, 15517, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Spiked Chain Wristbands'),
(254978, 15526, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Sentry''s Cape'),
(254978, 15894, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Bristlebark Buckler'),
(254978, 15972, 0, 0.014, 0, 1, 0, 1, 1, 'Tirig - Ritual Stein'),
(254978, 554280, 0, 0.417, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Glyph of Blocking'),
(254978, 1013734, 0, 0.417, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Impale'),
(254978, 1013791, 0, 0.625, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Demonic Brutality'),
(254978, 1013810, 0, 0.625, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Improved Aspect of the Monkey'),
(254978, 1013862, 0, 0.417, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Shield Mastery'),
(254978, 1175680, 0, 7.5, 0, 1, 0, 1, 1, 'Tirig - Mystic Scroll: Shield Specialization'),
(254978, 4050874, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Spaulders'),
(254978, 4050875, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Harness'),
(254978, 4050876, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Belt'),
(254978, 4050877, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Pants'),
(254978, 4050878, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Cuffs'),
(254978, 4050879, 0, 1.171, 0, 1, 0, 1, 1, 'Tirig - Dragon Tender''s Mace');

-- Spots read from the videos: Enchanter Veridan (hTDhaiodOwE), Silas Figner and Dorian Firehart at the Portal to
-- Stormwind and Roland Branwick between the two mage dummies on the top floor (KfIRjSeLn4Y), Tirig behind the
-- Rookery nests (KfIRjSeLn4Y 02:18-02:30) and Adelise in the west doorway of the Lakeshire stable beside a guard
-- (y03LWvmfnXM). Every spot, height and facing is estimated; heights in the tower are client WMO floors.
DELETE FROM `creature` WHERE `guid` BETWEEN 9950432 AND 9950438;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950432, 991478, 0, 0, 0, 1, 1, 0, -9657.5, -1945.5, 99.49, 4.06, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Enchanter Veridan (Red Mage Tower top floor, seen in the videos; spot and facing estimated)'),
(9950433, 991481, 0, 0, 0, 1, 1, 0, -9686.11, -1973.1, 99.49, 0.59, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Roland Branwick (Red Mage Tower top floor between the mage dummies, seen in the videos; spot and facing estimated)'),
(9950434, 254978, 0, 0, 0, 1, 1, 0, -9717.45, -2898.78, 53.8, 0.63, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Tirig (the Rookery behind the egg nests, seen in the videos; spot and facing estimated)'),
(9950435, 255205, 0, 0, 0, 1, 1, 0, -9478, -2279, 74.9, 1.57, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Adelise (Lakeshire stable west doorway, seen in the videos; spot and facing estimated)'),
(9950436, 991479, 0, 0, 0, 1, 1, 0, -9689.98, -1950.35, 99.49, 0.97, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Silas Figner (Red Mage Tower top floor at the Portal to Stormwind, seen in the videos; spot and facing estimated)'),
(9950437, 991480, 0, 0, 0, 1, 1, 0, -9687.14, -1946.24, 99.49, 4.11, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Dorian Firehart (Red Mage Tower top floor at the Portal to Stormwind, seen in the videos; spot and facing estimated)'),
(9950438, 21252, 0, 0, 0, 1, 1, 0, -9669.34, -1961.96, 65.5, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'World Trigger (Not Immune PC) (target of Meria Crastlor''s beam on the ground-floor rune circle; height estimated)');

-- Second Human Mage Dummy on the top floor and two more Pristine Black Dragon Eggs, one in each Rookery nest
-- (KfIRjSeLn4Y 02:18-02:30, where each party member loots their own egg). Spots and facings are estimated.
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9001374 AND 9001376;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
  `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9001374, 97444, 0, 0, 0, 1, 1, -9688.62, -1971.12, 99.49, 0.444, 0, 0, 0.2202, 0.9755, 120, 100, 1, '', 0, 'Human Mage Dummy (Red Mage Tower; second dummy seen in the videos along the wall; spot and facing estimated)'),
(9001375, 254685, 0, 0, 0, 1, 1, -9716.04, -2898.08, 53.6, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Pristine Black Dragon Egg (the Rookery, right nest; spot estimated)'),
(9001376, 254685, 0, 0, 0, 1, 1, -9713.55, -2900.57, 53.6, 0, 0, 0, 0, 1, 120, 100, 1, '', 0, 'Pristine Black Dragon Egg (the Rookery, left nest; spot estimated)');

-- Minervia's Past: video 3qfdpW_xSb0 (10:42-10:44) completes the objective while the player climbs the Tower of
-- Ilgalar's spiral stairs, before the Eye of Ilgalar is reached. A trigger bunny on the stairs gives the credit again;
-- the Eye's gossip credit of rev_20261010_98 stays. Spot and range are estimated; the height is a client WMO floor.
DELETE FROM `creature` WHERE `guid` = 9950431;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950431, 23837, 0, 0, 0, 1, 1, 0, -9271.0, -3311.0, 132.08, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'ELM General Purpose Bunny (Tower of Ilgalar stairs, credit for 254068 seen in the videos; spot estimated)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950431 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950431, 0, 0, 0, 10, 0, 100, 0, 1, 10, 1000, 1000, 1, 0, 33, 254969, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'ELM General Purpose Bunny - Within 10 Range Out of Combat LoS - Quest Credit ''Minervia''s Past''');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = -9950431
  AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, -9950431, 0, 0, 9, 0, 254068, 0, 0, 0, 0, 0, '', 'Tower of Ilgalar stair bunny - credit only on ''Minervia''s Past''');

-- Lakeshire NPCs where y03LWvmfnXM shows them: Solaina on the ground floor and Paien on the stairs of Lady Idelia
-- Solomon's house, Damion Tyndall at the loom upstairs in Luca Tyndall's house, the altar boys on the north side of
-- the altar. Contrary to rev_20261010_98 the chapel has pews: the congregation sits in the front pews facing the
-- altar, matched to the video by sex. Every spot is estimated; heights are client WMO floors.
UPDATE `creature` SET `position_x` = -9443, `position_y` = -2311, `position_z` = 75.29 WHERE `guid` = 9950417;
UPDATE `creature` SET `position_x` = -9448, `position_y` = -2293, `position_z` = 81.9 WHERE `guid` = 9950421;
UPDATE `creature` SET `position_x` = -9468, `position_y` = -2185, `position_z` = 74.98 WHERE `guid` = 9950410;
UPDATE `creature` SET `position_x` = -9424.9, `position_y` = -2076.4, `position_z` = 68.25, `orientation` = 4.7
  WHERE `guid` = 9950415;
UPDATE `creature` SET `position_x` = -9424.0, `position_y` = -2076.4, `position_z` = 68.25, `orientation` = 4.7
  WHERE `guid` = 9950416;
UPDATE `creature` SET `position_x` = -9424.7, `position_y` = -2082.5, `position_z` = 67.55, `orientation` = 1.57
  WHERE `guid` = 9950411;
UPDATE `creature` SET `position_x` = -9426.3, `position_y` = -2082.5, `position_z` = 67.55, `orientation` = 1.57
  WHERE `guid` = 9950412;
UPDATE `creature` SET `position_x` = -9432.2, `position_y` = -2086.5, `position_z` = 67.55, `orientation` = 1.57
  WHERE `guid` = 9950413;
UPDATE `creature` SET `position_x` = -9431.9, `position_y` = -2082.5, `position_z` = 67.55, `orientation` = 1.57
  WHERE `guid` = 9950414;

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9950411 AND 9950414;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
  `visibilityDistanceType`, `auras`) VALUES
(9950411, 0, 0, 5, 0, 0, 0, ''),
(9950412, 0, 0, 5, 0, 0, 0, ''),
(9950413, 0, 0, 5, 0, 0, 0, ''),
(9950414, 0, 0, 5, 0, 0, 0, '');
