-- Conquest of Azeroth continued the Spada storyline from Northshire into Goldshire: Bianca's maid,
-- Lady Agria's failing health and the curse her majordomo blames on a broken mirror, a mad woman's
-- kobolds, the refugees in the shadow of the new town hall, and a historian who wants a moment of your
-- time. None of it exists in this world. This restores the six quests 1660055-1660060.
--
-- WHERE EACH VALUE COMES FROM
--   quests, creatures, objects  the realm's own client cache (data-cache-945cd3b8b0ce4a496586). Every quest
--     and reward item already exists in item_template, so no item is written here.
--   places  CoA rebuilt Goldshire, and its client terrain (patch-WB1) shows where: the Spada Family Manor
--     (AreaTable 10217) on the hill above Mirror Lake, the town hall on the old faire ground with a refugee
--     camp against it, a market plaza where the Lion's Pride Inn stood (the inn moved 39 yards south-east),
--     and crop plots for melons, pumpkins and apples. Floors come from the server collision data.
--   who stands where  the client's QuestSuperTrack points place Dulcinea, Aldia Crayon (the manor's top
--     floor), Clara the Mad (the refugee camp), Eldor Hammer, Aliscar Lend (the east entrance arch), his
--     projection (on top of the arch) and the four vendors. The rest is INFERRED from the places.
--   shards, crops  INFERRED: hand-placed at landmarks of the places the quest texts name; each
--     spawn's Comment gives the landmark.
--   warrens  the Kobold Warren sightings of Questie-X-AscensionDB (Bronzebeard), zone percent converted
--     with WorldMapArea 30: the spur, flanks and terrace from the refugee camp down toward Fargodeep
--     Mine. One sighting lies inside an oak's trunk; that warren stands just east of the tree.
--   vendors  the four market sellers and their ingredients are tied together by the cache (questItem).
--   appearance  STAND-IN displays: every CoA display of this cast is missing from the client.
--   credits  the Mirror Shard and Kobold Warren objects credit their hidden markers when used, then
--     despawn until they respawn. 'Stay a While': the option sends the player to the gatehouse tower top
--     (objective point 8843) with CoA's Teleporting visual 267032, cast only by Aliscar and his projection;
--     the projection gives the lesson, then credits and sends the player back to the stall. Only its opener
--     (85160) and 'A mighty view' (85159) are sourced; the lesson lines are INFERRED. After the second
--     line the projection offers 'I've heard enough', which credits and sends the player down at once.
--     The projection is translucent (37800) with purple arcane motes (28126) and hovers.
--   ambush  from PR #5751 (PithoDalle): destroying a Kobold Warren (a 3 s cast with a fire burst,
--     go_coa_abbess_relic) has a 50% chance to release a Kobold Prospector (162915) that attacks.
--   dialogue  the greetings of Aliscar Lend (85190) and the mayor (85163, 85164) are from the cache, as
--     is the projection's (85160, linked to it by its words about the view from the arch: INFERRED).
--
-- Spawn guid blocks: creature 9002000-9002199, gameobject 7911000-7911199.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `rank`, `unit_class`, `unit_flags`, `type`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `gossip_menu_id`)
VALUES
(162800, 'Dulcinea', 'Maid of House Spada', 8, 8, 0, 12, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 0),
(162802, 'Aldia Crayon', 'Majordomo', 10, 10, 0, 12, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 0),
(162803, 'Lady Agria Spada', NULL, 8, 8, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 0),
(162805, 'Clara the Mad', NULL, 8, 8, 0, 12, 2, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162806, 'Aliscar Lend', NULL, 12, 12, 0, 12, 3, 0, 8, 0, 7, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, 0, 85190),
(162807, 'Harvend Thorm', 'Mayor of Goldshire', 10, 10, 0, 12, 3, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 85163),
(162801, 'Eldor Hammer', 'Westfall Refugee', 8, 8, 0, 12, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 0),
(162814, 'Ainora', 'Florist', 10, 10, 0, 12, 128, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162811, 'Darron', NULL, 10, 10, 0, 12, 128, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162809, 'Rowena', NULL, 10, 10, 0, 12, 128, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162826, 'Joaquin', NULL, 10, 10, 0, 12, 128, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162808, 'Thalira Conacher', NULL, 8, 8, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0, 0),
(162817, 'Westfall Refugee', NULL, 5, 5, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162818, 'Westfall Refugee', NULL, 5, 5, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162819, 'Westfall Refugee', NULL, 5, 5, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162820, 'Westfall Refugee', NULL, 5, 5, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162821, 'Goldshire Farmer', NULL, 6, 6, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.93, 1, 1, 1, 0, 0, 0),
(162822, 'Goldshire Farmer', NULL, 6, 6, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162823, 'Goldshire Farmer', NULL, 6, 6, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162824, 'Goldshire Farmer', NULL, 6, 6, 0, 12, 0, 0, 1, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 0, 0),
(162943, 'Arcane Projection of Aliscar', NULL, 12, 12, 0, 35, 0, 0, 8, 0, 7, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, 162921, 85160),
(162920, '[TG] kharanos hops', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0, 0),
(162921, '[KC] Listen to Aliscar Lend', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0, 0),
(162940, '[KC] Kobold Warren Destroyed', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0, 0),
(162915, 'Kobold Prospector', NULL, 6, 7, 0, 26, 0, 0, 1, 0, 7, 40, '', 0, 1, 1, 1, 1, 0, 0, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `gossip_menu_id` = VALUES(`gossip_menu_id`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (162800, 162801, 162802, 162803, 162805, 162806, 162807, 162808, 162809, 162811, 162814, 162817, 162818, 162819, 162820, 162821, 162822, 162823, 162824, 162826, 162915, 162920, 162921, 162940, 162943);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162800, 0, 3367, 1, 1),
(162802, 0, 8632, 1, 1),
(162803, 0, 1544, 1, 1),
(162805, 0, 2959, 1, 1),
(162806, 0, 5080, 1, 1),
(162807, 0, 1753, 1, 1),
(162801, 0, 1944, 1, 1),
(162814, 0, 1441, 1, 1),
(162811, 0, 3370, 1, 1),
(162809, 0, 1443, 1, 1),
(162826, 0, 3361, 1, 1),
(162808, 0, 5552, 1, 1),
(162817, 0, 18616, 1, 1),
(162818, 0, 18617, 1, 1),
(162819, 0, 18618, 1, 1),
(162820, 0, 18619, 1, 1),
(162821, 0, 3534, 1, 1),
(162822, 0, 3703, 1, 1),
(162823, 0, 1943, 1, 1),
(162824, 0, 3324, 1, 1),
(162943, 0, 5080, 1, 1),
(162920, 0, 11686, 1, 1),
(162921, 0, 11686, 1, 1),
(162940, 0, 11686, 1, 1),
(162915, 0, 139, 1, 0.5),
(162915, 1, 373, 1, 0.5);

DELETE FROM `creature_template_addon` WHERE `entry` IN (162803, 162943);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(162803, 0, 0, 3, 1, 0, 0, NULL),
(162943, 0, 0, 0, 1, 0, 0, '37800 28126');

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 162943;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`)
VALUES
(162943, 2, 0, 1, 1, 0, 0);

UPDATE `creature_template` SET `HoverHeight` = 1.5 WHERE `entry` = 162943;
DELETE FROM `npc_vendor` WHERE `entry` IN (162809, 162811, 162814, 162826);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`)
VALUES
(162814, 0, 558956, 0, 0, 0),
(162811, 0, 558957, 0, 0, 0),
(162809, 0, 558958, 0, 0, 0),
(162826, 0, 558959, 0, 0, 0);

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (162809, 162811, 162814, 162826);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(162814, 0, 558956),
(162811, 0, 558957),
(162809, 0, 558958),
(162826, 0, 558959);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` IN (85160, 85163, 85164, 85190);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`)
VALUES
(85160, 'Best views in all Goldshire, believe me! Well… except for the town hall clock tower.', 'Best views in all Goldshire, believe me! Well… except for the town hall clock tower.', 0, 1),
(85163, '<The mayor can’t help the flicker of a smile when his eyes meet Thalira Conacher’s across the great hall.>', '<The mayor can’t help the flicker of a smile when his eyes meet Thalira Conacher’s across the great hall.>', 0, 1),
(85164, 'The kingdom is divided into provinces, which in turn are divided into smaller territories. There’s still a feudal administration, with various noble families heading each region, but all are subordinate to the authority of the crown.$b$bThis part of Elwynn belongs to the Bruck family’s estate, on whose behalf I serve as mayor. While the Brucks enjoy the well-earned comforts of their centuries-old manor, I handle Goldshire’s governance and justice in accordance with their wisdom and the laws of the realm.$b$bOther noble families in Elwynn, like the Spada, Herbad, Locker, or Feandor, limit themselves to managing their holdings and properties, or what remains of them. Many have little left of nobility but the title.', 'The kingdom is divided into provinces, which in turn are divided into smaller territories. There’s still a feudal administration, with various noble families heading each region, but all are subordinate to the authority of the crown.$b$bThis part of Elwynn belongs to the Bruck family’s estate, on whose behalf I serve as mayor. While the Brucks enjoy the well-earned comforts of their centuries-old manor, I handle Goldshire’s governance and justice in accordance with their wisdom and the laws of the realm.$b$bOther noble families in Elwynn, like the Spada, Herbad, Locker, or Feandor, limit themselves to managing their holdings and properties, or what remains of them. Many have little left of nobility but the title.', 0, 1),
(85190, 'Welcome, $C.$b$bMy name is Aliscar Lend; mage, sorcerer, and public advisor for Goldshire.', 'Welcome, $C.$b$bMy name is Aliscar Lend; mage, sorcerer, and public advisor for Goldshire.', 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (85160, 85163, 85164, 85190);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(85160, 85160),
(85163, 85163),
(85164, 85164),
(85190, 85190);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (85160, 85163, 85190);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(85160, 0, 0, 'Thank you, I''ve heard enough.', 0, 1, 1, 0, 0, 0, 0, '', 0),
(85163, 0, 0, 'Who governs Goldshire?', 0, 1, 1, 85164, 0, 0, 0, '', 0),
(85190, 0, 0, 'I have a moment. Tell me about Goldshire.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 85190;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 85190, 0, 0, 0, 9, 0, 1660060, 0, 0, 0, 0, 0, '', 'Aliscar Lend - the history lesson only while Stay a While is taken');

-- ---------------------------------------------------------------------------
-- 3. World objects
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300546, 10, 1061017, 'Mirror Shard', '', 1, 'SmartGameObjectAI', 0, 1660057, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300547, 3, 60, 'Pumpkin', '', 0.5, '', 1689, 2300547, 0, 1, 0, 0, 0, 0, 1660059, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300548, 3, 332, 'Melon', '', 0.7, '', 1689, 2300548, 0, 1, 0, 0, 0, 0, 1660059, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300549, 3, 433, 'Apple', '', 0.5, '', 1689, 2300549, 0, 1, 0, 0, 0, 0, 1660059, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300579, 10, 1017889, 'Kobold Warren', '', 0.3, '', 0, 1660058, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (2300547, 2300548, 2300549);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300547, 558961, 0, 100, 1, 1, 0, 1, 1, 'CoA Goldshire: Pumpkin for Goldshire''s Generosity'),
(2300548, 558962, 0, 100, 1, 1, 0, 1, 1, 'CoA Goldshire: Melon for Goldshire''s Generosity'),
(2300549, 558963, 0, 100, 1, 1, 0, 1, 1, 'CoA Goldshire: Apple for Goldshire''s Generosity');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (2300547, 2300548, 2300549);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300547, 0, 558961),
(2300548, 0, 558962),
(2300549, 0, 558963);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660055, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 4, 120, 135, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Maid I Left Behind', 'Find Dulcinea, Bianca''s maid, in Goldshire.', 'You''ve been in and out of the abbey all day, yet I still haven''t seen my brother anywhere.$b$bI take it you couldn''t snap him out of it. Well... worth a try.$b$b<Her long, weary sigh says enough.>$b$bHeading out again? Maybe you can do me one more favor. On the way to the abbey I left one of my maids in Goldshire with a long list of ingredients to buy; medicine for my mother.$b$bHer name is Dulcinea. Could you find her and let her know I''ll be late?', '', 'Speak with Dulcinea.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660056, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 110, 120, 0, 0, 0, 0, 558960, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302015, 1, 2302020, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Agria''s Medicine', 'Buy the potion''s ingredients at the Goldshire market: Elgris Blossom Petals, Dun Kazad Liquor Concentrate, Pumpkin Juice, and a Murloc Eyeball.', 'Lady Agria Spada is a woman besieged by age. Of late she''s borne a litany of ailments that keep her to her bed.$b$bOnly one thing eases her: the draught brewed by her master alchemist.$b$bI''ve gathered a few ingredients, but the list is long and fussy. We still need Elgris Blossom Petals, Dun Kazad Liquor Concentrate, Pumpkin Juice, and a Murloc Eyeball.$b$bTake a turn through the market. Once you''ve got the lot, report to my lady''s manor. I don''t dare the roads alone, but you... you''re made of sterner stuff, aren''t you?', '', 'Speak with Aldia Crayon, butler to the Spadas, at the family manor.', 0, 0, 0, 0, 0, 0, 0, 0, 558956, 558957, 558958, 558959, 558960, 0, 1, 1, 1, 1, 1, 0, '', '', '', ''),
(1660057, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 350, 382, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302030, 1, 2302035, 1, 2302040, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Seven Years of Bad Luck', 'Inspect the broken mirror shards that Aldia Crayon blames for the curse afflicting Lady Agria Spada.', 'Hm...$b$b<The majordomo gives you a long, measuring look.>$b$bBefore you go... I need your help with one more matter.$b$bI''ve had the sense for some time that my lady''s ailments aren''t physical, but magical. A curse.$b$bIt started with a broken mirror. And you know what they say. However thorough I''ve been, shards keep turning up; bits of glass tucked around the manor and the grounds.$b$bWould you kindly deal with them?', '', 'Return to the butler.', 162920, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard Inspected', '', '', ''),
(1660058, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 260, 337, 0, 0, 0, 0, 0, 8, 0, 2302045, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Worm-Eaten Apple', 'Find and destroy the kobold warrens around Goldshire.', 'Whispers. They think no one''s noticed,but I sleep with my ear to the floor! Ha!$b$bThey dig and dig and dig. They''ll strike when you least expect it... unless you do something first.$b$bKobolds and kobolds and more kobolds. Under our feet! Watch where you step. Mind your footing!$b$bFind their warrens and set them alight. Crush them. With a big, heavy hammer!$b$b<She laughs to herself, then stares into the middle distance.>', '', 'Return to Clara the Mad.', 162940, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Kobold Warren Destroyed', '', '', ''),
(1660059, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 156, 213, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302050, 1, 2302055, 1, 2302060, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Goldshire''s Generosity', 'Gather Melons, Pumpkins, and Apples from the farms around Goldshire. Then deliver them to Eldor Hammer, leader of the refugees.', 'Welcome.$b$bI am Thorm—Harvend Thorm—mayor of Goldshire, serving on behalf of Lord Bruk and his house.$b$bYou may have noticed the makeshift camp in the shadow of this grand hall. Of late, Goldshire has taken in countless refugees out of Westfall. At times I fear it''s beyond our means...$b$bEven so, I won''t turn away while they go hungry. Walk the village fields and take a little from each harvest to bring to the camp. You have my leave—and, by extension, Lord Bruk''s.', '', 'Deliver the basket of food to Eldor Hammer.', 0, 0, 0, 0, 0, 0, 0, 0, 558961, 558962, 558963, 0, 0, 0, 3, 3, 10, 0, 0, 0, '', '', '', ''),
(1660060, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stay a While', 'Take a moment from the noise and haste and stay a while to listen to Aliscar Lend.', 'As it turns out, I''m the leading authority around here when it comes to the village''s history. Care for a short lesson?$b$b<The aging sorcerer seems eager, almost desperate, to talk.>$b$b<Perhaps he has something worth sharing.>', '', 'Say goodbye to Aliscar Lend.', 162921, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Listen to Aliscar Lend', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `BreadcrumbForQuestId`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660055, 0, 0, 1660000, 1660056, 0, 0),
(1660056, 0, 0, 0, 0, 1, 0),
(1660057, 0, 0, 1660056, 0, 0, 0),
(1660058, 0, 0, 0, 0, 0, 0),
(1660059, 0, 0, 0, 0, 0, 0),
(1660060, 0, 0, 0, 0, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660055, 'Did my lady Bianca send you?$B$B<Dulcinea dips into an awkward curtsy.>$B$BSo she’ll be delayed… I swear, that brother of hers is nothing but trouble.$B$BEither way, her mother’s medicine can’t wait. Would you be so kind as to help me with my errands?'),
(1660056, 'Another errand-runner?$B$BI don’t know what Lady Bianca and Moroi think they’re playing at, but their mother,my lady Agria, doesn’t have much time left…$B$B<Aldia gives the old woman a pitying look. Swaddled in layers of sheets and shawls, she looks half-buried already.>$B$BThe ingredients… Do you have them? Good. I’ll see they’re handed to the alchemist.'),
(1660057, 'So my instincts were right.$B$BThere’s no cure for old age, but with the curse broken, at least Lady Agria’s terrible pains should ease.$B$B<As he speaks, the years show: furrows cut deep in a lean face, watery eyes spent; he’s hardly younger than the lady he serves.>$B$BThank you for your diligent service.'),
(1660058, '<Clara the Mad holds an apple in her right hand, admiring it as if it were her most prized possession.>$B$BGoldshire is like this apple.$B$B<Slowly, she turns it to show a bite; inside—despite appearances—it’s rotten, worm-eaten.>'),
(1660059, 'My people won’t forget Goldshire’s kindness.$B$BI trust that one day we’ll repay it in full.'),
(1660060, 'I hope I didn’t bore you too much!');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660055, ''),
(1660056, 'Yes? What business brings you to the Spada estate?'),
(1660057, 'Did you find the mirror shards?'),
(1660058, 'Leave none of those vermin alive, or Goldshire will cave in under their tunnels.'),
(1660059, 'Can I help you?'),
(1660060, '');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161700, 1660055),
(162800, 1660056),
(162802, 1660057),
(162805, 1660058),
(162807, 1660059),
(162806, 1660060);

DELETE FROM `creature_questender` WHERE `quest` IN (1660055, 1660056, 1660057, 1660058, 1660059, 1660060);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(162800, 1660055),
(162802, 1660056),
(162802, 1660057),
(162805, 1660058),
(162801, 1660059),
(162806, 1660060);

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9002000, 9002001, 9002002, 9002003, 9002004, 9002005, 9002006, 9002007, 9002008, 9002009, 9002010, 9002011, 9002012, 9002013, 9002014, 9002015, 9002016, 9002017, 9002018, 9002019, 9002020);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9002000, 162800, 0, 0, 0, 1, 1, 0, -9464.47, 39.14, 56.53, 3.34, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack turn-in of 1660055: the market plaza signpost, facing the pumpkin stall'),
(9002001, 162802, 0, 0, 0, 1, 1, 0, -9275.25, 469.16, 89.87, 0.43, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack turn-in of 1660056 and 1660057: Spada Family Manor top floor, at Lady Agria''s bedside, facing her'),
(9002002, 162803, 0, 0, 0, 1, 1, 0, -9273.4, 470, 90.91, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: Spada Family Manor top floor, lying on the large bed'),
(9002003, 162805, 0, 0, 0, 1, 1, 0, -9579.2, 35.4, 58.74, 2.32, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack turn-in of 1660058, 0.7 yd out of the shack wall: at her shack in the refugee camp, facing the south meadow'),
(9002004, 162806, 0, 0, 0, 1, 1, 0, -9397.41, -12.37, 62.13, 2.61, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack turn-in of 1660060: the book stall under the east entrance arch, facing the arch'),
(9002005, 162807, 0, 0, 0, 1, 1, 0, -9558.4, 62.8, 62.17, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: town hall dais behind the podium, facing east down the hall'),
(9002006, 162801, 0, 0, 0, 1, 1, 0, -9565.48, 9.73, 59.18, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack turn-in of 1660059: refugee camp between the two pavilions, facing the way in from the village'),
(9002007, 162817, 0, 0, 0, 1, 1, 0, -9556.5, 13, 58.81, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: refugee camp, at the table of the pavilion nearest the hall'),
(9002008, 162818, 0, 0, 0, 1, 1, 0, -9577.5, 20, 59.43, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: refugee camp, by the beds beside the middle tent'),
(9002009, 162819, 0, 0, 0, 1, 1, 0, -9581, 12, 59.62, 0.73, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: refugee camp, by the south tent'),
(9002010, 162820, 0, 0, 0, 1, 1, 0, -9583.5, 31.5, 59.02, 5.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: refugee camp, by the campsite tent'),
(9002011, 162809, 0, 0, 0, 1, 1, 0, -9486.8, 36.2, 56.66, 0.23, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack objective 3 of 1660056, 0.5 yd off the counter: the pumpkin juice counter under the tent, facing the plaza'),
(9002012, 162811, 0, 0, 0, 1, 1, 0, -9465.3, 60.6, 56.11, 4.77, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack objective 2 of 1660056, 1.0 yd out of the wagon: beside the bottle-laden gypsy wagon, facing the plaza'),
(9002013, 162826, 0, 0, 0, 1, 1, 0, -9450.54, -81.71, 58.44, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack objective 4 of 1660056: the fish stall on the dock boardwalk, facing out of its open west side onto the boardwalk'),
(9002014, 162814, 0, 0, 0, 1, 1, 0, -9387.92, 23.72, 59.5, 4.37, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack objective 1 of 1660056: in front of the flower cart, facing away from it toward the road'),
(9002015, 162808, 0, 0, 0, 1, 1, 0, -9558, 52, 60.81, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: town hall floor below the dais, facing the mayor'),
(9002016, 162821, 0, 0, 0, 1, 1, 0, -9500.5, 86.5, 57.01, 1.57, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: east corner of the melon plot by the fence, facing the melons'),
(9002017, 162822, 0, 0, 0, 1, 1, 0, -9413, -41, 64.46, 5.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: pumpkin garden, inside the east fence, facing the patches'),
(9002018, 162823, 0, 0, 0, 1, 1, 0, -9445, -36.5, 60.23, 3.93, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: apple orchard, by the fruit buckets, facing the south trees'),
(9002019, 162824, 0, 0, 0, 1, 1, 0, -9506, 112, 57.55, 0.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: by the barn west of the melon plot'),
(9002020, 162943, 0, 0, 0, 1, 1, 0, -9406.46, -7.11, 78.22, 3.1416, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Goldshire: SuperTrack objective of 1660060: on top of the east entrance arch, facing the player he brings up');

DELETE FROM `gameobject` WHERE `guid` IN (7911000, 7911001, 7911002, 7911003, 7911004, 7911005, 7911006, 7911007, 7911008, 7911009, 7911010, 7911011, 7911012, 7911013, 7911014, 7911015, 7911016, 7911020, 7911021, 7911022, 7911023, 7911024, 7911025, 7911026, 7911027, 7911028, 7911029, 7911030, 7911031, 7911032, 7911033, 7911034, 7911035, 7911036, 7911037, 7911040, 7911041, 7911042, 7911043, 7911044, 7911045, 7911046, 7911047, 7911048, 7911049, 7911050, 7911060, 7911061, 7911062, 7911063, 7911064, 7911065, 7911066, 7911067, 7911068, 7911069, 7911070, 7911071, 7911080, 7911081, 7911082, 7911083, 7911084, 7911085, 7911086, 7911087, 7911088, 7911089, 7911090, 7911091, 7911092, 7911093, 7911094, 7911095, 7911096, 7911097, 7911098, 7911099, 7911100, 7911101, 7911102, 7911103);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7911000, 2300546, 0, 0, 0, 1, 1, -9274.5, 457.8, 82.27, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, ground floor dining hall, by the bookshelf'),
(7911001, 2300546, 0, 0, 0, 1, 1, -9287.5, 465, 82.27, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, ground floor, between the weapon rack and the jars'),
(7911002, 2300546, 0, 0, 0, 1, 1, -9279, 467.5, 89.87, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, top floor bedroom, by the wardrobe'),
(7911003, 2300546, 0, 0, 0, 1, 1, -9271, 460, 89.87, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, top floor study, beside the desk and the loom'),
(7911004, 2300546, 0, 0, 0, 1, 1, -9285.5, 463, 89.87, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, top floor west room, under the window planter'),
(7911005, 2300546, 0, 0, 0, 1, 1, -9297, 461, 86.05, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, south room, before the pew and the funerary banners'),
(7911006, 2300546, 0, 0, 0, 1, 1, -9285.8, 482.8, 77.74, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, grounds, beside the well'),
(7911007, 2300546, 0, 0, 0, 1, 1, -9271.5, 480.5, 78.79, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, grounds, by the fruit bucket under the tree north of the house'),
(7911008, 2300546, 0, 0, 0, 1, 1, -9263, 466, 79.73, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, grounds, by the stump and axe north-east of the house'),
(7911009, 2300546, 0, 0, 0, 1, 1, -9278, 489, 78.73, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, gazebo floor, beside the round table'),
(7911010, 2300546, 0, 0, 0, 1, 1, -9306, 490, 77.66, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, hedge garden, between the two lion statues'),
(7911011, 2300546, 0, 0, 0, 1, 1, -9313, 502, 77.71, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, hedge garden, among the benches and busts'),
(7911012, 2300546, 0, 0, 0, 1, 1, -9262.5, 437.5, 79.99, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, training yard, by the archery target'),
(7911013, 2300546, 0, 0, 0, 1, 1, -9283.5, 431.5, 78.7, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, just inside the gate'),
(7911014, 2300546, 0, 0, 0, 1, 1, -9265.5, 446, 79.48, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, beside the hearse by the front door'),
(7911015, 2300546, 0, 0, 0, 1, 1, -9291, 447, 78.35, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, beside the stone fence of the front path'),
(7911016, 2300546, 0, 0, 0, 1, 1, -9304.5, 447.5, 78.56, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Mirror Shard, Spada manor, by the bust at the south hedge corner'),
(7911020, 2300579, 0, 0, 0, 1, 1, -9633.58, 133.12, 45.93, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, terrace at the foot of the plateau''s south-west escarpment, tree stump 34 yd SSW (sighting 40.4,73.2)'),
(7911021, 2300579, 0, 0, 0, 1, 1, -9712.29, 209.46, 49.91, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, open terrace north of the Fargodeep knoll, bare tree 24 yd S (sighting 38.2,76.6)'),
(7911022, 2300579, 0, 0, 0, 1, 1, -9723.86, 171.29, 50.96, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, north foot of the Fargodeep knoll, bare tree 10 yd SE (sighting 39.3,77.1)'),
(7911023, 2300579, 0, 0, 0, 1, 1, -9721.55, -47.32, 37.45, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, east flank of the spur above the Maclure lowland, ruined catapult 41 yd NE (sighting 45.6,77.0)'),
(7911024, 2300579, 0, 0, 0, 1, 1, -9730.81, -12.62, 36.74, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, east flank slope below the spur, oak 15 yd N (sighting 44.6,77.4)'),
(7911025, 2300579, 0, 0, 0, 1, 1, -9763.22, -16.09, 31.68, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, foot of the east flank on the lowland, crates 36 yd E (sighting 44.7,78.8)'),
(7911026, 2300579, 0, 0, 0, 1, 1, -9772.48, 32.49, 33.76, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, lower slope south of the spur, between oaks 26 yd NNE and SSW (sighting 43.3,79.2)'),
(7911027, 2300579, 0, 0, 0, 1, 1, -9638.21, 67.19, 61.15, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, spur crest south-south-west of the refugee camp, oak 14 yd SE (sighting 42.3,73.4)'),
(7911028, 2300579, 0, 0, 0, 1, 1, -9745, 57, 38.8, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, mine approach below the spur''s tail, just east of the big oak (sighting 42.3,78.0 is inside its trunk)'),
(7911029, 2300579, 0, 0, 0, 1, 1, -9749.33, 129.65, 49.4, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, terrace at the knoll''s north-east foot above the mine galleries, oak 13 yd NE (sighting 40.5,78.2)'),
(7911030, 2300579, 0, 0, 0, 1, 1, -9763.22, 67.19, 38.95, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, mine-approach slope below the spur''s south end, oak 12 yd SSE (sighting 42.3,78.8)'),
(7911031, 2300579, 0, 0, 0, 1, 1, -9797.94, 129.65, 49.74, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, east shoulder of the Fargodeep knoll over the mine galleries (sighting 40.5,80.3)'),
(7911032, 2300579, 0, 0, 0, 1, 1, -9661.36, 105.36, 45.52, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, foot of the spur''s west flank on the terrace, tree stump 35 yd W (sighting 41.2,74.4)'),
(7911033, 2300579, 0, 0, 0, 1, 1, -9714.6, 25.55, 40.96, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, east flank of the spur''s south end (sighting 43.5,76.7)'),
(7911034, 2300579, 0, 0, 0, 1, 1, -9698.4, 164.35, 50.26, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, terrace between the fallen log 30 yd NNE and the knoll (sighting 39.5,76.0)'),
(7911035, 2300579, 0, 0, 0, 1, 1, -9647.47, 202.52, 49.3, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, terrace 53 yd east of the Westfall road, oak 22 yd W (sighting 38.4,73.8)'),
(7911036, 2300579, 0, 0, 0, 1, 1, -9714.6, 112.3, 46.25, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, foot of the spur''s south-west end (sighting 41.0,76.7)'),
(7911037, 2300579, 0, 0, 0, 1, 1, -9698.4, 63.72, 56.75, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Kobold Warren, south end of the spur crest, the last high ground before the mine approach (sighting 42.4,76.0)'),
(7911040, 2300548, 0, 0, 0, 1, 1, -9496, 90, 56.83, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, north-east corner, inside the fence post'),
(7911041, 2300548, 0, 0, 0, 1, 1, -9495.8, 95, 56.82, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, along the north fence, opposite the scarecrow'),
(7911042, 2300548, 0, 0, 0, 1, 1, -9496.5, 100, 56.91, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, along the north fence, by the lamppost'),
(7911043, 2300548, 0, 0, 0, 1, 1, -9498, 106.5, 56.95, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, north-west corner, beside the harness'),
(7911044, 2300548, 0, 0, 0, 1, 1, -9500, 89.5, 57.01, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, east edge, past the end of the fence'),
(7911045, 2300548, 0, 0, 0, 1, 1, -9500, 97.5, 56.96, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, middle row, just west of the scarecrow, by the SuperTrack point'),
(7911046, 2300548, 0, 0, 0, 1, 1, -9501.5, 102.5, 56.95, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, middle row, west end'),
(7911047, 2300548, 0, 0, 0, 1, 1, -9504.5, 90.5, 57.02, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, south-east corner'),
(7911048, 2300548, 0, 0, 0, 1, 1, -9505, 96.5, 57.01, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, south edge, behind the scarecrow'),
(7911049, 2300548, 0, 0, 0, 1, 1, -9505.5, 101, 57.03, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, south edge, middle'),
(7911050, 2300548, 0, 0, 0, 1, 1, -9504.5, 106.5, 56.99, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Melon, melon plot, south-west corner, by the barn yard'),
(7911060, 2300547, 0, 0, 0, 1, 1, -9501.85, 69.1, 56.54, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, west plot, beside the south patch'),
(7911061, 2300547, 0, 0, 0, 1, 1, -9503.75, 72.5, 56.71, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, west plot, between the patches, clear of the plow'),
(7911062, 2300547, 0, 0, 0, 1, 1, -9502.75, 73.75, 56.72, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, west plot, beside the north patch'),
(7911063, 2300547, 0, 0, 0, 1, 1, -9402.4, -41.25, 64.94, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, beside the north-west patch'),
(7911064, 2300547, 0, 0, 0, 1, 1, -9411.3, -47.7, 64.51, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, west row, beside its patch'),
(7911065, 2300547, 0, 0, 0, 1, 1, -9405, -47, 64.52, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, north row'),
(7911066, 2300547, 0, 0, 0, 1, 1, -9416.3, -54.5, 64.42, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, beside the south corner patch'),
(7911067, 2300547, 0, 0, 0, 1, 1, -9412.5, -52, 64.45, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, centre south'),
(7911068, 2300547, 0, 0, 0, 1, 1, -9410.2, -52.2, 64.46, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, centre, beside the patch'),
(7911069, 2300547, 0, 0, 0, 1, 1, -9397.5, -54.2, 64.45, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, by the north fence, beside its patch'),
(7911070, 2300547, 0, 0, 0, 1, 1, -9413.5, -58, 64.44, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, south-east row'),
(7911071, 2300547, 0, 0, 0, 1, 1, -9408.7, -60.9, 64.46, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Pumpkin, pumpkin garden, beside the east corner patch'),
(7911080, 2300549, 0, 0, 0, 1, 1, -9443.5, -27, 60.19, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the north-west tree, south-west side'),
(7911081, 2300549, 0, 0, 0, 1, 1, -9442.64, -32.84, 61.39, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, on the fruit in the small fruit bucket'),
(7911082, 2300549, 0, 0, 0, 1, 1, -9446, -28.2, 60.16, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, between the two western trees'),
(7911083, 2300549, 0, 0, 0, 1, 1, -9448.4, -28.6, 60.14, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the south-west tree, west side by the south fence'),
(7911084, 2300549, 0, 0, 0, 1, 1, -9448.4, -31.6, 60.14, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the south-west tree, east side'),
(7911085, 2300549, 0, 0, 0, 1, 1, -9446.5, -31.9, 60.19, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the south-west tree, north-east side'),
(7911086, 2300549, 0, 0, 0, 1, 1, -9443.68, -33.8, 61.34, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, on the fruit in the north fruit bucket'),
(7911087, 2300549, 0, 0, 0, 1, 1, -9447.9, -34.6, 60.17, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, between the south-west and middle south trees'),
(7911088, 2300549, 0, 0, 0, 1, 1, -9443.1, -36.9, 60.22, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the middle north tree, south side'),
(7911089, 2300549, 0, 0, 0, 1, 1, -9443, -39, 60.23, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the middle north tree, south-east side'),
(7911090, 2300549, 0, 0, 0, 1, 1, -9448.4, -37.2, 60.17, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the middle south tree, west side'),
(7911091, 2300549, 0, 0, 0, 1, 1, -9445.4, -39.3, 60.23, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, between the two middle trees'),
(7911092, 2300549, 0, 0, 0, 1, 1, -9447.5, -41, 60.2, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the middle south tree, east side'),
(7911093, 2300549, 0, 0, 0, 1, 1, -9443.4, -43.2, 60.23, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the north-east tree, south-west side'),
(7911094, 2300549, 0, 0, 0, 1, 1, -9445.6, -43.8, 60.21, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, between the two eastern trees'),
(7911095, 2300549, 0, 0, 0, 1, 1, -9443.3, -46.2, 60.23, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the north-east tree, south-east side'),
(7911096, 2300549, 0, 0, 0, 1, 1, -9441.4, -47, 60.18, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the north-east tree, toward the fence post'),
(7911097, 2300549, 0, 0, 0, 1, 1, -9447.84, -45.83, 61.26, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, on the fruit in the south fruit bucket'),
(7911098, 2300549, 0, 0, 0, 1, 1, -9446.4, -37.3, 60.21, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, at the farmer''s feet, between the fruit buckets and the middle south tree'),
(7911099, 2300549, 0, 0, 0, 1, 1, -9444.8, -41.5, 60.23, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, centre aisle between the middle and eastern trees'),
(7911100, 2300549, 0, 0, 0, 1, 1, -9441.1, -34.26, 61.66, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, on the heap in the apple crate by the farmhouse'),
(7911101, 2300549, 0, 0, 0, 1, 1, -9441.3, -42.7, 60.25, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, under the north-east tree, west side by the farmhouse wall'),
(7911102, 2300549, 0, 0, 0, 1, 1, -9443, -49, 60.2, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, inside the east fence, north of the wheelbarrow'),
(7911103, 2300549, 0, 0, 0, 1, 1, -9440.1, -33.26, 62.02, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Goldshire: Apple, orchard, on top of the heap in the apple crate');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300546, 2300579) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300546, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 162920, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard - On use - Credit the inspection'),
(2300546, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mirror Shard - Linked - Despawn until it respawns');

UPDATE `gameobject_template` SET `AIName` = '', `ScriptName` = 'go_coa_abbess_relic' WHERE `entry` = 2300579;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 162806 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162806, 0, 0, 1, 62, 0, 100, 0, 85190, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend - On Gossip Option 0 Selected - Close Gossip'),
(162806, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend - Linked - Hide the option during the lesson'),
(162806, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 267032, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend - Linked - Cast Teleporting'),
(162806, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -9408.46, -7.11, 78.219, 0, 'Aliscar Lend - Linked - Send the player to the gatehouse tower top'),
(162806, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16280600, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend - Linked - Start the lesson');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 16280600 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(16280600, 9, 0, 0, 0, 0, 100, 0, 2000, 2000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Opener'),
(16280600, 9, 1, 0, 0, 0, 100, 0, 10000, 10000, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Lesson 1'),
(16280600, 9, 2, 0, 0, 0, 100, 0, 14000, 14000, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Lesson 2'),
(16280600, 9, 3, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Offer to end the lesson early'),
(16280600, 9, 4, 0, 0, 0, 100, 0, 14000, 14000, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Lesson 3'),
(16280600, 9, 5, 0, 0, 0, 100, 0, 14000, 14000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Closing'),
(16280600, 9, 6, 0, 0, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Projection - Withdraw the early ending'),
(16280600, 9, 7, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Credit listening to him'),
(16280600, 9, 8, 0, 0, 0, 100, 0, 500, 500, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -9399.9, -12.9, 62.243, 0.209, 'Aliscar Lend lesson - Send the player back to the stall'),
(16280600, 9, 9, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aliscar Lend lesson - Show the option again');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 16280601 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(16280601, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 10, 9002020, 162943, 0, 0, 0, 0, 0, 0, 'Aliscar lesson ended early - Projection - Withdraw the early ending'),
(16280601, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 10, 9002004, 162806, 0, 0, 0, 0, 0, 0, 'Aliscar lesson ended early - Aliscar - Show the option again');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 162943 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(162943, 0, 0, 1, 62, 0, 100, 0, 85160, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Projection - On heard enough - Close Gossip'),
(162943, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 162921, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Projection - Linked - Credit listening to him'),
(162943, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -9399.9, -12.9, 62.243, 0.209, 'Projection - Linked - Send the player back down'),
(162943, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 80, 16280601, 0, 0, 0, 0, 0, 10, 9002004, 162806, 0, 0, 0, 0, 0, 0, 'Projection - Linked - End the lesson');

DELETE FROM `creature_text` WHERE `CreatureID` = 162943;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`)
VALUES
(162943, 0, 0, 'Best views in all Goldshire, believe me! Well… except for the town hall clock tower.', 12, 100, 'Arcane Projection of Aliscar - lesson 0 (npccache 85160)'),
(162943, 1, 0, 'Goldshire takes its name from the gold the first settlers found in these hills. Fargodeep and Jasperlode were dug by the same families who raised this village.', 12, 100, 'Arcane Projection of Aliscar - lesson 1 (INFERRED)'),
(162943, 2, 0, 'When the veins ran thin, the village stayed. Travelers on the road to Stormwind have kept the Lion''s Pride full ever since, and our farms feed half the city.', 12, 100, 'Arcane Projection of Aliscar - lesson 2 (INFERRED)'),
(162943, 3, 0, 'Now kobolds hold the old mines, and the Defias raid the farms we were once so proud of. Remember what this place was, $N. It could be that again.', 12, 100, 'Arcane Projection of Aliscar - lesson 3 (INFERRED)'),
(162943, 4, 0, 'A mighty view, don''t you think? Come now, back down with you.', 12, 100, 'Arcane Projection of Aliscar - lesson 4 (npccache 85159 + INFERRED)');
