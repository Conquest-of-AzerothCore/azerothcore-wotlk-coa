-- Gurubashi Arena gladiator chain from Ascension: 760000 "Warm Blooded Welcome" -> 760001 "No Chain, No Gain" ->
-- 760002 "The Final Roar", given by Gorguk Skullhook <Warlord of the Arena> at the camp outside the arena, next to
-- Roderic Gravetide. Ids, names, quest text, levels and rewards come from Ascension
-- (db.exil.es export, Rexxar client caches, gameplay video). Ascension's models 449284 and 449285 are not in our client,
-- so stand-in models are used. Boss stats and abilities, and the boss appearing in the arena on accept, are ours.

-- camp NPCs
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `RegenHealth`, `VerifiedBuild`) VALUES
(764795, 'Gorguk Skullhook', 'Warlord of the Arena', 60, 60, 35, 2, 1, 1.14286, 1, 768, 7, 'SmartAI', 5, 1, 0),
(764796, 'Roderic Gravetide', 'Warlord of the Arena', 60, 60, 35, 0, 1, 1.14286, 1, 768, 7, '', 5, 1, 0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `HealthModifier` = VALUES(`HealthModifier`), `RegenHealth` = VALUES(`RegenHealth`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (764795, 764796);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(764795, 0, 23864, 1, 1),
(764796, 0, 3167, 1, 1);
DELETE FROM `creature` WHERE `guid` BETWEEN 6976000 AND 6976005;
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(6976000, 764795, 0, 1, 1, -13359.5827, 139.9185, 17.3454, 4.597155, 300, 0, 0),
(6976001, 764796, 0, 1, 1, -13363.1789, 140.3941, 17.3265, 5.100601, 300, 0, 0);
-- Kingsblood node moved out of the camp
UPDATE `gameobject` SET `position_x` = -13327.8579, `position_y` = 164.8902, `position_z` = 17.0109 WHERE `guid` = 208850 AND `id` = 1624;

-- Gorguk's greeting (text from the gameplay video)
DELETE FROM `npc_text` WHERE `ID` = 764795;
INSERT INTO `npc_text` (`ID`, `text0_0`, `Probability0`) VALUES
(764795, 'We fight, we bleed, we break... all for a shot at the ring. Meals are hot, beds are dry, and the only fee is your pride. If you''ve got the guts to train with the rest of us, you''re welcome to stay.$B$BBut listen close: if you can''t best the fighters around you, you don''t eat. You don''t last. You vanish.$B$BGlory''s not handed out. You claw your way to it, same as the rest of us.', 1);
DELETE FROM `gossip_menu` WHERE `MenuID` = 764795;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (764795, 764795);
UPDATE `creature_template` SET `gossip_menu_id` = 764795, `npcflag` = 3 WHERE `entry` = 764795;

-- the three arena bosses (Ascension ids and models; elite, for a group of three)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `BaseAttackTime`, `unit_class`, `type`, `AIName`, `HealthModifier`, `RegenHealth`, `VerifiedBuild`) VALUES
(775897, 'Brakka', 'The Bonecrusher', 30, 30, 14, 1, 1.14286, 1, 2, 2000, 1, 7, 'SmartAI', 6, 1, 0),
(775898, 'Ironhide Gorefist', '', 31, 31, 14, 1, 1.14286, 1, 2, 2000, 1, 7, 'SmartAI', 7, 1, 0),
(775899, 'Majara', 'The Crimson Fang', 32, 32, 14, 1, 1.14286, 1, 2, 1600, 1, 7, 'SmartAI', 7, 1, 0) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `rank` = VALUES(`rank`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `HealthModifier` = VALUES(`HealthModifier`), `RegenHealth` = VALUES(`RegenHealth`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (775897, 775898, 775899);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(775897, 0, 24181, 1, 1), (775898, 0, 95376, 2, 1), (775899, 0, 328644, 3, 1);

-- Gorguk summons the quest's boss in the pit by the camp on accept; it leaves after 5 min out of combat
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (764795, 775897, 775898, 775899) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(764795, 0, 0, 0, 19, 0, 100, 0, 760000, 0, 0, 0, 0, 12, 775897, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Quest Accepted - Summon Brakka'),
(764795, 0, 1, 0, 19, 0, 100, 0, 760001, 0, 0, 0, 0, 12, 775898, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Quest Accepted - Summon Ironhide Gorefist'),
(764795, 0, 2, 0, 19, 0, 100, 0, 760002, 0, 0, 0, 0, 12, 775899, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Quest Accepted - Summon Majara'),
(764795, 0, 3, 0, 19, 0, 100, 0, 760000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Quest Accepted - Say Line 0'),
(764795, 0, 4, 0, 19, 0, 100, 0, 760001, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Quest Accepted - Say Line 1'),
(764795, 0, 5, 0, 19, 0, 100, 0, 760002, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Quest Accepted - Say Line 2'),
(775897, 0, 0, 0, 0, 0, 100, 0, 4000, 6000, 9000, 12000, 0, 11, 13737, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Brakka - In Combat - Cast Mortal Strike'),
(775897, 0, 1, 0, 0, 0, 100, 0, 8000, 10000, 15000, 18000, 0, 11, 6253, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Brakka - In Combat - Cast Backhand'),
(775897, 0, 2, 0, 2, 0, 100, 1, 0, 30, 0, 0, 0, 11, 3019, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Brakka - Between 0-30% Health - Cast Frenzy (No Repeat)'),
(775898, 0, 0, 0, 0, 0, 100, 0, 3000, 5000, 7000, 9000, 0, 11, 15496, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ironhide Gorefist - In Combat - Cast Cleave'),
(775898, 0, 1, 0, 0, 0, 100, 0, 6000, 8000, 14000, 16000, 0, 11, 6533, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Ironhide Gorefist - In Combat - Cast Net'),
(775898, 0, 2, 0, 0, 0, 100, 0, 10000, 12000, 16000, 20000, 0, 11, 8078, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ironhide Gorefist - In Combat - Cast Thunderclap'),
(775899, 0, 0, 0, 0, 0, 100, 0, 2000, 4000, 6000, 8000, 0, 11, 14873, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Majara - In Combat - Cast Sinister Strike'),
(775899, 0, 1, 0, 0, 0, 100, 0, 5000, 7000, 12000, 15000, 0, 11, 3147, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Majara - In Combat - Cast Rend Flesh'),
(775899, 0, 2, 0, 0, 0, 100, 0, 9000, 11000, 15000, 18000, 0, 11, 12540, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Majara - In Combat - Cast Gouge'),
(775899, 0, 3, 0, 2, 0, 100, 1, 0, 30, 0, 0, 0, 11, 3019, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Majara - Between 0-30% Health - Cast Frenzy (No Repeat)');

-- one boss per quest at a time: a group (or a second player) accepting while that boss is still alive in the pit
-- (~69 yd from Gorguk) joins the fight already running instead of summoning a copy; the same check guards the
-- fight option below when it is selected, since its gossip conditions are only checked when the menu opens
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 764795 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 764795, 0, 0, 29, 1, 775897, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - summon Brakka only if no Brakka is alive in the pit'),
(22, 2, 764795, 0, 0, 29, 1, 775898, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - summon Ironhide Gorefist only if none is alive in the pit'),
(22, 3, 764795, 0, 0, 29, 1, 775899, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - summon Majara only if no Majara is alive in the pit'),
(22, 7, 764795, 0, 0, 29, 1, 775897, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - fight option summons Brakka only if none is alive (two menus open at once)'),
(22, 8, 764795, 0, 0, 29, 1, 775898, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - fight option summons Ironhide Gorefist only if none is alive'),
(22, 9, 764795, 0, 0, 29, 1, 775899, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - fight option summons Majara only if none is alive');

-- retry (ours): while the quest is incomplete and its boss is not alive in the pit (it died for someone else, or
-- despawned after the player died), Gorguk offers to send in the opponent again
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 764795;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(764795, 0, 0, 'I''m ready for my fight.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(764795, 1, 0, 'I''m ready for my fight.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0),
(764795, 2, 0, 'I''m ready for my fight.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 764795;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 764795, 0, 0, 0, 9, 0, 760000, 0, 0, 0, 0, 0, '', 'Gorguk Skullhook - fight option while Warm Blooded Welcome is incomplete'),
(15, 764795, 0, 0, 0, 29, 1, 775897, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - and no Brakka is alive in the pit'),
(15, 764795, 1, 0, 0, 9, 0, 760001, 0, 0, 0, 0, 0, '', 'Gorguk Skullhook - fight option while No Chain, No Gain is incomplete'),
(15, 764795, 1, 0, 0, 29, 1, 775898, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - and no Ironhide Gorefist is alive in the pit'),
(15, 764795, 2, 0, 0, 9, 0, 760002, 0, 0, 0, 0, 0, '', 'Gorguk Skullhook - fight option while The Final Roar is incomplete'),
(15, 764795, 2, 0, 0, 29, 1, 775899, 100, 0, 1, 0, 0, '', 'Gorguk Skullhook - and no Majara is alive in the pit');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 764795 AND `source_type` = 0 AND `id` BETWEEN 6 AND 11;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(764795, 0, 6, 0, 62, 0, 100, 0, 764795, 0, 0, 0, 0, 12, 775897, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Gossip Option 0 Selected - Summon Brakka'),
(764795, 0, 7, 0, 62, 0, 100, 0, 764795, 1, 0, 0, 0, 12, 775898, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Gossip Option 1 Selected - Summon Ironhide Gorefist'),
(764795, 0, 8, 0, 62, 0, 100, 0, 764795, 2, 0, 0, 0, 12, 775899, 4, 300000, 0, 0, 0, 8, 0, 0, 0, 0, -13344.084, 207.1044, 5.9858, 4.755127, 'Gorguk Skullhook - On Gossip Option 2 Selected - Summon Majara'),
(764795, 0, 9, 0, 62, 0, 100, 0, 764795, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Gossip Option Selected - Close Gossip'),
(764795, 0, 10, 0, 62, 0, 100, 0, 764795, 1, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Gossip Option Selected - Close Gossip'),
(764795, 0, 11, 0, 62, 0, 100, 0, 764795, 2, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gorguk Skullhook - On Gossip Option Selected - Close Gossip');

-- Gorguk points the player to the pit (one line per quest, from the gameplay video)
DELETE FROM `creature_text` WHERE `CreatureID` = 764795;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(764795, 0, 0, 'Your first test waits in the pit. Do not keep it waiting.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gorguk Skullhook - Warm Blooded Welcome accepted'),
(764795, 1, 0, 'Challenger, the sand is ready. Bleed well.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gorguk Skullhook - No Chain, No Gain accepted'),
(764795, 2, 0, 'Challenger. The pit is waiting.', 12, 0, 100, 0, 0, 0, 0, 0, 'Gorguk Skullhook - The Final Roar accepted');

-- quests (Ascension text, levels, money, Booty Bay up / Bloodsail down; 760002 rewards from the Rexxar quest cache)
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `Flags`,
`RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`,
`RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`,
`RewardFactionID1`, `RewardFactionValue1`, `RewardFactionID2`, `RewardFactionValue2`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `VerifiedBuild`) VALUES
(760000, 2, 30, 25, 33, 1, 3, 7, 40000, 495, 10, 375250, 300, 1397886, 1, 1710, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 2, 87, -2,
'Warm Blooded Welcome', 'Slay Brakka the Bonecrusher in the Gladiator''s Arena.',
'You want to fight in the Arena? First, you''ll need to survive Brakka.$B$BBrakka the Bonecrusher once led a raiding party deep into Zul''Gurub. After smashing through trolls, beasts, and even a stone golem with nothing but his fists, he went looking for something harder to break.$B$BNow he fights for the crowd''s bone, blood, and glory.$B$BStep into the pit, and prove your bones are tougher than his fists.',
'Return to Gorguk Skullhook outside the Gurubashi Arena.', 775897, 1, 0),
(760001, 2, 30, 25, 33, 1, 3, 7, 40000, 495, 10, 375250, 300, 1397886, 1, 1710, 5, 6149, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 2, 87, -2,
'No Chain, No Gain', 'Slay Ironhide Gorefist in the Gladiator''s Arena.',
'Your next opponent is Ironhide Gorefist, a brutal ogre-blooded warbringer out of the Blackrock clan.$B$BHe''s brawled his way through half the Eastern Kingdoms. His signature chains echo through every fight like a death knell, ringing louder with every blow. When they start rattling, the crowd knows someone''s about to fall.$B$BThe crowd''s seen your first taste of blood. Now they want a feast. Give them Ironhide.',
'Return to Gorguk Skullhook outside the Gurubashi Arena.', 775898, 1, 0),
(760002, 2, 30, 25, 33, 1, 3, 7, 40000, 495, 10, 375250, 300, 0, 0, 0, 0, 0, 0, 217842, 1, 217844, 1, 217843, 1, 217845, 1, 217851, 1, 21, 2, 87, -2,
'The Final Roar', 'Slay Majara the Crimson Fang in the Gladiator''s Arena.',
'Only one stands between you and your place in the pit.$B$BMajara the Crimson Fang is not a brawler. She is a hunter. Cold. Precise.$B$BRaised in the jungle and shaped by the hunt. Some say the Gurubashi beastmasters trained her. Others say she hunted them for sport.$B$BShe does not roar. She waits. Watches.$B$BThis is not a fight. It is a test. Prove you are more than prey. Face Majara in the arena, and survive the hunter''s killstroke.',
'Return to Gorguk Skullhook outside the Gurubashi Arena.', 775899, 1, 0) ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `VerifiedBuild` = VALUES(`VerifiedBuild`);
-- turn-in texts (gameplay video)
DELETE FROM `quest_offer_reward` WHERE `ID` IN (760000, 760001, 760002);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`) VALUES
(760000, 'So Brakka''s down, huh? I''ll be honest, I didn''t expect your bones to hold up.$B$BThat was your first real step into the pit. You''ve tasted the blood, felt the roar of the crowd. Doesn''t get any easier from here.$B$BBrakka''s just the warm-up. The real monsters are still waiting.'),
(760001, 'So... the brute finally fell. I didn''t think you''d last more than a minute against him, but here you are, bloodied and still breathing.$B$BThat wasn''t just a fight, you won the respect of the old hands, the coin-tossers, and the killers who''ve seen it all. You''re one step closer to earning your place in the arena''s legend.$B$BDon''t get comfortable. The next challenge will hit even harder.'),
(760002, 'You lived through it. You beat Majara.$B$BNot many do. That roar of hers? That was the sound of a killer who knew she finally met her match.$B$BYou''ve fought beasts, brutes, and bloodletters and come out standing.$B$BThe crowd knows your name now. Welcome to the arena... gladiator.');
DELETE FROM `quest_template_addon` WHERE `ID` IN (760000, 760001, 760002);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (760000, 0, 760001), (760001, 760000, 760002), (760002, 760001, 0);
DELETE FROM `creature_queststarter` WHERE `quest` IN (760000, 760001, 760002);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (764795, 760000), (764795, 760001), (764795, 760002);
DELETE FROM `creature_questender` WHERE `quest` IN (760000, 760001, 760002);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (764795, 760000), (764795, 760001), (764795, 760002);

-- #11738: the weapons are rewards of "The Final Roar" now, so their #8904 worldforged pickups go (hidden, not deleted)
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6975023, 6975026, 6975027, 6975028) AND `id` IN (1345016, 1345007, 1345043, 1345080);
