-- Duskwood restore dialogue from Ascension captures. Progress and reward texts and the Reunited talk are transcribed
-- from MatodanDLC's recordings: jLBZUj7KUhw (2026-07-20) for 254086-254091 (0:03:08, 1:12:31, 1:40:05, 1:51:39 and
-- 1:52:29) and the Reunited talk (1:51:37-1:52:24); Dqaoz1Ls6xk (2026-07-19) for 255074 (0:22:07), 255068 (0:32:17)
-- and 255069 (0:32:45); 6QNRME4U5pY (2026-07-19) for 255067 (1:35:21); 7Klf_HWwngk (2026-08-16, 0:01:31) and
-- 6QNRME4U5pY (0:35:44) for 255071; JqXNTd-9MFA (2026-08-16) for 255073 (0:10:00) and 255072 (0:10:38). Emotes are
-- not visible and are left at 0.
DELETE FROM `quest_request_items` WHERE `ID` IN (254088,254089,255067,255068,255074);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`)
  VALUES
(254088, 0, 0, 'I don''t know if the bandits would have left anything valuable, but maybe there''s something he''ll recognize.', 0),
(254089, 0, 0, 'He won''t say anything, but I''m certain it''s him. I''d thought maybe, before you have got here, he...\n\nI know. It''s rare that worgen retain even a trace of who they once were. It was just a selfish hope, nothing more.', 0),
(255067, 0, 0, 'These rings, I''ve...seen them before...', 0),
(255068, 0, 0, 'Did you find the gems? I won''t blame you if you didn''t, those ogres are quite frightening.', 0),
(255074, 0, 0, 'Have something for me?', 0);

DELETE FROM `quest_offer_reward`
  WHERE `ID` IN (254086,254087,254088,254089,254091,255067,255068,255069,255071,255072,255073,255074);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`,
  `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(254086, 0, 0, 0, 0, 0, 0, 0, 0, 'See what I mean now, might be talking a bit, but he ain''t saying anything useful.\n\nGot a name out of him you say? Julie? That''s more than we''ve got I reckon.\n\nNow where''ve I heard that name before...', 0),
(254087, 0, 0, 0, 0, 0, 0, 0, 0, '<The woman looks to be on the verge of tears, but she composes herself some as you approach.>\n\nHello. May I help you with something?\n\nA worgen spoke my name...?\n\nArvis, is this what you''ve become? Sorry...I need a moment...', 0),
(254088, 0, 0, 0, 0, 0, 0, 0, 0, 'That old book...so it survived then? Arvis was trying to write a book in whatever spare time he had after managing the farm...he had a whole series in mind actually...\n\n<Tears stream down the woman''s cheek.>\n\nI''m sure he''ll recognize it. He has to. If there''s anything still left of him, he has to.', 0),
(254089, 0, 0, 0, 0, 0, 0, 0, 0, 'You brought the Nectar? Great, I suppose it''s about time we start.', 0),
(254091, 0, 0, 0, 0, 0, 0, 0, 0, 'Looks like it went feral again. A shame, would''ve talked to it myself some, but I figured the wife had a better chance.\n\nWe''d been thinking the worgen here were just wild beasts that used to be men, but that one mentioned something about a "Wolf Cult", and a leader. Ain''t that something?\n\nSeems we might''ve been going about this all wrong. I''ll make sure word gets back to our people in Darkshire, if the worgen have an actual goal we''d better stay vigilant.', 0),
(255067, 0, 0, 0, 0, 0, 0, 0, 0, 'These all belong to Eleanor''s past husbands, I forged them myself...\n\nShe wants me to melt these down for a new wedding ring doesn''t she?', 0),
(255068, 0, 0, 0, 0, 0, 0, 0, 0, 'Those will work perfectly! I''m glad it wasn''t too much trouble for you.\n\nHmm...\n\n<She analyzes the jewels closely.>\n\nYes, I believe these shall suffice in measuring up to even Eleanor''s standards!', 0),
(255069, 0, 0, 0, 0, 0, 0, 0, 0, 'Oh this ring is perfect for a woman of my stature! Seems I was right to trust in your capabilities.\n\nI look forward to the day I can wear this on my finger, it''s certainly my favorite of my collection so far.\n\nI''ll send for you when I need my next one. Now if you''ll excuse me, I have some prospects to tend to...', 0),
(255071, 0, 0, 0, 0, 0, 0, 0, 0, 'Who am I? Why...I''m known as Quill!\n\nMaster thrill seeker of all things bathed in darkness and shadow!', 0),
(255072, 0, 0, 0, 0, 0, 0, 0, 0, 'You found some locations for me to explore? Excellent! I shall make haste!\n\nBut, erm...they''re not TOO scary right?', 0),
(255073, 0, 0, 0, 0, 0, 0, 0, 0, 'You have my thanks, we will sleep well tonight!\n\n<Her gaze drifts back to Brutus, quietly chucking to herself.>\n\n...Some more than others.', 0),
(255074, 0, 0, 0, 0, 0, 0, 0, 0, 'Wolf meat?\n\n<Watcher Dodds grimaces.>\n\nSure, he''s right, it''s better than starving. As long as it''s cooked right it''s edible enough. I''ll make sure it gets put to use. Good work taking care of those ravagers.', 0);

-- Greetings: Ascension npccache.wdb captures (up to 2026-09-05), matching the recordings: the caged worgen's three steps
-- and Oswin Drake (jLBZUj7KUhw 0:02:51), Ryton Altham (jLBZUj7KUhw 1:53:32), Eleanor Zemille (Dqaoz1Ls6xk 0:32:45),
-- Quill the Foolish and Quartermaster Fenrich (7Klf_HWwngk 0:01:30 and 0:04:01). The menu ids are new.
DELETE FROM `npc_text` WHERE `ID` IN (58094,58095,58096,115565,19402,120,71,69);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`,
  `em0_2`, `em0_3`, `em0_4`, `em0_5`, `text1_0`, `text1_1`, `BroadcastTextID1`, `lang1`, `Probability1`, `em1_0`,
  `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`, `text2_0`, `text2_1`, `BroadcastTextID2`, `lang2`, `Probability2`,
  `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`, `text3_0`, `text3_1`, `BroadcastTextID3`, `lang3`,
  `Probability3`, `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`, `text4_0`, `text4_1`, `BroadcastTextID4`,
  `lang4`, `Probability4`, `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`, `text5_0`, `text5_1`,
  `BroadcastTextID5`, `lang5`, `Probability5`, `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`, `text6_0`,
  `text6_1`, `BroadcastTextID6`, `lang6`, `Probability6`, `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
  `text7_0`, `text7_1`, `BroadcastTextID7`, `lang7`, `Probability7`, `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`,
  `em7_5`, `VerifiedBuild`) VALUES
(58094, '<The worgen growls at you through the cage>', '<The worgen growls at you through the cage>', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(58095, 'Fresh meat...\n\n<The worgen continues to growl through its words.>\n\nDie, meat, devour...', 'Fresh meat...\n\n<The worgen continues to growl through its words.>\n\nDie, meat, devour...\n\nJulie...run...', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(58096, '<For a brief moment, you can see a flash of recognition in the beast''s eyes.>\n\nJulie...run...\n\n<The recognition fades, and the worgen growls at you again.>', '<For a brief moment, you can see a flash of recognition in the beast''s eyes.>\n\nJulie...run...\n\n<The recognition fades, and the worgen growls at you again.>', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(115565, 'You’re either lost or looking for trouble, stranger. Either way, welcome to Blackthorn Garrison… the last place anyone wants to be stationed.\n\nWhy are we here? Because Duskwood ain''t getting any safer, that’s why. The Night Watch does what it can, but this place? It needs more than a few torches and sharp sticks to keep the horrors out. We’re here to keep the nightmares from spilling into Elwynn.\n\nThe fence? You’d think it’s to keep things out, but truth is… it’s just as much to keep things in.', 'You’re either lost or looking for trouble, stranger. Either way, welcome to Blackthorn Garrison… the last place anyone wants to be stationed.\n\nWhy are we here? Because Duskwood ain''t getting any safer, that’s why. The Night Watch does what it can, but this place? It needs more than a few torches and sharp sticks to keep the horrors out. We’re here to keep the nightmares from spilling into Elwynn.\n\nThe fence? You’d think it’s to keep things out, but truth is… it’s just as much to keep things in.', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(19402, 'What? Are you looking for something?\n\nThere''s nothing left here. Dead crops. Dead people. So many... dead.\n\nThe blight has taken everything. Even the earth feels it, its shadow seeps into the soil like poison. It''s unnatural... If I weren''t so stubborn, if I hadn''t insisted on staying in our home, maybe they''d still be here.\n\nIt''s just Minnie and I now. We''re all that''s left... and I still refuse to leave.\n\nLight save us both.', 'What? Are you looking for something?\n\nThere''s nothing left here. Dead crops. Dead people. So many... dead.\n\nThe blight has taken everything. Even the earth feels it, its shadow seeps into the soil like poison. It''s unnatural... If I weren''t so stubborn, if I hadn''t insisted on staying in our home, maybe they''d still be here.\n\nIt''s just Minnie and I now. We''re all that''s left... and I still refuse to leave.\n\nLight save us both.', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(120, 'It’s sweet, really - having four men compete for your attention.\n\nMakes you feel… appreciated. Powerful.', 'It’s sweet, really - having four men compete for your attention.\n\nMakes you feel… appreciated. Powerful.', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(71, 'Greetings friend, want to share my fire?\n\nIt''s quite dark out here, and there are some strange noises that give me goosebumps and send shivers down my spine.\n\n…Isn''t it great?!', 'Greetings friend, want to share my fire?\n\nIt''s quite dark out here, and there are some strange noises that give me goosebumps and send shivers down my spine.\n\n…Isn''t it great?!', 0, 0, 1, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(69, 'Another face in Darkshire… that makes three today.\n\nEither you’re brave, lost, or both. If you plan to head into the woods, you’ll want proper steel and dry rations.\n\nThe Night Watch doesn’t always get the chance to bring people back.', 'Another face in Darkshire… that makes three today.\n\nEither you’re brave, lost, or both. If you plan to head into the woods, you’ll want proper steel and dry rations.\n\nThe Night Watch doesn’t always get the chance to bring people back.', 0, 0, 100, 1, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (9950200,9950201,9950202,9950203,9950204,9950205,9950206,9950207);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES
(9950200, 58094),
(9950201, 58095),
(9950202, 58096),
(9950203, 115565),
(9950204, 19402),
(9950205, 120),
(9950206, 71),
(9950207, 69);

-- Option texts from jLBZUj7KUhw 0:03:01-0:03:03 and 7Klf_HWwngk 0:04:01; the cursor hides the punctuation after
-- 'hmm' in the worgen's last option, which is estimated. The worgen only answers while 'The Interrogation' is taken.
DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (9950200,9950201,9950202,9950203,9950204,9950205,9950206,9950207);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
  `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
  `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9950200, 0, 0, 'I don''t mean you any harm. I heard you might still remember your old life.', 0, 1, 1, 9950201, 0, 0, 0, '', 0, 0),
(9950201, 0, 0, 'Please, try to remember, you were a human once, weren''t you? What was your name?', 0, 1, 1, 9950202, 0, 0, 0, '', 0, 0),
(9950202, 0, 0, 'Julie, hmm? That might be the most I''ll get here.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(9950207, 0, 1, 'I want to browse your goods.', 0, 3, 128, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 9950200;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 9950200, 0, 0, 0, 9, 0, 254086, 0, 0, 0, 0, 0, '', 'Nightbane Worgen - show option only on ''The Interrogation''');

-- The Reunited talk after 'Addle's Stead' is turned in to Julie Addle, line by line as recorded, with Captain Aldric
-- Vayne's line (jLBZUj7KUhw 1:51:53), and Ryton Altham's lines about his pumpkins (jLBZUj7KUhw 1:53:17 and 1:53:29).
DELETE FROM `creature_text` WHERE `CreatureID` IN (764561, 254906, 764560, 255157);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(764561, 0, 0, 'Ju..lie?', 12, 0, 100, 0, 0, 0, 0, 0, 'Nightbane Worgen - May We Be Reunited 0'),
(764561, 1, 0, 'Julie, get away! I can''t fight it!', 12, 0, 100, 0, 0, 0, 0, 0, 'Nightbane Worgen - May We Be Reunited 1'),
(764561, 2, 0, 'You don''t understand, it''s not just me! The Wolf Cult, they''re after the source of the worgen! They called it the Scythe of...', 12, 0, 100, 0, 0, 0, 0, 0, 'Nightbane Worgen - May We Be Reunited 2'),
(764561, 3, 0, 'NO! My head is clear but I can still feel it creeping back, you cannot let me out! It''s safer for you if I stay here! It''s safer for everyone!', 12, 0, 100, 0, 0, 0, 0, 0, 'Nightbane Worgen - May We Be Reunited 3'),
(764561, 4, 0, 'The one that turned me is a worgen named Gervase, tell the Night Watch to find him!', 12, 0, 100, 0, 0, 0, 0, 0, 'Nightbane Worgen - May We Be Reunited 4'),
(254906, 0, 0, 'Arvis? You do recognize me! I knew you''re still there!', 12, 0, 100, 0, 0, 0, 0, 0, 'Julie Addle - May We Be Reunited 0'),
(254906, 1, 0, 'Don''t worry about me! Just try to remember, your name is Arvis Addle...', 12, 0, 100, 0, 0, 0, 0, 0, 'Julie Addle - May We Be Reunited 1'),
(254906, 2, 0, 'None of that matters now! We need to find a way to turn you back! No, if you can stay yourself it doesn''t matter if your form changes, I''ll tell the Night Watch to let you out!', 12, 0, 100, 0, 0, 0, 0, 0, 'Julie Addle - May We Be Reunited 2'),
(254906, 3, 0, 'I''ll tell them! Just...try to hold on a bit longer, alright?', 12, 0, 100, 0, 0, 0, 0, 0, 'Julie Addle - May We Be Reunited 3'),
(764560, 0, 0, 'Everything seems to be in order!', 12, 0, 100, 0, 0, 0, 0, 0, 'Captain Aldric Vayne - May We Be Reunited 0'),
(255157, 0, 0, 'What the hells happened to my pumpkins?!', 12, 0, 100, 0, 0, 0, 0, 0, 'Ryton Altham - Ambient 0'),
(255157, 1, 0, 'That''s what I get for using magic from the Defias...', 12, 0, 100, 0, 0, 0, 0, 0, 'Ryton Altham - Ambient 1');

-- Quartermaster Fenrich's shop in the order of his vendor window in 6QNRME4U5pY (2026-07-19, 1:01:52); Strong Rope is
-- also in the db.exil.es dump 2026-10-04 (npc_vendor) and the Exiles DB export (2026-09-12).
DELETE FROM `npc_vendor` WHERE `entry` = 751501;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(751501, 0, 4498, 0, 0, 0, 0),
(751501, 1, 4470, 0, 0, 0, 0),
(751501, 2, 29010, 0, 0, 0, 0),
(751501, 3, 29009, 0, 0, 0, 0),
(751501, 4, 4497, 0, 0, 0, 0),
(751501, 5, 159, 0, 0, 0, 0),
(751501, 6, 914470, 0, 0, 0, 0),
(751501, 7, 30816, 0, 0, 0, 0);
