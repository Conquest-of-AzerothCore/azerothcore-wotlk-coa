-- Conquest of Azeroth class trainers in Coldridge Valley (package ct-coldridge): the fifteen trainers of
-- the Coldridge intro letters, the letters themselves, and the first class chains with every chain NPC,
-- object, drop and credit they need. Builds on rev_20260923_05_coa_class_trainer_core.sql (trainer
-- kits 900000+class, class menus 930000+class, shared chain templates).
--
-- WHERE EACH VALUE COMES FROM
--   trainer positions  SOURCED-CLIENT: the QuestSuperTrack turn-in point of each intro letter, z from the
--     server floor (surface.floor). Zipak Cogweight stands at the CoA-only grave scene in Kharanos that his
--     point marks. Facings are INFERRED toward the way players arrive; each spawn comment says which.
--   trainer names  SOURCED-CACHE (creaturecache) for 13; Yiro the Vanquisher and Zipak Cogweight are new
--     NPCs named by their letters. Letter texts that name older NPCs (Elund Stormbelch, Savina Gloom, Aldus
--     Hammerfist, Harodormu) stay verbatim; the NPC at the point is the cache record.
--   looks  no capture of any trainer exists: every creature_display_preset is a stand-in copied from a
--     stock NPC of the right race, sex and craft (named per row) and then varied (INFERRED).
--   quests  SOURCED-CACHE questcache. Letters start at Sten Stoutarm after Dwarven Outfitters (179), the
--     stock letter pattern (INFERRED); chains start at the letter trainer. Letter pages 6002, 6003, 6006,
--     6011, 6013, 6014 and 6015 come from pagetextcache (paragraph breaks restored as $B$B); 6001, 6004,
--     6005, 6007, 6008, 6009, 6010 and 6012 are missing everywhere and are new text in CoA's voice.
--   chain places  INFERRED from the quest texts and hand-placed on the CoA terrain: the frozen lake
--     (Scorch), the ruined excavation camp among the Burly Rockjaw Troggs (the ritual circle and the
--     scrap), the broken-cart camp south of Anvilmar (the pendant), the flat valley floor at the foot of
--     the Coldridge Pass road (the statue), Anvilmar itself (wand, riddle answer, Efry, the disguised
--     witch); Gyrothor beside Zipak at the Kharanos grave (200199 "in this very room").
--   drops  SOURCED-EXILES creature_loot chances (724: 45/55/45% bones, flesh, skull, 33% power core;
--     707: 25% small sword); Scorch 100%.
--   stock spawns  every stock class trainer keeps its post and role. Marryk Nurribit (guid 1025), 0.24 yd
--     from Grelin Ironbeard's point, steps aside and Bromos Grummner (guid 403) is hidden while the
--     Cultist kill copy stands at his post (rev_20260924_13).
--
-- Blocks: creature guid 9003300-9003499, gameobject guid 7912200-7912299, creature entry 9300150-9300199,
-- gameobject entry 9301150-9301199, gossip and npc_text 930250-930299.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- 502952 Grelin Ironbeard (Barbarian): name and subname from creaturecache 502952 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Granis
--   Swiftaxe 1229 (Ironforge warrior trainer), changed iron-grey hair and a braided beard, bare chest under one
--   plate pauldron, mountaineer bracers; race from Barbarian, "I be Grelin Ironbeard ... every dwarf's heart"
--   (npccache 587577)
-- 502771 Freja Stormbelch (Stormbringer): name and subname from creaturecache 502771 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 female from dwarf female from
--   Karrina Mekenda 2879 (mail pauldrons), changed helm removed to show braided hair, storm-blue mail; race from
--   the Stormbelch surname is dwarven; the cache record is a woman (the letter names Elund)
-- 503241 Kharzon the Hammer (Guardian): name and subname from creaturecache 503241 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Jern
--   Hornhelm 1105 (Ironforge plate helm), changed darker hair and a forked beard; race from page 6002 signs
--   "Kharzon the Hammer"; 200119 calls the trainer "he"
-- 502800 Thiduis Pride (Templar): name and subname from creaturecache 502800 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Azar
--   Stronghammer 1232 (paladin trainer), changed white hair and beard, plate shoulders added; race from page
--   6003 "By beard and hammer ... dwarven devotion"
-- 503411 Baruhr Mightmane (Ranger): name and subname from creaturecache 503411 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Grif Wildheart
--   1231 (hunter trainer), changed leather cap added, darker mane and beard; race from the Mightmane surname and
--   the Coldridge letter
-- 502820 Bieko (Chronomancer): name and subname from creaturecache 502820 (SOURCED-CACHE); look is a stand-in,
--   no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 7 male from gnome male from Magis Sparkmantle
--   1228 (mage trainer), changed sand-coloured hair, leather mantle for bronze tones; race from Chronomancer was
--   a gnome class, not a dwarf one (RACE-CLASS.md)
-- 502924 Ophana Gloom (Necromancer): name and subname from creaturecache 502924 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 7 female from gnome female from
--   Twilight Acolyte 4809 (hooded robes), changed pale skin and black hair under the hood; race from Necromancer
--   was a gnome class, not a dwarf one (RACE-CLASS.md)
-- 503400 Debbie Whirlyflame (Pyromancer): name and subname from creaturecache 503400 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 7 female from gnome female from
--   Dalaran Mage 1914, changed ember-red hair, Dalaran tabard removed; race from the gnomish name and the
--   whirling voice of 200143
-- 502830 Clippo Doomwhistle (Cultist): name and subname from creaturecache 502830 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 7 male from gnome male from Twilight
--   Loreseeker 4812 (cultist robes), changed changed hair, beard and face; race from the gnomish name
-- 503271 Cleric Stonelight (Sun Cleric): name and subname from creaturecache 503271 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 female from dwarf female from Dun
--   Garok Priest 2346, changed hood removed to show fair hair, white vestments; race from the dwarven surname;
--   nothing in 200060 names a sex, so a woman varies the dwarf roster
-- 502870 Binkle Coldbolt (Tinker): name and subname from creaturecache 502870 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 7 male from gnome male from Finbus
--   Geargrind 1676 (engineering trainer, goggles), changed changed hair and beard; race from the gnomish name;
--   200089 calls him "he"
-- 9300151 Zipak Cogweight (Reaper): new NPC Zipak Cogweight, named as the letter 51014 and page 6015 ("Zipak
--   Cogweight, Reaper Trainer") (INFERRED: no cache record); look is a stand-in, no SMSG_MIRRORIMAGE_DATA
--   capture of this trainer exists: race 7 male from gnome male from Gimrizz Shadowcog 5612 (warlock trainer),
--   changed ashen skin, dark hood added; race from the gnomish name Cogweight (letter 51014, page 6015)
-- 50342 Katho Hammerfist (Primalist): name and subname from creaturecache 50342 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Hegnar
--   Rumbleshot 1243, changed leather pauldrons added, wild hair; race from the Hammerfist surname (page 6014)
-- 502910 Murmon Fuseforge (Runemaster): name and subname from creaturecache 502910 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 3 male from dwarf male from Tognus
--   Flintfire 1241 (smith apron), changed forge gloves added, changed hair and beard; race from page 6011 "our
--   oldest halls"
-- 9300150 Yiro the Vanquisher (Witch Hunter): new NPC Yiro the Vanquisher, named as the letter 51012 and page
--   6013 ("Yiro the Vanquisher, Witch Hunter Trainer") (INFERRED: no cache record); look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: race 1 male from human male from Osborne the Night Man
--   918 (dark leathers), changed wide-brimmed hunter hat added, black hair; race from Witch Hunter was never a
--   dwarf or gnome class (RACE-CLASS.md), so Yiro is a human hunter of witches
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(502952, 'Grelin Ironbeard', 'Barbarian Trainer', 930250, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502771, 'Freja Stormbelch', 'Stormbringer Trainer', 930016, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503241, 'Kharzon the Hammer', 'Guardian Trainer', 930018, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502800, 'Thiduis Pride', 'Templar Trainer', 930019, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503411, 'Baruhr Mightmane', 'Ranger Trainer', 930021, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502820, 'Bieko', 'Chronomancer Trainer', 930022, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502924, 'Ophana Gloom', 'Necromancer Trainer', 930023, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503400, 'Debbie Whirlyflame', 'Pyromancer Trainer', 930024, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502830, 'Clippo Doomwhistle', 'Cultist Trainer', 930025, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503271, 'Cleric Stonelight', 'Sun Cleric Trainer', 930027, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502870, 'Binkle Coldbolt', 'Tinker Trainer', 930028, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300151, 'Zipak Cogweight', 'Reaper Trainer', 930030, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50342, 'Katho Hammerfist', 'Primalist Trainer', 930031, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502910, 'Murmon Fuseforge', 'Runemaster Trainer', 930032, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300150, 'Yiro the Vanquisher', 'Witch Hunter Trainer', 930015, 10, 10, 0, 55, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50342, 502771, 502800, 502820, 502830, 502870, 502910, 502924, 502952, 503241, 503271, 503400, 503411, 9300150, 9300151);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(502952, 0, 53, 1, 1),
(502771, 0, 54, 1, 1),
(503241, 0, 53, 1, 1),
(502800, 0, 53, 1, 1),
(503411, 0, 53, 1, 1),
(502820, 0, 1563, 1, 1),
(502924, 0, 1564, 1, 1),
(503400, 0, 1564, 1, 1),
(502830, 0, 1563, 1, 1),
(503271, 0, 54, 1, 1),
(502870, 0, 1563, 1, 1),
(9300151, 0, 1563, 1, 1),
(50342, 0, 53, 1, 1),
(502910, 0, 53, 1, 1),
(9300150, 0, 49, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (50342, 502771, 502800, 502820, 502830, 502870, 502910, 502924, 502952, 503241, 503271, 503400, 503411, 9300150, 9300151);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(502952, 53, 3, 0, 1, 3, 6, 5, 8, 9, 0, 0, 7326, 0, 0, 1326, 2038, 2370, 3520, 1027, 0, 0),
(502771, 54, 3, 1, 1, 2, 3, 7, 4, 0, 0, 0, 10583, 10584, 0, 10585, 4499, 10586, 0, 0, 0, 0),
(503241, 53, 3, 0, 1, 1, 3, 3, 2, 5, 0, 12033, 0, 11641, 9812, 3369, 642, 3542, 3560, 1214, 0, 0),
(502800, 53, 3, 0, 1, 2, 8, 7, 9, 10, 0, 0, 13715, 0, 3671, 1346, 3672, 2938, 3673, 3674, 0, 0),
(503411, 53, 3, 0, 1, 5, 2, 1, 6, 8, 0, 12487, 0, 548, 0, 2286, 7510, 7511, 0, 7512, 0, 0),
(502820, 1563, 7, 0, 1, 1, 7, 2, 8, 3, 0, 0, 145942, 7343, 0, 7020, 7344, 6247, 0, 0, 0, 0),
(502924, 1564, 7, 1, 1, 4, 2, 8, 1, 0, 0, 144978, 0, 147150, 148598, 150212, 10349, 154354, 0, 156852, 0, 0),
(503400, 1564, 7, 1, 1, 0, 2, 5, 2, 0, 0, 0, 0, 0, 148616, 150266, 152208, 154412, 0, 0, 0, 0),
(502830, 1563, 7, 0, 1, 3, 1, 6, 5, 2, 0, 0, 0, 147154, 148601, 150215, 1973, 154357, 0, 156855, 0, 0),
(503271, 54, 3, 1, 1, 1, 5, 4, 9, 0, 0, 0, 0, 0, 147255, 150323, 152268, 154478, 156238, 156935, 0, 0),
(502870, 1563, 7, 0, 1, 1, 8, 5, 3, 4, 0, 8997, 0, 8998, 7415, 3531, 5405, 546, 0, 670, 0, 0),
(9300151, 1563, 7, 0, 1, 7, 3, 0, 0, 6, 0, 144980, 0, 3292, 0, 2468, 3279, 7122, 0, 2825, 0, 0),
(50342, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(502910, 53, 3, 0, 1, 0, 9, 4, 3, 2, 0, 0, 0, 7314, 7315, 5398, 598, 3351, 0, 5628, 0, 0),
(9300150, 49, 1, 0, 1, 2, 4, 2, 0, 5, 0, 12488, 0, 9951, 2988, 1420, 1199, 1112, 0, 3358, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50342, 502771, 502800, 502820, 502830, 502870, 502910, 502924, 502952, 503241, 503271, 503400, 503411, 9300150, 9300151);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(502952, 1, 2025, 0, 0),
(502771, 1, 2072, 0, 0),
(503241, 1, 2028, 12997, 0),
(502800, 1, 1976, 0, 0),
(503411, 1, 2878, 0, 2511),
(502820, 1, 16894, 0, 0),
(502924, 1, 2013, 0, 0),
(503400, 1, 5201, 0, 0),
(502830, 1, 7166, 2944, 0),
(503271, 1, 22980, 0, 0),
(502870, 1, 6219, 0, 2508),
(9300151, 1, 13054, 0, 0),
(50342, 1, 1317, 0, 0),
(502910, 1, 5956, 4838, 0),
(9300150, 1, 3572, 1172, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (50342, 502771, 502800, 502820, 502830, 502870, 502910, 502924, 502952, 503241, 503271, 503400, 503411, 9300150, 9300151);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(502952, 900012),
(502771, 900016),
(503241, 900018),
(502800, 900019),
(503411, 900021),
(502820, 900022),
(502924, 900023),
(503400, 900024),
(502830, 900025),
(503271, 900027),
(502870, 900028),
(9300151, 900030),
(50342, 900031),
(502910, 900032),
(9300150, 900015);

-- ---------------------------------------------------------------------------
-- 2. Named menus and texts
-- ---------------------------------------------------------------------------
-- Grelin Ironbeard keeps his own cached greeting (npccache 587577) with the Barbarian refusal and
-- training option; Gyrothor Turbospark talks to the Reaper of 200199 (INFERRED text).
DELETE FROM `npc_text` WHERE `ID` IN (587577, 930251);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(587577, 'Har! Another warrior seeks the way of primal fury, eh? I be Grelin Ironbeard, and I''ve been smashin'' skulls since before ye were born, lad! In the deepest tunnels of Ironforge, where the forges burn hottest, I learned that true strength comes not from hammer and anvil, but from the savage fire that burns within every dwarf''s heart. Ye got that fire in yer belly? Then step forward and I''ll teach ye to fight like the mountain itself!', 'Har! Another warrior seeks the way of primal fury, eh? I be Grelin Ironbeard, and I''ve been smashin'' skulls since before ye were born, lad! In the deepest tunnels of Ironforge, where the forges burn hottest, I learned that true strength comes not from hammer and anvil, but from the savage fire that burns within every dwarf''s heart. Ye got that fire in yer belly? Then step forward and I''ll teach ye to fight like the mountain itself!', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930251, 'Hmph. Come to watch an old cog wind down, have you? Eighty years of gears and grease, and all I get at the end is a cold chair and a colder draught.', 'Hmph. Come to watch an old cog wind down, have you? Eighty years of gears and grease, and all I get at the end is a cold chair and a colder draught.', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930250, 930251);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930250, 587577),
(930250, 287575),
(930251, 930251);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930250, 930251);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930250, 0, 3, 'I seek training as a Barbarian.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930251, 0, 0, 'Zipak Cogweight asked me to keep you company for a while.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930250, 930251) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930250, 587577, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Barbarian'),
(14, 930250, 287575, 0, 0, 15, 0, 2048, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Barbarian'),
(15, 930250, 0, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Barbarian'),
(15, 930251, 0, 0, 0, 9, 0, 200199, 0, 0, 0, 0, 0, '', 'Gyrothor Turbospark - option only while Call of the Shadowlands is taken');

-- ---------------------------------------------------------------------------
-- 4. Chain NPCs
-- ---------------------------------------------------------------------------
-- 9300154 Gyrothor Turbospark: new NPC named by quest 200199 ("a gnome who is near his end, Gyrothor
--   Turbospark"); INFERRED look; look gnome male from Doctor Draxlegauge 2774 (monocle, coat), changed aged
--   face, pale hair, long beard (INFERRED stand-in)
-- 9300155 Hulda Frostwhisper: new NPC: the witch of 200255 in her disguise ("She's here in Anvilmar"); name
--   INFERRED; look dwarf female from Rudra Amberstill 1265 (homespun dress), changed grey hair, older face
--   (INFERRED stand-in)
-- 299326 Kali: fixed quest entry 299326 of 200105 ("They're known as Kali. Kill her"); INFERRED dwarf rookie;
--   look dwarf female from Bael'dun Digger 2989 (rough leathers), changed changed hair and face (INFERRED stand-
--   in)
-- 254000 Efry Cogspark: creaturecache 254000 with its CoA display 254001 (model info in rev_20260925_11); a
--   gnome woman and inventor (npccache 58058 "Efry's the brightest gnome"); unarmed because 200118 asks for a
--   weapon
-- 299236 Bromos Grummner: fixed quest entry 299236 of 200072; the stock paladin trainer 926 look (display 3393)
--   and mace 1903; neutral faction 7 so the Anvilmar guards stay out of it
-- 9300152 Talos: new NPC named by quest 200002 ("my falcon, Talos"); display 25103 is the small eagle (scale
--   0.45), the nearest bird of prey in the client (INFERRED stand-in)
-- 9300153 Scorch: new NPC named by quest 200143 ("a fire elemental ... his name is Scorch"); display 1405 small
--   fire elemental
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9300154, 'Gyrothor Turbospark', '', 930251, 8, 8, 0, 55, 1, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(9300155, 'Hulda Frostwhisper', '', 0, 5, 5, 0, 55, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(299326, 'Kali', '', 0, 4, 4, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 134217728, 0, 'SmartAI', 0, 1.2, 1, 1, 1, 0, ''),
(254000, 'Efry Cogspark', '', 0, 10, 10, 0, 55, 2, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 7, 134217728, 0, '', 0, 1.225, 1, 1, 1, 2, ''),
(299236, 'Bromos Grummner', '', 0, 5, 5, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 2, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300152, 'Talos', 'Baruhr''s Falcon', 0, 3, 3, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(9300153, 'Scorch', '', 0, 5, 5, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 4, 0, 9300153, '', 0, 1.5, 1, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254000, 299236, 299326, 9300152, 9300153, 9300154, 9300155);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(9300154, 0, 1563, 1, 1),
(9300155, 0, 54, 1, 1),
(299326, 0, 54, 1, 1),
(254000, 0, 254001, 1, 1),
(299236, 0, 3393, 1, 1),
(9300152, 0, 25103, 1, 1),
(9300153, 0, 1405, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (254000, 299326, 9300154, 9300155);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(9300154, 1563, 7, 0, 1, 0, 11, 1, 6, 6, 0, 2330, 0, 8475, 8476, 5398, 2848, 3382, 0, 8478, 0, 0),
(9300155, 54, 3, 1, 1, 4, 11, 10, 8, 0, 0, 0, 0, 3254, 0, 3255, 3256, 3257, 0, 0, 0, 0),
(299326, 54, 3, 1, 1, 3, 6, 9, 2, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (254000, 299236, 299326, 9300152, 9300153, 9300154, 9300155);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(299326, 1, 2491, 0, 0),
(299236, 1, 1903, 0, 0);

DELETE FROM `creature_text` WHERE `CreatureID` IN (299326, 9300154, 9300155);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `comment`)
VALUES
(9300154, 0, 0, 'The Shadowlands, is it? Hmph. Just one more contraption I haven''t taken apart yet. Thank you for sitting with me, $n.', 12, 0, 100, 1, 'Gyrothor Turbospark - after the Reaper keeps him company (INFERRED)'),
(9300155, 0, 0, 'So the Vanquisher sent a pup to sniff me out! Then burn with me!', 14, 0, 100, 0, 'Hulda Frostwhisper - revealed by the Witcher''s Torch (INFERRED)'),
(299326, 0, 0, 'The Warband turned me away? Then I''ll carve my own way in, starting with you!', 14, 0, 100, 0, 'Kali - on aggro (INFERRED)');

-- ---------------------------------------------------------------------------
-- 5. Chain objects
-- ---------------------------------------------------------------------------
-- 9301150 Training Wand: 200166: Harodormu's wand left in Anvilmar; the wand model 100515 (INFERRED object, no
--   cache record)
-- 9301151 Eye of the Beholder: 200110: the answer to the Riddlestone, inside Anvilmar; a crystal-ball model
--   (4891) (INFERRED object, no cache record)
-- 9301152 Ritual Circle: 200043-200045: Ophana's ritual circle; display 6679 at size 0.4, CoA's own Magic Circle
--   Visual pairing (gameobjectcache 90267) (INFERRED object, no cache record)
-- 9301153 Lost Pendant: 200060: the Sun Cleric's pendant dropped at the pillaged camp; the necklace model
--   1010146 (INFERRED object, no cache record)
-- 9301154 Scrap Metal: 200066: salvage left at the ruined excavation camp that the Burly Rockjaw Troggs overran
--   ("one of those abandoned camps that are infested with troggs"); the ruined steam-tank gear model 7000
--   (INFERRED object, no cache record)
-- 9301155 Statue of Uther: 200083: "a statue erected ... in honor of a powerful Paladin who fell during the
--   third war"; UtherStatue.mdx (6815) (INFERRED object, no cache record)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`)
VALUES
(9301150, 3, 100515, 'Training Wand', '', 1, 43, 9301150, 0, 1, 0, 0, 0, 0, 200166, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301151, 3, 4891, 'Eye of the Beholder', '', 0.6, 43, 9301151, 0, 1, 0, 0, 0, 0, 200110, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301152, 2, 6679, 'Ritual Circle', '', 0.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI'),
(9301153, 3, 1010146, 'Lost Pendant', '', 1, 43, 9301153, 0, 1, 0, 0, 0, 0, 200060, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301154, 3, 7000, 'Scrap Metal', '', 0.8, 43, 9301154, 0, 1, 0, 0, 0, 0, 200066, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301155, 5, 6815, 'Statue of Uther', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9301150, 9301151, 9301153, 9301154);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9301150, 661335, 0, 100, 1, 1, 0, 1, 1, 'CoA Coldridge: Training Wand (quest 200166)'),
(9301151, 661330, 0, 100, 1, 1, 0, 1, 1, 'CoA Coldridge: Eye of the Beholder (quest 200110)'),
(9301153, 663319, 0, 100, 1, 1, 0, 1, 1, 'CoA Coldridge: Lost Pendant (quest 200060)'),
(9301154, 663320, 0, 100, 1, 1, 0, 1, 1, 'CoA Coldridge: Scrap Metal (quest 200066)');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (9301150, 9301151, 9301153, 9301154);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(9301150, 0, 661335),
(9301151, 0, 661330),
(9301153, 0, 663319),
(9301154, 0, 663320);

-- ---------------------------------------------------------------------------
-- 6. Drops
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((724, 458421), (724, 458422), (724, 458423), (724, 661417), (707, 662330), (9300153, 662331));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(724, 458421, 0, 45, 1, 1, 0, 1, 1, 'Burly Rockjaw Trogg - Bones (200044; Exiles creature_loot 45%)'),
(724, 458422, 0, 55, 1, 1, 0, 1, 1, 'Burly Rockjaw Trogg - Fresh Flesh (200044; Exiles creature_loot 55%)'),
(724, 458423, 0, 45, 1, 1, 0, 1, 1, 'Burly Rockjaw Trogg - Skull (200044; Exiles creature_loot 45%)'),
(724, 661417, 0, 33, 1, 1, 0, 1, 1, 'Burly Rockjaw Trogg - Power Core (200090; Exiles creature_loot 33%)'),
(707, 662330, 0, 25, 1, 1, 0, 1, 1, 'Rockjaw Trogg - Small Sword (200118; Exiles creature_loot 25%)'),
(9300153, 662331, 0, 100, 1, 1, 0, 1, 1, 'Scorch - Heart of Scorch (200143; the text: "obtain his heart")');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((724, 0), (724, 1), (724, 2), (724, 3), (707, 0), (9300153, 0));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(724, 0, 458421),
(724, 1, 458422),
(724, 2, 458423),
(724, 3, 661417),
(707, 0, 662330),
(9300153, 0, 662331);

-- ---------------------------------------------------------------------------
-- 7. Quests
-- ---------------------------------------------------------------------------
-- The Ranger's Path (200002) carries the Northshire copy's map point (-8799.29, -412.93) in the cache;
-- it points at Talos's post here, the quest's own target (DERIVED). The Stolen Power Core (200090):
-- ObjectiveText1 is '0' in the cache (a CoA data quirk on its seven copies only); left blank.
-- RewardNextQuest (the next step is offered at turn-in): questcache NextQuestInChain where the next quest is in
--   this file: 200117->200118, 200118->200119, 200043->200044, 200044->200045, 200002->200003, 200003->200004,
--   200089->200090, 200090->200091.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(51000, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Storm Codex', 'Seek out Storm Codex and seek out Elund Stormbelch in Coldridge Valley.', 'The mountain air crackles with energy around this tome, $N. Even after dealing with those tough wolves, I can feel the electrical power contained within. Mountain storms are fierce and unforgiving - perhaps you have the fortitude to master their fury?', '', 'Seek out Elund Stormbelch in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660011, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Storm Codex and seek out Elund Stormbelch in Coldridge Valley.', '', '', ''),
(51001, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660012, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Guardian''s Oath', 'Seek out Guardian''s Oath and seek out Kharzon the Hammer in Coldridge Valley.', 'This oath rings with the strength of mountain stone, $N. You showed courage facing those wolves - now the words speak of standing firm like the peaks themselves, unmovable in the face of any storm. Do you have the fortitude to be an immovable guardian?', '', 'Seek out Kharzon the Hammer in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660012, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Guardian''s Oath and seek out Kharzon the Hammer in Coldridge Valley.', '', '', ''),
(51002, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660013, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Templar''s Vow', 'Seek out Templar''s Vow and seek out Thiduis Pride in Coldridge Valley.', 'By my beard! The Light shines as bright as forge-fire from this document, $N. You handled those wolves with honor - the mountain dwarves have always known that true faith burns like the eternal flames of our forges - steady, strong, and unquenchable.', '', 'Seek out Thiduis Pride in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660013, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Templar''s Vow and seek out Thiduis Pride in Coldridge Valley.', '', '', ''),
(51003, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660014, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ranger''s Guide', 'Seek out Ranger''s Guide and seek out Baruhr Mightmane in Coldridge Valley.', 'Fascinating! This guide still carries the scent of high mountain air, $N. You showed skill tracking those wolves - I can almost hear the cry of eagles and feel the bite of wind through stone passes. The mountain wilderness calls to those brave enough to answer.', '', 'Seek out Baruhr Mightmane in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660014, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Ranger''s Guide and seek out Baruhr Mightmane in Coldridge Valley.', '', '', ''),
(51004, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660015, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Temporal Manuscript', 'Seek out Temporal Manuscript and seek out Bieko in Coldridge Valley.', 'Strange... this manuscript seems to exist at multiple altitudes simultaneously, $N. After watching you deal with those wolves, I see the thin mountain air must make temporal magic more visible. Only those with the clearest minds should attempt such studies.', '', 'Seek out Bieko in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660015, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Temporal Manuscript and seek out Bieko in Coldridge Valley.', '', '', ''),
(51005, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660016, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Necromantic Journal', 'Seek out Necromantic Journal and seek out Savina Gloom in Coldridge Valley.', 'The very stone grows cold around this journal, $N. These mountains hold many ancient secrets, and after seeing how you dealt with those wolves, some of them involve the restless dead. Tread carefully with such dangerous knowledge.', '', 'Seek out Ophana Gloom in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660016, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Necromantic Journal and seek out Ophana Gloom in Coldridge Valley.', '', '', ''),
(51006, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660017, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Flame Codex', 'Seek out Flame Codex and seek out Debbie Whirlyflame in Coldridge Valley.', 'Hot as forge-fire, this one! The codex radiates heat that could warm these cold mountain halls, $N. You showed fire in your spirit fighting those wolves - fire magic is respected here. We dwarves know the value of a flame that never dies.', '', 'Seek out Debbie Whirlyflame in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660017, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Flame Codex and seek out Debbie Whirlyflame in Coldridge Valley.', '', '', ''),
(51007, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660018, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Forbidden Treatise', 'Seek out Forbidden Treatise and seek out Clippo Doomwhistle in Coldridge Valley.', 'Greetings, $N. Clippo Doomwhistle stopped by recently and told me to give this to you.  By the mountain kings... the symbols on this treatise seem to shift and writhe when I''m not looking directly at them, $N. After watching you face those wolves, the mountain echoes carry strange whispers when this thing is near.   Handle it with extreme caution.', '', 'Seek out Clippo Doomwhistle in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660018, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Forbidden Treatise and seek out Clippo Doomwhistle in Coldridge Valley.', '', '', ''),
(51008, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660019, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Solar Scripture', 'Seek out Solar Scripture and seek out Cleric Stonelight in Coldridge Valley.', 'Blessed Light! This scripture shines like the sun reflecting off fresh snow, $N. You showed righteous courage against those wolves - the mountain peaks are closer to the heavens, and perhaps that''s why the Light''s blessing feels so strong at this altitude.', '', 'Seek out Cleric Stonelight in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660019, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Solar Scripture and seek out Cleric Stonelight in Coldridge Valley.', '', '', ''),
(51009, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660020, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Engineering Manual', 'Seek out Engineering Manual and seek out Binkle Coldbolt in Coldridge Valley.', 'Now this is proper dwarven work! I can hear the gears clicking and steam hissing just by holding this manual, $N. After seeing your practical approach to those wolves it looks like Binkle Coldbolt thinks you''ve got a shot at learning from the best. Afterall, our mountain engineering is the finest in all the land - if you''re clever enough to learn it without blowing yourself up!', '', 'Seek out Binkle Coldbolt in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660020, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Engineering Manual and seek out Binkle Coldbolt in Coldridge Valley.', '', '', ''),
(51010, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660021, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runic Inscription', 'Seek out Runic Inscription and seek out Murmon Fuseforge in Coldridge Valley.', 'Ancient power flows through this stone tablet, $N. The runes carved here are older than our oldest halls, carved by hands that shaped the very mountains. After watching you face those wolves, such knowledge comes with great responsibility.', '', 'Seek out Murmon Fuseforge in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660021, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Runic Inscription and seek out Murmon Fuseforge in Coldridge Valley.', '', '', ''),
(51011, 2, 2, 2, -526, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660022, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Tablet', 'Seek out Ancient Tablet and seek out Grelin Ironbeard in Coldridge Valley.', 'This tablet pulses with raw, primal energy, $N. You fought those wolves like a true warrior - the barbarian''s way is harsh but honest. No fancy techniques, just pure strength and determination. The mountain breeds warriors, not dancers.', '', 'Seek out Grelin Ironbeard in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660022, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Ancient Tablet and seek out Grelin Ironbeard in Coldridge Valley.', '', '', ''),
(51012, 2, 2, 2, -519, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660023, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hunter''s Mandate', 'Seek out Yiro the Vanquisher in Coldridge Valley.', 'This mandate bears the seal of the vanquishers, $N. The mountains hide many evils that must be rooted out, and Yiro calls for those with the courage to hunt darkness in these frozen peaks. Do you have what it takes to become a hunter of evil?', '', 'Seek out Yiro the Vanquisher in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660023, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Sacred Letter and seek out Yiro the Vanquisher in Coldridge Valley.', '', '', ''),
(51013, 2, 2, 2, -531, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660024, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Primal Codex', 'Seek out Primal Codex and seek out Katho Hammerfist in Coldridge Valley.', 'Raw elemental power swirls around this codex, $N! After seeing how you handled those wolves, the magic contained within is as untamed as a mountain storm and twice as dangerous. Only those with the strength to embrace chaos should dare to study such primal forces.', '', 'Seek out Katho Hammerfist in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660024, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Primal Codex and seek out Aldus Hammerfist in Coldridge Valley.', '', '', ''),
(51014, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 660025, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Manual', 'Seek out Death Manual and seek out Zipak Cogweight in Coldridge Valley.', 'The very air grows colder when this manual is near, $N. Death is a constant companion in these harsh mountains, and after watching you put those wolves out of their misery, perhaps that is why some learn to guide it rather than fear it. Handle this knowledge with the respect it deserves.', '', 'Seek out Zipak Cogweight in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 660025, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Death Manual and seek out Zipak Cogweight in Coldridge Valley.', '', '', ''),
(200105, 2, 3, 3, -526, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 532805, 1, 532806, 1, 395861, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Welcome to the Warband', 'Kill Kali and return back to your trainer.', 'Har! Har! Welcome, $N. Glad you could join the Warband.  What is the Warband, you might be wondering? Considering your arrival, I would have assumed you''d already know. Well, little $c, this is about to be a rude awakening.  The Warband is where all barbarians, brutes, and strongmen alike come together to compete to see who is the strongest, most brutal, and most powerful individual of them all.  That''s the only way we can TRULY test our mettle. THIS IS IT! You may be new to this, but absolutely nobody will go easy on you.  Your first test will be the same as all the other rookies. There''s an individual who has been mucking things up and spreading rumors just because they couldn''t cut it and were denied access to the Warband.  They''re known as Kali. Kill her, hahaha! I will reward you with a weapon well-suited for a noob like yourself if you are capable of such a task.  Come back to me alive, or die.', '', 'Return to your trainer.', 299326, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200166, 2, 3, 3, -530, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 553122, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Perfect Timing', 'Find Harodormu''s wand in Anvilmar.', 'Ahhh, $N, I saw your arrival long ago. Now it is time to teach you what it means to be a Chronomancer. To weave the very fabric of space and time. To be equivalent to a god...   Let me not get ahead of myself. For you, $N, are new to the world of chronomancy, and before I can allow you to inhabit this world with such latent power... you must learn how to control yourself.  As a Chronomancer, you are a master of time magic. This means you must respect time on the most foundational of levels. It just so happens that I left my wand somewhere in this building.  You have 2 minutes. Find it for me.', '', 'Return to Harodormu.', 0, 0, 0, 0, 0, 0, 0, 0, 661335, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200072, 2, 3, 3, -522, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532803, 1, 532804, 1, 532881, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Going MAD!', 'Kill Bromos Grummner.', 'You have arrived at the most opportune time, $N.  I have heard the whispers of the great beyond. It tells me of a particularly dangerous individual to our cause. I need you to destroy them, swiftly.  If you do this I will reward you with a weapon fit for a follower of the Old Gods themselves.  The individual you''re looking for waits inside Anvilmar. They go by the name of "Bromos Grummner". End him.', '', 'Return to your trainer.', 299236, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200117, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200118, 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Peace Through Strength', 'Find Efry Cogspark in Anvilmar.', 'It is nice to meet you, $N. We have much work to accomplish together and you, my friend, have much to learn!  We are Guardians, and as such we are tasked with, quite literally, guarding Azeroth. From the occasional ne''er-do-well that robs a man, to far more threatening monsters who pose a threat to our people. We are the ones who heed the call.  And, as my example preludes, I have such a task for you today. If you can do this, you are more than ready to proceed further into your training.  There is an individual nearby named Efry Cogspark, and I believe she could use my help.  Visit her and see what she needs.', '', 'Find Efry Cogspark in Anvilmar.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200118, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200119, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Prioritizing Defense', 'Kill Rockjaw Troggs until you find a suitable weapon for Efry Cogspark.', 'Hi, friend! You''re here to help, that''s great!  I''m in need of a weapon for self defense and if you could help me acquire one I would be inclined to reward you.  The troggs nearby... I''ve been studying them. They have a particular sword that would be perfect for me. If you could acquire one for me in tip-top shape, that would be perfect!', '', 'Return to Efry Cogspark.', 0, 0, 0, 0, 0, 0, 0, 0, 662330, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200119, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 0, 2, 25, 0, 0, 0, 0, 0, 0, 0, 0, 245712, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Helping A Friend', 'Return to your trainer with news of your success.', 'Now I can defend myself in the world and I feel so safe! Thank you!  I found a shield during my adventures in a random mine - I think someone dropped it. I gave it to your trainer and now he will give it to you!', '', 'Return to your trainer with news of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200043, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200044, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of Death', 'Find and interact with the ritual circle.', 'Greetings, $C. Glad you could join me in the graveyard today.  Beautiful day, isn''t it?  It seems you''ve already been acquainted with undeath, I am impressed by your ability to raise the dead.   Perhaps you could be used to my benefit, which I''m sure you would not mind. I have a particularly powerful Undead that I wish to summon, but I dare not attempt it myself - I am far too important.  You, however, could learn quite a lot by succeeding here. And if you are to fail? I will simply raise you as my own.  Do not overthink it. Let me mark your map to the location of where my ritual must be had. You must collect specific items in order to complete the ritual.  Now, be gone.', '', 'Interact with the ritual circle.', 685121, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the ritual circle', '', '', ''),
(200044, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200045, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Calls', 'Kill Troggs and loot their bones, flesh, and skull.', 'In order to summon the Undead monstrosity, I must bring the following ingredients to the ritual circle.  - Bones - Fresh Flesh - Skull  The nearby Troggs have just what is needed.', '', 'Return to the ritual circle.', 0, 0, 0, 0, 0, 0, 0, 0, 458421, 458422, 458423, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(200045, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 660053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Dead', 'Kill the Undead Monstrocity.', '<The materials dissipate into the ritual circle into a puff of smoke>  ...something seems off.  The summon has failed, inspect the ritual circle again. But be careful, it is unstable.', '', 'Return to your trainer.', 299232, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200160, 2, 3, 3, -531, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 296200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Way of the Bear', 'Kill 8 Frostmane Troll Whelps.', 'Welcome, $C. I have awaited your arrival here in Coldridge Valley.  You come to me for wisdom, and as such, I will deliver.  The first step to becoming a master $C is mastering the way of the bear. With each successive mastery will come yet another challenge, but for now, let''s focus on what it means to unlock your inner savage instincts.  Bears are large, ferocious creatures. They know only what they must to survive, and that is to kill. There is little one can do to escape from a bear who wishes to end their life.  Through the bear we gain savagery, viciousness, and strength, without mercy.   Show me that you understand this by ending the lives of the Ice Trolls to the west of here and I will reward you.', '', 'Return to your trainer.', 706, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200143, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 293203, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Way of the Pyromancer', 'Defeat Scorch and acquire his heart.', 'Whoa... I don''t feel so good, $N.  So many whirls... I shouldn''t have stared into the fire for so long.  While I was whirling... I mean while I was swirling...swirling... Oooh...  A group of rogue Pyromancers whirled around and summoned a fire elemental! He''s bound to a campfire on the frozen lake and if you don''t stop him he''ll harm many innocent people!  Find this elemental, his name is Scorch. Whirl and swirl him with your fire and obtain his heart, bring it back to me so I can study it.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 662331, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200002, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200003, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -6153, 594, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ranger''s Path', 'Find Baruhr''s falcon in Coldridge Valley.', 'Being a Ranger is more than just picking up a bow, or fighting from the cover of the trees, $n.  Being a Ranger, at its core, means that you have a profound connection to the wilds. You are its protector.  I sent my falcon, Talos, to scout the surrounding areas, but he has not returned.   Please, find him and direct him to return back to me.', '', 'Find Baruhr''s falcon in Coldridge Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200003, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200004, 3, 0, 0, 0, 0, 0, 0, 662316, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Surprise Attack!', 'Slay the suspicious creature.', 'Something is rustling in the nearby bushes.  You''re under attack! ', '', 'Tend to the falcon.', 299222, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200004, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 0, 2, 70, 0, 0, 0, 0, 0, 662317, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 818000, 1, 727000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Falcons Are Friends', 'Use the Red Vial on the falcon.', 'You find a note attached to the falcon that reads:  <If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.>', '', 'Return to your trainer.', 685011, 0, 0, 0, 1, 0, 0, 0, 662317, 662316, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 'Tend to Talos'' wounds', '', '', ''),
(200199, 2, 3, 3, -508, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 540070, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Shadowlands', 'Visit Gyrothor Turbospark in Anvilmar.', 'Ahh, finally, I have awaited another $R such as myself to pursue such an envious craft!  ...you are bold. I can sense you have come to me to learn. I do have a simple task for you today, young $C.  In this very room is a gnome who is near his end, Gyrothor Turbospark. Despite a life full of adventure and fulfillment, he is bitter of his encroaching end.  He will die and the Shadowlands will claim him. But today is not his day. Yet, I can feel his yearning to leave this plane, but he is unaware of what lays before him once he is gone.  You may not have expected such a task, but I would humbly ask you to pay him a visit and have a chat.', '', 'Return to your trainer.', 685022, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chat with Gyrothor Turbospark', '', '', ''),
(200110, 2, 3, 3, -527, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 661329, 0, 0, 293202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes of Power', 'Figure out the riddle etched on the runestone.', 'Greetings, $N. I''m glad you could finally join me, I have awaited your arrival.  Today, a simple lesson in problem solving for an aspiring Runemaster such as yourself. Perhaps you will succeed, perhaps you will not.  Here, I have a rune. Etched on the rune is a riddle. Figure the riddle out and return to me.   A hint? The best I can do is tell you that the answer to this riddle lays within this building. Not without.  I will know when you return if you have figured it out or not, do not worry. Succeed, and I will reward you.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661330, 661329, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, '', '', '', ''),
(200089, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 200090, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Useful In Your Own Right', 'Assist Binkle Coldbolt with his tinkering shenanigans.', 'Greetings, $N, I am glad to make your acquaintance and I have heard much about you before your arrival.  You have come to me to learn and as a $C you have already shown yourself to be a dutiful student of the arcane. But there is so much more to the power that we call forth than just lightning and electricity.  In time, you will learn just how deep your potential lays. But for now... I do have a bit of a task for you.  There''s an individual nearby known as "Binkle Coldbolt" and he always calls on my aid for his... tinkering shenanigans... He needs some lightning, $N, but I am busy. Can you go and assist him?', '', 'Assist Binkle Coldbolt with his tinkering shenanigans.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200090, 2, 3, 0, -520, 0, 0, 0, 0, 0, 0, 200091, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Stolen Power Core', 'Kill Burly Rockjaw Troggs until one of them drops the power core.', 'Howdy, $N! Glad your trainer got around to sendin'' some help my way.  This is a very simple task, I just need some POWER! But unfortunately my power core has been stolen by one of the nearby Burly Rockjaw Troggs. Can you return it for me?', '', 'Return to Binkle Coldbolt.', 0, 0, 0, 0, 0, 0, 0, 0, 661417, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200091, 2, 3, 0, -525, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 663317, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Job For A Stormbringer', 'Tell your trainer of your success.', 'I appreciate you retrieving this power core! You can return to your trainer now and let him know what you''ve done for me.', '', 'Tell your trainer of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200060, 2, 3, 3, -507, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 454381, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Pendant', 'Find the lost pendant.', 'Greetings, $C. You have arrived at the perfect time.  I have lost a pendant of mine that is quite powerful. Lost may be the wrong word, but alas, we best not get lost in the semantics.  Well, I guess I owe it to you to at least explain what happened if you''re going to help me. So here goes.  I was camping out to the south of Anvilmar in an attempt to spy on the local Trogg population. Unfortunately, one night while I was asleep I was ambushed by a group of them and they drove me out and pillaged my camp.  In my haste, I dropped my pendant. Please, find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200083, 2, 3, 3, -524, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 52855, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Quiet Life', 'Visit the statue of Uther in Coldridge Pass.', 'Welcome to the order, $N. I have awaited your arrival.  As Templars, we have ascended to the highest order of the holy faith, and as such we have quite a lot of responsibility on our shoulders.  Paladins and Priests work alongside us to maintain peace through the Holy Light in this world and each of us, though different in our own subtle ways, hope to bring the light to Azeroth once more. Despite it''s perils.  Our path may be different but some may argue that it is far more rigorous. To be a templar means to maintain extremely precise control of your emotions, your combat flow, and your mind.  In order to keep myself healthy, I enjoy meditating near a statue erected not too far from here in honor of a powerful Paladin who fell during the third war. Please, visit the area yourself. Tell me what you experience when you return.', '', 'Visit the statue of Uther in Coldridge Pass.', 685037, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit the statue of Uther', '', '', ''),
(200066, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 415000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ingenuity At It''s Finest!', 'Collect 3 Scrap Metal.', 'Why I''ll be! Howdy there! $N, was it??  I see you be the tinkerin'' type and I was honestly on the look out for one like you. I''m tryin'' to make a special type of gun, a homemade gun some might say, but I need some more metal.  There is some metal out there near one of those abandoned camps that are infested with troggs that could be used to create a gun for you and me. Collect me some and I''ll go tinkerin'' away!', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663320, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', ''),
(200255, 2, 3, 3, -519, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662219, 0, 0, 717002, 1, 410005, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Hunt Begins', 'Reveal the witch and kill her.', 'I can feel an evil presence.  You can feel it too, can''t you? That is why you have come to me at the most opportune of times.  There is one here. A witch. Brooding with evil and malintent.  May the Light bless us for what we''re about to do.  Here, take this torch. She''s here in Anvilmar and I''ve marked her location on your map. Use the torch on her to reveal her true self. Kill it. No mercy.  Return to me when it''s been slain.  Damned witches.', '', 'Return to your trainer.', 685221, 299333, 0, 0, 1, 1, 0, 0, 662219, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Find the Witch', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

UPDATE `quest_template` SET `TimeAllowed` = 120 WHERE `ID` = 200166;

DELETE FROM `quest_template_addon` WHERE `ID` IN (51000, 51001, 51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 200002, 200003, 200004, 200043, 200044, 200045, 200060, 200066, 200072, 200083, 200089, 200090, 200091, 200105, 200110, 200117, 200118, 200119, 200143, 200160, 200166, 200199, 200255);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(51000, 0, 32768, 179, 1, 0),
(51001, 0, 131072, 179, 1, 0),
(51002, 0, 262144, 179, 1, 0),
(51003, 0, 1048576, 179, 1, 0),
(51004, 0, 2097152, 179, 1, 0),
(51005, 0, 4194304, 179, 1, 0),
(51006, 0, 8388608, 179, 1, 0),
(51007, 0, 16777216, 179, 1, 0),
(51008, 0, 67108864, 179, 1, 0),
(51009, 0, 134217728, 179, 1, 0),
(51010, 0, 2147483648, 179, 1, 0),
(51011, 0, 2048, 179, 1, 0),
(51012, 0, 16384, 179, 1, 0),
(51013, 0, 1073741824, 179, 1, 0),
(51014, 0, 536870912, 179, 1, 0),
(200105, 0, 2048, 51011, 0, 0),
(200166, 0, 2097152, 51004, 0, 0),
(200072, 0, 16777216, 51007, 0, 0),
(200117, 0, 131072, 51001, 0, 0),
(200118, 0, 131072, 200117, 0, 0),
(200119, 0, 131072, 200118, 0, 0),
(200043, 0, 4194304, 51005, 0, 0),
(200044, 0, 4194304, 200043, 0, 0),
(200045, 0, 4194304, 200044, 0, 0),
(200160, 0, 1073741824, 51013, 0, 0),
(200143, 0, 8388608, 51006, 0, 0),
(200002, 0, 1048576, 51003, 0, 0),
(200003, 0, 1048576, 200002, 1, 0),
(200004, 0, 1048576, 200003, 1, 0),
(200199, 0, 536870912, 51014, 0, 0),
(200110, 0, 2147483648, 51010, 1, 0),
(200089, 0, 32768, 51000, 0, 0),
(200090, 0, 32768, 200089, 0, 0),
(200091, 0, 32768, 200090, 0, 0),
(200060, 0, 67108864, 51008, 0, 0),
(200083, 0, 262144, 51002, 0, 0),
(200066, 0, 134217728, 51009, 0, 0),
(200255, 0, 16384, 51012, 1, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (51000, 51001, 51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 200002, 200003, 200004, 200043, 200044, 200045, 200060, 200066, 200072, 200083, 200089, 200090, 200091, 200105, 200110, 200117, 200118, 200119, 200143, 200160, 200166, 200199, 200255);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(51000, 'Excellent, $N! You have heeded the mountain storm''s call and proven yourself worthy. The power of wind and lightning flows through you now like the eternal tempests that crown our peaks. As a Stormbringer, you will command the very forces that shape the mountains themselves.$B$BWelcome to the path of the mountain tempest. Let your enemies tremble before your elemental fury!'),
(51001, 'Well done, $N! You understand the sacred duty that comes with this calling. A mountain Guardian stands as immovable as the peaks themselves, never yielding, never breaking, like the very stone beneath our feet.$B$BYour training begins now. Remember - your life belongs to those you protect. Honor that trust with the strength of the mountain itself.'),
(51002, 'The Light shines brightly within you, $N! You have embraced the Templar''s path and dedicated your soul to divine service in these sacred halls. Through faith and devotion, you will become an instrument of holy justice, burning bright as forge-fire.$B$BYour sacred duty begins this day. May your conviction be as enduring as mountain stone, and your faith burn eternal.'),
(51003, 'The mountain wilds have chosen well, $N. You carry the spirit of the high places within you, and the ancient ways call to your blood. As a mountain Ranger, you will be the bridge between the stone halls and the untamed peaks.$B$BWelcome to the brotherhood of the mountain wild. May your aim be true and your path lead to the freedom of the heights.'),
(51004, 'Fascinating, $N. You perceive the flow of time itself, a gift granted to very few mortals at this altitude. As a Chronomancer, you will learn to bend causality to your will and walk between the moments that echo through these ancient peaks.$B$BTime is your ally now. Use this power wisely, for the consequences of temporal manipulation echo across all the mountain''s ages.'),
(51005, 'You have potential, $N. Death holds no fear for you in these halls where so many ancients rest, and that is... refreshing. As a Necromancer, you will learn to work with the mountain''s death rather than against it.$B$BYour education in the ancient arts begins now. Remember - death is not evil, merely inevitable. Guide it well through these sacred stone halls.'),
(51006, 'Magnificent, $N! The flames dance eagerly around you, drawn to the forge-fire in your dwarven soul. As a Pyromancer, you will learn that destruction and creation are merely two sides of the same hammer.$B$BLet the mountain fire burn within you! From the ashes of the old world, we will forge something new and beautiful in the dwarven way.'),
(51007, 'Yesss, $N... the mountain whispers told me you would come. You have been marked by powers beyond mortal comprehension, chosen to serve truths that echo through these ancient stone halls. The Old Gods smile upon you from the deep places.$B$BMadness is merely clarity unbound, young cultist. Embrace the chaos that sleeps beneath the mountain, and let it reshape you into something... greater.'),
(51008, 'Blessed are you, $N! The sun''s radiance flows through your very being, marking you as one chosen for healing and renewal in these pure heights. As a Sun Cleric, you will bring hope to the hopeless and light to the deepest mountain halls.$B$BYour path of healing begins now. May your light never dim, and may you always bring dawn to those lost in the mountain''s darkness.'),
(51009, 'Brilliant, $N! I can practically hear the gears turning in that clever dwarven mind of yours. As a Tinker, you will learn to blend the precision of mountain engineering with the wonder of magic - a fusion that will make even Ironforge jealous.$B$BYour apprenticeship in innovation begins today! Together, we will build wonders that will amaze the world and make our mountain ancestors proud.'),
(51010, 'Ancient power recognizes ancient power, $N. You possess the rare gift to read the first language of magic - the runes carved by the Titans into the very bones of this mountain. This is knowledge from the dawn of the world itself.$B$BYour study of runic magic begins today. The old ways endure because they are as eternal as the mountain stone. May you prove worthy of such trust.'),
(51011, 'Aye, that''s the spirit, $N! You have the heart of a true mountain warrior, as fierce and unbreakable as the peaks themselves. As a Barbarian, you will learn to fight with the raw power of the mountain - no fancy techniques, just pure dwarven strength.$B$BYour training begins now. Remember - the mountain doesn''t negotiate, it doesn''t compromise, and it never yields. Neither should you!'),
(51012, 'The Light has guided you to me, $N.$B$BThese frozen peaks may seem peaceful, but evil lurks in every shadow, every cave, every forgotten ruin. As a Witch Hunter, you will be the Light''s weapon against corruption. You will track down cultists, destroy demonic influences, and purge the darkness wherever it festers.$B$BYour righteous fury will burn through the coldest mountain air. Your blessed weapons will strike down the unholy. In these harsh lands, you will become the vanquisher of all that corrupts and destroys.$B$BWelcome to the eternal hunt. Let evil tremble at your approach!'),
(51013, 'Raw power flows through you, $N! You understand that the elements in their purest form care nothing for civilization''s rules. As a Primalist, you will wield earth, air, fire, and water as the mountain itself does - wild, untamed, unstoppable.$B$BYour training in primal magic begins now. Remember - the mountain is your teacher, and it shows no mercy to the weak.'),
(51014, 'You understand the truth, $N. Good. Death comes for all who walk these mountain paths, but through your work, it need not be feared. As a Reaper, you will guide souls to their proper rest and maintain the balance in these ancient halls.$B$BYour service to the eternal cycle begins now. The mountain dead are patient teachers - learn from them well.'),
(200105, ''),
(200166, 'Welcome back, $N. I knew you would find my wand in time. Literally.$B$BThis wand is for you. I hope it serves you well. In fact, I know it will.'),
(200072, ''),
(200117, ''),
(200118, ''),
(200119, ''),
(200043, '<The ritual circle pulsates with necromantic energy>'),
(200044, '<The ritual circle begins to erupt. The monster is being summoned>'),
(200045, 'Well, that''s exactly what I thought would happen.$B$BBut, hey, you didn''t die. You''re a better Necromancer already!$B$BHere, I sent my other apprentices to gather the scraps from your battle, they made this.$B$BTake it and get out of my sight.'),
(200160, 'Aha! You have shown me that you are truly powerful. For this, I reward you with a symbol of the Bear itself. May it guide you on your journeys and give you strength over your foes.'),
(200143, ''),
(200002, 'This seems to be the falcon in question, and it seems injured.'),
(200003, 'The falcon seems distraught. It must have been the suspicious creature who attacked it!'),
(200004, 'Thank you for finding Talos. He has already returned to me, healthy as ever.$B$BI''ve already sent him on yet another scouting mission.$B$B... you''re saying a strange creature was seen near Talos and that it attacked you? That must have been the creature that injured my boy.$B$BI''ll have to look into this more. Based on your description, whatever this is, it''s not native to Dun Morogh.'),
(200199, 'You may not have expected such a task, $N. But it is important to understand that the Shadowlands call for those who are ready, and knowing when to claim a soul can be just as important as the reclamation of the soul itself.$B$BFor helping our friend out here, I will reward you with these boots. May they serve you well, as they are enchanted to allow you to walk on the surface of water itself.'),
(200110, ''),
(200089, ''),
(200090, ''),
(200091, ''),
(200060, '<The pendant glimmers. It gives off a strong holy presence>$B$BYou have done well, $N. This pendant, I will give to you.$B$BKeep it close, for someday, you may need it again and I may teach you how to unlock far more of its powers.'),
(200083, ''),
(200066, 'Well, this is perfect!$B$BI was able to use this metal to finish a new gun for me and, guess what, I made you one too!$B$BTake it and have a great day!'),
(200255, 'Yet another evil creature banished from our world.$B$B... and yet.$B$BStill so many others to destroy. Be vigilant.$B$BHere, take these, let them guide you in your battles with evil.');

DELETE FROM `quest_request_items` WHERE `ID` IN (51000, 51001, 51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 200002, 200003, 200004, 200043, 200044, 200045, 200060, 200066, 200072, 200083, 200089, 200090, 200091, 200105, 200110, 200117, 200118, 200119, 200143, 200160, 200166, 200199, 200255);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(51000, 'I can sense the storm''s energy crackling around you, $N. Have you brought the Storm Codex? The mountain tempests call to those who would master their power.'),
(51001, 'Stand tall, $N. Do you carry the Guardian''s Oath? A true mountain guardian must understand the weight of their sacred duty.'),
(51002, 'The Light shines upon you, $N. Have you brought the Templar''s Vow? Only through absolute devotion can one serve the divine will in these sacred peaks.'),
(51003, 'The wild mountain air speaks of you, $N. Have you brought the Ranger''s Guide? Nature recognizes its own, and calls you to the ancient ways of the high places.'),
(51004, 'Time flows strangely around you, $N. Do you possess the Temporal Manuscript? The streams of chronos move differently at this altitude.'),
(51005, 'The mountain dead whisper of you, $N. Have you brought the Necromantic Journal? Death magic chooses its practitioners carefully in these ancient halls.'),
(51006, 'I feel the forge-fire radiating from you, $N. Do you carry the Flame Codex? Fire seeks those with the passion to wield its destructive beauty like the dwarven smiths of old.'),
(51007, 'The mountain voices grow louder when you approach, $N. Have you brought the Forbidden Treatise? The Old Gods echo through these stone halls.'),
(51008, 'Your presence brings warmth to this sacred place, $N. Do you have the Solar Scripture? The sun''s blessing flows strongest at these pure heights.'),
(51009, 'I hear the sound of gears turning and steam hissing, $N. Have you brought the Engineering Manual? Innovation calls to minds capable of true dwarven engineering.'),
(51010, 'Ancient power resonates within you, $N. Have you brought the Runic Inscription? The first magic carved into these very mountain bones recognizes one worthy of its secrets.'),
(51011, 'You carry the scent of battle, $N. Have you brought the Ancient Tablet? The mountain breeds only the strongest warriors.'),
(51012, 'You carry the hunter''s spirit, $N. Have you brought the Hunter''s Mandate? Evil awaits judgment.'),
(51013, 'Raw elemental forces swirl around you, $N. Do you carry the Primal Codex? The untamed elements of the mountain call to their chosen.'),
(51014, 'The veil grows thin around you, $N. Do you carry the Death Manual? Those who serve the natural order understand death''s place in the mountain cycle.'),
(200105, ''),
(200166, 'Ahh, you''ve returned.'),
(200072, ''),
(200117, ''),
(200118, ''),
(200119, ''),
(200043, ''),
(200044, '<You place the ingredients on the ritual circle>'),
(200045, ''),
(200160, ''),
(200143, ''),
(200002, 'An'' you''ve brought my vial back. I know what this means. Thank you lad.'),
(200003, ''),
(200004, 'Aye lad, Talos has already returned. Thank you.'),
(200199, ''),
(200110, ''),
(200089, ''),
(200090, ''),
(200091, ''),
(200060, 'Aye, lad. You''ve done it.'),
(200083, ''),
(200066, 'Have you found the scrap yet?'),
(200255, 'You have returned, wow!');

-- Map markers the texts promise ("Let me mark your map", "I have marked her location"): the target spawn.
DELETE FROM `quest_poi` WHERE `QuestID` IN (200043, 200255);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200043, 0, 0, 0, 27, 0, 0, 1),
(200255, 0, 0, 0, 27, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200043, 200255);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200043, 0, 0, -6247, 483),
(200255, 0, 0, -6068, 392);

DELETE FROM `creature_queststarter` WHERE `quest` IN (51000, 51001, 51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 200002, 200003, 200004, 200043, 200044, 200045, 200060, 200066, 200072, 200083, 200089, 200090, 200091, 200105, 200110, 200117, 200118, 200119, 200143, 200160, 200166, 200199, 200255);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(658, 51000),
(658, 51001),
(658, 51002),
(658, 51003),
(658, 51004),
(658, 51005),
(658, 51006),
(658, 51007),
(658, 51008),
(658, 51009),
(658, 51010),
(658, 51011),
(658, 51012),
(658, 51013),
(658, 51014),
(503411, 200002),
(9300152, 200003),
(9300152, 200004),
(502924, 200043),
(503271, 200060),
(502870, 200066),
(502830, 200072),
(502800, 200083),
(502771, 200089),
(502870, 200090),
(502870, 200091),
(502952, 200105),
(502910, 200110),
(503241, 200117),
(254000, 200118),
(254000, 200119),
(503400, 200143),
(50342, 200160),
(502820, 200166),
(9300151, 200199),
(9300150, 200255);

DELETE FROM `creature_questender` WHERE `quest` IN (51000, 51001, 51002, 51003, 51004, 51005, 51006, 51007, 51008, 51009, 51010, 51011, 51012, 51013, 51014, 200002, 200003, 200004, 200043, 200044, 200045, 200060, 200066, 200072, 200083, 200089, 200090, 200091, 200105, 200110, 200117, 200118, 200119, 200143, 200160, 200166, 200199, 200255);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(502771, 51000),
(503241, 51001),
(502800, 51002),
(503411, 51003),
(502820, 51004),
(502924, 51005),
(503400, 51006),
(502830, 51007),
(503271, 51008),
(502870, 51009),
(502910, 51010),
(502952, 51011),
(9300150, 51012),
(50342, 51013),
(9300151, 51014),
(9300152, 200002),
(9300152, 200003),
(503411, 200004),
(502924, 200045),
(503271, 200060),
(502870, 200066),
(502830, 200072),
(502800, 200083),
(502870, 200089),
(502870, 200090),
(502771, 200091),
(502952, 200105),
(502910, 200110),
(254000, 200117),
(254000, 200118),
(503241, 200119),
(503400, 200143),
(50342, 200160),
(502820, 200166),
(9300151, 200199),
(9300150, 200255);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (200044, 200045);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(9301152, 200044),
(9301152, 200045);

DELETE FROM `gameobject_questender` WHERE `quest` IN (200043, 200044);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(9301152, 200043),
(9301152, 200044);

-- ---------------------------------------------------------------------------
-- 8. Readable pages
-- ---------------------------------------------------------------------------
-- The letters 660011-660025 point at pages 6001-6015, none of which the world DB has. The pages shared
-- by every zone, 11112 (Note of the Ranger chain) and 27575 (Riddlestone), are written once by
-- ct-deathknell, which claimed them first.
DELETE FROM `page_text` WHERE `ID` IN (6001, 6002, 6003, 6004, 6005, 6006, 6007, 6008, 6009, 6010, 6011, 6012, 6013, 6014, 6015);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(6001, 'Can ye feel it crackling in the air, lad? The mountain storms are the fiercest in all of Khaz Modan, and the lightning that splits these peaks answers to those with the stomach to call it.$B$BCome find me in Anvilmar if ye''d rather hurl the thunder than hide from it.$B$B-Freja Stormbelch, Stormbringer Trainer', 0),
(6002, 'The mountains forge the strongest guardians, lad.$B$BStone teaches patience. Iron teaches resilience. And the hammer teaches that protection comes through strength, not just courage. A dwarven guardian stands like a mountain - unmovable, unbreakable.$B$BSeek me in Coldridge Valley when you''re ready to become the anvil upon which evil breaks.$B$B-Kharzon the Hammer, Guardian Trainer', 0),
(6003, 'By beard and hammer, the Light calls to ye!$B$BI served in the halls of Ironforge before taking up residence in these mountains. The Light burns just as bright in stone halls as it does in gilded cathedrals. Aye, and perhaps brighter, for it has the strength of the mountain to back it.$B$BCome find me in Coldridge Valley, and learn what dwarven devotion truly means.$B$B-Thiduis Pride, Templar Trainer', 0),
(6004, 'The high passes teach patience. The wolves teach cunning. The eagles teach ye to see a rabbit twitch from a mile off.$B$BI''ve walked every trail from Coldridge to the Loch, and there''s room at my side for one more set of sharp eyes. Seek me in Coldridge Valley.$B$B-Baruhr Mightmane, Ranger Trainer', 0),
(6005, 'You have already read this letter. You will read it again. Time up here runs thin and cold, like the air.$B$BI have waited for you at the top of the stairs in Anvilmar for longer than you have been alive, and also for a few minutes. Do not be late.$B$B-Bieko, Chronomancer Trainer', 0),
(6006, 'Death echoes loudly in these ancient halls.$B$BThe mountains are graveyards of giants, filled with the bones of creatures that walked when the world was young. I have learned much from these silent teachers, and the mountain dead are... generous with their wisdom.$B$BFind me in Coldridge Valley if you can stomach lessons from the deepest tombs.$B$B-Savina Gloom, Necromancer Trainer', 0),
(6007, 'Fire! Real fire, not the tame little flames the forge-folk keep in their hearths! The snow up here melts just the same as anywhere else, trust me, I''ve checked.$B$BCome find me by the anvils in Anvilmar and we''ll see how bright you can burn.$B$B-Debbie Whirlyflame, Pyromancer Trainer', 0),
(6008, 'Do not read this aloud.$B$BThe whispers beneath the mountain have spoken your name, and they are patient. When the cold makes your thoughts slow, listen for them. I will be waiting under the pines west of the valley''s heart.$B$B-Clippo Doomwhistle, Cultist Trainer', 0),
(6009, 'Up here the sun rises over snow, and the Light comes twice as bright. Even the mountain remembers warmth.$B$BIf the dawn stirs something in you, come to the upper floor of Anvilmar and learn to carry it to others.$B$B-Cleric Stonelight, Sun Cleric Trainer', 0),
(6010, 'Gears, springs, a pinch of blasting powder and a steady hand. That''s all it takes, and maybe an eyebrow or two.$B$BIf ye''ve got the itch to build something that goes boom, come find me by the gun racks in Anvilmar.$B$B-Binkle Coldbolt, Tinker Trainer', 0),
(6011, 'The deepest runes are carved in mountain stone.$B$BThese peaks remember the first words of power, when the Titans shaped the world with runic magic. I have spent decades learning to read the symbols carved by their ancient hands into the very bones of the earth.$B$BSeek me in Coldridge Valley, where the oldest magic still pulses through living rock.$B$B-Murmon Fuseforge, Runemaster Trainer', 0),
(6012, 'Har! Words won''t teach ye to fight, so I''ll keep this short.$B$BFind me in Anvilmar. Bring your fists. Leave your manners.$B$B-Grelin Ironbeard, Barbarian Trainer', 0),
(6013, 'By hammer and Light! Evil finds no sanctuary in these frozen peaks!$B$BI have spent years hunting down corruption in these mountains, tracking cultists and demon-worshippers who thought the cold would hide their sins. The Light burns brightest against the mountain frost.$B$BSeek me in Coldridge Valley, and I will teach you to vanquish evil wherever it hides.$B$BYiro the Vanquisher$BWitch Hunter Trainer', 0),
(6014, 'The mountains themselves are primal forces, lad!$B$BUp here, the elements are raw, untamed, unfiltered by civilization''s corrupting touch. I have learned to channel earth, air, fire, and water in their purest, most chaotic forms. No fancy spellwork - just raw elemental fury!$B$BFind me in Coldridge Valley when you''re ready to unleash nature''s primal wrath.$B$B-Kathos Hammerfist, Primalist Trainer', 0),
(6015, 'Death comes to all, but at this altitude, it comes faster.$B$BThe mountain air is thin, the cold is bitter, and the old bones rest deep in these ancient halls. I have guided countless souls across the threshold, from frost-bitten miners to fallen warriors. Death is not evil - it is simply... inevitable.$B$BSeek me in Coldridge Valley if you understand this truth.$B$B-Zipak Cogweight, Reaper Trainer', 0);

-- ---------------------------------------------------------------------------
-- 9. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9003300, 9003301, 9003302, 9003303, 9003304, 9003305, 9003306, 9003307, 9003308, 9003309, 9003310, 9003311, 9003312, 9003313, 9003314, 9003320, 9003321, 9003322, 9003323, 9003324, 9003325, 9003326, 9003327) OR `guid` BETWEEN 9003300 AND 9003499;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9003300, 502771, 0, 0, 0, 1, 1, 1, -6099.43, 405.44, 395.536, 4.87, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Freja Stormbelch, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51000, z from surface.floor; Anvilmar main hall (floor 395.54), west side by the chairs, faces east across the hall toward the forge'),
(9003301, 503241, 0, 0, 0, 1, 1, 1, -6104.15, 389.07, 395.542, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Kharzon the Hammer, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51001, z from surface.floor; Anvilmar main hall (floor 395.54), by the south-west anvils, faces the south door past the forge'),
(9003302, 502800, 0, 0, 0, 1, 1, 1, -6056.34, 374.58, 392.763, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Thiduis Pride, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51002, z from surface.floor; Anvilmar north room (floor 392.76), east end by the stairs, faces south-west toward the middle room'),
(9003303, 503411, 0, 0, 0, 1, 1, 1, -6185.74, 338.42, 404.128, 3.29, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Baruhr Mightmane, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51003, z from surface.floor; Coldridge Valley, top of the graveyard knoll, faces down the slope to the start clearing'),
(9003304, 502820, 0, 0, 0, 1, 1, 1, -6053.65, 390.14, 398.871, 4.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Bieko, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51004, z from surface.floor; Anvilmar upper floor (398.87), south side, faces the head of the stairs where players arrive'),
(9003305, 502924, 0, 0, 0, 1, 1, 1, -6167.75, 345.83, 399.922, 2.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Ophana Gloom, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51005, z from surface.floor; Coldridge Valley, inside the graveyard fence by the coffins, faces the lamp-lit path climbing from the start'),
(9003306, 503400, 0, 0, 0, 1, 1, 1, -6101.3, 377.48, 395.542, 3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Debbie Whirlyflame, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51006, z from surface.floor; Anvilmar main hall (floor 395.54), by the south-east anvils, faces the south door'),
(9003307, 502830, 0, 0, 0, 1, 1, 1, -6232.22, 393.42, 389.945, 4.55, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Clippo Doomwhistle, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51007, z from surface.floor; Coldridge Valley, under the big pine west of the start, faces south between the two saplings toward Sten and the start clearing'),
(9003308, 503271, 0, 0, 0, 1, 1, 1, -6053.69, 382.02, 398.873, 4.95, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Cleric Stonelight, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51008, z from surface.floor; Anvilmar upper floor (398.87), east side, faces the head of the stairs'),
(9003309, 502870, 0, 0, 0, 1, 1, 1, -6116.33, 396.93, 395.542, 3.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Binkle Coldbolt, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51009, z from surface.floor; Anvilmar main hall (floor 395.54), by the gun racks, faces the south door'),
(9003310, 502910, 0, 0, 0, 1, 1, 1, -6115.39, 384.21, 395.542, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Murmon Fuseforge, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51010, z from surface.floor; Anvilmar main hall (floor 395.54), among the south tables, faces the south door'),
(9003311, 502952, 0, 0, 0, 1, 1, 1, -6055.95, 388.11, 392.761, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Grelin Ironbeard, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51011, z from surface.floor; Anvilmar north room (floor 392.76), faces south across the room toward the doorway from the middle room, crates behind him'),
(9003312, 9300150, 0, 0, 0, 1, 1, 1, -6126.68, 384.03, 395.543, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Yiro the Vanquisher, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51012, z from surface.floor; Anvilmar main hall (floor 395.54), entrance hall, faces the south door'),
(9003313, 50342, 0, 0, 0, 1, 1, 1, -6217.5, 384.67, 388.619, 4.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Katho Hammerfist, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51013, z from surface.floor; Coldridge Valley, by the fallen tree on the path, faces the path and the start clearing'),
(9003314, 9300151, 0, 0, 0, 1, 1, 1, -5597.9, -607.87, 452.097, 1.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Zipak Cogweight, Coldridge: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 51014, z from surface.floor; Kharanos grave scene (CoA-only dirt mound, lampposts and candles), at the head of the fresh grave, turned toward the path from Kharanos'),
(9003320, 299236, 0, 0, 0, 1, 1, 1, -6120.68, 382.09, 395.543, 6.161, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Anvilmar, Bromos Grummner''s stock post in the entrance hall, stock facing north into the hall; replaces stock guid 403'),
(9003321, 254000, 0, 0, 0, 1, 1, 0, -6111.03, 369.59, 395.542, 1.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Anvilmar, main hall (395.54) at the Coldridge Mountaineer post by the powder kegs and cargo: the turn-in point ST1088 of 254000/254001 (SOURCED-CLIENT, Questie 1.0 yd), moved there by dm-coldridge-misc; faces north-west into the hall toward the anvils'),
(9003322, 9300154, 0, 0, 0, 1, 1, 0, -5600.5, -607.5, 452.134, 2.43, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Kharanos grave scene, sitting on the ground 2.6 yd from Zipak Cogweight ("In this very room is a gnome who is near his end", 200199), facing the fresh grave'),
(9003323, 9300155, 0, 0, 0, 1, 1, 0, -6068, 392, 392.762, 4.3, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Anvilmar, north room west end by the candle-lit tables, faces the ramp and doorway from the middle room where players come in; the witch of 200255'),
(9003324, 299326, 0, 0, 0, 1, 1, 1, -6108, 706, 433.593, 4.48, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: shelf above the crash site, brooding by her campfire, faces the ramp that climbs from the south-east'),
(9003325, 9300152, 0, 0, 0, 1, 1, 0, -6153, 594, 386.31, 4.585, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: north meadow at the foot of the big pine, the scouting falcon grounded, faces south toward Baruhr and the start'),
(9003326, 9300153, 0, 0, 0, 1, 1, 0, -6317, 714, 384.687, 4.92, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: frozen lake in the south-west of the valley, on the ice beside his campfire, faces the east shore where players come from'),
(9003327, 685037, 0, 0, 0, 1, 1, 0, -5906.5, 22.7, 367.209, 5.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Coldridge: Coldridge Pass (area 800), flat valley floor at the foot of the pass road, 4 yd in front of the Statue of Uther, facing it; walk-in credit marker for 200083');

DELETE FROM `creature_addon` WHERE `guid` = 9003322 OR `guid` BETWEEN 9003300 AND 9003499;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9003322, 0, 0, 1, 1, 0, 0, NULL);

DELETE FROM `gameobject` WHERE `guid` IN (7912200, 7912201, 7912202, 7912203, 7912204, 7912205, 7912206, 7912207, 7912208, 7912209, 7912210, 7912211, 7912212, 7912213, 7912214, 7912215, 7912216, 7912217, 7912218, 7912219, 7912220, 7912221) OR `guid` BETWEEN 7912200 AND 7912299;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912200, 9301152, 0, 0, 0, 1, 1, -6247, 483, 386.548, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, north edge of the ruins, open ground'),
(7912201, 9301150, 0, 0, 0, 1, 1, -6063.8, 379.4, 393.658, 0.7, 0, 0, 0.342898, 0.939373, 60, 100, 1, '', 'CoA Coldridge: Anvilmar, north room, on the south table beside the candelabra'),
(7912202, 9301150, 0, 0, 0, 1, 1, -6114.9, 379.2, 396.438, 2.3, 0, 0, 0.912764, 0.408487, 60, 100, 1, '', 'CoA Coldridge: Anvilmar, main hall, on the south-east table among the chairs'),
(7912203, 9301151, 0, 0, 0, 1, 1, -6063.8, 386.4, 393.658, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Coldridge: Anvilmar, north room, on the north table beside the bread'),
(7912204, 9301151, 0, 0, 0, 1, 1, -6097.6, 404.6, 396.411, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Coldridge: Anvilmar, main hall, on the west table behind Freja Stormbelch'),
(7912205, 9301153, 0, 0, 0, 1, 1, -6422.5, 352, 390.738, 1.1, 0, 0, 0.522687, 0.852525, 60, 100, 1, '', 'CoA Coldridge: pillaged camp at the broken cart south of Anvilmar, in the snow north-east of the cart'),
(7912206, 9301153, 0, 0, 0, 1, 1, -6419.5, 343.5, 391.155, 4, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 'CoA Coldridge: pillaged camp at the broken cart south of Anvilmar, in the snow east of the cart, where she fled'),
(7912207, 9301154, 0, 0, 0, 1, 1, -6270.5, 489, 386.188, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, at the collapsed south end of the west tent'),
(7912208, 9301154, 0, 0, 0, 1, 1, -6268, 479.5, 386.28, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, between the camp chair and the dig-site rocks'),
(7912209, 9301154, 0, 0, 0, 1, 1, -6277.5, 476, 386.148, 4.1, 0, 0, 0.887362, -0.461073, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, beside the abandoned excavation hammers'),
(7912210, 9301154, 0, 0, 0, 1, 1, -6256, 475.5, 386.037, 5.5, 0, 0, 0.381661, -0.924302, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, by the broken barrel east of the east tent'),
(7912211, 9301154, 0, 0, 0, 1, 1, -6246, 470, 385.919, 1.7, 0, 0, 0.75128, 0.659983, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, north-east edge, below the old stump'),
(7912212, 9301154, 0, 0, 0, 1, 1, -6244.5, 495, 387.122, 3.4, 0, 0, 0.991665, -0.128844, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, north of the tents, beyond the small pines'),
(7912213, 9301154, 0, 0, 0, 1, 1, -6247, 507, 386.225, 0.3, 0, 0, 0.149438, 0.988771, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, north-west edge, beyond the big pine'),
(7912214, 9301154, 0, 0, 0, 1, 1, -6268, 509, 386.918, 2.2, 0, 0, 0.891207, 0.453596, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, west side, beside the lone snow pine'),
(7912215, 9301154, 0, 0, 0, 1, 1, -6283, 497, 386.137, 5, 0, 0, 0.598472, -0.801144, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, south-west, past the paired snow pines'),
(7912216, 9301154, 0, 0, 0, 1, 1, -6285.5, 478, 386.11, 1.1, 0, 0, 0.522687, 0.852525, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, south edge, south of the paired snow pines'),
(7912217, 9301154, 0, 0, 0, 1, 1, -6268, 463.5, 386.077, 3.8, 0, 0, 0.9463, -0.32329, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, east edge, beyond the excavation hammers'),
(7912218, 9301154, 0, 0, 0, 1, 1, -6258, 528, 386.144, 6, 0, 0, 0.14112, -0.989992, 60, 100, 1, '', 'CoA Coldridge: ruined excavation camp west of the start among the Burly Rockjaw Troggs, west end, south of the lone pines'),
(7912219, 9301155, 0, 0, 0, 1, 1, -5905, 19, 367.05, 1.95, 0, 0, 0.827702, 0.561168, 300, 100, 1, '', 'CoA Coldridge: Coldridge Pass (area 800), flat valley floor at the foot of the pass road, south of the road''s end where the mountaineer''s patrol turns, faces up the road toward the pass mouth; base within 0.06 yd of the ground over its whole footprint'),
(7912220, 1798, 0, 0, 0, 1, 1, -6319.5, 711, 384.687, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Coldridge: frozen lake in the south-west of the valley, Scorch''s campfire on the ice (200143)'),
(7912221, 1798, 0, 0, 0, 1, 1, -6111, 703, 433.087, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Coldridge: shelf above the crash site, Kali''s campfire');

-- ---------------------------------------------------------------------------
-- 10. Scripts
-- ---------------------------------------------------------------------------
-- Entry scripts on the package's own NPCs and circle; the shared visit marker 685037 runs a guid script.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (299326, 9300152, 9300154, 9300155) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(299326, 0, 0, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kali - On Aggro - Say Line 0'),
(9300152, 0, 0, 0, 19, 0, 100, 0, 200003, 0, 0, 0, 0, 0, 12, 299222, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -6146, 598.5, 388.437, 4, 'Talos - On Quest A Surprise Attack! Accepted - Summon Suspicious Creature from the pines'),
(9300152, 0, 1, 0, 8, 0, 100, 0, 684328, 0, 3000, 3000, 0, 0, 33, 685011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Talos - On Spellhit Tend Jo''s Wounds (Red Vial) - Quest Credit Tend to Talos'' wounds'),
(9300154, 0, 0, 1, 62, 0, 100, 0, 930251, 0, 0, 0, 0, 0, 33, 685022, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gyrothor Turbospark - On Gossip Option 0 Selected - Quest Credit Chat with Gyrothor'),
(9300154, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gyrothor Turbospark - Linked - Say Line 0'),
(9300154, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gyrothor Turbospark - Linked - Close Gossip'),
(9300155, 0, 0, 1, 8, 0, 100, 0, 512352, 0, 10000, 10000, 0, 0, 33, 685221, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hulda Frostwhisper - On Spellhit Witcher''s Torch - Quest Credit Find the Witch'),
(9300155, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Hulda Frostwhisper - Linked - Say Line 0'),
(9300155, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 299333, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -6068, 392, 392.762, 4.3, 'Hulda Frostwhisper - Linked - Summon the Witch in her place attacking the torch-bearer'),
(9300155, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hulda Frostwhisper - Linked - Despawn the disguise');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9301152 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(9301152, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Gossip Hello - Quest Credit Find the ritual circle'),
(9301152, 1, 1, 0, 19, 0, 100, 0, 200045, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -6243, 479.5, 386.972, 3.3, 'Ritual Circle - On Quest Call of the Dead Accepted - Summon the Undead Monstrosity'),
(9301152, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, -6243, 479.5, 386.972, 3.3, 'Ritual Circle - On Use - Summon the Undead Monstrosity again if none is near');

DELETE FROM `conditions` WHERE `SourceEntry` = 9301152 AND `SourceTypeOrReferenceId` = 22;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 9301152, 1, 0, 9, 0, 200045, 0, 0, 0, 0, 0, '', 'Ritual Circle - re-summon only while Call of the Dead is taken'),
(22, 3, 9301152, 1, 0, 29, 1, 299232, 20, 0, 1, 0, 0, '', 'Ritual Circle - re-summon only if no living Undead Monstrosity is within 20 yd');

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9003327 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-9003327, 0, 0, 0, 10, 0, 100, 0, 1, 8, 1000, 1000, 1, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit marker at the Statue of Uther - On OOC LOS - Quest Credit Visit the statue of Uther');
