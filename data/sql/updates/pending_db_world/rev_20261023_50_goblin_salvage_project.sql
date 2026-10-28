-- CoA Goblin Salvage Project: a level 30-40 Stranglethorn questline that awards Lootbot 3000 (57000).

INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyPrice`, `SellPrice`, `InventoryType`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `startquest`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellcooldown_1`, `spellcategorycooldown_1`, `description`)
VALUES
(9707001, 12, 0, 'Strange Piece of Scrap', 4486, 1, 0, 0, 0, 0, 1, 0, 1, 1, 4, 176000, 0, 0, 0, -1, -1, 'Stamped with a half-scratched Venture Co. serial number.'),
(9707002, 12, 0, 'Salvaged Gearbox', 5199, 1, 2048, 0, 0, 0, 1, 0, 6, 6, 4, 0, 0, 0, 0, -1, -1, ''),
(9707003, 12, 0, 'Shredder Power Core', 13706, 1, 2048, 0, 0, 0, 1, 0, 1, 1, 4, 0, 0, 0, 0, -1, -1, ''),
(9707004, 12, 0, 'Volatile Fuel Canister', 5272, 1, 2048, 0, 0, 0, 1, 0, 1, 1, 4, 0, 0, 0, 0, -1, -1, ''),
(9707005, 12, 0, 'Calibrated Logic Core', 4754, 1, 2048, 0, 0, 0, 1, 0, 1, 1, 4, 0, 0, 0, 0, -1, -1, ''),
(9707006, 12, 0, 'Lootbot Field Remote', 11823, 1, 0, 0, 0, 0, 1, 0, 1, 1, 4, 0, 9930889, 0, 0, -1, -1, 'Summons the prototype Lootbot for its field test.'),
(9707007, 12, 0, 'Field Test Sample', 7758, 1, 2048, 0, 0, 0, 1, 0, 8, 20, 4, 0, 0, 0, 0, -1, -1, ''),
(9707008, 12, 0, 'Salvage License Application', 24417, 1, 0, 0, 0, 0, 1, 0, 1, 1, 4, 0, 0, 0, 0, -1, -1, 'Signed in triplicate. Needs one more stamp.')
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `BuyPrice` = VALUES(`BuyPrice`), `SellPrice` = VALUES(`SellPrice`), `InventoryType` = VALUES(`InventoryType`), `ItemLevel` = VALUES(`ItemLevel`), `RequiredLevel` = VALUES(`RequiredLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `bonding` = VALUES(`bonding`), `startquest` = VALUES(`startquest`), `spellid_1` = VALUES(`spellid_1`), `spelltrigger_1` = VALUES(`spelltrigger_1`), `spellcharges_1` = VALUES(`spellcharges_1`), `spellcooldown_1` = VALUES(`spellcooldown_1`), `spellcategorycooldown_1` = VALUES(`spellcategorycooldown_1`), `description` = VALUES(`description`);

-- The client has no Item.dbc row for 9707001-9707008, and it draws a bag icon from that row: without one the
-- items showed a question mark. These rows match item_template and reach the client through the item patch
-- stream (the core registers the ids); their displays are ItemDisplayInfo rows the client already has.
DELETE FROM `item_dbc` WHERE `ID` BETWEEN 9707001 AND 9707008;

INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`)
VALUES
(9707001, 12, 0, -1, 0, 4486, 0, 0),
(9707002, 12, 0, -1, 0, 5199, 0, 0),
(9707003, 12, 0, -1, 0, 13706, 0, 0),
(9707004, 12, 0, -1, 0, 5272, 0, 0),
(9707005, 12, 0, -1, 0, 4754, 0, 0),
(9707006, 12, 0, -1, 0, 11823, 0, 0),
(9707007, 12, 0, -1, 0, 7758, 0, 0),
(9707008, 12, 0, -1, 0, 24417, 0, 0);

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(9312001, 0, 0, 0, 0, 0, 'Fizzlebolt Gearwhistle', 'Gnomeregan Salvage Engineer', NULL, 0, 40, 40, 0, 12, 3, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(9312002, 0, 0, 0, 0, 0, 'Grizzik Scrapsnatch', 'Bilgewater Cartel Inventor', NULL, 0, 40, 40, 0, 29, 3, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 2, '', 0),
(9312003, 0, 0, 0, 0, 0, 'Haywire Lootbot Prototype', NULL, NULL, 0, 37, 37, 0, 14, 0, 1, 1.14286, 1, 1, 18, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 9, 0, 9312003, 0, 0, 0, 0, 60, 259, '', 0, 1, 2.5, 1, 1, 1, 0, 0, 1, -93, 0, '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9312001, 9312002, 9312003);

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(9312001, 0, 2590, 1, 1, 0),
(9312002, 0, 1233, 1, 1, 0),
(9312003, 0, 6888, 2.5, 1, 0);

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
VALUES
(9312001, 3, 335, 'Discarded Prototype', '', '', 1, 43, 9312001, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', ''),
(9312002, 3, 5093, 'Volatile Fuel Canister', '', '', 1, 43, 9312002, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`);

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `AllowableRaces`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `StartItem`, `Flags`, `RewardItem1`, `RewardAmount1`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `ItemDrop1`, `ItemDropQuantity1`)
VALUES
(176000, 2, 34, 30, 33, 0, 0, 3, 0, 0, 8, 0, 0, 'A Strange Piece of Scrap', 'Take the Strange Piece of Scrap to the salvage engineer at the Rebel Camp or at Grom''gol Base Camp.', '<The scrap is still warm and smells of machine oil. A half-scratched Venture Co. serial number is stamped on one side, and someone has scrawled "PROTOTYPE - DO NOT LOOT" beneath it.>$B$BAn engineer would know what this is. The Alliance has one at the Rebel Camp, and the Horde one at Grom''gol Base Camp.', '', 'Bring the scrap to a salvage engineer.', 9707001, 0, 0, 1, 0, 0, 0, 0),
(176001, 2, 35, 30, 33, 1101, 176002, 5, 2500, 0, 8, 0, 0, 'One Goblin''s Junk', 'Bring Fizzlebolt Gearwhistle 6 Salvaged Gearboxes from the Venture Co. in northern Stranglethorn, a Shredder Power Core from a Venture Co. Shredder and a Volatile Fuel Canister from the Venture Co. Base Camp.', 'That serial number is Venture Co. stock, and the rest of it is still out there! The goblins strip this jungle for timber and ore, and they throw away more machinery than Gnomeregan ever built.$B$BI can assemble a proper salvage unit from their leftovers, but precision needs parts: six intact gearboxes from their workers, a power core out of one of their Shredders, and one of those volatile fuel canisters they stack at the Base Camp. Gently with that last one, please.', '', 'Return to Fizzlebolt Gearwhistle.', 9707002, 9707003, 9707004, 6, 1, 1, 0, 0),
(176002, 2, 36, 30, 33, 1101, 176003, 5, 2500, 0, 8, 0, 0, 'Assembly Required', 'Destroy the Haywire Lootbot Prototype at the Venture Co. Base Camp and bring its Calibrated Logic Core to Fizzlebolt Gearwhistle.', 'Gears, power, fuel... and still no brain. My logic core keeps sorting copper coins by smell.$B$BThe Venture Co. built a looting prototype of their own and lost control of it. It patrols their Base Camp, grabbing everything that isn''t nailed down. Its logic core is perfectly calibrated. Destroy the machine and bring me that core.', '', 'Return to Fizzlebolt Gearwhistle.', 9707005, 0, 0, 1, 0, 0, 0, 0),
(176003, 2, 37, 30, 33, 1101, 176004, 5, 2500, 9707006, 8, 0, 0, 'Field Testing', 'Use the Lootbot Field Remote, then let the Lootbot collect 8 Field Test Samples from Venture Co. workers you defeat in Stranglethorn.', 'It works! At least, the schematics say it should.$B$BTake this remote and summon the Lootbot near the Venture Co. workers. Defeat them and let the Lootbot collect a field test sample from each one. Eight samples should give me enough data. Do stay close: it has not learned to be shy yet.', '', 'Return to Fizzlebolt Gearwhistle.', 9707007, 0, 0, 8, 0, 0, 9707006, 1),
(176004, 2, 38, 30, 33, 1101, 0, 5, 0, 9707008, 8, 57000, 1, 'Licensed Salvage Assistant', 'Take the Salvage License Application to Baron Revilgaz in Booty Bay.', 'Eight perfect samples! It''s ready.$B$BThere is one problem: Booty Bay owns the salvage rights along this coast, and an unlicensed Lootbot ends up as scrap on Baron Revilgaz''s desk. I filled in the application. Take it to the Baron, and once it has his stamp, the Lootbot is yours.', '', 'Bring the application to Baron Revilgaz in Booty Bay.', 9707008, 0, 0, 1, 0, 0, 0, 0),
(176011, 2, 35, 30, 33, 690, 176012, 5, 2500, 0, 8, 0, 0, 'One Goblin''s Junk', 'Bring Grizzik Scrapsnatch 6 Salvaged Gearboxes from the Venture Co. in northern Stranglethorn, a Shredder Power Core from a Venture Co. Shredder and a Volatile Fuel Canister from the Venture Co. Base Camp.', 'Venture Co. junk! You know what that is, friend? Free inventory. Those Venture boys throw away more profit than Kezan makes in a year.$B$BHere''s the pitch: a mechanical partner that picks up loot while you do the hard part. I need six working gearboxes from their workers, a power core out of one of their Shredders, and a fuel canister from their Base Camp. Don''t shake that one.', '', 'Return to Grizzik Scrapsnatch.', 9707002, 9707003, 9707004, 6, 1, 1, 0, 0),
(176012, 2, 36, 30, 33, 690, 176013, 5, 2500, 0, 8, 0, 0, 'Assembly Required', 'Destroy the Haywire Lootbot Prototype at the Venture Co. Base Camp and bring its Calibrated Logic Core to Grizzik Scrapsnatch.', 'Gears, power, fuel: the body''s done. The brain''s the expensive part.$B$BThe Venture Co. built a loot-grabbing prototype of their own and lost the remote, now it''s tearing up their Base Camp. Its logic core is top quality. Smash the thing, bring me the core, and we save months of research.', '', 'Return to Grizzik Scrapsnatch.', 9707005, 0, 0, 1, 0, 0, 0, 0),
(176013, 2, 37, 30, 33, 690, 176014, 5, 2500, 9707006, 8, 0, 0, 'Field Testing', 'Use the Lootbot Field Remote, then let the Lootbot collect 8 Field Test Samples from Venture Co. workers you defeat in Stranglethorn.', 'Every great product needs a field test before launch.$B$BTake this remote and summon the prototype near the Venture Co. workers. You knock them down, it picks up a sample from each one. Eight samples should convince any investor. Stay close: it hasn''t figured out who it works for yet.', '', 'Return to Grizzik Scrapsnatch.', 9707007, 0, 0, 8, 0, 0, 9707006, 1),
(176014, 2, 38, 30, 33, 690, 0, 5, 0, 9707008, 8, 57000, 1, 'Licensed Salvage Assistant', 'Take the Salvage License Application to Baron Revilgaz in Booty Bay.', 'Eight samples! We''ve got a product!$B$BOne small detail: Booty Bay owns the salvage rights here, and Baron Revilgaz takes his cut of everything. I filled in the license application. Take it to the Baron in Booty Bay, get his stamp, and the Lootbot is all yours.', '', 'Bring the application to Baron Revilgaz in Booty Bay.', 9707008, 0, 0, 1, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `AllowableRaces` = VALUES(`AllowableRaces`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);

INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `SpecialFlags`)
VALUES
(176000, 40, 0, 0, 0),
(176001, 40, 0, 176000, 0),
(176002, 40, 0, 176001, 0),
(176003, 40, 0, 176002, 0),
(176004, 40, 0, 176003, 0),
(176011, 40, 0, 176000, 0),
(176012, 40, 0, 176011, 0),
(176013, 40, 0, 176012, 0),
(176014, 40, 0, 176013, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);

INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(176000, 'A Venture Co. serial number... and "PROTOTYPE"? The goblins are building something out there.$B$BWhere did you find this? Never mind. It''s what it could become that matters.'),
(176001, 'All of it, and the canister didn''t even explode. Splendid! Now I can start the assembly.'),
(176002, 'A beautiful core. Look at those solder joints! Our Lootbot finally has a brain.'),
(176003, 'Eight samples, each one sorted and labeled. The prototype exceeded every prediction!'),
(176004, '<Baron Revilgaz reads every line of the application, then stamps it with obvious satisfaction.>$B$BA licensed salvage assistant, all paperwork in order. Booty Bay gets its cut, you get your Lootbot. Good business all around.$B$BTake care of it. I don''t want to see it at the auction house.'),
(176011, 'Look at all this merchandise! The canister didn''t even blow up. That''s what I call a good deal.'),
(176012, 'Now that''s a premium logic core. The Venture Co. paid for the research and we get the product.'),
(176013, 'Eight samples and zero lawsuits! Investors are going to love this.'),
(176014, '<Baron Revilgaz reads every line of the application, then stamps it with obvious satisfaction.>$B$BA licensed salvage assistant, all paperwork in order. Booty Bay gets its cut, you get your Lootbot. Good business all around.$B$BTake care of it. I don''t want to see it at the auction house.');

DELETE FROM `quest_request_items` WHERE `ID` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);

INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(176000, 'What have you got there?'),
(176001, 'Have you found the parts? Precision is everything.'),
(176002, 'Did you get the logic core from that machine?'),
(176003, 'How is the field test going? Is the Lootbot collecting?'),
(176004, 'An application? From a gnome? Let me see it.'),
(176011, 'Got my parts? Time is money, friend.'),
(176012, 'Is that runaway machine still running around?'),
(176013, 'How many samples so far?'),
(176014, 'An application? From one of the Cartel? Let me see it.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);

INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(9312001, 176001),
(9312001, 176002),
(9312001, 176003),
(9312001, 176004),
(9312002, 176011),
(9312002, 176012),
(9312002, 176013),
(9312002, 176014);

DELETE FROM `creature_questender` WHERE `quest` IN (176000, 176001, 176002, 176003, 176004, 176011, 176012, 176013, 176014);

INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(9312001, 176000),
(9312002, 176000),
(9312001, 176001),
(9312001, 176002),
(9312001, 176003),
(2496, 176004),
(9312002, 176011),
(9312002, 176012),
(9312002, 176013),
(2496, 176014);

DELETE FROM `creature_loot_template` WHERE `Item` IN (9707002, 9707003, 9707005, 9707007);

INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(921, 9707002, 0, 40, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Salvaged Gearbox'),
(921, 9707007, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Field Test Sample'),
(1094, 9707002, 0, 40, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Salvaged Gearbox'),
(1094, 9707007, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Field Test Sample'),
(1095, 9707002, 0, 40, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Salvaged Gearbox'),
(1095, 9707007, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Field Test Sample'),
(1096, 9707002, 0, 40, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Salvaged Gearbox'),
(1096, 9707007, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Field Test Sample'),
(1097, 9707002, 0, 40, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Salvaged Gearbox'),
(1097, 9707007, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Field Test Sample'),
(4260, 9707003, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Shredder Power Core'),
(9312003, 9707005, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Calibrated Logic Core');

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9312001, 9312002);

INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9312001, 9707001, 0, 100, 0, 1, 0, 1, 1, 'Goblin Salvage Project: Strange Piece of Scrap'),
(9312002, 9707004, 0, 100, 1, 1, 0, 1, 1, 'Goblin Salvage Project: Volatile Fuel Canister');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 4 AND `SourceGroup` = 9312001 AND `SourceEntry` = 9707001;

INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(4, 9312001, 9707001, 0, 0, 8, 0, 176000, 0, 0, 1, 0, 0, '', 'Strange Piece of Scrap drops until A Strange Piece of Scrap is rewarded'),
(4, 9312001, 9707001, 0, 0, 9, 0, 176000, 0, 0, 1, 0, 0, '', 'Strange Piece of Scrap drops only while A Strange Piece of Scrap is not active');

DELETE FROM `creature` WHERE `guid` IN (9112000, 9112001, 9112002);

INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9112000, 9312001, 0, 33, 0, 1, 1, 0, -11307.4, -191.2, 75.35, 1.95, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Fizzlebolt Gearwhistle, Goblin Salvage Project, Rebel Camp'),
(9112001, 9312002, 0, 33, 0, 1, 1, 0, -12341.85, 165.85, 3.12, 4.2, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0, 'Grizzik Scrapsnatch, Goblin Salvage Project, Grom''gol Base Camp'),
(9112002, 9312003, 0, 33, 0, 1, 1, 0, -11985.0, -536.0, 12.06, 3.0, 60, 8, 0, 0, 0, 1, 0, 0, 0, '', 0, 0, 'Haywire Lootbot Prototype, Goblin Salvage Project, Venture Co. Base Camp');

DELETE FROM `gameobject` WHERE `guid` IN (9112000, 9112001, 9112002, 9112003, 9112004, 9112005);

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(9112000, 9312001, 0, 33, 0, 1, 1, -11960.5, -486.5, 17.08, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'Discarded Prototype, Venture Co. Base Camp'),
(9112001, 9312001, 0, 33, 0, 1, 1, -11951.0, -505.0, 17.15, 4.0, 0, 0, 0.909297, -0.416147, 120, 100, 1, '', 'Discarded Prototype, Venture Co. Base Camp'),
(9112002, 9312001, 0, 33, 0, 1, 1, -11938.5, -576.0, 16.9, 2.5, 0, 0, 0.948985, 0.315322, 120, 100, 1, '', 'Discarded Prototype, Venture Co. Base Camp'),
(9112003, 9312002, 0, 33, 0, 1, 1, -12132.7, -638.5, 13.6, 0.7, 0, 0, 0.342898, 0.939373, 120, 100, 1, '', 'Volatile Fuel Canister, Venture Co. Base Camp'),
(9112004, 9312002, 0, 33, 0, 1, 1, -12110.3, -629.76, 15.61, 3.3, 0, 0, 0.996865, -0.079121, 120, 100, 1, '', 'Volatile Fuel Canister, Venture Co. Base Camp'),
(9112005, 9312002, 0, 33, 0, 1, 1, -12079.1, -733.46, 14.28, 5.1, 0, 0, 0.557684, -0.830054, 120, 100, 1, '', 'Volatile Fuel Canister, Venture Co. Base Camp');

DELETE FROM `npc_vendor` WHERE `entry` = 900008 AND `item` = 57000;

DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` = 57000;

INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
VALUES
(57000, 0, 0, 0);
