-- CoA Deathknell: the Cain Family Estate chain (1660024-1660029, 1660042), CoA 363 and 6395, the east
-- slope re-floors, the Pilgrim's Bounty turkeys there and the recorded Deathknell props;
-- Kobold Desecrators in the Cain crypt (1660025 texts; points inferred).
-- Creature guids 9010000-9010349, gameobject guids 7916000-7916119, gossip menus 932400-932414.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- Stand-in displays where the CoA model is missing from the client.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(161739, 'Anthon', 'Heritage League Delegate', 0, 7, 7, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161740, 'Riscell Cain', 'Heritage League', 0, 13, 13, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161741, 'Exsangue', 'Deathstalker', 0, 20, 20, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161742, 'Deathguard Eric', NULL, 0, 15, 15, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161746, 'Kalis', 'Heritage League', 0, 12, 12, 0, 68, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161747, 'Thris', 'Heritage League', 932402, 14, 14, 0, 68, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161748, 'Selevis', 'Heritage League', 932400, 12, 12, 0, 68, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(161743, 'Necrotic Bear', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 4, 1, 1, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161749, 'Zombie', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161752, 'Ghoul', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161753, 'Brainless Majordomo', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 161753, '', 0, 2, 1, 1, 1, 1, 0, 0, ''),
(161754, 'Brainless Maid', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 161754, '', 0, 2, 1, 1, 1, 1, 0, 0, ''),
(161755, 'Brainless Stablemaster', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 161755, '', 0, 2, 1, 1, 1, 1, 0, 0, ''),
(161757, 'Aberrant Progeny', NULL, 0, 7, 7, 0, 7, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 3, 0, 0, '', 0, 5.76, 1, 1, 1, 1, 0, 0, ''),
(161762, 'Mother', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161763, 'Father', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161764, 'Cousin Salem', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161765, 'Uncle Abel', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 6, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161836, 'Hound of House Cain', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 1, 0, 0, '', 0, 2.79, 1, 1, 1, 1, 0, 0, ''),
(161751, 'Kobold Desecrator', NULL, 0, 3, 3, 0, 26, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 7, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161739, 161740, 161741, 161742, 161743, 161746, 161747, 161748, 161749, 161751, 161752, 161753, 161754, 161755, 161757, 161762, 161763, 161764, 161765, 161836);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(161739, 0, 14756, 1, 1),
(161740, 0, 15113, 1, 1),
(161741, 0, 2863, 1, 1),
(161742, 0, 2855, 1, 1),
(161746, 0, 12290, 1, 1),
(161747, 0, 27289, 1, 1),
(161748, 0, 22537, 1, 1),
(161743, 0, 1082, 1, 1),
(161749, 0, 10979, 1, 1),
(161752, 0, 519, 1, 1),
(161753, 0, 828, 1, 1),
(161754, 0, 1200, 1, 1),
(161755, 0, 1196, 1, 1),
(161757, 0, 76125, 1, 1),
(161762, 0, 11835, 1, 1),
(161763, 0, 3222, 1, 1),
(161764, 0, 10483, 1, 1),
(161765, 0, 10478, 1, 1),
(161836, 0, 9021, 1, 1),
(161751, 0, 2299, 1, 1);

-- The Aberrant Progeny display lacks model info.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 76125;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(76125, 1, 1.5, 2, 0);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` IN (62702, 62710, 85169, 85170);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(62702, '<On closer inspection of the Forsaken, you realize that the only thing keeping her two eyeballs from plummeting to the ground are her dark-lensed spectacles. Pressed flat against the glass, dangling loosely by the optic nerve, they give her the unsettling look of having wide, ever-alert eyes.>$b$BGreetings!', '<On closer inspection of the Forsaken, you realize that the only thing keeping her two eyeballs from plummeting to the ground are her dark-lensed spectacles. Pressed flat against the glass, dangling loosely by the optic nerve, they give her the unsettling look of having wide, ever-alert eyes.>$b$BGreetings!', 0, 0, 1),
(62710, '<The Forsaken nods enthusiastically, sending the spectacles (and the dangling eyes behind them) bobbing up and down.>$b$bWhy, I’m one of its longest-standing members!$b$bBack when I was alive, I served in Capital City as the royal historian of Lordaeron. My final work, a biography of King Terenas, stands as the finest chronicle ever written of any monarch. Not all the credit is mine, of course; fate itself handed me the perfect ending: the crown prince, executioner of his own father. A story that practically wrote itself!$b$bAh, forgive me, I digress. As I was saying, I joined the Heritage League ages ago. I’ve taken part in nearly every expedition into Whispering Forest and beyond. You wouldn’t believe how many estates, manors, and palaces we’ve had to restore. And there’s still so much left to do...$b$bIf your road ever takes you into the Whispering Forest, seek out my colleague Seldorn in Cragstead. He’d welcome an extra pair of hands.$b$b', '<The Forsaken nods enthusiastically, sending the spectacles (and the dangling eyes behind them) bobbing up and down.>$b$bWhy, I’m one of its longest-standing members!$b$bBack when I was alive, I served in Capital City as the royal historian of Lordaeron. My final work, a biography of King Terenas, stands as the finest chronicle ever written of any monarch. Not all the credit is mine, of course; fate itself handed me the perfect ending: the crown prince, executioner of his own father. A story that practically wrote itself!$b$bAh, forgive me, I digress. As I was saying, I joined the Heritage League ages ago. I’ve taken part in nearly every expedition into Whispering Forest and beyond. You wouldn’t believe how many estates, manors, and palaces we’ve had to restore. And there’s still so much left to do...$b$bIf your road ever takes you into the Whispering Forest, seek out my colleague Seldorn in Cragstead. He’d welcome an extra pair of hands.$b$b', 0, 0, 1),
(85169, '<The Forsaken’s eyes are two tiny marbles. With each turn of her head they roll in their bony sockets, tethered by the optic nerve and a constant index finger that “seats” them back into place.>$b$b<Her attention rests on the ledger lying on the table.>', '<The Forsaken’s eyes are two tiny marbles. With each turn of her head they roll in their bony sockets, tethered by the optic nerve and a constant index finger that “seats” them back into place.>$b$b<Her attention rests on the ledger lying on the table.>', 0, 0, 1),
(85170, '<The Forsaken pries her gaze from the book with a gravedigger’s unhurried care.>$b$bI manage the estate. Despite Lordaeron’s ruin, we salvaged plenty: jewels, furniture, ceramics, tapestries, rugs, shoes, dresses… Those who owned them in life expect to reclaim them in death.$b$bOf course it isn’t that simple, especially for the aristocracy. They come asking to annul the wills they wrote in life, which now, in death, leave them at their families’ mercy. Families we can’t always find; not everyone who died was raised by the Scourge, and not everyone who became undead recovered free will…', '<The Forsaken pries her gaze from the book with a gravedigger’s unhurried care.>$b$bI manage the estate. Despite Lordaeron’s ruin, we salvaged plenty: jewels, furniture, ceramics, tapestries, rugs, shoes, dresses… Those who owned them in life expect to reclaim them in death.$b$bOf course it isn’t that simple, especially for the aristocracy. They come asking to annul the wills they wrote in life, which now, in death, leave them at their families’ mercy. Families we can’t always find; not everyone who died was raised by the Scourge, and not everyone who became undead recovered free will…', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932400, 932401, 932402, 932403);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932400, 62702),
(932401, 62710),
(932402, 85169),
(932403, 85170);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932400, 932401, 932402, 932403);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932400, 0, 0, 'What is the Heritage League?', 0, 1, 1, 932401, 0, 0, 0, '', 0),
(932402, 0, 0, 'What do you do here?', 0, 1, 1, 932403, 0, 0, 0, '', 0);

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`)
VALUES
(2300524, 0, 300448, 'Dungeon Door', '', '', 1, '', 0, 1903, 5000, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300528, 3, 69772, 'Gaudy Painting', '', '', 1, '', 1689, 2300528, 0, 0, 0, 0, 0, 0, 1660028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300529, 3, 7075, 'Shimmering Jewel', '', '', 1, '', 1689, 2300529, 0, 0, 0, 0, 0, 0, 1660028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300530, 3, 621, 'Crystal Ball', '', '', 1, '', 1689, 2300530, 0, 0, 0, 0, 0, 0, 1660028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300531, 3, 1011043, 'Family Signet', '', '', 1, '', 1689, 2300531, 0, 0, 0, 0, 0, 0, 1660028, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300540, 10, 84863, 'Remains of Riscell''s relatives', '', '', 1, 'SmartGameObjectAI', 0, 1660025, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300541, 10, 84864, 'Remains of Riscell''s relatives', '', '', 1, 'SmartGameObjectAI', 0, 1660025, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300542, 10, 84865, 'Remains of Riscell''s relatives', '', '', 1, 'SmartGameObjectAI', 0, 1660025, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2300543, 10, 84863, 'Remains of Riscell''s relatives', '', '', 1, 'SmartGameObjectAI', 0, 1660025, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(600632, 5, 8618, 'Banner Prop', '', '', 1.42242, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(600633, 5, 8364, 'Plague Cistern Prop', '', '', 0.327267, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(600636, 5, 63383, 'Cauldron Prop', '', '', 1.42242, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(174, 5, 166, 'Common Anvil', '', '', 2, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(520048, 5, 515675, 'Sturdy Arrow PROP', '', 'Looting', 0.1, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(523523, 5, 406, 'Ancient Statuette', '', '', 8, '', 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9303400, 10, 6479, 'Old Digging Shovel', '', '', 1, 'SmartGameObjectAI', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- The cellar door is locked like stock key doors; the quest objects are usable only while needed.
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (2300524, 2300528, 2300529, 2300530, 2300531, 2300540, 2300541, 2300542, 2300543);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`)
VALUES
(2300524, 0, 2),
(2300528, 0, 4),
(2300529, 0, 4),
(2300530, 0, 4),
(2300531, 0, 4),
(2300540, 0, 4),
(2300541, 0, 4),
(2300542, 0, 4),
(2300543, 0, 4);

DELETE FROM `creature_loot_template` WHERE `Entry` IN (161753, 161754, 161755);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161753, 559138, 0, 100, 1, 1, 0, 1, 1, 'Brainless Majordomo - key fragment'),
(161754, 559139, 0, 100, 1, 1, 0, 1, 1, 'Brainless Maid - key fragment'),
(161755, 559140, 0, 100, 1, 1, 0, 1, 1, 'Brainless Stablemaster - key fragment');

DELETE FROM `creature_questitem` WHERE `CreatureEntry` IN (161753, 161754, 161755);
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(161753, 0, 559138),
(161754, 0, 559139),
(161755, 0, 559140);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (2300528, 2300529, 2300530, 2300531);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300528, 559164, 0, 100, 1, 1, 0, 1, 1, 'Gaudy Painting'),
(2300529, 559165, 0, 100, 1, 1, 0, 1, 1, 'Shimmering Jewel'),
(2300530, 559166, 0, 100, 1, 1, 0, 1, 1, 'Crystal Ball'),
(2300531, 559167, 0, 100, 1, 1, 0, 1, 1, 'Family Signet');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (2300528, 2300529, 2300530, 2300531);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300528, 0, 559164),
(2300529, 0, 559165),
(2300530, 0, 559166),
(2300531, 0, 559167);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660024, 2, 6, 3, 154, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Monsters With Noble Intentions', 'Speak with Riscell Cain at the Heritage League camp.', 'Greetings.$B$BI’m Anthon, proud member of the Heritage League. By order of our queen, my organization has taken on the royal duty of cataloguing, reclaiming, and restoring the cultural legacy of Lordaeron so it may serve the Forsaken.$B$BNot far from here, the road winds west, up the hill, to the Cain family estates.$B$BHere, I’ll mark on your map the location of my colleagues’ camp. They could use an extra hand; even before Lordaeron’s fall, there were rumors the manor was cursed… all because of a certain witch.', '', 'Speak with Riscell Cain.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660025, 2, -1, 3, 154, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 8, 0, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Restless Family Members', 'Purify the remains of Riscell’s deceased relatives in the Cain Family Crypt, and send their spirits back to the Afterlife.', 'We’ve made good progress on our own, but there’s still a great deal of work ahead.$B$BI’ll get straight to it. My parents died a few years before the Scourge came, yet their crypt suffered desecrations and humiliations I can hardly bring myself to name. So much so that their spirits now haunt the halls they once walked in life; confused, tormented.$B$BGo down into the family crypt, where my ancestors lie buried, and offer a brief prayer for their souls. That should draw their spirits back to their remains… where you can face them and send them on to the afterlife, where they belong.', '', 'Return to Riscell.', 161762, 161763, 161764, 161765, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mother banished', 'Father banished', 'Cousin Salem banished', 'Uncle Abel banished'),
(1660026, 2, -1, 3, 154, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 8, 0, 828, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'An Unspeakable Secret', 'Retrieve the key fragments held by the manor’s majordomo, maid, and stablemaster.', 'With the spirits dealt with, there’s another matter… one far beyond the abilities of my colleagues.$B$BMy sister Priscilla, curse her name, turned the manor into a den of witchcraft. Her worst experiments were sealed away in the basement, whose key, we’ve just found out, was broken into three pieces, now held by the former majordomo, the maid, and the stablemaster. Brainless husks, the three of them.$B$BKill them and recover their fragments of the key. Exsangue will reforge it so you can open the basement and… give it a thorough cleaning.', '', 'Deliver the key fragments to Deathstalker Exsangue.', 0, 0, 0, 0, 0, 0, 0, 0, 559138, 559139, 559140, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(1660027, 2, 6, 3, 154, 0, 2, 0, 0, 0, 0, 0, 7, 25, 0, 0, 0, 0, 0, 559141, 8, 0, 559183, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The True Heir of the Cains', 'Use the key to access the basement and defeat the creature within.', 'Done.$B$B<Exsangue hands you the key, pieced together from the jagged remnants of the original. Twisted, splintered… its ability to hold remains as doubtful as whatever waits behind that door.>$B$BI’ll make sure no shambling corpse sneaks up on you while you deal with… whatever’s been locked away down there.$B$BMore than once, I’ve thought I heard a wail, followed by gurgling and screams. Tread carefully.', '', 'Report to Riscell on what transpired.', 161757, 0, 0, 0, 1, 0, 0, 0, 559141, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Aberrant Progeny defeated', '', '', ''),
(1660028, 2, 6, 3, 154, 0, 0, 0, 0, 0, 0, 0, 6, 50, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Noble Heritage', 'Explore Cain Family Manor and recover whatever valuables remain. Then bring them to Thris.', 'Do you know how the Heritage League funds itself?$B$BOur Queen allows us to keep a share of the treasures we recover. Which is why, up to now, we’ve restored far more palaces than fortresses.$B$BBefore their fall, the Cains were among the wealthiest families in the realm. I’d wager there’s still plenty in that manor worth laying hands on.$B$BGive it a look, will you? Depending on what you find, we might strike a deal.$B$BBut take care. The former lady of the manor, Riscell’s sister… Let’s just say the place is haunted.', '', 'Return to Thris.', 0, 0, 0, 0, 0, 0, 0, 0, 559164, 559165, 559166, 559167, 0, 0, 1, 1, 1, 1, 0, 0, '', '', '', ''),
(1660029, 2, -1, 3, 154, 0, 0, 0, 0, 0, 0, 0, 5, 30, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Friends We Make Along the Way', 'Slay the creatures prowling Cain Manor: zombies, ghouls, and bears.', 'You’ve noticed, haven’t you? I can barely keep up here. And these wretches keep finding new ways to get themselves in trouble.$B$BI know someone who could lend us a hand… if we can get the right ingredients.$B$BI must remain here, protecting the camp. But you… you’ve already proven you can handle yourself.$B$BKill the creatures prowling around the estate: zombies, ghouls, bears… Don’t bother hauling back what they leave behind; their organs are volatile, and if not handled properly they could spoil... or worse. I’ll take care of extracting what we need from their bodies once this is all over.', '', 'Return to Deathguard Eric.', 161743, 161752, 161749, 0, 1, 5, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660042, 2, 6, 3, 154, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559179, 1, 559180, 1, 559181, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'I''m Home', 'Defeat the Hound of House Cain behind the manor.', 'We are monsters. But sadder still than our fate is the confused, agonized misery of the beasts that roam our woods and fields.$B$BOnce, I think my heart might have pitied them. But I’ve no pity left. And besides, the practical thing is to put them down.$B$BEspecially the old, faithful hound of the Cain family.$B$BCircle the mansion, find his grave, and make sure he’s truly dead. He wouldn’t be the first undead mastiff to catch his master’s scent… and devour him.', '', 'Return to Kalis.', 161836, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660024, 1660025, 1660026, 1660027, 1660028, 1660029, 1660042);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660024, 0, 0, 0, 0, 0),
(1660025, 0, 0, 1660024, 0, 0),
(1660026, 0, 0, 1660025, 0, 0),
(1660027, 0, 0, 1660026, 1, 0),
(1660028, 0, 0, 1660025, 0, 0),
(1660029, 0, 0, 1660025, 0, 0),
(1660042, 0, 0, 1660025, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660024, 1660025, 1660026, 1660027, 1660028, 1660029, 1660042);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660024, 'Anthon sent you? The last Forsaken he dragged in caused more trouble than he was worth… but your tendons seem better preserved. Perhaps you can actually do something useful for us after all.$B$BAllow me to introduce myself:$B$BI am Riscell Cain. Yes; technically the last living heir with a claim to these lands… or at least, I would have been.$B$BStill, I feel they remain my responsibility. So I joined the Heritage League, determined to help restore my family’s estate and place it in service to the New Order.'),
(1660025, 'Kobolds, you say? The lowest sort; vandals, scavengers, petty thieves. Let them rot! I’ll personally see their burrows choked with blight.$B$BAs for your work… I’m impressed. Our deathstalker stationed in the manor reports the spirits no longer wander its halls and chambers.$B$BDo you know what that means? We’re ready for our next move.'),
(1660026, 'You have the key fragments?$B$BSplendid, I was beginning to get impatient.$B$BJust give me a moment…'),
(1660027, '<Riscell shakes his head slowly as you recount what you’ve seen.>$B$BThat creature… I’d heard the rumors, but even for my sister, they seemed too grotesque to believe.$B$BTo think Priscilla consorted with a demon… and bore that “thing”.$B$BIn any case, you’ve done the Heritage League a great service, and restored the dignity of my family name in the process. You have my “undying” gratitude.'),
(1660028, '<If greed had a color, it would be the yellow of this forsaken’s eyes.>$B$BA saucy painting… a crystal ball (likely cursed), a jewel we’d need appraised before celebrating, and a family signet whose worth, I’d wager, is purely sentimental.$B$BNot much, really. <She shrugs as if it were nothing. But her eyes… they say otherwise.>$B$BI doubt I’ll fetch much for these, but it’s better than nothing. As for the family signet… let’s do Riscell a favor and keep it. You know how painful it can be to dredge up old memories…'),
(1660029, 'You’re back. And you’ve left quite the trail of corpses behind you.$B$BGood.$B$B<The forsaken grins at the thought of what he’ll be able to harvest from the bodies.>$B$BWith this, and a spark of electricity, the forsaken I know can stitch us together a friend. You know, someone to lend a hand. Or two. Or three. I’m talking about one of those great bloated things we call “Abominations”.'),
(1660042, 'The hound… it’s dead?$B$B<The Forsaken shakes his head, heavy with sorrow.>$B$BA shame. Rot has twisted so many minds, it’s safer not to take chances.$B$BWho knows… perhaps this dog might’ve been different.$B$BHere. You’ve earned it.');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660024, 1660025, 1660026, 1660027, 1660028, 1660029, 1660042);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660025, 'Have you purified my family’s remains? If only my sister’s name were among those niches…'),
(1660026, 'Got the key fragments? Don’t tell me we made it too hard for you…'),
(1660027, 'I trust you’ve done the job. Otherwise, you wouldn’t be standing here so casually, talking to me… right?'),
(1660028, 'Did you find anything of value in there?'),
(1660029, 'Done with the shopping yet?'),
(1660042, 'I think I heard the beast howling in the distance. End it quickly, please.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (1660024, 1660025, 1660026, 1660027, 1660028, 1660029, 1660042);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161739, 1660024),
(161740, 1660025),
(161740, 1660026),
(161741, 1660027),
(161747, 1660028),
(161742, 1660029),
(161746, 1660042);

DELETE FROM `creature_questender` WHERE `quest` IN (1660024, 1660025, 1660026, 1660027, 1660028, 1660029, 1660042);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(161740, 1660024),
(161740, 1660025),
(161741, 1660026),
(161740, 1660027),
(161747, 1660028),
(161742, 1660029),
(161746, 1660042);

-- 363 is a kill quest in CoA; 6395 also asks for Samuel Fipps.
UPDATE `quest_template` SET `LogDescription` = 'Defeat Duskbats on the road to Deathknell.', `QuestDescription` = 'Finally, you’re awake. We almost gave up on you. I’m Mordo, caretaker of the Deathknell crypt. You’re free from the Lich King now.$B$BTo leave the crypt, take the steps up.$B$BDefeat the Duskbats on the road to Deathknell, then meet Shadow Priest Sarvis in the chapel at the bottom of the hill for further instructions.', `QuestCompletionLog` = 'Speak with Shadow Priest Sarvis at Deathknell.', `RequiredNpcOrGo1` = 1512, `RequiredNpcOrGoCount1` = 8 WHERE `ID` = 363;
UPDATE `quest_template` SET `RequiredNpcOrGo2` = 1919, `RequiredNpcOrGoCount2` = 1 WHERE `ID` = 6395;

-- ---------------------------------------------------------------------------
-- 5. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9010000, 9010001, 9010002, 9010003, 9010004, 9010005, 9010006, 9010007, 9010008, 9010009, 9010010, 9010011, 9010012, 9010020, 9010021, 9010022, 9010023, 9010024, 9010025, 9010026, 9010027, 9010028, 9010029, 9010030, 9010031, 9010032, 9010033, 9010034, 9010035, 9010036, 9010037, 9010038, 9010039, 9010040, 9010041, 9010042, 9010043, 9010050, 9010051, 9010052, 9010053, 9010054, 9010055, 9010056, 9010057, 9010058, 9010059, 9010060, 9010061, 9010062, 9010063, 9010064, 9010065, 9010066, 9010080, 9010081, 9010082, 9010083, 9010084, 9010085, 9010086, 9010087, 9010100, 9010101, 9010102, 9010103, 9010104, 9010105, 9010106, 9010107, 9010108, 9010109, 9010110, 9010111, 9010112, 9010113, 9010114, 9010115, 9010116, 9010117, 9010118, 9010119, 9010120, 9010121, 9010122, 9010123, 9010124, 9010130, 9010131, 9010132, 9010133) OR `guid` BETWEEN 9010000 AND 9010349;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9010000, 161739, 0, 0, 0, 1, 1, 0, 1847.8, 1597.3, 94.144, 0.52, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Questie point on the village street; faces the square'),
(9010001, 161740, 0, 0, 0, 1, 1, 0, 1869.9, 1838.75, 157.928, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8678, League camp; faces the estate path'),
(9010002, 161742, 0, 0, 0, 1, 1, 0, 1865.4, 1845, 157.761, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8704 (1.5 yd), League camp, clear of the bush; guards the path'),
(9010003, 161746, 0, 0, 0, 1, 1, 0, 1870.34, 1843.6, 157.936, 3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8719, League camp table'),
(9010004, 161747, 0, 0, 0, 1, 1, 0, 1873.87, 1843.89, 158.043, 3.79, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8703, League camp; faces the ledger on the table'),
(9010005, 161748, 0, 0, 0, 1, 1, 0, 1878, 1839, 158.24, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: between the two League tents; the League historian (INFERRED)'),
(9010006, 161741, 0, 0, 0, 1, 1, 0, 1936.42, 1974.28, 156.64, 5.48, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8686, manor hall; watches the cellar door'),
(9010007, 161753, 0, 0, 0, 1, 1, 0, 1921.41, 1929.9, 163.038, 3.9, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8683, manor upper floor'),
(9010008, 161754, 0, 0, 0, 1, 1, 0, 1916.91, 2005.17, 156.602, 0.8, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8684, outside the north wing'),
(9010009, 161754, 0, 0, 0, 1, 1, 0, 1934.19, 1991.89, 156.449, 2.3, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Questie point behind the manor'),
(9010010, 161755, 0, 0, 0, 1, 1, 0, 1887.46, 1946.77, 154.999, 5.5, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8685, in the stable'),
(9010011, 161757, 0, 0, 0, 1, 1, 0, 1931.89, 1957.86, 148.653, 0.83, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8687, manor cellar; faces the stair'),
(9010012, 161836, 0, 0, 0, 1, 1, 0, 1942.72, 1985.06, 156.079, 0.8, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: ST8718, at his grave behind the manor'),
(9010020, 161749, 0, 0, 0, 1, 1, 0, 1858, 1888.5, 157.09, 1.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; lower path bend, out of the bush on the Questie point'),
(9010021, 161749, 0, 0, 0, 1, 1, 0, 1864.83, 1895.24, 157.513, 0.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, path east of the camp'),
(9010022, 161749, 0, 0, 0, 1, 1, 0, 1867.59, 1902.22, 158.766, 2.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, path east of the camp'),
(9010023, 161749, 0, 0, 0, 1, 1, 0, 1872.1, 1893.5, 157.911, 4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, path east of the camp'),
(9010024, 161749, 0, 0, 0, 1, 1, 0, 1879.44, 1902.33, 159.066, 3.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, rise before the fence'),
(9010025, 161749, 0, 0, 0, 1, 1, 0, 1879.73, 1912.9, 158.92, 5.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, rise before the fence'),
(9010026, 161749, 0, 0, 0, 1, 1, 0, 1888.17, 1911.48, 158.974, 0.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, by the broken fence'),
(9010027, 161749, 0, 0, 0, 1, 1, 0, 1880.17, 1871.93, 157.663, 2.7, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, beside the stone bench'),
(9010028, 161749, 0, 0, 0, 1, 1, 0, 1889.19, 1869.86, 158.224, 4.4, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, beside the stone bench'),
(9010029, 161749, 0, 0, 0, 1, 1, 0, 1888.31, 1861.68, 158.558, 1.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, by the red rock'),
(9010030, 161749, 0, 0, 0, 1, 1, 0, 1861.92, 1933.49, 157.115, 5.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, west meadow'),
(9010031, 161749, 0, 0, 0, 1, 1, 0, 1857.7, 1936.1, 157.551, 3.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, west meadow'),
(9010032, 161749, 0, 0, 0, 1, 1, 0, 1850.14, 1934.69, 156.384, 0.3, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, west meadow'),
(9010033, 161749, 0, 0, 0, 1, 1, 0, 1855, 1942.5, 157.577, 2.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; under the canopy tree, out of the bush on the Questie point'),
(9010034, 161749, 0, 0, 0, 1, 1, 0, 1835.89, 1940.14, 156.165, 4.8, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, meadow toward the crypt'),
(9010035, 161749, 0, 0, 0, 1, 1, 0, 1829.2, 1937.96, 157.308, 1.9, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, meadow toward the crypt'),
(9010036, 161749, 0, 0, 0, 1, 1, 0, 1818.44, 1917.8, 158.72, 3.7, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, below the crypt hill'),
(9010037, 161749, 0, 0, 0, 1, 1, 0, 1852.5, 1916.5, 155.802, 0.7, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; south meadow, off the fallen tree on the Questie point'),
(9010038, 161749, 0, 0, 0, 1, 1, 0, 1839.8, 1907.8, 155.649, 5.5, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; south meadow, out of the bush on the Questie point'),
(9010039, 161749, 0, 0, 0, 1, 1, 0, 1900.96, 1916.93, 158.252, 2.2, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, beside the hearse'),
(9010040, 161749, 0, 0, 0, 1, 1, 0, 1903.8, 1923.36, 157.237, 4.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, beside the hearse'),
(9010041, 161749, 0, 0, 0, 1, 1, 0, 1865.7, 1964.76, 158.418, 1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, lake shore'),
(9010042, 161749, 0, 0, 0, 1, 1, 0, 1860.25, 1960.73, 158, 3.6, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, lake shore'),
(9010043, 161749, 0, 0, 0, 1, 1, 0, 1865.85, 1958.33, 157.455, 5.1, 180, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Zombie; Questie point, lake shore'),
(9010050, 161752, 0, 0, 0, 1, 1, 0, 1924.96, 1956.37, 155.808, 2.4, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, manor great hall'),
(9010051, 161752, 0, 0, 0, 1, 1, 0, 1943.14, 1957.35, 155.806, 3.9, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, manor east hall'),
(9010052, 161752, 0, 0, 0, 1, 1, 0, 1927.94, 1939.05, 154.141, 0.8, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, manor south room'),
(9010053, 161752, 0, 0, 0, 1, 1, 0, 1932, 1943, 154.141, 5.5, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point moved 2 yd off the stair edge, manor south room'),
(9010054, 161752, 0, 0, 0, 1, 1, 0, 1925.83, 1916.82, 157.345, 1.4, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, south lawn'),
(9010055, 161752, 0, 0, 0, 1, 1, 0, 1936.01, 1924.12, 154.996, 0.2, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, south lawn'),
(9010056, 161752, 0, 0, 0, 1, 1, 0, 1963.06, 1931.53, 155.922, 3, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, east field'),
(9010057, 161752, 0, 0, 0, 1, 1, 0, 1924.45, 1989.71, 157.971, 4.6, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, behind the manor'),
(9010058, 161752, 0, 0, 0, 1, 1, 0, 1903.58, 1980.12, 159.343, 2.9, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; Questie point, lakeside garden'),
(9010059, 161752, 0, 0, 0, 1, 1, 0, 1960, 1944, 156.903, 3.5, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; east field, before the manor front'),
(9010060, 161752, 0, 0, 0, 1, 1, 0, 1893, 1959, 156.006, 5, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; north of the stable door'),
(9010061, 161752, 0, 0, 0, 1, 1, 0, 1910, 1968, 156.177, 1.1, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; garden between the stable and the north wing'),
(9010062, 161752, 0, 0, 0, 1, 1, 0, 1948, 1924, 156.393, 2, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; south-east lawn corner'),
(9010063, 161752, 0, 0, 0, 1, 1, 0, 1955, 1972, 156.012, 4.2, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; by the red rock east of the north wing'),
(9010064, 161752, 0, 0, 0, 1, 1, 0, 1968, 1960, 157.481, 3.4, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; east field, toward the woods'),
(9010065, 161752, 0, 0, 0, 1, 1, 0, 1915, 1910, 158.292, 0.6, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; south lawn by the path'),
(9010066, 161752, 0, 0, 0, 1, 1, 0, 1946, 1935, 155.148, 2.8, 180, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Ghoul; east lawn by the manor wall'),
(9010080, 161743, 0, 0, 0, 1, 1, 0, 1802.95, 1961.38, 156.206, 1.5, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; Questie point, above the crypt mouth'),
(9010081, 161743, 0, 0, 0, 1, 1, 0, 1968.29, 1938.94, 155.868, 3.3, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; Questie point, east field'),
(9010082, 161743, 0, 0, 0, 1, 1, 0, 1976.8, 1952.12, 155.415, 4.1, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; Questie point, east field edge'),
(9010083, 161743, 0, 0, 0, 1, 1, 0, 1822, 1960, 156.327, 0.4, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; meadow between the crypt and the lake'),
(9010084, 161743, 0, 0, 0, 1, 1, 0, 1845, 1885, 156.835, 5.8, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; south slope below the camp'),
(9010085, 161743, 0, 0, 0, 1, 1, 0, 1904.8, 1997, 157.476, 2.2, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; lake shore north of the stable, out of the reeds'),
(9010086, 161743, 0, 0, 0, 1, 1, 0, 1830, 1890, 157.673, 1, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; south-west woods edge'),
(9010087, 161743, 0, 0, 0, 1, 1, 0, 1975, 1968, 154.888, 3.8, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Cain estate: Necrotic Bear; north-east field toward the woods'),
(9010130, 161751, 0, 0, 0, 1, 1, 0, 1781, 1970, 124.072, 2.84, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; lower hall between the parents'' niches, prying at Mother''s'),
(9010131, 161751, 0, 0, 0, 1, 1, 0, 1789, 1964, 124.072, 0.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; lower hall south side, rummaging toward Father''s niche'),
(9010132, 161751, 0, 0, 0, 1, 1, 0, 1757, 1944, 132.057, 2.62, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; west chamber, picking at Cousin Salem''s coffin'),
(9010133, 161751, 0, 0, 0, 1, 1, 0, 1788, 1940, 132.057, 4.54, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cain crypt: Kobold Desecrator; south-east chamber floor, turned toward Uncle Abel''s niche'),
(9010100, 1512, 0, 0, 0, 1, 1, 0, 1718, 1645, 124.696, 5.5, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; north of the upper road bend below the crypt hill'),
(9010101, 1512, 0, 0, 0, 1, 1, 0, 1726, 1622, 120.178, 0.8, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south of the upper road'),
(9010102, 1512, 0, 0, 0, 1, 1, 0, 1729, 1638, 120.878, 4.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; above the road by the grave frame'),
(9010103, 1512, 0, 0, 0, 1, 1, 0, 1741, 1633, 117.757, 3.6, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; north flank of the road'),
(9010104, 1512, 0, 0, 0, 1, 1, 0, 1735, 1616, 117.794, 1.3, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; west of the three canopy trees'),
(9010105, 1512, 0, 0, 0, 1, 1, 0, 1757, 1631, 115.51, 2.4, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; north flank, below the hearse'),
(9010106, 1512, 0, 0, 0, 1, 1, 0, 1763, 1605, 110.306, 0.1, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south of the road past the stump'),
(9010107, 1512, 0, 0, 0, 1, 1, 0, 1767, 1639, 113.398, 5, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; beside the coffin pile'),
(9010108, 1512, 0, 0, 0, 1, 1, 0, 1779, 1605, 108.839, 3.2, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; road side past the fallen tree'),
(9010109, 1512, 0, 0, 0, 1, 1, 0, 1787, 1590, 105.201, 1.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south of the lower road'),
(9010110, 1512, 0, 0, 0, 1, 1, 0, 1796, 1598, 102.314, 4.3, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; lower road toward the chapel'),
(9010111, 1512, 0, 0, 0, 1, 1, 0, 1741, 1592, 114.824, 0.6, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; by the tombstone monuments'),
(9010112, 1512, 0, 0, 0, 1, 1, 0, 1761, 1585, 110.969, 2.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south of the monuments'),
(9010113, 1512, 0, 0, 0, 1, 1, 0, 1729, 1598, 117.625, 5.3, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; below the canopy trees'),
(9010114, 1512, 0, 0, 0, 1, 1, 0, 1714, 1616, 122.071, 1.7, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; west slope under the crypt'),
(9010115, 1512, 0, 0, 0, 1, 1, 0, 1705, 1627, 123.058, 0, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; top of the road by the crypt stairs'),
(9010116, 1512, 0, 0, 0, 1, 1, 0, 1720, 1605, 120.134, 3.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; west slope south of the road'),
(9010117, 1512, 0, 0, 0, 1, 1, 0, 1770, 1580, 111.435, 2.2, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south hillside'),
(9010118, 1512, 0, 0, 0, 1, 1, 0, 1795, 1627, 110.214, 4.6, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; north bank of the lower road'),
(9010119, 1512, 0, 0, 0, 1, 1, 0, 1767, 1612, 111.137, 1.1, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; between the stump and the fallen tree'),
(9010120, 1512, 0, 0, 0, 1, 1, 0, 1728, 1568, 124.275, 0.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south-west hillside'),
(9010121, 1512, 0, 0, 0, 1, 1, 0, 1782, 1645, 111.97, 5.9, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; north of the coffin pile'),
(9010122, 1512, 0, 0, 0, 1, 1, 0, 1706, 1598, 122.902, 2.7, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; west edge below the crypt'),
(9010123, 1512, 0, 0, 0, 1, 1, 0, 1756, 1566, 113.409, 1.4, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; south edge by the lantern path'),
(9010124, 1512, 0, 0, 0, 1, 1, 0, 1778, 1631, 111.006, 3, 180, 10, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA 363 crypt road: Duskbat; by the coffins and lantern');

DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9010000 AND 9010349;

DELETE FROM `gameobject` WHERE `guid` IN (7916000, 7916001, 7916002, 7916003, 7916004, 7916005, 7916006, 7916007, 7916008, 7916010, 7916011, 7916012, 7916013, 7916014, 7916015, 7916018, 7916019) OR `guid` BETWEEN 7916000 AND 7916119;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7916000, 2300540, 0, 0, 0, 1, 1, 1767.97, 1974.13, 124.202, 4.38, 0, 0, 0.814341, -0.580387, 60, 100, 1, '', 'CoA Cain estate: ST8679, Mother''s niche; along the wall'),
(7916001, 2300541, 0, 0, 0, 1, 1, 1795.55, 1973.23, 124.202, 5.95, 0, 0, 0.165823, -0.986156, 60, 100, 1, '', 'CoA Cain estate: ST8680, Father''s niche'),
(7916002, 2300542, 0, 0, 0, 1, 1, 1751.59, 1947.12, 133.006, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Cain estate: atlas point on Salem''s coffin (ST8681)'),
(7916003, 2300543, 0, 0, 0, 1, 1, 1785.96, 1928.36, 132.544, 5.95, 0, 0, 0.165823, -0.986156, 60, 100, 1, '', 'CoA Cain estate: ST8682, Abel''s niche'),
(7916004, 2300524, 0, 0, 0, 1, 1, 1941.74, 1968.71, 155.844, 2.356, 0, 0, 0.923842, 0.382773, 0, 100, 1, '', 'CoA Cain estate: atlas point, top of the cellar stair; across the stairwell'),
(7916005, 2300528, 0, 0, 0, 1, 1, 1924.93, 1976.02, 158.776, 5.5, 0, 0, 0.381661, -0.924302, 120, 100, 1, '', 'CoA Cain estate: ST8699, upper floor wall; faces the room'),
(7916006, 2300529, 0, 0, 0, 1, 1, 1921.2, 1931.49, 154.155, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Cain estate: ST8700, south room floor'),
(7916007, 2300530, 0, 0, 0, 1, 1, 1924.93, 1955.26, 177.579, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Cain estate: ST8701, on the top floor round table'),
(7916008, 2300531, 0, 0, 0, 1, 1, 1939.4, 1945.25, 176.445, 0, 0, 0, 0, 1, 120, 100, 1, '', 'CoA Cain estate: ST8702, on the roof'),
(7916019, 9303400, 0, 0, 0, 1, 1, 1940, 1961, 148.651, 0.35, 0, 0, 0.174108, 0.984727, 60, 100, 1, '', 'CoA Cain estate: cellar floor west of the stair foot; lifts a player locked below the door back to the ground floor'),
(7916010, 600632, 0, 0, 0, 1, 1, 1659.56, 1687.91, 120.841, 5.62, 0, 0, 0.325549, -0.945525, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, beside Mordo; faces him'),
(7916011, 600633, 0, 0, 0, 1, 1, 1659.31, 1692.19, 120.635, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, beside Mordo'),
(7916012, 600636, 0, 0, 0, 1, 1, 1656.3, 1686.93, 119.953, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, beside Mordo'),
(7916013, 191351, 0, 0, 0, 1, 1, 1659.34, 1691.34, 120.719, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, over the cistern'),
(7916014, 174, 0, 0, 0, 1, 1, 1939.53, 1545.6, 90.165, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, abandoned smithy'),
(7916015, 520048, 0, 0, 0, 1, 1, 1849.41, 1759.76, 137.669, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, western gully'),
(7916018, 523523, 0, 0, 0, 1, 1, 2196.577, 1452.045, 87.955, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell prop: atlas point, east road');

-- ---------------------------------------------------------------------------
-- 6. Scripts
-- ---------------------------------------------------------------------------
-- Each remains summons its spirit at the player who prayed, and the spirit attacks that player; the remains
-- despawn for 60 s. The cellar shovel returns a player locked below the door to the ground floor.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161762, 161763, 161764, 161765) AND `source_type` = 0;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300540, 2300541, 2300542, 2300543, 9303400) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300540, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 161762, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - On Use - Summon Mother'),
(2300540, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - Linked - Despawn until it respawns'),
(2300541, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 161763, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - On Use - Summon Father'),
(2300541, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - Linked - Despawn until it respawns'),
(2300542, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 161764, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - On Use - Summon Cousin Salem'),
(2300542, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - Linked - Despawn until it respawns'),
(2300543, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 161765, 1, 120000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - On Use - Summon Uncle Abel'),
(2300543, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Remains of Riscell''s relatives - Linked - Despawn until it respawns'),
(9303400, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 1934.5, 1972, 156.64, 0.87, 'Old Digging Shovel - On Gossip Hello - Teleport to the manor ground floor');

-- ---------------------------------------------------------------------------
-- 7. Stock rows: Marla's Grave, the east slope and its turkeys
-- ---------------------------------------------------------------------------
-- Marla's Grave to CoA's point in the graveyard's first row (ST6961).
UPDATE `gameobject` SET `position_x` = 1884.37, `position_y` = 1587.55, `position_z` = 89.559 WHERE `guid` = 45015 AND `id` = 178090;
-- East slope: terrain CoA raised or lowered around the new Felo camp.
UPDATE `creature` SET `position_x` = 1920.77, `position_y` = 1754.41, `position_z` = 102.131 WHERE `guid` = 38317 AND `id` = 1512;
UPDATE `creature` SET `position_x` = 1911.89, `position_y` = 1753.78, `position_z` = 100.186 WHERE `guid` = 41897 AND `id` = 1512;
UPDATE `creature` SET `position_x` = 1936, `position_y` = 1678, `position_z` = 83.163 WHERE `guid` = 44730 AND `id` = 1512;
UPDATE `creature` SET `position_x` = 1942.02, `position_y` = 1673.68, `position_z` = 81.193 WHERE `guid` = 44829 AND `id` = 1508;
UPDATE `creature` SET `position_x` = 1888.92, `position_y` = 1729.84, `position_z` = 94.972 WHERE `guid` = 44825 AND `id` = 1508;
UPDATE `creature` SET `position_x` = 1930.21, `position_y` = 1662.69, `position_z` = 80.665 WHERE `guid` = 44831 AND `id` = 1502;
UPDATE `creature` SET `position_x` = 1884.93, `position_y` = 1772.64, `position_z` = 117.882 WHERE `guid` = 41900 AND `id` = 1512;
UPDATE `creature` SET `position_x` = 1907.38, `position_y` = 1691.07, `position_z` = 86.34 WHERE `guid` = 44731 AND `id` = 1512;
UPDATE `creature` SET `position_x` = 1905.41, `position_y` = 1601.54, `position_z` = 85.682 WHERE `guid` = 44926 AND `id` = 1501;
UPDATE `creature` SET `position_x` = 1919.49, `position_y` = 1623.68, `position_z` = 82.311 WHERE `guid` = 44935 AND `id` = 1501;
-- Pilgrim's Bounty turkeys (event 26) on the same slope.
UPDATE `creature` SET `position_x` = 1927.26, `position_y` = 1692.24, `position_z` = 85.932 WHERE `guid` = 240648 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1912.12, `position_y` = 1645.39, `position_z` = 82.448 WHERE `guid` = 242380 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1922.86, `position_y` = 1625.93, `position_z` = 81.841 WHERE `guid` = 242408 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1912.84, `position_y` = 1604.96, `position_z` = 83.023 WHERE `guid` = 242483 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1922.86, `position_y` = 1660.1, `position_z` = 81.55 WHERE `guid` = 242490 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1881.93, `position_y` = 1774.41, `position_z` = 118.742 WHERE `guid` = 242769 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1917.79, `position_y` = 1752.5, `position_z` = 101.037 WHERE `guid` = 242784 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1908, `position_y` = 1752, `position_z` = 99.697 WHERE `guid` = 242820 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1913.28, `position_y` = 1698.36, `position_z` = 88.259 WHERE `guid` = 242824 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1908.9, `position_y` = 1605.24, `position_z` = 83.32 WHERE `guid` = 243899 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1910.31, `position_y` = 1641.54, `position_z` = 84.086 WHERE `guid` = 243904 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1926.77, `position_y` = 1661.55, `position_z` = 81.155 WHERE `guid` = 243906 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1931.45, `position_y` = 1688.03, `position_z` = 84.995 WHERE `guid` = 243914 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1936, `position_y` = 1542, `position_z` = 90.14 WHERE `guid` = 241974 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1905.91, `position_y` = 1666.46, `position_z` = 83.728 WHERE `guid` = 242845 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1960, `position_y` = 1604, `position_z` = 88.174 WHERE `guid` = 241984 AND `id` = 32820;
UPDATE `creature` SET `position_x` = 1870, `position_y` = 1557, `position_z` = 93.207 WHERE `guid` = 242420 AND `id` = 32820;
