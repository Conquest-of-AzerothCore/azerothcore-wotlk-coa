-- Westfall quests restored in rev_20261004_10 had no progress or completion text. Fill both from the HideXs
-- archive where it has them; its description and objectives match the client questcache for every quest here.
-- 26994 and 100466 have no progress text in the archive and get none.

DELETE FROM `quest_request_items` WHERE `ID` IN (1313, 17009, 17011, 17012, 17014, 26993, 26995, 26996, 26997, 255057, 999913, 999914, 999933);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`) VALUES
(1313, 'Did you find them all...?'),
(17009, 'This must be the chest spoken of from the map!'),
(17011, 'Have you done it, $N? Are the gnolls all dead?'),
(17012, 'I''d like to picture the screams of every gnoll you slay. How many have you slain so far?'),
(17014, 'Have you dealth with the Harvest Reapers, $N?'),
(26993, 'Is my farm safe?'),
(26995, 'There are golems to be killed! Westfall is in dire need of help.'),
(26996, 'Have you killed the golems?'),
(26997, 'Are our farms reclaimed?'),
(255057, 'Well?'),
(999913, 'Did you manage to find him...?'),
(999914, 'Did you find it?'),
(999933, '<The Archivist blanches at the smell wafting from your pockets.>');

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1313, 17009, 17011, 17012, 17014, 26993, 26994, 26995, 26996, 26997, 100466, 255057, 999913, 999914, 999933);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(1313, 'Perfect timing. With these back in our hands, the wounded at Sentinel Hill stand a fighting chance. Well done.'),
(17009, 'This... doesn''t look like treasure. Then again... perhaps someone from the Explorers'' League would know more about this.'),
(17011, 'You''ve done a lot to help ease the pain of this poor ole'' farmer, $N. Like I said, it''s not much, but please take what I have left as payment.'),
(17012, 'Hah, I hope those gnolls never recover from the blow that you''ve dealt them this day! Again, it''s not much, but please accept my humble offer as payment for what you''ve done for me.'),
(17014, 'The kindness of others never ceases to amaze me, $N. With your call to duty, I imagine you will go on to do great things for the Alliance.'),
(26993, 'Thank you so much $N! Do you think you could help a friend of mine with their golem problem, too?'),
(26994, 'Furlbrow sent you? Bless the lands, I could use a hand around here!'),
(26995, 'Ah, excellent work. Each golem dead is a step towards freedom!'),
(26996, 'Our farms are one step closer to being the property of Westfall''s citizens again. There is just one farm left to reclaim!'),
(26997, '<Farmer Saldean cheers.>$B$BWestfall is free again! The golems are gone and our farms are ours again! Thanks for your assistance $N, and if you ever need anything, don''t hesitate to stop by.'),
(100466, 'Welcome to Sentinel Hill. You''re just in time, danger is afoot..'),
(255057, 'Nice work.$B$BThey obviously need more practice. I hope they can hold their own against you sooner rather than later, we need all the manpower we can get.'),
(999913, 'The patroller has been killed and cannot return with her information to the Archivist.'),
(999914, 'Oh... oh I see....$B$BI had a feeling, even if I tried to deny such a thing. I could only hope that his papers were missing because of carelessness, or laziness, but to know his reasons are far more grim...$B$BI hope that he was the only one who befell such a fate. But if you do find any others, please return with their reports and inform me of their fates. Now if you''ll excuse me, I need a moment to myself...'),
(999933, 'Disgusting, but vital... I will try to clean this and decipher it as best as I can.$B$BEven if it''s dirty work, I owe it to that protector. Thank you.');
