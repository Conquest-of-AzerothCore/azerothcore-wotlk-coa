-- Conquest of Azeroth quests in Elwynn Forest that this world has never carried, outside the
-- Goldshire storyline: the Ascension 17000 series (Maclure, Bouden, the Tower of Azora, Guard Thomas,
-- the Smudged Note, Ridgepoint Tower, Mirror Lake), the Bandit's Bastion quests (100071-100074) and
-- Agent Serina Vale's mineral dig (254038-254108).
--
-- WHERE EACH VALUE COMES FROM
--   quests, objects, items, reward items  the realm's own client cache (data-cache-945cd3b8b0ce4a496586).
--     Every quest and reward item already exists in item_template, so no item is written here.
--   object positions  SOURCED from the QuestSuperTrack objective points (Maclure Supplies, the Supply
--     Cache, one Mirror Lake Harvest, the Crocolisk Egg) and the archive atlas (one Harvest, one crate of
--     Stolen Goods); the rest are placed by hand at a named landmark, each on the server floor.
--   quest givers  SOURCED where the quest text names them; the rest INFERRED from the voice of the text.
--   Esyra's greeting  npccache 4000. Supply Run follows Remy's Gold Dust Exchange (INFERRED from its text).
--   new NPCs  Guard Jacob, Esyra and Sinter Wive come from the creature cache. Agent Serina Vale (996114 in
--     Goldshire, 996115 at the Bastion) is in no source; two entries keep each copy's quests apart. Displays
--     the client cannot resolve use stock stand-ins. Givers and enders stand at their QuestSuperTrack
--     turn-in points; Esyra stands 1.9 yd from hers because Servant of Azora 80924 occupies it.
--   mobs  stock Defias, beasts, gnolls and spiders are added by hand to fill each objective area; the
--     Mirror Lake Orchard's Defias Cutpurses follow the Exiles export's stock spawns, which this world
--     lacks; its Defias Bandits come from the relocations migration.
--   drop chances  SOURCED from the Exiles export creature_loot (100% for every quest drop here).
--   credits  Slimy Solution: the vial spell hitting a murloc corpse credits it and removes the corpse;
--     a condition refuses the vial on a living murloc, as its spell description says (corpse only).
--     Unexpected Results: the enchanted fragment credits once per beast per ten minutes. Final Dig: a new
--     gossip option on Innkeeper Farley, shown only with the quest, gives him away (option and line INFERRED).
--   not restored  quests 254039 and 254040 are in no source, so 254041 and 254095 follow 254038 directly.
--
-- Spawn guid blocks: creature 9002200-9002599, gameobject 7911200-7911599. Quest 17005 starts from the
-- Smudged Note that rev_20260922_00_coa_northshire_quests.sql spawns.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `rank`, `unit_class`, `unit_flags`, `type`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `gossip_menu_id`)
VALUES
(157000, 'Guard Jacob', NULL, 30, 30, 0, 12, 2, 0, 1, 0, 7, 0, '', 0, 1.36, 1, 1, 1, 0, 0),
(900017, 'Esyra', 'Apprentice of Azora', 10, 10, 0, 12, 3, 0, 8, 0, 7, 0, '', 0, 0.96, 1, 1, 1, 0, 4000),
(996119, 'Defias Sentry', NULL, 9, 10, 0, 17, 0, 0, 1, 0, 7, 0, '', 0, 0.92448, 1, 1, 1, 0, 0),
(996114, 'Agent Serina Vale', NULL, 20, 20, 0, 35, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0),
(996115, 'Agent Serina Vale', NULL, 20, 20, 0, 35, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0),
(764542, 'Sinter Wive', NULL, 15, 15, 0, 35, 2, 0, 1, 0, 7, 0, '', 0, 1, 1, 1, 1, 0, 0),
(300220, '[KC] Slimy Murloc Spittle', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0),
(996120, '[KC] Find the Mole', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0),
(996121, '[KC] Test Minerals Potency', NULL, 1, 1, 0, 35, 0, 0, 1, 33555202, 10, 0, '', 0, 1, 1, 1, 1, 130, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `gossip_menu_id` = VALUES(`gossip_menu_id`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (157000, 300220, 764542, 900017, 996114, 996115, 996119, 996120, 996121);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(157000, 0, 1984, 1, 1),
(900017, 0, 3768, 1, 1),
(996119, 0, 5035, 1, 1),
(996114, 0, 5783, 1, 1),
(996115, 0, 5783, 1, 1),
(764542, 0, 1659, 1, 1),
(300220, 0, 11686, 1, 1),
(996120, 0, 11686, 1, 1),
(996121, 0, 11686, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 996119;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(996119, 1, 1896, 0, 0);

UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` IN (250, 66, 11916, 955, 958, 11072);
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (118, 822);

DELETE FROM `npc_text` WHERE `ID` = 4000;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`)
VALUES
(4000, 'Oh! Hello! You must be an adventurer, right? That’s so exciting! I’ve been helping out here at the Tower of Azora, just an apprentice really, but I finally got assigned some real tasks!     I can’t leave the grounds yet, but maybe you can help me with them?', 'Oh! Hello! You must be an adventurer, right? That’s so exciting! I’ve been helping out here at the Tower of Azora, just an apprentice really, but I finally got assigned some real tasks!     I can’t leave the grounds yet, but maybe you can help me with them?', 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 4000;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(4000, 4000);

-- ---------------------------------------------------------------------------
-- 2. World objects
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(96000, 3, 36, 'Maclure Supplies', '', 1, 43, 96000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(96002, 3, 31, 'Supply Cache', '', 1, 43, 96002, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(96003, 3, 3012, 'Mirror Lake Harvest', 'Reclaiming', 1, 43, 96003, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(5055563, 3, 286, 'Stolen Goods', '', 1, 43, 5055563, 0, 1, 0, 0, 0, 0, 100073, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(25428, 3, 3851, 'Crocolisk Egg', 'Looting', 1, 57, 25428, 0, 1, 0, 0, 0, 0, 254051, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- ---------------------------------------------------------------------------
-- 3. Quests
-- ---------------------------------------------------------------------------
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(17000, 2, 9, 5, 12, 0, 0, 0, 0, 0, 0, 0, 4, 350, 375, 0, 0, 0, 0, 0, 8, 0, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stolen Supplies', 'Return the Stolen Supplies to Pa Maclure.', 'Damn Defias have come through and ransacked our supplies! What did we ever do to them? Other than feed them before they decided to turn on us of course. Well I won''t stand for it!$B$BYou can find their encampent not far East of here at Jarod''s Landing. Give them hell and then return those supplies and I''ll see you compensated appropriately.', '', 'Return to Pa Maclure at the Maclure Vinyards.', 0, 0, 0, 0, 0, 0, 0, 0, 157000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(17001, 2, 9, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 375, 375, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Extravagant Order', 'Return 4 Gem Encrusted Spider Silk to Tharynn Bouden.', 'Ah, Hero, may I have a moment? You see, I''ve come across a grand business opportunity and could use your expertise. I''ve gotten recent reports of a spider infestation—disgusting things—in the Jasperlode Mines. Bad news for the Kobolds, but a great opportunity for us!$B$BApparently the spiders produce a very unique, and very valuable type of silk—Gem Encrusted Spider Silk! I''ve hypothesized it has something to do with feasting on the kobold miners located in and around the mine, but it''s just a theory. Anyway, if you could bring me 4 of these Gem Encrusted Spider Silks I could reward you handsomely!', '', 'Return 4 Gem Encrusted Spider Silk to Tharynn Bouden.', 0, 0, 0, 0, 0, 0, 0, 0, 157001, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, '', '', '', ''),
(17002, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 5, 300, 187, 0, 0, 0, 0, 0, 8, 0, 157003, 4, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Master''s Orders', 'Recover 10 Depleted Mana Gems and return to the Tower of Azora.', 'Hi there! I just got assigned to help with a research project, and I think this might be my big chance to show the master I am ready for more responsibility.  We are studying magical depletion, and for that, we need samples of spent arcane matter. I think you can collect them from the Defias Rogue Wizards near Stone Cairn Lake. They''re dangerous, but I heard they''ve been overcasting their spells lately, which makes them perfect for what we need.  Would you be willing to bring back ten of their Depleted Mana Gems? I''ll make sure you''re rewarded. And if this goes well... maybe I''ll get to try casting something bigger than Mage Armor!', '', 'Recover 10 Depleted Mana Gems and return to the Tower of Azora.', 0, 0, 0, 0, 0, 0, 0, 0, 157002, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, '', '', '', ''),
(17003, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 5, 300, 187, 0, 0, 0, 0, 157006, 8, 0, 157005, 1, 1397885, 1, 0, 0, 0, 0, 157006, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Slimy Solution', 'Retrieve 10 Slimy Murloc Spittle Samples and return to the Tower of Azora.', 'Hi! Sorry if this sounds a little strange, but would you be willing to help with a research assignment?  The master has begun to study magical residue in... well, spit. Murloc spit, to be precise. He wants to see how lingering arcane energy reacts in biological material. I know, kind of gross, but fascinating, right?  There are Murloc Lurkers and Foragers near Eastvale Lodging Camp, both north and south of the lake. If you can gather ten samples of their spittle and bring them back, I will make sure you''re properly rewarded. I even prepared a vial for collection.', '', 'Retrieve 10 Slimy Murloc Spittle Samples and return to the Tower of Azora.', 300220, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Slimy Murloc Spittle Collected', '', '', ''),
(17004, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 157009, 1, 157010, 1, 157011, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Disarming the Gnolls', 'Retrieve 6 Gnoll Blades and 10 Gnoll Axes and return to Guard Thomas at the east Elwynn bridge.', 'As if the murloc infestation weren''t bad enough, we also have gnolls gnawing at our borders. If it''s not one problem, it''s another!$B$BDo the kingdom and the people of Elwynn justice and disarm this threat before it even has a chance to become a real problem. Bring me 6 Gnoll Blades from the gnoll runts and 10 Gnoll Axes from their outrunners.$B$BYou can find their encampment along the North and Northwestern ends of Stone Cairn Lake. If you do this, the Stormwind Army will be sure to reward you accordingly.', '', 'Retrieve 6 Gnoll Blades and 10 Gnoll Axes and retun to Guard Thomas at the east Elwynn bridge.', 0, 0, 0, 0, 0, 0, 0, 0, 157007, 157008, 0, 0, 0, 0, 6, 10, 0, 0, 0, 0, '', '', '', ''),
(17005, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 4, 350, 375, 0, 0, 0, 0, 157012, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Last Memento', 'Return the Smudged Note to Imelda in Stormwind.', 'My dearest Imelda. Even though you have moved to Stormwind, I hope you know that no distance could ever keep us apart. My love for you is that of infinite burning suns. You shall forever own a piece of my heart. Never forget.$B$B-Ethan$B$BI should attempt to return this note to Imelda. She will probably want to know how Ethan felt.', '', 'Return the Smudged Note to Imelda in Stormwind.', 0, 0, 0, 0, 0, 0, 0, 0, 157012, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(17006, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 5, 300, 375, 0, 0, 0, 0, 0, 8, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'King''s Justice', 'Slay 8 Defias Bandits and return the Supply Cache to Guard Jacob at Ridgepoint Tower.', 'Hero, I''ve got a problem. Our scouts have reported that a shipment that was en route to Lakeshire was intercepted by the Defias. I need you to retrieve that shipment and give the Defias what''s coming to them.$B$BI don''t believe they''ve yet had time to move the shipment to one of their safehouses. It seems a small band of Defias is guarding the shipment just East of here.$B$BI unfortunately can''t spare the men, but if you kill 8 Defias bandits and return to me with the shipment I will make sure you are compensated appropriately.', '', 'Slay 8 Defias Bandits and return the Supply Cache to Guard Jacob at Ridgepoint Tower.', 116, 0, 0, 0, 8, 0, 0, 0, 157013, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(17007, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 2, 150, 150, 0, 0, 0, 0, 157013, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Delivery to Lakeshire', 'Deliver the Supply Cache to Magistrate Solomon in Lakeshire.', 'Uh, one moment, Hero. Listen, I hate to ask another favor of you, but I simply can''t spare any men at the moment. Could you be so generous as to deliver this supply cache to Lakeshire.$B$BI think Magistrate Solomon will want to hear of what you did for his people and I''m sure he''ll see you rewarded for your good deeds.', '', 'Deliver the Supply Cache to Magistrate Solomon in Lakeshire.', 0, 0, 0, 0, 0, 0, 0, 0, 157013, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(17008, 2, 10, 7, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 187, 0, 0, 0, 0, 0, 0, 0, 157015, 5, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Reclaim the Harvest', 'Retrieve 8 Mirror Lake Apples and return them to Sergeant De Vries in Westbrook Garrison.', 'It''s a shame, $N. The Defias have overrun the Mirror Lake Orchard and are hijacking the harvest. I remember my mother making her famous Mirror Lake apple pie for me when I was a child. It''s something I wish I could share with the rest of the men here at the garrison.$B$BSay, you look like a well traveled $R. Do you think you could venture to the Mirror Lake Orchard to the northeast of the garrison and gather enough apples there for me to make some pies? I''ll even whip a few up for you! Oh, and feel free to give the Defias our regards.', '', 'Retrieve 8 Mirror Lake Apples and return them to Sergeant De Vries in Westbrook Garrison.', 0, 0, 0, 0, 0, 0, 0, 0, 157014, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, '', '', '', ''),
(100071, 2, 8, 4, 12, 0, 0, 0, 0, 0, 0, 0, 5, 130, 135, 0, 0, 0, 0, 0, 0, 0, 1397885, 1, 500813, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Defias Disruption', 'Thin the ranks of the Defias at the Bandit Bastion, east of Goldshire.', 'Oh, um... are you one of those brave types? The ones who deal with danger and monsters and... all that?  It’s just that things have not been the same here lately. The taproom’s quieter, the roads feel emptier, and even the usual loud sorts have stopped passing through. I keep trying to tell myself it is just a slow season, but... I do not think that''s it.  I heard a rumor, just a rumor, that some of those Defias bandits have built up a camp somewhere east of here. People are saying they''ve been stopping travelers, stealing supplies, or maybe worse. I do not really know for sure, but... maybe if someone went out there and gave them a reason to think twice, things might calm down a bit?  That might bring folks back.', '', 'Return to Melika Isenstrider at Goldshire in Elwynn Forest.', 116, 474, 0, 0, 6, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(100073, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 90, 0, 0, 0, 0, 0, 0, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 500814, 1, 500815, 1, 500816, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Supply Run', 'Recover 4 Stolen Supply Crates from the Bandit Bastion, east of Goldshire.', 'Listen, I have a bit of a follow up for you, if you''re still feeling up to the task.  There’s talk that the Defias have gathered in a proper hideout east of here. It’s a large encampment, far more organized than the usual rabble.  Some local merchants were hit in a raid not long ago. Crates of supplies were taken. Useful things like tools, cloth, even some rare spirits. The sort of goods folks rely on around here.  It’s not without risk, but if someone were to head in and recover what was lost, I know a few people who would be grateful. I would see to it that you''re rewarded for your effort.', '', 'Return to Remy "Two Times" at Goldshire in Elwynn Forest.', 0, 0, 0, 0, 0, 0, 0, 0, 5055564, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, '', '', '', ''),
(100074, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 5, 130, 135, 0, 0, 0, 0, 5055565, 0, 0, 1397884, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Betrayal Within', 'Return to Marshal Dughan.', 'You''ve found what looks like a genuine Alliance document, carried by a man dressed as a soldier stationed deep in a Defias outpost. The contents point to collusion between Alliance forces and local bandits.  This should not be happening. Someone loyal needs to see this.  Deliver the document to an appropriate Alliance official. With any luck, they will know what to do with it.', '', 'Return to Marshal Dughan at Goldshire in Elwynn Forest.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254038, 2, 7, 6, 12, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Start Digging', 'Meet Serina at the rendezvous point near Bandits’ Bastion.', 'You don''t seem to be from around here. This place is getting noisy. Too many eyes, too many questions. I don’t like repeating myself, and I don’t trust half the people within earshot.     Meet me near the Bandit''s Bastion, so I can go over the details.', '', 'Report to Agent Serina Vale near The Bandit''s Bastion in Elwynn Forest.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254041, 2, 8, 5, 12, 0, 0, 0, 0, 0, 0, 0, 4, 175, 202, 0, 0, 0, 0, 0, 8, 0, 1252803, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Report To The General', 'Bring this information to General Marcus Jonathan', 'General Marcus Johnson will want to know about what you found here.  Bring this report to him, you should find him as you enter Stormwind. ', '', 'Report to General Marcus Johnathan at Valley of Heroes in Stormwind.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254051, 2, 15, 10, 12, 0, 0, 0, 0, 0, 0, 0, 5, 375, 202, 0, 0, 0, 0, 0, 0, 0, 1397885, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Save The Crocs', 'Sinter Wive wants you to retrieve the Crocolisk Egg from the Trogg "Poachers" on the island to the North.', 'I have been watchin’ a nest by the river for days now. One of the crocs finally laid, just one perfect egg. Beautiful thing. Spotted shell, warm to the touch. I was hopin’ to move it somewhere safe, give it a real shot at hatching.  Then those filthy troggs showed up. Grunting and stomping through the brush, one of ‘em grabbed the egg like it was a rock and ran off screamin’.  They do not know what they are holding. They will eat it or smash it or boil it in mud if we do not get it back fast. You are faster than me, and you are not afraid to get dirty.  Bring that egg back. I will owe you one.', '', 'Report to Sinter Wive in Loch Modan.', 0, 0, 0, 0, 0, 0, 0, 0, 1252808, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254095, 2, 7, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 354526, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Arcane Insight', 'Deliver the mineral fragment to the Tower of Azora and seek magical insight into its properties and potential use.', 'I don''t recognize this mineral. That worries me. When gold’s involved, people talk. But this? This has everyone quiet.    The mages at the Tower of Azora may be able to tell us more. They deal in things not found on trade routes.    Take the fragment to them. And be careful what you say, I don’t want this spreading before we know what we’re standing in.', '', 'Deliver the Mineral Fragment to a Mage at the Tower of Azora in Elwynn Forest.', 0, 0, 0, 0, 0, 0, 0, 0, 354526, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254098, 2, 8, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 354525, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mixed Reagents', 'Get the Bundle of Samples to Dawn Brightstar.', 'Now that we have both samples, I need them prepared properly and for that, we’ll need Dawn Brightstar.  She handles our volatile components and has a much steadier hand than I do.  Take the spider legs and the filled vial to her inside the tower. Don’t spill anything and don’t let her talk you into trying anything. She gets... curious.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 354525, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254099, 2, 8, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 354524, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Test the Mix', 'Drink the "Enriched" Mineral Water to check for any ill affects.', 'Hmm.. It doesn''t seem to react at all. Think at this dosage level the mineral has no reaction.  You look like a strong and healthy individual mind taking a sip? It is perfectly safe! I think..  Report your findings to Theocritus.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(254106, 2, 8, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 354527, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Enchant the Mineral', 'Bring Mineral Fragment to Kitta Firewind.', 'So amounts found in Jasperlode Mine are definately not enough for anything, even after prolonged exposure and appear to be safe.  But given Defias is mining for it, there must be something more to it. Bring the Mineral Fragment to Kitta Firewind inside Tower of Azora to see if she can enchant it for us to see if mineral reacts in any way to magic.', '', '', 0, 0, 0, 0, 0, 0, 0, 0, 354527, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(254107, 2, 9, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 354047, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Unexpected Results', 'Test the Enchanted Mineral Fragment.', 'Be very, very careful while handling this. Mineral appears to be highly unstable when exposed to magic.   We need to test its full potential.  Go outside of Tower of Azora and test it on local wild life.', '', 'Report your findings back to Agent Serina Vale at Goldshire in Elwynn Forest.', 996121, 0, 0, 0, 5, 0, 0, 0, 354047, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Test Minerals Potency', '', '', ''),
(254108, 2, 9, 6, 12, 0, 0, 0, 0, 0, 0, 0, 5, 0, 202, 0, 0, 0, 0, 0, 0, 0, 375250, 250, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Final Dig', 'Find Defias mole inside Lion''s Pride Inn.', 'While you were out looking into the uses for the mineral. I managed to put back together who might be the mole for Defias in Lion''s Pride Inn from all the Charred Documents we recovered earlier.  Based on said documents it should be someone working in the Inn, someone who has extended history with them.   We just need to question few people inside and see who slips up.', '', 'Report back to Agent Serina Vale at Goldshire in Elwynn Forest.', 996120, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the Mole', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (17000, 17001, 17002, 17003, 17004, 17005, 17006, 17007, 17008, 100071, 100073, 100074, 254038, 254041, 254051, 254095, 254098, 254099, 254106, 254107, 254108);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(17000, 0, 0, 0, 0, 0),
(17001, 0, 0, 0, 0, 0),
(17002, 0, 0, 0, 0, 0),
(17003, 0, 0, 0, 1, 0),
(17004, 0, 0, 0, 0, 0),
(17005, 0, 0, 0, 1, 0),
(17006, 0, 0, 0, 0, 0),
(17007, 0, 0, 17006, 1, 0),
(17008, 0, 0, 0, 0, 0),
(100071, 0, 0, 0, 0, 0),
(100073, 0, 0, 47, 0, 0),
(100074, 0, 0, 0, 1, 0),
(254038, 0, 0, 0, 0, 0),
(254041, 0, 0, 254038, 0, 0),
(254051, 0, 0, 0, 0, 0),
(254095, 0, 0, 254038, 1, 0),
(254098, 0, 0, 254095, 1, 0),
(254099, 0, 0, 254098, 1, 2),
(254106, 0, 0, 254099, 1, 0),
(254107, 0, 0, 254106, 1, 0),
(254108, 0, 0, 254107, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (17000, 17001, 17002, 17003, 17004, 17005, 17006, 17007, 17008, 100071, 100073, 100074, 254038, 254041, 254051, 254095, 254098, 254099, 254106, 254107, 254108);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(17000, 'Praise the King! I was worried we may never see those supplies again. I don''t know what we would have done without you, Hero.'),
(17001, 'Let''s see what you''ve found He—Wow! I mean, ehrm, it''s just as I expected. You''ve done well, Hero. Here, take this as generous payment for your assistance.'),
(17002, 'You got them! You actually got them! I can''t wait to show the master. I’ll make sure he knows you were the one who made it all happen.'),
(17003, 'Thank you, $R. The Master will be pleased.'),
(17004, 'That''s one less problem I, and the people of Elwynn, need to worry about. Thank you, $N. What you''ve done for us is greatly appreciated.'),
(17005, 'Oh, my, goodness. By the Holy Light, $N! That Ethan is always so dramatic!$B$BI swear, if that boy spent half the time actually doing something as he does fantasizing. Well, let''s just say he could be an accomplished individual. Instead he sits around and sulks and moans about how things could be.$B$BDon''t worry about Ethan, $N. He''s had messages delivered to me plenty of times now saying he''s in a place far from Elwynn where, ''demons ravage the lands, savage red orcs roam, and strange creatures wrapped in bandges haggle for space goods.'' Pffft, as if!$B$BAnyway, thanks for bringing this to me. I know you meant well. Here''s for your troubles.'),
(17006, 'Ah, thank the light and thank you, Hero. You''ve done the King a great service this day. Now if only I could spare a contingent of men to deliver this.'),
(17007, 'Oh, I was wondering where our last caravan had gotten off to! Thank you, Hero. You''ve done me, and the people of Lakeshire, a great service this day. Now if only I could get word back from the King.'),
(17008, 'Hot darn $N, you''ve done it! Please take this as payment for your kindness.$B$BOh, I can''t wait to the smiling faces around the garrison when I show them what I''ve made!'),
(100071, ''),
(100073, 'Well done. I’ll see to it these goods get back to their rightful owners.'),
(100074, 'So... you found this on one of our own, did you?$B$BThis seal’s legitimate. I’d stake my badge on it. But these orders are treason. Coordinating with bandits? Authorizing raids on our people?$B$BThis isn’t some forgery. Someone gave these commands, and they’ll answer for it.$B$BThank you for bringing this forward. Quietly. We’ll handle the rest.'),
(254038, ''),
(254041, ''),
(254051, 'That is it. That is the one. Warm and whole, not a scratch on the shell. I would hug you if I were not covered in swamp water and croc spit.$B$BYou did good. Really good. This little one might just have a chance now.'),
(254095, ''),
(254098, ''),
(254099, ''),
(254106, ''),
(254107, ''),
(254108, '');

DELETE FROM `quest_request_items` WHERE `ID` IN (17000, 17001, 17002, 17003, 17004, 17005, 17006, 17007, 17008, 100071, 100073, 100074, 254038, 254041, 254051, 254095, 254098, 254099, 254106, 254107, 254108);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(17000, 'How is your search going? The Defias haven''t given you too much trouble, have they?'),
(17001, 'So, Hero, how goes your foray into the Jasperlode Mine?'),
(17002, 'Oh! Did you find any of the gems? I’ve got a spot cleared on the desk and everything!'),
(17003, 'Did you manage to complete the task requested?'),
(17004, 'So, have the gnolls been dealt with?'),
(17005, 'What''s that? You have something for me, $N?'),
(17006, 'Have the Defias been taken care of?'),
(17007, 'What''s this, Hero?'),
(17008, 'Did you manage to reclaim some of the harvest?'),
(100071, ''),
(100073, 'How’s it look out there? You get your hands on any of those crates?'),
(100074, 'You’ve got something to report? Let me see it.'),
(254038, ''),
(254041, ''),
(254051, 'You find the egg? Tell me you got to it before they cracked it open.'),
(254095, ''),
(254098, ''),
(254099, ''),
(254106, ''),
(254107, ''),
(254108, '');

-- ---------------------------------------------------------------------------
-- 4. Who offers and who takes them back
-- ---------------------------------------------------------------------------
DELETE FROM `creature_queststarter` WHERE `quest` IN (17000, 17001, 17002, 17003, 17004, 17005, 17006, 17007, 17008, 100071, 100073, 100074, 254038, 254041, 254051, 254095, 254098, 254099, 254106, 254107, 254108);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(250, 17000),
(66, 17001),
(900017, 17002),
(900017, 17003),
(261, 17004),
(157000, 17006),
(157000, 17007),
(955, 17008),
(6778, 100071),
(241, 100073),
(996114, 254038),
(996115, 254041),
(764542, 254051),
(996115, 254095),
(313, 254098),
(958, 254099),
(313, 254106),
(11072, 254107),
(996114, 254108);

DELETE FROM `gameobject_queststarter` WHERE `quest` = 17005;
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(96001, 17005);

DELETE FROM `creature_questender` WHERE `quest` IN (17000, 17001, 17002, 17003, 17004, 17005, 17006, 17007, 17008, 100071, 100073, 100074, 254038, 254041, 254051, 254095, 254098, 254099, 254106, 254107, 254108);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(250, 17000),
(66, 17001),
(900017, 17002),
(900017, 17003),
(261, 17004),
(11916, 17005),
(157000, 17006),
(344, 17007),
(955, 17008),
(6778, 100071),
(241, 100073),
(240, 100074),
(996115, 254038),
(466, 254041),
(764542, 254051),
(313, 254095),
(958, 254098),
(313, 254099),
(11072, 254106),
(996114, 254107),
(996114, 254108);

-- ---------------------------------------------------------------------------
-- 5. Loot
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((43, 157001), (471, 157001), (474, 157002), (97, 157007), (478, 157008));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(43, 157001, 0, 100, 1, 1, 0, 1, 1, 'Mine Spider - Gem Encrusted Spider Silk (creaturecache, Exiles creature_loot 100%)'),
(471, 157001, 0, 100, 1, 1, 0, 1, 1, 'Mother Fang - Gem Encrusted Spider Silk (creaturecache, Exiles creature_loot 100%)'),
(474, 157002, 0, 100, 1, 1, 0, 1, 1, 'Defias Rogue Wizard - Depleted Mana Gem (creaturecache, Exiles creature_loot 100%)'),
(97, 157007, 0, 100, 1, 1, 0, 1, 1, 'Riverpaw Runt - Gnoll Sword (creaturecache, Exiles creature_loot 100%)'),
(478, 157008, 0, 100, 1, 1, 0, 1, 1, 'Riverpaw Outrunner - Gnoll Axe (creaturecache, Exiles creature_loot 100%)');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((43, 0), (471, 0), (474, 2), (97, 1), (478, 1));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(43, 0, 157001),
(471, 0, 157001),
(474, 2, 157002),
(97, 1, 157007),
(478, 1, 157008);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (25428, 96000, 96002, 96003, 5055563);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(96000, 157000, 0, 100, 1, 1, 0, 1, 1, 'CoA Elwynn: quest item from Maclure Supplies'),
(96002, 157013, 0, 100, 1, 1, 0, 1, 1, 'CoA Elwynn: quest item from Supply Cache'),
(96003, 157014, 0, 100, 1, 1, 0, 1, 1, 'CoA Elwynn: quest item from Mirror Lake Harvest'),
(5055563, 5055564, 0, 100, 1, 1, 0, 1, 1, 'CoA Elwynn: quest item from Stolen Goods'),
(25428, 1252808, 0, 100, 1, 1, 0, 1, 1, 'CoA Elwynn: quest item from Crocolisk Egg');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (25428, 96000, 96002, 96003, 5055563);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(96000, 0, 157000),
(96002, 0, 157013),
(96003, 0, 157014),
(5055563, 0, 5055564),
(25428, 0, 1252808);

-- ---------------------------------------------------------------------------
-- 6. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9002200, 9002201, 9002202, 9002203, 9002204, 9002205, 9002206, 9002209, 9002213, 9002216, 9002220, 9002221, 9002222, 9002223, 9002226, 9002230, 9002231, 9002233, 9002235, 9002237, 9002244, 9002245, 9002247, 9002250, 9002251, 9002252, 9002253, 9002254, 9002260, 9002261, 9002262, 9002263, 9002264, 9002265, 9002266, 9002267, 9002268, 9002269, 9002271, 9002272, 9002277, 9002279, 9002282, 9002290, 9002291, 9002292, 9002300, 9002301, 9002302, 9002303, 9002304, 9002305, 9002306, 9002307, 9002308, 9002309, 9002310, 9002320, 9002321, 9002322, 9002323, 9002324, 9002325, 9002326, 9002327, 9002328, 9002330, 9002331, 9002332, 9002333, 9002334, 9002335, 9002336, 9002337, 9002338, 9002339, 9002340, 9002341, 9002342, 9002343, 9002344, 9002345, 9002346, 9002347) OR `guid` BETWEEN 9002200 AND 9002599;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9002200, 157000, 0, 0, 0, 1, 1, 0, -9769.75, -1379.84, 62.78, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Ridgepoint Tower first floor at the 17006 SuperTrack turn-in point, facing east toward the Defias camp'),
(9002201, 900017, 0, 0, 0, 1, 1, 0, -9562.33, -722.93, 64.74, 0.82, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Tower of Azora ground floor at the 17002/17003 SuperTrack turn-in point, the Servant of Azora post CoA gave her'),
(9002202, 996114, 0, 0, 0, 1, 1, 0, -9451.46, 79.9, 57.49, 4.37, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Goldshire lane outside the smithy at the 254107 SuperTrack turn-in point, facing down the lane to the inn'),
(9002203, 996115, 0, 0, 0, 1, 1, 0, -9783.61, -404.56, 60.29, 4.71, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: 254038 SuperTrack turn-in point: the rendezvous on the west cliff above the Bastion''s mine, overlooking the camp'),
(9002204, 764542, 0, 0, 0, 1, 1, 0, -5200.66, -3521.83, 303.97, 0.17, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Loch Modan shore at the 254051 SuperTrack turn-in point, facing the trogg island'),
(9002205, 996119, 0, 0, 0, 1, 1, 1, -9790, -484, 30.6, 4.99, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, inside the farmhouse at the desk by the book stack, deep in the camp'),
(9002206, 116, 0, 0, 0, 1, 1, 1, -9746.5, -427.5, 44.6, 0, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, gate walkway above the north ravine, watching the approach over the barricade'),
(9002209, 116, 0, 0, 0, 1, 1, 1, -9768, -427, 33.8, 1.05, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, training yard, sparring with the north dummy'),
(9002213, 116, 0, 0, 0, 1, 1, 1, -9801, -429.5, 31.84, 1.57, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, inside the mine entrance, facing the tunnel'),
(9002216, 116, 0, 0, 0, 1, 1, 1, -9788.5, -463.5, 30.18, 0.24, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, under the storehouse crane, stacking crates'),
(9002220, 116, 0, 0, 0, 1, 1, 1, -9822, -428, 38.34, 3.14, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, west end of the south boardwalk, watching the south approach'),
(9002221, 116, 0, 0, 0, 1, 1, 1, -9838, -466, 30.3, 1.57, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, outside the south wall, patrolling the approach under the big oak'),
(9002222, 116, 0, 0, 0, 1, 1, 1, -9784, -497, 32.84, 1.57, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, east campsite between the tent and the supply wagon'),
(9002223, 116, 0, 0, 0, 1, 1, 1, -9760, -472, 57.74, 3.8, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, lookout on the hill above the camp, watching the loot deck'),
(9002226, 474, 0, 0, 0, 1, 1, 1, -9779, -449.5, 31.16, 4.71, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, west side of the long loot table, reading the mission board'),
(9002230, 474, 0, 0, 0, 1, 1, 1, -9807, -464.5, 28.9, 1.2, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, shed, at the lockbox table'),
(9002231, 474, 0, 0, 0, 1, 1, 1, -9825, -439, 36.3, 3.14, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, middle of the south boardwalk behind the barricades'),
(9002233, 474, 0, 0, 0, 1, 1, 1, -9838, -438, 32.42, 1.57, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, outside the south wall on the west approach'),
(9002235, 474, 0, 0, 0, 1, 1, 1, -9793, -478.5, 30.6, 5, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, inside the farmhouse, guarding the Sentry''s quarters'),
(9002237, 474, 0, 0, 0, 1, 1, 1, -9814, -444, 29.7, 3.9, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Bandit''s Bastion, south yard between the bunk shed and the boardwalk stairs'),
(9002244, 116, 0, 0, 0, 1, 1, 1, -9740, -1560, 50.9, 0, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, lookout on the north ridge'),
(9002245, 116, 0, 0, 0, 1, 1, 1, -9738, -1590, 49.17, 0.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, north-east ridge'),
(9002247, 116, 0, 0, 0, 1, 1, 1, -9776, -1608, 43.98, 4.7, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, east, under the big oak'),
(9002250, 116, 0, 0, 0, 1, 1, 1, -9805, -1552, 38.99, 2.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, south-west slope'),
(9002251, 116, 0, 0, 0, 1, 1, 1, -9795, -1535, 41.3, 1.57, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, west approach from the tower road'),
(9002252, 116, 0, 0, 0, 1, 1, 1, -9775, -1530, 46.47, 1.57, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, west, watching the road to Ridgepoint Tower'),
(9002253, 116, 0, 0, 0, 1, 1, 1, -9755, -1530, 48.9, 1.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, north-west slope'),
(9002254, 116, 0, 0, 0, 1, 1, 1, -9814, -1572, 33.5, 3.14, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Defias camp east of Ridgepoint Tower, south, lower ground below the camp'),
(9002260, 1922, 0, 0, 0, 1, 1, 0, -9365, -715, 66.35, 3.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, between the two northern oaks'),
(9002261, 1922, 0, 0, 0, 1, 1, 0, -9352, -740, 69.08, 4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east edge'),
(9002262, 1922, 0, 0, 0, 1, 1, 0, -9440, -695, 64.64, 2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, open grass west of the southern oaks'),
(9002263, 1922, 0, 0, 0, 1, 1, 0, -9470, -705, 62.85, 1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-west edge toward the tower'),
(9002264, 1922, 0, 0, 0, 1, 1, 0, -9395, -760, 64.73, 5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, east clearing'),
(9002265, 1922, 0, 0, 0, 1, 1, 0, -9470, -785, 61.02, 0.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east clearing'),
(9002266, 822, 0, 0, 0, 1, 1, 0, -9410, -675, 65.58, 2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, west edge'),
(9002267, 822, 0, 0, 0, 1, 1, 0, -9445, -735, 65.09, 4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, under the southern oak'),
(9002268, 822, 0, 0, 0, 1, 1, 0, -9380, -775, 63.66, 5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, beside the eastern oak'),
(9002269, 822, 0, 0, 0, 1, 1, 0, -9425, -775, 65.01, 4.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east grass'),
(9002330, 1922, 0, 0, 0, 1, 1, 0, -9383, -800, 66.36, 0.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east, past the eastern oak'),
(9002331, 822, 0, 0, 0, 1, 1, 0, -9352, -712, 66.43, 3.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north edge, beyond the northern oaks'),
(9002332, 1922, 0, 0, 0, 1, 1, 0, -9383, -684, 67.72, 4.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-west, between the north-west oak and the path'),
(9002333, 1922, 0, 0, 0, 1, 1, 0, -9442, -668, 64.94, 5.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, west edge of the grass'),
(9002334, 822, 0, 0, 0, 1, 1, 0, -9482, -732, 60.97, 0.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-west, beside the south-west oak'),
(9002335, 1922, 0, 0, 0, 1, 1, 0, -9484, -757, 61.78, 0.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south, toward the tower grounds'),
(9002336, 822, 0, 0, 0, 1, 1, 0, -9447, -798, 62.13, 1.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east, under the south-east oak'),
(9002337, 1922, 0, 0, 0, 1, 1, 0, -9405, -797, 66.58, 1.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, east, between the two eastern clearings'),
(9002338, 1922, 0, 0, 0, 1, 1, 0, -9420, -757, 65.14, 3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, middle of the wood, south of the central oak'),
(9002339, 822, 0, 0, 0, 1, 1, 0, -9380, -742, 68.64, 2.4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east clearing below the eastern oak'),
(9002340, 1922, 0, 0, 0, 1, 1, 0, -9412, -698, 67.36, 4.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, clearing between the western oaks'),
(9002341, 822, 0, 0, 0, 1, 1, 0, -9462, -720, 63.31, 5.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north side of the south-west oak'),
(9002342, 1922, 0, 0, 0, 1, 1, 0, -9362, -757, 67.23, 2.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, north-east, below the eastern oak'),
(9002343, 1922, 0, 0, 0, 1, 1, 0, -9462, -800, 60.17, 1.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: wood north of the Tower of Azora, south-east clearing, with the pair by the oak'),
(9002271, 94, 0, 0, 0, 1, 1, 1, -9462, 486, 53.94, 3.14, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Mirror Lake Orchard, Exiles spawn 80396 moved 6 yd north-west, clear of relocated Defias Bandit 80385 and the oak roots'),
(9002272, 94, 0, 0, 0, 1, 1, 1, -9495.64, 457.06, 52.12, 0, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Mirror Lake Orchard, Exiles spawn 80400, south rows'),
(9002277, 94, 0, 0, 0, 1, 1, 1, -9517.96, 494.38, 52.09, 0, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Mirror Lake Orchard, Exiles spawn 80405, south-west of the orchard'),
(9002279, 94, 0, 0, 0, 1, 1, 1, -9453.23, 512.81, 56.13, 3.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Mirror Lake Orchard, Exiles spawn 80397, north-west of the orchard'),
(9002282, 94, 0, 0, 0, 1, 1, 1, -9459.9, 426.18, 52.62, 2.4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Mirror Lake Orchard, Exiles spawn 80402, north-east of the orchard'),
(9002290, 43, 0, 0, 0, 1, 1, 0, -9030, -591, 56.38, 1.57, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, upper east lobe between the webbed spiders'),
(9002291, 43, 0, 0, 0, 1, 1, 0, -9045, -610, 52.5, 3.9, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, lower east lobe on the way to Mother Fang''s den'),
(9002292, 43, 0, 0, 0, 1, 1, 0, -9030, -558, 55.16, 4.7, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Jasperlode Mine spider chamber, west lobe'),
(9002300, 97, 0, 0, 0, 1, 1, 1, -8993, -826, 69.67, 5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, between the west tent and the stores'),
(9002301, 97, 0, 0, 0, 1, 1, 1, -8970, -845, 68.77, 1.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, behind the east tent'),
(9002302, 97, 0, 0, 0, 1, 1, 1, -9000, -860, 70.23, 3.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, south of the tents toward the shore'),
(9002303, 97, 0, 0, 0, 1, 1, 1, -8965, -825, 68.83, 0.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, north-east edge under the oak'),
(9002304, 97, 0, 0, 0, 1, 1, 1, -9030, -835, 69.14, 3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, south-west, toward the north-west end of the lake'),
(9002305, 478, 0, 0, 0, 1, 1, 1, -8970, -805, 69.68, 0.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, north, on the trail to the upper camp'),
(9002306, 478, 0, 0, 0, 1, 1, 1, -9005, -800, 69.62, 1.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, west of the camp'),
(9002307, 478, 0, 0, 0, 1, 1, 1, -8958, -860, 70.03, 4.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, east, toward the lake'),
(9002308, 478, 0, 0, 0, 1, 1, 1, -9010, -880, 69.17, 3.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, south, along the north shore'),
(9002309, 478, 0, 0, 0, 1, 1, 1, -8935, -830, 68.64, 0.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, north-east, between the oaks'),
(9002310, 478, 0, 0, 0, 1, 1, 1, -9043, -817, 69.5, 2.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Riverpaw camp on the north shore of Stone Cairn Lake, south-west, above the west end of the lake'),
(9002320, 474, 0, 0, 0, 1, 1, 1, -9170, -1040, 71.8, 6.2, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, west of the stones, on the path from the 17002 point'),
(9002321, 474, 0, 0, 0, 1, 1, 1, -9160, -1075, 70.85, 0.8, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, south of the stone ring'),
(9002322, 474, 0, 0, 0, 1, 1, 1, -9120, -1080, 72.22, 2.2, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, north-east of the stone ring'),
(9002323, 474, 0, 0, 0, 1, 1, 1, -9100, -1030, 72.75, 3.6, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, north-west of the stone ring'),
(9002324, 474, 0, 0, 0, 1, 1, 1, -9195, -1025, 73.2, 5.9, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, south-west, facing the stones'),
(9002325, 474, 0, 0, 0, 1, 1, 1, -9172, -1092, 72.11, 0.6, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, south, under the big oak'),
(9002326, 474, 0, 0, 0, 1, 1, 1, -9206, -1036, 70.66, 0.2, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, south-west edge'),
(9002327, 474, 0, 0, 0, 1, 1, 1, -9110, -990, 72.81, 4, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, north-west, between the stones and the lone wizards'),
(9002328, 474, 0, 0, 0, 1, 1, 1, -9165, -1015, 69.93, 5.2, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, west, between the stones and the northern group'),
(9002344, 474, 0, 0, 0, 1, 1, 1, -9200, -1065, 70.85, 0.23, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, south, clearing at the north-west edge of the south oak canopy, facing the stones'),
(9002345, 474, 0, 0, 0, 1, 1, 1, -9238, -1078, 68.03, 0.27, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, far south, lakeside meadow above the shore, murloc huts 80 yd east-south-east, facing the stones'),
(9002346, 474, 0, 0, 0, 1, 1, 1, -9064, -1005, 71.18, 3.71, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, north-west, open rise at the east edge of the north oak grove, facing the stones'),
(9002347, 474, 0, 0, 0, 1, 1, 1, -9095, -1075, 73.8, 2.58, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Elwynn: Stone Cairn standing stones, north-east, at the foot of the Earthroot knoll, facing the stones');

DELETE FROM `gameobject` WHERE `guid` IN (7911200, 7911201, 7911202, 7911203, 7911204, 7911205, 7911206, 7911207, 7911208, 7911209, 7911210, 7911211, 7911212, 7911213, 7911214, 7911215, 7911216, 7911217, 7911218, 7911219, 7911220, 7911221, 7911230, 7911231, 7911232, 7911233, 7911234, 7911235, 7911236, 7911237, 7911238, 7911239, 7911240, 7911241, 7911250) OR `guid` BETWEEN 7911200 AND 7911599;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7911200, 96000, 0, 0, 0, 1, 1, -9950.16, -132.37, 25.37, 0, 0, 0, 0, 1, 2, 100, 1, '', 'CoA Elwynn: 17000 SuperTrack objective point, inside the farmhouse at Jerod''s Landing (atlas sighting 0.4 yd away)'),
(7911201, 96002, 0, 0, 0, 1, 1, -9766.9, -1560.26, 41.48, 0, 0, 0, 0, 1, 2, 100, 1, '', 'CoA Elwynn: Defias camp east of Ridgepoint Tower, 17006 SuperTrack objective point beside the camp crates (atlas sighting 0.3 yd away)'),
(7911202, 96003, 0, 0, 0, 1, 1, -9491.41, 475.9, 50.96, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, 17008 SuperTrack objective point, between three trees'),
(7911203, 96003, 0, 0, 0, 1, 1, -9482.9, 441.86, 53.11, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, atlas sighting, east rows'),
(7911204, 96003, 0, 0, 0, 1, 1, -9488, 493, 51.97, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree by the west fence'),
(7911205, 96003, 0, 0, 0, 1, 1, -9478, 495, 52.63, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the north-west corner'),
(7911206, 96003, 0, 0, 0, 1, 1, -9474.5, 483.5, 52.12, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree by the north fence'),
(7911207, 96003, 0, 0, 0, 1, 1, -9481.5, 487, 51.9, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the west rows'),
(7911208, 96003, 0, 0, 0, 1, 1, -9478, 474.5, 51.9, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the middle rows'),
(7911209, 96003, 0, 0, 0, 1, 1, -9479, 467.5, 51.53, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the middle rows, north side'),
(7911210, 96003, 0, 0, 0, 1, 1, -9486, 467, 51.4, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the middle rows, south side'),
(7911211, 96003, 0, 0, 0, 1, 1, -9492.5, 465, 51.2, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree by the south fence'),
(7911212, 96003, 0, 0, 0, 1, 1, -9477.5, 458, 51.56, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the east rows, north side'),
(7911213, 96003, 0, 0, 0, 1, 1, -9486.5, 458, 51.55, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the east rows'),
(7911214, 96003, 0, 0, 0, 1, 1, -9490, 454.5, 51.9, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the south-east rows'),
(7911215, 96003, 0, 0, 0, 1, 1, -9476.5, 452.5, 51.95, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the north-east rows'),
(7911216, 96003, 0, 0, 0, 1, 1, -9492, 447.5, 52.73, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the south-east corner'),
(7911217, 96003, 0, 0, 0, 1, 1, -9473, 448, 52.47, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the north-east corner'),
(7911218, 96003, 0, 0, 0, 1, 1, -9481.5, 449, 52.28, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the east rows, middle'),
(7911219, 96003, 0, 0, 0, 1, 1, -9494, 482.5, 51.24, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the south-west rows'),
(7911220, 96003, 0, 0, 0, 1, 1, -9484, 473, 51.4, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the middle rows, west side'),
(7911221, 96003, 0, 0, 0, 1, 1, -9485.5, 482.5, 51.6, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Elwynn: Mirror Lake Orchard, foot of the tree in the west rows, middle'),
(7911230, 5055563, 0, 0, 0, 1, 1, -9757.68, -442.04, 32.79, 3.63, 0, 0, 0.97033, -0.241784, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, atlas sighting, ravine by the crate stacks'),
(7911231, 5055563, 0, 0, 0, 1, 1, -9784.5, -452, 30.77, 1.57, 0, 0, 0.706825, 0.707388, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, south end of the long loot table'),
(7911232, 5055563, 0, 0, 0, 1, 1, -9789, -467, 29.37, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, under the storehouse crane beside the crate stacks'),
(7911233, 5055563, 0, 0, 0, 1, 1, -9793, -438, 29.57, 1.2, 0, 0, 0.564642, 0.825336, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, beside the ore carts at the mine mouth'),
(7911234, 5055563, 0, 0, 0, 1, 1, -9803.5, -429, 31.49, 1.57, 0, 0, 0.706825, 0.707388, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, inside the mine entrance'),
(7911235, 5055563, 0, 0, 0, 1, 1, -9804, -465, 28.9, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, shed, beside the lockbox table'),
(7911236, 5055563, 0, 0, 0, 1, 1, -9818, -457, 30.56, 1.57, 0, 0, 0.706825, 0.707388, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, bunk shed, at the foot of the bunks'),
(7911237, 5055563, 0, 0, 0, 1, 1, -9795, -470.5, 28.9, 0.5, 0, 0, 0.247404, 0.968912, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, farmyard by the farmhouse''s west wall'),
(7911238, 5055563, 0, 0, 0, 1, 1, -9786, -481.5, 30.6, 4.7, 0, 0, 0.711473, -0.702713, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, inside the farmhouse by the coal piles'),
(7911239, 5055563, 0, 0, 0, 1, 1, -9781.5, -497, 33, 5, 0, 0, 0.598472, -0.801144, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, east campsite, at the tent'),
(7911240, 5055563, 0, 0, 0, 1, 1, -9762, -436, 32.54, 0.3, 0, 0, 0.149438, 0.988771, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, ravine path below the gate stairs'),
(7911241, 5055563, 0, 0, 0, 1, 1, -9823, -431, 38.4, 3.14, 0, 0, 1, 0.000796, 120, 100, 1, '', 'CoA Elwynn: Bandit''s Bastion, west end of the south boardwalk'),
(7911250, 25428, 0, 0, 0, 1, 1, -4980.27, -3483, 305.61, 0, 0, 0, 0, 1, 2, 100, 1, '', 'CoA Elwynn: 254051 SuperTrack objective point on the trogg island, beside the troggs'' cauldron (atlas sighting 3 yd away)');

-- ---------------------------------------------------------------------------
-- 7. Scripts
-- ---------------------------------------------------------------------------
-- The stock blocks of the murlocs, the beasts and Innkeeper Farley are rewritten whole: their
-- existing rows are kept verbatim and the quest rows are added after them.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (46, 118, 295, 524, 732, 822, 1922) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(46, 0, 0, 0, 2, 0, 100, 1, 0, 40, 0, 0, 0, 0, 11, 3368, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Forager - Between 0-40% Health - Cast ''Drink Minor Potion'' (Phase 1)'),
(46, 0, 1, 2, 8, 0, 100, 0, 966240, 0, 0, 0, 0, 0, 33, 300220, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Forager - On Spellhit Collect Slimy Murloc Spittle - Quest Credit'),
(46, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Forager - Linked - Despawn the milked corpse'),
(118, 0, 0, 0, 8, 0, 100, 0, 350249, 0, 600000, 600000, 0, 0, 33, 996121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Prowler - On Spellhit Enchanted Mineral - Credit testing the mineral, once per beast'),
(295, 0, 0, 1, 62, 0, 100, 512, 1291, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Innkeeper Farley - On Gossip Option 0 Selected - Close Gossip'),
(295, 0, 1, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 134, 24751, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Innkeeper Farley - On Gossip Option 0 Selected - Invoker Cast ''Trick or Treat'''),
(295, 0, 2, 3, 62, 0, 100, 0, 1291, 4, 0, 0, 0, 0, 33, 996120, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Innkeeper Farley - On Gossip Option 4 Selected - Credit finding the mole'),
(295, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Innkeeper Farley - Linked - Say Line 2'),
(295, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Innkeeper Farley - Linked - Close Gossip'),
(524, 0, 0, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 11, 6268, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockhide Boar - On Aggro - Cast ''Rushing Charge'''),
(524, 0, 1, 0, 8, 0, 100, 0, 350249, 0, 600000, 600000, 0, 0, 33, 996121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Rockhide Boar - On Spellhit Enchanted Mineral - Credit testing the mineral, once per beast'),
(732, 0, 0, 0, 67, 0, 100, 0, 3900, 6900, 3900, 6900, 0, 5, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Lurker - On Behind Target - Cast ''Backstab'' (No Repeat)'),
(732, 0, 1, 2, 8, 0, 100, 0, 966240, 0, 0, 0, 0, 0, 33, 300220, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Lurker - On Spellhit Collect Slimy Murloc Spittle - Quest Credit'),
(732, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Murloc Lurker - Linked - Despawn the milked corpse'),
(822, 0, 0, 0, 8, 0, 100, 0, 350249, 0, 600000, 600000, 0, 0, 33, 996121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Young Forest Bear - On Spellhit Enchanted Mineral - Credit testing the mineral, once per beast'),
(1922, 0, 0, 1, 1, 0, 100, 0, 120000, 600000, 120000, 600000, 0, 0, 4, 1018, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gray Forest Wolf - Out of Combat - Play Sound 1018'),
(1922, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 5, 393, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gray Forest Wolf - Out of Combat - Play Emote 393'),
(1922, 0, 2, 0, 8, 0, 100, 0, 350249, 0, 600000, 600000, 0, 0, 33, 996121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gray Forest Wolf - On Spellhit Enchanted Mineral - Credit testing the mineral, once per beast');

DELETE FROM `creature_text` WHERE `CreatureID` = 295 AND `GroupID` = 2;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `comment`)
VALUES
(295, 2, 0, 'Defias? Never had any dealings with... well, not since the old masons'' guild days. Can I get you anything else?', 12, 0, 100, 'Innkeeper Farley - gives himself away (INFERRED)');

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 1291 AND `OptionID` = 4;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(1291, 4, 0, 'What do you know about the Defias?', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 1291 AND `SourceEntry` = 4;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceEntry` = 966240;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 1291, 4, 0, 0, 9, 0, 254108, 0, 0, 0, 0, 0, '', 'Innkeeper Farley - mole question only while Final Dig is taken'),
(17, 0, 966240, 0, 0, 36, 1, 0, 0, 0, 1, 0, 0, '', 'Collect Slimy Murloc Spittle - only on a corpse, never a living murloc');
