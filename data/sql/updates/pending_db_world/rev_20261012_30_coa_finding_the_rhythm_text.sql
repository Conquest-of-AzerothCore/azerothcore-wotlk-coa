-- "Finding the Rhythm" (255079) and "Dancing to the Beat" (255080) showed blank progress/completion windows:
-- quest_request_items and quest_offer_reward had no row for them. Text as shown by Ascension (issue #7416).
DELETE FROM `quest_request_items` WHERE `ID` IN (255079,255080);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`) VALUES
(255079, 'What do you need, friend?'),
(255080, 'Ya'' back! Did ya get dat drum yet?');

DELETE FROM `quest_offer_reward` WHERE `ID` IN (255079,255080);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(255079, 'In need of a drum you say?$B$BYou''ve come to the right place, my leatherworking skills are the finest in all the Barrens!'),
(255080, 'By de loa look at dat!$B$BA well crafted drum and a big ol'' drumstick!$B$BDis is surely to lift ma sister''s heavy heart! Spirits be wit ya mon!');
