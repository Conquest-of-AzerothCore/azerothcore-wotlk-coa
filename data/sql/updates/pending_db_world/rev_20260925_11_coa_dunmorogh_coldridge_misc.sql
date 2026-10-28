-- CoA Coldridge Valley: Efry Cogspark's Nylrisa chain 254000-254002 with Mountaineer Tagnur and the two
-- security bots, six more Rockjaw Raiders in the Coldridge Pass tunnel, and Mountaineer Thalos on his CoA
-- post. Creature guids 9008400-9008479.

-- ---------------------------------------------------------------------------
-- 1. Creatures of the chain
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(254002, 'Mountaineer Tagnur', NULL, 932231, 57, 57, 0, 55, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 5, 1, 1, 1, 2, ''),
(254004, 'Damaged Security Bot', NULL, 0, 1, 1, 0, 72, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 9, 0, 254004, '', 0, 2.232, 1, 1, 1, 0, ''),
(254005, 'Security Bot AN-32', NULL, 0, 1, 1, 0, 72, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 9, 0, 254005, '', 0, 2.232, 1, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254002, 254004, 254005);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(254002, 0, 254000, 1, 1),
(254004, 0, 15200, 1, 1),
(254005, 0, 8369, 1, 1);

-- CoA displays 254000 (Tagnur) and 254001 (Efry, migration 07) lack model info; values of stock displays
-- of the same models (53, 5435).
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (254000, 254001);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(254000, 0.347, 1.5, 0, 0),
(254001, 0.3519, 1.725, 1, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (254002, 254004, 254005);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(254002, 1, 2023, 0, 2552);

-- Greetings: npccache 52000 (Efry, template in migration 07) and 52001 (Tagnur).
DELETE FROM `npc_text` WHERE `ID` IN (52000, 52001);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(52000, 'Ah, I just need to change...no, that''s not it. Come on!$B$BOh, hey there, I didn''t see you! No, I''m doing perfectly fine, thanks! ...Okay, maybe I could actually use some help.', 'Ah, I just need to change...no, that''s not it. Come on!$B$BOh, hey there, I didn''t see you! No, I''m doing perfectly fine, thanks! ...Okay, maybe I could actually use some help.', 0, 0, 1),
(52001, 'Aye, hello there. Dangerous parts these are, ye''d best be careful.', 'Aye, hello there. Dangerous parts these are, ye''d best be careful.', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932230, 932231);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932230, 52000),
(932231, 52001);

UPDATE `creature_template` SET `gossip_menu_id` = 932230, `npcflag` = `npcflag` | 1 WHERE `entry` = 254000;

-- ---------------------------------------------------------------------------
-- 2. Drops
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE `Entry` IN (254004, 254005);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(254004, 254000, 0, 100, 1, 1, 0, 1, 1, 'Damaged Security Bot - Security Bot AN-29 (254000)'),
(254005, 254001, 0, 100, 1, 1, 0, 1, 1, 'Security Bot AN-32 - Security Bot AN-32 (254001)');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (254004, 254005);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(254004, 0, 254000),
(254005, 0, 254001);

-- ---------------------------------------------------------------------------
-- 3. Quests
-- ---------------------------------------------------------------------------
-- Paragraph breaks from the AscensionES archive (dEN).
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`, `AllowableRaces`)
VALUES
(254000, 2, -1, 1, 132, 0, 0, 0, 0, 0, 0, 254001, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 828, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Small Mistake', 'Search the Frostmane Encampment for Clues.', 'Oh blast it all! This is bad…this is really bad…hey, you! Yeah, you! You want a job? Good. I’ve got one. Okay, calm down Efry, calm down…$B$BSo I was making a bot and I tried to make it smart! I was going to make a bot slow down, sorry. I made a bot, Intelligent Automated Security Guardian, or Nylrisa. What, you think I’m gonna go around calling it Iasg? No way! Nylrisa is my pride and joy, why, she’ll shape our concept of technology as we know it! Why, she’s probably a better strategist than you or I! With Nylrisa guarding your home, even a team of coordinated adventurers wouldn’t stand a chance!$B$BAt least…that was the idea…$B$BNylrisa has gone rogue. She left, who knows where, but with everything she’s capable of…well, this really isn’t good. I mean, I sorta gave her the ability to control bots and…look, this wasn’t supposed to happen, okay? Look, she attacked the Frostmane trolls over nearby, seems like she didn’t finish the job, but maybe she left something behind.', '', 'Return to Efry Cogspark at Coldridge Valley in Dun Morogh.', 0, 0, 0, 0, 0, 0, 0, 0, 254000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Search for clues to Nylrisa''s location.', '', '', '', 1101),
(254001, 2, -1, 1, 132, 0, 0, 0, 0, 0, 0, 254002, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'We Found Her!', 'Search for Nylrisa to the south-west of Brewnall Village.', 'Alright, I got it! She’s not even that far out, just in the south end of Coldridge Valley. You should hurry before she leaves, and…you might have to destroy her, but try not to damage the internal components more than you have to. I just need to figure out what happened, make a few adjustments, and everything will be good, I swear!$B$BBut she’s still a danger right now, so get moving and go shut her down! I’ll…figure the rest out later.', '', 'Return to Efry Cogspark at Coldridge Valley in Dun Morogh.', 0, 0, 0, 0, 0, 0, 0, 0, 254001, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Search for Nylrisa', '', '', '', 1101),
(254002, 2, 2, 1, 132, 0, 0, 0, 0, 0, 0, 254003, 5, 0, 67, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 5, 0, 54, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Scout''s Favor', 'Slay 4 Rockjaw Raiders and meet with Mountaineer Tagnur on the other end of the tunnel.', 'No idea if Nylrisa''s actually targetting the Frostmanes, but I don''t have any other leads right now, so let''s try and find that exile and see if she knows anything we don''t.$B$BAlright, now, if I were an exiled troll, where would I be? Well, anywhere that isn’t one of the main encampments probably. Oh that really doesn’t narrow it down, does it? Wait, I know, I overheard this from a scout, maybe he saw more! The scout went up through the tunnel, you might’ve passed by him earlier even. Go find him, ask him what he knows!$B$BI’m heading to Thelsamar, maybe see if any of the dwarves there saw anything. Meet me there after you’re done and let me know if you got anything out of that troll, kay? Oh, uh, clear some troggs out of that tunnel while you’re there, might make that dwarf more open to chatting. Also, so I can actually get through…', '', 'Speak with Mountaineer Tagnur', 1718, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 1101)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`), `AllowableRaces` = VALUES(`AllowableRaces`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (254000, 254001, 254002);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(254000, 0, 0, 0, 0, 0),
(254001, 0, 0, 254000, 0, 0),
(254002, 0, 0, 254001, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (254000, 254001, 254002);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(254000, 'You found something…let me see! Yeah, that’s it, that’s one of the bots she has control over! Hmm, the signal goes both ways so…just give me a moment…I should be able to track her down from this.'),
(254001, 'Another bot? So she wasn’t there? Wait, that means…oh this really isn’t good. Nylrisa figured out how to redirect the signal. Send it to this random thing, and she’s off who knows where.$B$BHmm, we need another plan. You said you found this near the Frostmane encampment? I’m noticing a trend…we need to figure out what she’s been doing, and the only people who know that are the Frostmane Trolls. The ones that…attack us on sight. There may just be one we can ask though. There’s one some of the scouts were talking about, that was separated from the tribe. Seemed wary of them even. And if she’s wary of the other trolls, that means maybe this one doesn’t get along with them. An exile or something.$B$BAnd the enemy of our enemy is our friend, right?'),
(254002, 'Here for an exiled troll? Aye, I might know somethin’ like that.$B$BCleared out the tunnel, huh? Dunno about that, those troggs always seem ta keep crawlin’ back, but it’s a start at least. Sure, that’s enough to tell ye what I saw, not sure what ye need it for. Exiled or not, only good troll’s a dead one if ye ask me.');

DELETE FROM `quest_request_items` WHERE `ID` IN (254000, 254001, 254002);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(254000, 'Find anything yet? Come on, there''s gotta be something there!'),
(254001, 'Um, be careful, as I said, Nylrisa is pretty dangerous so...look, we don''t have time to gather an army so this is all on you!$B$BNo pressure...scrap that, lots of pressure, all the pressure, come on, get moving!'),
(254002, 'I''m sure he''ll tell you, but, better clear out the troggs to be sure...I really don''t feel like waiting for an escort to Kharanos');

DELETE FROM `creature_queststarter` WHERE `quest` IN (254000, 254001, 254002);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(254000, 254000),
(254000, 254001),
(254000, 254002);

DELETE FROM `creature_questender` WHERE `quest` IN (254000, 254001, 254002);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(254000, 254000),
(254000, 254001),
(254002, 254002);

-- ---------------------------------------------------------------------------
-- 4. Spawns: Tagnur, the two bots and the Coldridge Pass Raiders
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9008400, 9008401, 9008402, 9008410, 9008411, 9008412, 9008413, 9008414, 9008415) OR `guid` BETWEEN 9008400 AND 9008479;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9008400, 254002, 0, 0, 0, 1, 1, 1, -5923.73, 17.851, 366.15, 1.95, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Kharanos end of the Coldridge Pass road: the turn-in point ST1090 of 254002 (SOURCED-CLIENT, Questie 2.5 yd), at the north end of the ruined steam tank; faces up the road toward the pass exit, the way players come'),
(9008401, 254004, 0, 0, 0, 1, 1, 0, -6340.81, 802.589, 390.731, 3, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: foot of the pine slope east of the Frostmane Troll Whelp camp north of the troll cave: the objective point ST55 of 254000 (SOURCED-CLIENT, Questie 0.5 yd); faces the whelps it was sent against'),
(9008402, 254005, 0, 0, 0, 1, 1, 0, -6416.3, 452.161, 383.113, 6.02, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: south end of the valley among the Ragged Timber Wolves: the objective point ST54 of 254001 (SOURCED-CLIENT; its z floats 1.8, so z is the terrain floor); faces up the valley toward Anvilmar, where players come from'),
(9008410, 1718, 0, 0, 0, 1, 1, 1, -6190, 122, 429.924, 3.84, 180, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), the bend 26 yd inside the west mouth, between the stock Raiders 326 and 323 and 36 yd from the Coldridge Mountaineers; faces down the corridor toward the mouth'),
(9008411, 1718, 0, 0, 0, 1, 1, 1, -6155, 116, 420.888, 2.38, 180, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), the upper chamber at the head of the ramp, between the stock Raiders 323 and 321; faces the bend where players come in'),
(9008412, 1718, 0, 0, 0, 1, 1, 1, -6160, 62, 413.138, 1.52, 180, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), main chamber, by the excavation tent and barrels, 15 yd west of the stock pair 318/1553; faces the foot of the ramp'),
(9008413, 1718, 0, 0, 0, 1, 1, 1, -6140, 72, 416.303, 2.14, 180, 4, 0, 71, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), open middle of the main chamber, roaming between the tent and the east corridor; faces the ramp'),
(9008414, 1718, 0, 0, 0, 1, 1, 1, -6108, 65, 415.448, 2.93, 180, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), east corridor beside the dwarven brazier, between the stock Raiders 319 and 1556; faces back toward the main chamber'),
(9008415, 1718, 0, 0, 0, 1, 1, 1, -6090, 55, 412.618, 2.63, 180, 0, 0, 71, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass tunnel (Anvilmarpass.wmo floor), east corridor halfway between the stock Raiders 1556 and 1562, 63 yd short of the caravan stop; faces back down the corridor');

-- ---------------------------------------------------------------------------
-- 5. Mountaineer Thalos on his CoA post
-- ---------------------------------------------------------------------------
-- Mountaineer Thalos (331) to the turn-in point ST1241 of 282; stock facing kept.
UPDATE `creature` SET `position_x` = -6240.28, `position_y` = 136.578, `position_z` = 430.929 WHERE `guid` = 331 AND `id` = 1965;
