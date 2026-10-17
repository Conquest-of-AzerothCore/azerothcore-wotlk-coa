-- White-Glove Mischief and From Grain to Flour: the custom copies (9920010, 9920021) are the working ones - the C++ script
-- spell_coa_stormwind_quests.cpp drives them by those ids (opening Little Mickey's flask in the Petitioner's Chamber; grinding
-- at the Dunshire mill). Keep them and retire the Pale Reach duplicates 175022 and 175029 instead (corrects rev_20261016_22).
DELETE FROM `creature_queststarter` WHERE `quest` IN (175022, 175029, 9920010, 9920021);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164026, 9920010),
(164035, 9920021);
DELETE FROM `creature_questender` WHERE `quest` IN (175022, 175029, 9920010, 9920021);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164026, 9920010),
(164034, 9920021);
DELETE FROM `quest_template_addon` WHERE `ID` = 175030;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES
(175030, 9920021);
