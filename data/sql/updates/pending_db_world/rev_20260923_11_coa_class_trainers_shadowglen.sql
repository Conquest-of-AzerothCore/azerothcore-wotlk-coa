-- Conquest of Azeroth class trainers in Shadowglen (Teldrassil): the 19 CoA trainers of Aldrassil and
-- its grounds, the intro letters Conservator Ilthalaine hands out after The Balance of Nature, each
-- class's first quest chain (27 quests) and every creature and object those chains need. Builds on
-- rev_20260923_05 (class kits, class menus, shared chain templates).
--
-- WHERE EACH VALUE COMES FROM
--   trainer points  SOURCED-CLIENT: the QuestSuperTrack turn-in point of each letter (z from the server
--     floor). Facings are chosen by hand toward the way players arrive (reasons in the spawn comments).
--   trainers  name and title SOURCED-CACHE (creaturecache); Exodite Telusaara is new (the letter names
--     her; no cache record). Looks are stand-ins: no mirror-image capture of any Shadowglen trainer
--     exists and their CoA displays do not resolve, so each look copies a stock NPC of the inferred race
--     and theme, restyled so no two match. Named greetings: 25002 Nerdris, 25008 Shadowglen's ranger.
--   letters  SOURCED-CACHE quests 650141-650159; giver INFERRED from the stock letter pattern (Ilthalaine
--     after quest 456, as 3116-3120). Letter pages SOURCED-CACHE where cached (7004, 7005, 7007, 7009,
--     7010, 7012, 7013, 7014, 7019); the other ten are new in the same voice (INFERRED).
--   chains  SOURCED-CACHE quests; starters, enders and places from their texts; chain links by
--     PrevQuestID only. Drop chances SOURCED-EXILES. Every target, holder, object and marker is placed
--     by hand at a named landmark; where no source exists the choice is marked INFERRED.
--   stock trainers  Frahun Shadewhisper (46179) stands within 1.7 yd of a CoA trainer point and steps
--     aside; Alyissia (46178) is hidden while her Cultist kill copy stands in (rev_20260924_13).
--   stock spawn moved  Lyrai (46171), 2.5 yd west to stand beside Kaleidormu on his point (INFERRED).
--   map markers  quest_poi for 200046 and 200056, whose texts mark the map (INFERRED points).
--
-- Blocks: creature guid 9004100-9004299, gameobject guid 7912600-7912699, creature entry 9300350-9300399,
-- gameobject entry 9301350-9301399, gossip menu and npc_text 930450-930499. 19 trainers, 19 letters, 27 chain
-- quests, 29 creature and 22 gameobject spawns.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- 50295 Barbarian: template, look and weapons are ct-northshire's (second spawn of the Northshire Barbarian,
--   INFERRED: the cache has one Amanda)
-- 50344 Felsworn: night elf woman (page text 7005 "seek her"; Felsworn is a night elf class): Illidari look of
--   Alandien 21171, hair restyled; her warglaives
-- 503250 Witch Hunter: human man (page text 7019: "has brought his expertise to Teldrassil", "his"): Scarlet
--   Champion 4302 plate and crusader hat without the Scarlet tabard, restyled; sword and crossbow of a witch
--   hunter
-- 502772 Stormbringer: draenei woman (page text 7014: "has brought her knowledge to Teldrassil. This powerful
--   shaman"): Farseer Umbrua 20407 mail, restyled; Farseer Javad's staff
-- 502780 Knight of Xoroth: draenei woman (page text 7007 "her"; the chain's "mortal visage" of a demon): the
--   draenei death knight look 28424 in dark plate, restyled; a runeblade
-- 503240 Guardian: night elf woman (letter "herself", npccache 25002 "Analyze how I wield my mace"): Champion
--   Sentinel 13427 plate, restyled; a mace and the Darnassus Champion's shield
-- 502801 Templar: draenei woman (Templar is a draenei class, not a night elf one): Aldor Vindicator 18549 plate
--   and circlet, restyled; Vindicator's Brand and a draenei shield
-- 502920 Bloodmage: night elf man (Bloodmage is a night elf class): Highborne Summoner 11466 robes, hair
--   restyled; the Summoner's staff
-- 50341 Ranger: night elf man (npccache 25008, the Shadowglen ranger who "mastered the bow"): Cenarion Scout
--   Landion 15609 leathers, restyled; dagger and bow
-- 502821 Chronomancer: night elf man (letter: a bronze dragon teaching chronomancy; his mortal guise INFERRED as
--   a night elf in Teldrassil): Lorekeeper Lydros 14368 hat and robes, hair restyled bronze; staff
-- 50294 Necromancer: draenei man ("of the Auchenai"): Auchenai Necromancer 18702 robes, restyled; the Auchenai
--   staff
-- 502831 Cultist: night elf woman (page text 7004 "She"): Twilight Geomancer 5862 robes, restyled; the
--   Geomancer's staff
-- 50326 Starcaller: night elf woman (page text 7013 "she"): Huntress Skymane 14378, restyled; a glaive-spear and
--   a bow
-- 9300350 Sun Cleric: draenei woman ("Exodite", from the Exodar): Aldor Anchorite 19142 robes, restyled;
--   Ishanah's staff
-- 502871 Tinker: gnome man ("Rapidspyre", the chain's tinkering Jimb'les): Tinkmaster Overspark 7944 goggles and
--   leathers, restyled; a wrench and a rifle
-- 50343 Venomancer: night elf man ("Fangshifter"; Venomancer is a night elf class): Boahn 3672, Druid of the
--   Fang, restyled; the Druid of the Fang claws
-- 502890 Reaper: night elf man, hooded (INFERRED: "the Shade" who "walks between life and death"): Arantir's
--   Shadow 7229 hooded leathers, restyled; a scythe
-- 503420 Primalist: night elf woman (page text 7009 "her home"): Cenarion Druid 4052 leathers, restyled; Arch
--   Druid Renferal's staff
-- 502911 Runemaster: night elf woman (page text 7012: "Though the night elves have their own magical traditions,
--   she studies the runic arts"): Shen'dralar Ancient 14358, restyled; a lorekeeper's tome
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(50344, 'Flowzie the Fel-Touched', 'Felsworn Trainer', 930014, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503250, 'Darkslayer Harrendor', 'Witch Hunter Trainer', 930015, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502772, 'Q''ru', 'Stormbringer Trainer', 930016, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502780, 'Aheravara', 'Knight of Xoroth Trainer', 930017, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503240, 'Nerdris Darkstrike', 'Guardian Trainer', 930450, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502801, 'Elleora', 'Templar Trainer', 930019, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502920, 'Aramadus', 'Bloodmage Trainer', 930020, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50341, 'Hydriel Featherflight', 'Ranger Trainer', 930451, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502821, 'Kaleidormu', 'Chronomancer Trainer', 930022, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50294, 'Baarelam of the Auchenai', 'Necromancer Trainer', 930023, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502831, 'Saelina Shedana', 'Cultist Trainer', 930025, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50326, 'Huntress Naalia', 'Starcaller Trainer', 930026, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300350, 'Exodite Telusaara', 'Sun Cleric Trainer', 930027, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502871, 'Joro Rapidspyre', 'Tinker Trainer', 930028, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50343, 'Ko''rahl Fangshifter', 'Venomancer Trainer', 930029, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502890, 'Canni the Shade', 'Reaper Trainer', 930030, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503420, 'Prim''ula', 'Primalist Trainer', 930031, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502911, 'Raethere Daltrall', 'Runemaster Trainer', 930032, 10, 10, 0, 80, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50294, 50326, 50341, 50343, 50344, 502772, 502780, 502801, 502821, 502831, 502871, 502890, 502911, 502920, 503240, 503250, 503420, 9300350);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(50344, 0, 56, 1, 1),
(503250, 0, 49, 1, 1),
(502772, 0, 16126, 1, 1),
(502780, 0, 16126, 1, 1),
(503240, 0, 56, 1, 1),
(502801, 0, 16126, 1, 1),
(502920, 0, 55, 1, 1),
(50341, 0, 55, 1, 1),
(502821, 0, 55, 1, 1),
(50294, 0, 16125, 1, 1),
(502831, 0, 56, 1, 1),
(50326, 0, 56, 1, 1),
(9300350, 0, 16126, 1, 1),
(502871, 0, 1563, 1, 1),
(50343, 0, 55, 1, 1),
(502890, 0, 55, 1, 1),
(503420, 0, 56, 1, 1),
(502911, 0, 56, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (50294, 50326, 50341, 50343, 50344, 502772, 502780, 502801, 502821, 502831, 502871, 502890, 502911, 502920, 503240, 503250, 503420, 9300350);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(50344, 56, 4, 1, 1, 5, 1, 3, 4, 8, 0, 145533, 146604, 148105, 149525, 151375, 153487, 155566, 156552, 157838, 0, 0),
(503250, 49, 1, 0, 1, 1, 3, 5, 0, 4, 0, 144968, 145916, 147121, 148574, 10337, 2871, 154317, 0, 156825, 0, 0),
(502772, 16126, 11, 1, 1, 7, 7, 8, 2, 2, 0, 0, 27943, 0, 33624, 27940, 33625, 0, 0, 27941, 0, 0),
(502780, 16126, 11, 1, 1, 4, 2, 6, 0, 2, 0, 0, 44227, 0, 44228, 44236, 44230, 41584, 0, 44232, 0, 0),
(503240, 56, 4, 1, 1, 4, 2, 6, 1, 2, 0, 163917, 164031, 149088, 12629, 164997, 164033, 164034, 0, 164035, 0, 0),
(502801, 16126, 11, 1, 1, 5, 0, 9, 1, 0, 0, 144904, 146450, 148047, 149294, 151197, 153279, 155387, 0, 157707, 0, 158500),
(502920, 55, 4, 0, 1, 5, 8, 1, 7, 1, 0, 0, 12046, 0, 5210, 0, 5212, 19079, 0, 12546, 0, 0),
(50341, 55, 4, 0, 1, 0, 1, 6, 0, 5, 0, 0, 19612, 26711, 26714, 9458, 4600, 26713, 9847, 26185, 0, 0),
(502821, 55, 4, 0, 1, 5, 3, 3, 3, 1, 0, 18390, 0, 53683, 53684, 54655, 29586, 53686, 0, 13116, 0, 0),
(50294, 16125, 11, 0, 1, 13, 7, 4, 2, 3, 0, 0, 146485, 0, 149343, 151234, 153325, 0, 0, 0, 0, 0),
(502831, 56, 4, 1, 1, 5, 1, 0, 6, 4, 0, 0, 146122, 147683, 148881, 150724, 152732, 154901, 156344, 157318, 0, 0),
(50326, 56, 4, 1, 1, 5, 6, 5, 0, 4, 0, 11956, 24198, 20145, 5673, 7493, 22646, 8801, 0, 8802, 0, 0),
(9300350, 16126, 11, 1, 1, 8, 5, 3, 3, 0, 0, 0, 42894, 0, 31526, 30780, 31527, 31779, 0, 0, 0, 0),
(502871, 1563, 7, 0, 1, 3, 0, 1, 5, 4, 0, 14208, 14209, 8998, 7915, 6092, 1648, 14210, 1549, 14206, 0, 0),
(50343, 55, 4, 0, 1, 4, 7, 2, 3, 1, 0, 0, 0, 0, 147339, 150409, 8867, 154573, 0, 157027, 0, 0),
(502890, 55, 4, 0, 1, 2, 4, 5, 7, 0, 0, 12569, 0, 3564, 7557, 12555, 1174, 12570, 0, 12571, 0, 0),
(503420, 56, 4, 1, 1, 2, 6, 2, 2, 8, 0, 0, 0, 0, 147352, 150419, 152386, 154587, 156248, 157038, 0, 0),
(502911, 56, 4, 1, 1, 5, 3, 1, 3, 6, 0, 8051, 0, 7851, 24144, 19168, 5745, 7378, 13359, 9198, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50294, 50326, 50341, 50343, 50344, 502772, 502780, 502801, 502821, 502831, 502871, 502890, 502911, 502920, 503240, 503250, 503420, 9300350);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(50344, 1, 30208, 30209, 0),
(503250, 1, 1899, 0, 2551),
(502772, 1, 1908, 0, 0),
(502780, 1, 38707, 0, 0),
(503240, 1, 2810, 14825, 0),
(502801, 1, 29124, 24331, 0),
(502920, 1, 13061, 0, 0),
(50341, 1, 10619, 0, 5258),
(502821, 1, 49311, 0, 0),
(50294, 1, 13698, 0, 0),
(502831, 1, 5303, 0, 0),
(50326, 1, 13632, 0, 2550),
(9300350, 1, 28738, 0, 0),
(502871, 1, 1911, 0, 12523),
(50343, 1, 3494, 35719, 0),
(502890, 1, 28650, 0, 0),
(503420, 1, 13721, 0, 0),
(502911, 1, 12742, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (50294, 50326, 50341, 50343, 50344, 502772, 502780, 502801, 502821, 502831, 502871, 502890, 502911, 502920, 503240, 503250, 503420, 9300350);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(50344, 900014),
(503250, 900015),
(502772, 900016),
(502780, 900017),
(503240, 900018),
(502801, 900019),
(502920, 900020),
(50341, 900021),
(502821, 900022),
(50294, 900023),
(502831, 900025),
(50326, 900026),
(9300350, 900027),
(502871, 900028),
(50343, 900029),
(502890, 900030),
(503420, 900031),
(502911, 900032);

-- Named menus: Nerdris Darkstrike and Hydriel Featherflight speak their own cached greetings; Thalador
-- talks with the Reaper (INFERRED text).
DELETE FROM `npc_text` WHERE `ID` IN (25002, 25008, 930452);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(25002, 'Come, $c. It is I, Nerdris Darkstrike. It is so very nice to meet you.$B$BAnalyze how I wield my mace, $c.$B$BValor. Strength. Commitment. $n, these must triumph all other virtues!', 'Come, $c. It is I, Nerdris Darkstrike. It is so very nice to meet you.$B$BAnalyze how I wield my mace, $c.$B$BValor. Strength. Commitment. $n, these must triumph all other virtues!', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(25008, 'A lot of us in Shadowglen harness magic, I however, do not.$B$BBut let me tell you something - there''s more than one way to protect these ancient forests.$B$BWhile others call upon arcane forces, I have mastered the bow and learned to move like shadow through the trees.$B$BIf you seek the ranger''s path, I can show you how nature itself becomes your greatest ally.', 'A lot of us in Shadowglen harness magic, I however, do not.$B$BBut let me tell you something - there''s more than one way to protect these ancient forests.$B$BWhile others call upon arcane forces, I have mastered the bow and learned to move like shadow through the trees.$B$BIf you seek the ranger''s path, I can show you how nature itself becomes your greatest ally.', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(930452, '<The old elf leans on the railing, his gaze resting on the canopy far below.>$B$BAh, a young one. When I was your age I carried a glaive against the Legion itself, and I have buried more friends than I can count. Now my days are quiet, and I spend them up here, watching the leaves.$B$BWhat brings you to an old soldier, $c?', '<The old elf leans on the railing, his gaze resting on the canopy far below.>$B$BAh, a young one. When I was your age I carried a glaive against the Legion itself, and I have buried more friends than I can count. Now my days are quiet, and I spend them up here, watching the leaves.$B$BWhat brings you to an old soldier, $c?', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930450, 930451, 930452);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930450, 25002),
(930450, 175050),
(930451, 25008),
(930451, 102056),
(930452, 930452);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930450, 930451, 930452);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930450, 0, 3, 'I seek training as a Guardian.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930451, 0, 3, 'I seek training as a Ranger.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930452, 0, 0, 'Canni the Shade asked me to speak with you about what waits beyond this life.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930450, 930451, 930452) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930450, 25002, 0, 0, 15, 0, 131072, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Guardian'),
(14, 930450, 175050, 0, 0, 15, 0, 131072, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Guardian'),
(15, 930450, 0, 0, 0, 15, 0, 131072, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Guardian'),
(14, 930451, 25008, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Ranger'),
(14, 930451, 102056, 0, 0, 15, 0, 1048576, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Ranger'),
(15, 930451, 0, 0, 0, 15, 0, 1048576, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Ranger'),
(15, 930452, 0, 0, 0, 9, 0, 200038, 0, 0, 0, 0, 0, '', 'Thalador - option only while Call of the Shadowlands is taken');

-- ---------------------------------------------------------------------------
-- 2. Chain creatures and credit markers
-- ---------------------------------------------------------------------------
-- 9300350 Exodite Telusaara: the Sun Cleric trainer letter 650155 names (INFERRED new entry: no cache record)
-- 299237 Alyissia: Cultist "Going MAD!" target: the stock warrior trainer's name, display 1721 and sword
--   (SOURCED-CACHE creaturecache 3593 keeps name and display); neutral faction 7 so that she fights back without
--   attacking passers-by or drawing the sentinels
-- 299227 Satyr Trickster: Knight of Xoroth "The Demon Inside" target (name from the quest text); the Bleakheart
--   Trickster satyr (display 2018) and its demon faction 90, INFERRED
-- 299327 Alanor: Barbarian "Welcome to the Warband" target ("Kill Alanor ... bring her head back"): a night elf
--   woman who failed the Warband (display 2183) with a great axe, neutral faction 7, INFERRED
-- 9300351 Suspicious Night Elf: Bloodmage "Blood Is Power": the "suspicious Night Elf in the Grell camps" who
--   holds the Tome of Blood; the grells' own faction 189 (he is one of them), hooded display 2530, INFERRED
-- 9300352 Brim: Ranger chain: Hydriel's falcon Brim (name from 200005); the Hunting Hawk display 81083 of this
--   realm's own Hunting Hawk 116130, INFERRED
-- 9300353 Thalador: Reaper "Call of the Shadowlands": "an old elf who is nearing his end ... he lives a quaint
--   life in Aldrassil"; Elder Moonwarden's white-haired look (display 15621), INFERRED
-- 9300354 Wandering Herbalist: Witch Hunter "The Hunt Begins": the witch in her disguise, a night elf herbalist
--   (display 4182, Cylania Rootstalker's look); the Witcher's Torch reveals her, INFERRED
-- 685015 [KC] Splash Exodite Telusaara: Poisoning the World objective 1: Telusaara credits it on the Mysterious
--   Concoction
-- 685016 [KC] Splash Darkslayer Harrendor: Poisoning the World objective 2
-- 685017 [KC] Splash Baarelam of the Auchenai: Poisoning the World objective 3
-- 685032 Invisible Dummy (Starcaller1): SOURCED-CACHE name; waits in the Shadowglen moonwell and credits 685031
--   to a player who steps into the water
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(299237, 'Alyissia', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299227, 'Satyr Trickster', NULL, 0, 4, 4, 0, 90, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 3, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299327, 'Alanor', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300351, 'Suspicious Night Elf', NULL, 0, 3, 3, 0, 189, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 9300351, '', 0, 1, 1, 1, 1, 0, ''),
(9300352, 'Brim', 'Hydriel''s Falcon', 0, 3, 3, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(9300353, 'Thalador', NULL, 930452, 10, 10, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(9300354, 'Wandering Herbalist', NULL, 0, 4, 4, 0, 80, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(685015, '[KC] Splash Exodite Telusaara', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 130, ''),
(685016, '[KC] Splash Darkslayer Harrendor', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 130, ''),
(685017, '[KC] Splash Baarelam of the Auchenai', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 130, ''),
(685032, 'Invisible Dummy (Starcaller1)', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 130, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (299227, 299237, 299327, 685015, 685016, 685017, 685032, 9300351, 9300352, 9300353, 9300354);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(299237, 0, 1721, 1, 1),
(299227, 0, 2018, 1, 1),
(299327, 0, 2183, 1, 1),
(9300351, 0, 2530, 1, 1),
(9300352, 0, 81083, 1, 1),
(9300353, 0, 15621, 1, 1),
(9300354, 0, 4182, 1, 1),
(685015, 0, 11686, 1, 1),
(685016, 0, 11686, 1, 1),
(685017, 0, 11686, 1, 1),
(685032, 0, 11686, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (299237, 299327, 9300351);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(299237, 1, 1899, 0, 0),
(299327, 1, 14475, 0, 0),
(9300351, 1, 2711, 0, 0);

-- ---------------------------------------------------------------------------
-- 3. World objects
-- ---------------------------------------------------------------------------
-- 9301350 Training Wand: Chronomancer "Perfect Timing": the wand lying where Kaleidormu left it (wand model
--   100515 of the stock chest Galgosh's Other Bone)
-- 9301351 Eye of the Beholder: Runemaster "Runes of Power": the gemstone the riddle points to (EyeOfAzora model
--   621 of the stock chest Ryson's All Seeing Eye, standing on the floor as the other zones' Eye chests do)
-- 9301352 Skull of L'ok: Felsworn "Coming into Demonhood": the demon skull (skull model 4173 of Horgus' Skull)
-- 9301353 Lost Pendant: Sun Cleric "Lost Pendant" (necklace model 63520 of the CoA Frozen Pendant 356439)
-- 9301354 Scrap Metal: Tinker "Ingenuity At It's Finest!" (gnome steel plate 450 of the stock Super Strong Metal
--   Plate)
-- 9301355 Statue of Uther: Templar "A Quiet Life": Uther's statue (UtherStatue.mdx, display 6815 of the stock
--   Uther's Statue 181653)
-- 9301356 Ritual Circle: Necromancer chain: the ritual circle (the Dire Maul warlock circle 5812); ends Call of
--   Death, gives and ends Death Calls, gives Call of the Dead; SmartGameObjectAI credits and summons
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`)
VALUES
(9301350, 3, 100515, 'Training Wand', '', 1, 43, 9301350, 0, 1, 0, 0, 0, 0, 200167, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301351, 3, 621, 'Eye of the Beholder', '', 1, 43, 9301351, 0, 1, 0, 0, 0, 0, 200111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301352, 3, 4173, 'Skull of L''ok', '', 1.2, 43, 9301352, 0, 1, 0, 0, 0, 0, 200021, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301353, 3, 63520, 'Lost Pendant', '', 1, 43, 9301353, 0, 1, 0, 0, 0, 0, 200061, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301354, 3, 450, 'Scrap Metal', '', 0.8, 43, 9301354, 0, 1, 0, 0, 0, 0, 200067, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301355, 5, 6815, 'Statue of Uther', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301356, 2, 5812, 'Ritual Circle', '', 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- The Ranger's Path (200005) carries the Northshire copy's map point (-8799.29, -412.93) in the cache;
-- it points at Brim's glade here, the quest's own target (DERIVED). The Stolen Power Core (200093):
-- ObjectiveText1 is '0' in the cache (a CoA data quirk on its seven copies only); left blank.
-- RewardNextQuest (the next step is offered at turn-in): questcache NextQuestInChain where the next quest is in
--   this file: 200005->200006, 200006->200007, 200046->200047, 200047->200048, 200092->200093, 200093->200094,
--   200131->200132, 200132->200133.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(650141, 2, 2, 2, -526, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650141, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warrior''s Letter', 'Seek out Amanda in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be an ancient tablet carved with primitive barbarian runes that pulse with primal fury. The stone itself radiates wild strength, and it seems to be from Amanda, who teaches the barbarian''s way in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Amanda in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650141, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Amanda in Shadowglen', '', '', ''),
(650142, 2, 2, 2, -516, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650142, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Mage Letter', 'Seek out Aramadus in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a crimson scroll stained with what looks suspiciously like blood. The parchment pulses rhythmically with dark magical energies, and it seems to be from Aramadus, the blood mage who practices these forbidden arts in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Aramadus in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650142, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Aramadus in Shadowglen', '', '', ''),
(650143, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Temporal Letter', 'Seek out Kaleidormu in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a temporal manuscript that seems to exist in multiple moments simultaneously. The text shifts before my eyes, showing glimpses of past and future, and it seems to be from Kaleidormu, the bronze dragon who teaches chronamancy in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Kaleidormu in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650143, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Kaleidormu in Shadowglen', '', '', ''),
(650144, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650144, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Whispered Tome', 'Seek out Saelina Shedana in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a whispered parchment covered in symbols that shift when not observed directly. Strange voices echo from within, and it seems to be from Saelina Shedana, who communes with forbidden powers in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Saelina Shedana in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650144, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Saelina Shedana in Shadowglen', '', '', ''),
(650145, 2, 2, 2, -517, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650145, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Demonic Pact', 'Seek out Flowzie the Fel-Touched in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a demonic contract wreathed in green fel flames. The parchment bears infernal script that sears the eyes, and it seems to be from Elyri the Fel-Touched, who teaches others to bind demonic power in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Flowzie the Fel-Touched in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650145, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Elyri the Fel-Touched in Shadowglen', '', '', ''),
(650146, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650146, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sacred Warding', 'Seek out Nerdris Darkstrike in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be sacred warding inscribed with solemn vows of protection. The parchment radiates an aura of unbreakable defense, and it seems to be from Nerdris Darkstrike, who has dedicated herself to protecting others. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Nerdris Darkstrike in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650146, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Nerdris Darkstrike in Shadowglen', '', '', ''),
(650147, 2, 2, 2, -518, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650147, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dark Chivalry', 'Seek out Aheravara in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a dark proclamation bearing the seal of Xoroth, wreathed in cold shadow flames. The document speaks of wielding darkness in service of light, and it seems to be from Aheravara, who walks this dangerous path in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Aheravara in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650147, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Aheravara in Shadowglen', '', '', ''),
(650148, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Deathbound Codex', 'Seek out Baarelam of the Auchenai in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a bone-bound codex that chills the air around it. I can hear faint whispers of the departed emanating from its pages, and it seems to be from Baarelam of the Auchenai, who practices necromancy in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Baarelam of the Auchenai in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650148, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Baarelam of the Auchenai in Shadowglen', '', '', ''),
(650149, 2, 2, 2, -531, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650149, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Elemental Calling', 'Seek out Prim''ula in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be an elemental scroll that crackles with primal energy. Miniature storms, flames, and earthen tremors swirl across its surface, and it seems to be from Prim''ula, who commands the elements in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Prim''ula in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650149, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Prim''ula in Shadowglen', '', '', ''),
(650150, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warden''s Call', 'Seek out Hydriel Featherflight in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a nature-worn parchment that still bears traces of the deep wilderness - pine needles, moss, and the scent of ancient forests. It seems to be from Hydriel Featherflight, the ranger who protects the wilds of Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Hydriel Featherflight in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650150, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Hydriel Featherflight in Shadowglen', '', '', ''),
(650151, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Soul Harvest', 'Seek out Canni the Shade in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a grim letter bound in black leather that seems to drain light from its surroundings. The scent of autumn''s end clings to its pages, and it seems to be from Canni the Shade, who walks between life and death in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Canni the Shade in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650151, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Canni the Shade in Shadowglen', '', '', ''),
(650152, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650152, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Inscribed Tablet', 'Seek out Raethere Daltrall in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be an inscribed tablet carved with glowing runes that pulse with primordial power. The symbols seem older than civilization itself, and it seems to be from Raethere Daltrall, the runemaster who dwells in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Raethere Daltrall in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650152, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Raethere Daltrall in Shadowglen', '', '', ''),
(650153, 2, 2, 2, -506, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650153, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Celestial Guidance', 'Seek out Huntress Naalia in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a celestial chart containing star maps that twinkle with actual starlight. The parchment is warm to the touch despite its ethereal coldness, and it seems to be from Huntress Naalia, who studies the stars in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Huntress Naalia in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650153, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Huntress Naalia in Shadowglen', '', '', ''),
(650154, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650154, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Thunder''s Call', 'Seek out Q''ru in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a storm manuscript that crackles with electrical energy. Thunder rumbles softly from within its pages, and it seems to be from Q''ru, the stormbringer who commands tempests in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Q''ru in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650154, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Q''ru in Shadowglen', '', '', ''),
(650155, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650155, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Solar Benediction', 'Seek out Exodite Telusaara in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a golden scripture that radiates the warm light of dawn. Blessed parchment glows with healing energy, and it seems to be from Exodite Telusaara, the sun cleric who brings light to Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Exodite Telusaara in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650155, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Exodite Telusaara in Shadowglen', '', '', ''),
(650156, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650156, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sacred Vow', 'Seek out Elleora in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a sacred vow written on blessed parchment that emanates holy light. The document fills nearby hearts with courage, and it seems to be from Elleora, who serves as a templar in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Elleora in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650156, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Elleora in Shadowglen', '', '', ''),
(650157, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650157, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mechanical Schematics', 'Seek out Joro Rapidspyre in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be mechanical schematics filled with intricate blueprints. I can hear the faint sound of ticking clockwork mechanisms emanating from the pages, and it seems to be from Joro Rapidspyre, the tinker who works in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Joro Rapidspyre in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650157, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Joro Rapidspyre in Shadowglen', '', '', ''),
(650158, 2, 2, 2, -515, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650158, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Toxic Formulae', 'Seek out Ko''rahl Fangshifter in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a leather compendium reeking of exotic toxins, with green vapors occasionally seeping from between its pages. It seems to be from Ko''rahl Fangshifter, who studies the art of venoms and antidotes in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Ko''rahl Fangshifter in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650158, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Ko''rahl Fangshifter in Shadowglen', '', '', ''),
(650159, 2, 2, 2, -519, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650159, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Inquisitor''s Mandate', 'Seek out Darkslayer Harrendor in Shadowglen.', 'I was asked to bring this to your attention, $N. It appears to be a blessed mandate that burns with righteous fire. Its holy script is designed to strike fear into the hearts of the corrupt, and it seems to be from Darkslayer Harrendor, who hunts corruption in Shadowglen. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Darkslayer Harrendor in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 650159, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak to Darkslayer Harrendor in Shadowglen', '', '', ''),
(200005, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200006, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 10688, 728, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ranger''s Path', 'Find Hydriel''s falcon in Shadowglen.', 'Being a Ranger is more than just picking up a bow, or fighting from the cover of the trees, $n.  Being a Ranger, at its core, means that you have a profound connection to the wilds. You are its protector.  I sent my falcon, Brim, to scout the surrounding areas, but he has not returned.   Please, find him and direct him to return back to me.', '', 'Find Hydriel''s falcon in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200006, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200007, 3, 0, 0, 0, 0, 0, 0, 662316, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Surprise Attack!', 'Slay the suspicious creature.', 'Something is rustling in the nearby bushes.  You''re under attack! ', '', 'Tend to the falcon.', 299222, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200007, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 0, 2, 70, 0, 0, 0, 0, 0, 662317, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 818000, 1, 727000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Falcons Are Friends', 'Use the Red Vial on the falcon.', 'You find a note attached to the falcon that reads:  <If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.>', '', 'Return to your trainer.', 685011, 0, 0, 0, 1, 0, 0, 0, 662317, 662316, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 'Tend to Brim''s wounds', '', '', ''),
(200018, 2, 3, 3, -516, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 661317, 1, 1505015, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Is Power', 'Collect the Tome of Blood from the suspicious Night Elf.', 'Ahh, $C. Your day has finally come.  Blood. Something you should be well acquainted with at this point, in some way or another. Blood is life. But blood, as you will soon learn, is also power.  I want you to imagine what you can be capable of in a world in which you can control the very life essence of another beings body. To simply crush their insides with the flick of a wrist...  Intoxicating.  In due time, you will learn more. For now, I require your assistance in pursuing my own studies and through this I will also be able to help you learn.   Nearby is a tome held by a suspicious Night Elf in the Grell camps, and one of which I require for my studies. Collect it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661316, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200021, 2, 3, 3, -517, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 727002, 1, 727001, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Coming into Demonhood', 'Retrieve the skull of Lo''k.', 'And so it begins.  Greetings, $N. I can already tell that you have begun to feel the residual fel power that burns within your veins. I envy you, there was once a time where I was not so used to it as I am now.  You are Felsworn, and as such, you are at the border of mortality and the likes of demons. However, unlike some, you and I will not fall to the traps of power that fel magic provides, and that so many other practitioners fall too, often unbeknownstly. Perhaps you will even become powerful enough to take on a demonic form someday, but for now, your Fel Empowerment will do you wonders at bringing out your true potential.  Let me make myself clear, the Horde and Alliance are of no use to us, but they must believe we are their allies in order for our greater goals to become achievable. Do not forget this. When it all comes to a head, do not forget where your true allegiance lays.  And now, a test. A skull of a powerful demon known as Lo''k has been placed in the surrounding area. Find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200025, 2, 3, 3, -515, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662217, 0, 0, 292200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Poisoning the World', 'Splash the mysterious concoction on nearby citizens.', 'Welcome, $C. Have you come to poison the well, so to speak?  I am always willing to teach new and aspiring masters of the venomous arts, but in return, I sometimes require a favor. This is fine, yes?  Look around you. There are citizens of every shade. But they are pure, which is good, they are untainted. Here I have a concoction that I have made. What it does, should not be of concern to you.  What I need is for you to splash it on three people in particular; first, Exodite Telusaara, second, Darkslayer Harrendor, and third, Baarelam of the Auchenai.  Return to me when you have done this and I will make it worth your time.', '', 'Return to your trainer.', 685015, 685016, 685017, 0, 1, 1, 1, 0, 662217, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Exodite Telusaara', 'Darkslayer Harrendor', 'Baarelam of the Auchenai', ''),
(200031, 2, 3, 3, -506, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 300100, 1, 300101, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Champion of Elune', 'Head to the nearby Moonwell to praise Elune.', 'Ishnu-alah, $N. I see Elune has not forgotten you, good, I could use one so blessed.  As Starcallers, we are champions of Elune, and as such, we must carry out her will - wherever it takes us, and whatever it must be.  But, when the land is embroiled with peace, one must learn to still pay respects to Elune, so that she will be there to guide us when the land is yet again filled with war and despair.  Make a pilgrimage to the nearby Moonwell, step inside its magical waters, meditate, and pay respects to the goddess, then return to me.', '', 'Return to your trainer.', 685031, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Pay respects to Elune', '', '', ''),
(200036, 2, 3, 3, -518, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 2000124, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Demon Inside', 'Kill the Satyr Trickster in Shadowglen.', 'Aha, $N, welcome, do you like your mortal visage? The time has come for us to unleash hell upon Azeroth, one step at a time.  As you well know, there are only so many of us, but our numbers will grow with time. I need not remind you, I assume, that the plight of the Alliance is not your primary concern. They are but a tool, a shield, so that we may further our own goals.  At every step, at every moment, we must wreck havoc on this world, yet we must not give up our secret - that we are demons - and as such, I have a little task for you.  There is a satyr who should not be here. He is causing trouble for the local residents of Shadowglen.  I have been tasked by my superiors here to deal with him.   Kill him, Satyrs are not seen kindly here.', '', 'Return to your trainer.', 299227, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200038, 2, 3, 3, -508, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 540070, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Shadowlands', 'Visit Thalador in Aldrassil.', 'Welcome, $C. I have heard much about your arrival here in Shadowglen. I have much to teach you.  But you have come to me at the perfect moment, for I have a special task for you.  Here in Aldrassil is an old elf who is nearing his end. In his prime, he was a behemoth on the battlefield and took many lives. But now, he lives a quaint life in Aldrassil.  He will die and the Shadowlands will claim him. But today is not his day. Yet, I can feel his yearning to leave this plane, but he is unaware of what lays before him once he is gone.  You may not have expected such a task, but I would humbly ask you to pay him a visit and have a chat.', '', 'Return to your trainer.', 685022, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chat with Thalador', '', '', ''),
(200046, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200047, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of Death', 'Find and interact with the ritual circle.', 'Greetings, $C. Glad you could join me in the graveyard today.  Beautiful day, isn''t it?  It seems you''ve already been acquainted with undeath, I am impressed by your ability to raise the dead.   Perhaps you could be used to my benefit, which I''m sure you would not mind. I have a particularly powerful Undead that I wish to summon, but I dare not attempt it myself - I am far too important.  You, however, could learn quite a lot by succeeding here. And if you are to fail? I will simply raise you as my own.  Do not overthink it. Let me mark your map to the location of where my ritual must be had. You must collect specific items in order to complete the ritual.  Now, be gone.', '', 'Interact with the ritual circle.', 685121, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the ritual circle', '', '', ''),
(200047, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200048, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Calls', 'Kill Grells and loot their bones, flesh, and skull.', 'In order to summon the Undead monstrosity, I must bring the following ingredients to the ritual circle.  - Bones - Fresh Flesh - Skull  The nearby Grells have just what is needed.', '', 'Return to the ritual circle.', 0, 0, 0, 0, 0, 0, 0, 0, 458421, 458422, 458423, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(200048, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 660053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Dead', 'Kill the Undead Monstrocity.', '<The materials dissipate into the ritual circle into a puff of smoke>  ...something seems off.  The summon has failed, inspect the ritual circle again. But be careful, it is unstable.', '', 'Return to your trainer.', 299232, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200056, 2, 3, 3, -519, 0, 0, 0, 0, 0, 0, 0, 4, 66, 0, 0, 0, 0, 0, 662219, 0, 0, 717002, 1, 410005, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Hunt Begins', 'Reveal the witch and kill her.', 'I can feel an evil presence.  You can feel it too, can''t you? That is why you have come to me at the most opportune of times.  There is one here. A witch. Brooding with evil and malintent.  May the Light bless us for what we''re about to do.  Here, take this torch. She''s here and I''ve marked her location on your map. Use the torch on her to reveal her true self. Kill it. No mercy.  Return to me when it''s been slain.  Damned witches.', '', 'Return to your trainer.', 685221, 299333, 0, 0, 1, 1, 0, 0, 662219, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Find the Witch', '', '', ''),
(200061, 2, 3, 3, -507, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 454381, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Pendant', 'Find the lost pendant.', 'Greetings, $C. You have arrived at the perfect time.  I have lost a pendant of mine that is quite powerful. Lost may be the wrong word, but alas, we best not get lost in the semantics.  Well, I guess I owe it to you to at least explain what happened if you''re going to help me. So here goes.  I was attempting to show the Grell that they too can turn the Light... but it did not bode well. They chased me out of their camp and I barely made it out alive.  In my haste, I dropped my pendant. Please, find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200067, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 415000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ingenuity At It''s Finest!', 'Collect 3 Scrap Metal.', 'Greetings. $N, was it? Welcome to Aldrassil.  You seem to be the tinkering type and I was honestly on the look out for one like you. I''m trying to make a special type of gun, a homemade gun some might say, but I need some more metal.  There is some metal out there near the grell camps that could be used to create a gun for you and me. Collect me some and I''ll go tinkering away!', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663320, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', ''),
(200073, 2, 3, 3, -522, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532803, 1, 532804, 1, 532881, 1, 0, 0, 0, 0, 0, 0, 1, 10348.9, 700.849, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Going MAD!', 'Kill Alyissia.', 'You have arrived at the most opportune time, $N.  I have heard the whispers of the great beyond. It tells me of a particularly dangerous individual to our cause. I need you to destroy them, swiftly.  If you do this I will reward you with a weapon fit for a follower of the Old Gods themselves.  The individual you''re looking for lays inside Aldrassil. I think somewhere outside. They go by the name of "Alyissia". End her.', '', 'Return to your trainer.', 299237, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200079, 2, 3, 3, -524, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 52855, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Quiet Life', 'Visit the statue of Uther in Shadowglen.', 'Welcome to the order, $N. I have awaited your arrival.  As Templars, we have ascended to the highest order of the holy faith, and as such we have quite a lot of responsibility on our shoulders.  Paladins and Priests work alongside us to maintain peace through the Holy Light in this world and each of us, though different in our own subtle ways, hope to bring the light to Azeroth once more. Despite it''s perils.  Our path may be different but some may argue that it is far more rigorous. To be a templar means to maintain extremely precise control of your emotions, your combat flow, and your mind.  In order to keep myself healthy I enjoy meditating on a hill where a statue of a powerful Paladin was erected in his honor by some visiting Paladins after the third war. Please, visit the area yourself. Tell me what you experience when you return.', '', 'Visit the statue of Uther in Shadowglen.', 685037, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit the statue of Uther', '', '', ''),
(200092, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 200093, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Useful In Your Own Right', 'Assist Jimb''les Rapidspyre with his tinkering shenanigans.', 'Greetings, $N, I am glad to make your acquaintance and I have heard much about you before your arrival.  You have come to me to learn and as a $C you have already shown yourself to be a dutiful student of the arcane. But there is so much more to the power that we call forth than just lightning and electricity.  In time, you will learn just how deep your potential lays. But for now... I do have a bit of a task for you.  There''s an individual nearby known as "Jimb''les Rapidspyre" and he always calls on my aid for his... tinkering shenanigans... He needs some lightning, $N, but I am busy. Can you go and assist him?', '', 'Assist Jimb''les Rapidspyre with his tinkering shenanigans.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200093, 2, 3, 0, -520, 0, 0, 0, 0, 0, 0, 200094, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Stolen Power Core', 'Kill grells until one of them drops the power core.', 'Howdy, $N! Glad your trainer got around to sendin'' some help my way.  This is a very simple task, I just need some POWER! But unfortunately my power core has been stolen by one of the nearby grells. Can you return it for me?', '', 'Return to Jimb''les Rapidspyre.', 0, 0, 0, 0, 0, 0, 0, 0, 661417, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200094, 2, 3, 0, -525, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 663317, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Job For A Stormcaller', 'Tell your trainer of your success.', 'I appreciate you retrieving this power core! You can return to your trainer now and let him know what you''ve done for me.', '', 'Tell your trainer of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200106, 2, 3, 3, -526, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 532805, 1, 532806, 1, 395861, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Welcome to the Warband', 'Kill Alanor and bring her head back to your trainer.', 'Har! Har! Welcome, $N. Glad you could join the Warband.  What is the Warband, you might be wondering? Considering your arrival, I would have assumed you''d already know. Well, little $c, this is about to be a rude awakening.  The Warband is where all barbarians, brutes, and strongmen alike come together to compete to see who is the strongest, most brutal, and most powerful individual of them all.  That''s the only way we can TRULY test our mettle. THIS IS IT! You may be new to this, but absolutely nobody will go easy on you.  Your first test will be the same as all the other rookies. There''s an individual who has been mucking things up and spreading rumors just because they couldn''t cut it and were denied access to the Warband.  They''re known as Alanor. Kill her, hahaha! I will reward you with a weapon well-suited for a noob like yourself if you are capable of such a task.  Come back to me alive, or die.', '', 'Return to your trainer.', 299327, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200111, 2, 3, 3, -527, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 661329, 0, 0, 293202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes of Power', 'Figure out the riddle etched on the runestone.', 'Greetings, $N. I''m glad you could finally join me, I have awaited your arrival.  Today, a simple lesson in problem solving for an aspiring Runemaster such as yourself. Perhaps you will succeed, perhaps you will not.  Here, I have a rune. Etched on the rune is a riddle. Figure the riddle out and return to me.   A hint? The best I can do is tell you that the answer to this riddle lays within Aldrassil. Not without.  I will know when you return if you have figured it out or not, do not worry. Succeed, and I will reward you.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661330, 661329, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, '', '', '', ''),
(200131, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200132, 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Peace Through Strength', 'Find Gilshalan Windwalker in Shadowglen.', 'It is nice to meet you, $N. We have much work to accomplish together and you, my friend, have much to learn!  We are Guardians, and as such we are tasked with, quite literally, guarding Azeroth. From the occasional ne''er-do-well that robs a man, to far more threatening monsters who pose a threat to our people. We are the ones who heed the call.  And, as my example preludes, I have such a task for you today. If you can do this, you are more than ready to proceed further into your training.  There is an individual nearby who goes by the name of Gilshalan Windwalker, perhaps you''ve met him already? I believe he could use my help.  Visit him and see what he needs.', '', 'Find Gilshalan Windwalker in Shadowglen.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200132, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200133, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Prioritizing Defense', 'Kill Grell until you find a suitable weapon for Gilshalan Windwalker.', 'Greetings, $N. I can see you''re here to help, that''s great!  I''m in need of a weapon for self defense and if you could help me acquire one I would be inclined to reward you.  The grells nearby... I''ve been studying them. One of them has a particular weapon that would be perfect for me. If you could acquire one for me in tip-top shape, that would be perfect!', '', 'Return to Gilshalan Windwalker.', 0, 0, 0, 0, 0, 0, 0, 0, 662330, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200133, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 0, 2, 25, 0, 0, 0, 0, 0, 0, 0, 0, 245712, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Helping A Friend', 'Return to your trainer with news of your success.', 'You have done well by bringing me this.   Now, I will do well for you. Here, I found this shield in the spider mine not too far from here. May it serve you well.', '', 'Return to your trainer with news of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200161, 2, 3, 3, -531, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 296200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Way of the Bear', 'Kill 8 Webwood Spider.', 'Welcome, $C. I have awaited your arrival here in Aldrassil.    You come to me for wisdom, and as such, I will deliver.    The first step to becoming a master $C is mastering the way of the bear. With each successive mastery will come yet another challenge, but for now, let''s focus on what it means to unlock your inner savage instincts.    Bears are large, ferocious creatures. They know only what they must to survive, and that is to kill. There is little one can do to escape from a bear who wishes to end their life.    Through the bear we gain savagery, viciousness, and strength, without mercy.     Show me that you understand this by ending the lives of the Webwood Spiders in the cave near here and I will reward you.', '', 'Return to your trainer.', 1986, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200167, 2, 3, 3, -530, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 553122, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Perfect Timing', 'Find Kaleidormu''s wand in Aldrassil.', 'Ahhh, $N, I saw your arrival long ago. Now it is time to teach you what it means to be a Chronomancer. To weave the very fabric of space and time. To be equivalent to a god...   Let me not get ahead of myself. For you, $N, are new to the world of chronomancy, and before I can allow you to inhabit this world with such latent power... you must learn how to control yourself.  As a Chronomancer, you are a master of time magic. This means you must respect time on the most foundational of levels. It just so happens that I left my wand somewhere in the in this building here.  You have 2 minutes. Find it for me.', '', 'Return to Kaleidormu.', 0, 0, 0, 0, 0, 0, 0, 0, 661335, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

UPDATE `quest_template` SET `TimeAllowed` = 120 WHERE `ID` = 200167;

DELETE FROM `quest_template_addon` WHERE `ID` IN (200005, 200006, 200007, 200018, 200021, 200025, 200031, 200036, 200038, 200046, 200047, 200048, 200056, 200061, 200067, 200073, 200079, 200092, 200093, 200094, 200106, 200111, 200131, 200132, 200133, 200161, 200167, 650141, 650142, 650143, 650144, 650145, 650146, 650147, 650148, 650149, 650150, 650151, 650152, 650153, 650154, 650155, 650156, 650157, 650158, 650159);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(650141, 0, 2048, 456, 1, 0),
(650142, 0, 524288, 456, 1, 0),
(650143, 0, 2097152, 456, 1, 0),
(650144, 0, 16777216, 456, 1, 0),
(650145, 0, 8192, 456, 1, 0),
(650146, 0, 131072, 456, 1, 0),
(650147, 0, 65536, 456, 1, 0),
(650148, 0, 4194304, 456, 1, 0),
(650149, 0, 1073741824, 456, 1, 0),
(650150, 0, 1048576, 456, 1, 0),
(650151, 0, 536870912, 456, 1, 0),
(650152, 0, 2147483648, 456, 1, 0),
(650153, 0, 33554432, 456, 1, 0),
(650154, 0, 32768, 456, 1, 0),
(650155, 0, 67108864, 456, 1, 0),
(650156, 0, 262144, 456, 1, 0),
(650157, 0, 134217728, 456, 1, 0),
(650158, 0, 268435456, 456, 1, 0),
(650159, 0, 16384, 456, 1, 0),
(200005, 0, 1048576, 650150, 0, 0),
(200006, 0, 1048576, 200005, 1, 0),
(200007, 0, 1048576, 200006, 1, 0),
(200018, 0, 524288, 650142, 0, 0),
(200021, 0, 8192, 650145, 0, 0),
(200025, 0, 268435456, 650158, 1, 0),
(200031, 0, 33554432, 650153, 0, 0),
(200036, 0, 65536, 650147, 0, 0),
(200038, 0, 536870912, 650151, 0, 0),
(200046, 0, 4194304, 650148, 0, 0),
(200047, 0, 4194304, 200046, 0, 0),
(200048, 0, 4194304, 200047, 0, 0),
(200056, 0, 16384, 650159, 1, 0),
(200061, 0, 67108864, 650155, 0, 0),
(200067, 0, 134217728, 650157, 0, 0),
(200073, 0, 16777216, 650144, 0, 0),
(200079, 0, 262144, 650156, 0, 0),
(200092, 0, 32768, 650154, 0, 0),
(200093, 0, 32768, 200092, 0, 0),
(200094, 0, 32768, 200093, 0, 0),
(200106, 0, 2048, 650141, 0, 0),
(200111, 0, 2147483648, 650152, 1, 0),
(200131, 0, 131072, 650146, 0, 0),
(200132, 0, 131072, 200131, 0, 0),
(200133, 0, 131072, 200132, 0, 0),
(200161, 0, 1073741824, 650149, 0, 0),
(200167, 0, 2097152, 650143, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (200005, 200006, 200007, 200018, 200021, 200025, 200031, 200036, 200038, 200046, 200047, 200048, 200056, 200061, 200067, 200073, 200079, 200092, 200093, 200094, 200106, 200111, 200131, 200132, 200133, 200161, 200167, 650141, 650142, 650143, 650144, 650145, 650146, 650147, 650148, 650149, 650150, 650151, 650152, 650153, 650154, 650155, 650156, 650157, 650158, 650159);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(650141, 'I can see the primal fury awakening in your blood, $N! You have chosen the ancient path of the barbarian, embracing the wild rage that flows through the veins of those who refuse to be tamed.$B$BAs a Barbarian, you will learn to channel your innermost fury into devastating combat techniques. Your enemies will flee before your berserker rage, while your allies draw strength from your untamed courage. The wilderness itself will become your ally, teaching you to fight like the beasts of the forest.$B$BThis path is not for the weak of heart or mind. You must learn to balance your rage with wisdom, your fury with honor. But for those who master this balance, there is no force more terrifying on the battlefield than a barbarian in full fury.$B$BWelcome, brother of the wild. Let your training begin!'),
(650142, 'The crimson art flows through you now, $N. I can sense the power in your veins, the willingness to sacrifice life itself for greater magical might. You have chosen the dangerous path of blood magic.$B$BAs a Bloodmage, you will learn to manipulate the very essence of life, turning blood into raw magical energy. Your own vitality will fuel spells of incredible power, while your enemies'' life force becomes your weapon. This is magic at its most primal and dangerous.$B$BRemember always that every spell cast comes at a cost. Your own blood, your enemies'' blood, the blood of sacrifice - all become components in your dark art. But for those brave enough to pay this price, the rewards are beyond ordinary comprehension.$B$BThe crimson path is now yours to walk. May your power grow with each drop spilled.'),
(650143, 'Time itself shifts around you, $N! You have chosen to study the most complex and dangerous of all magical arts - the manipulation of temporal reality itself. Few mortals possess the mental discipline required for chronamancy.$B$BAs a Chronomancer, you will learn to slow your enemies until they move like statues, accelerate your allies to superhuman speed, and even glimpse echoes of past and future events. The very fabric of time will bend to your will.$B$BThis magic demands perfect precision and unwavering focus. A single miscalculation could trap you in temporal loops, age you decades in seconds, or worse. But master these techniques, and you will become nearly untouchable in battle.$B$BThe streams of time await your command. Let us begin with the fundamental principles of temporal manipulation.'),
(650144, 'The whispers grow stronger now that you have joined us, $N. I can hear the Old Ones speaking of your potential, their ancient voices carried on winds that normal minds cannot perceive. You have chosen the path of forbidden knowledge.$B$BAs a Cultist, you will learn to commune with entities that exist beyond mortal understanding, gaining power through dangerous pacts and eldritch wisdom. Your magic will tap into forces that predate civilization itself.$B$BThis knowledge comes with great risk. The whispers can drive weak minds to madness, and the beings you contact care nothing for mortal concerns. But for those with the strength to endure, the secrets of the universe itself lie within reach.$B$BListen carefully to what I teach you. The Old Ones are always watching, and they do not tolerate failure from those who serve them.'),
(650145, 'The fel energies recognize you now, $N. Your soul bears the mark of one willing to embrace demonic power without hesitation. In an age ruled by fire and ruin, only those strong enough to claim corruption survive.$B$BAs one of the Felsworn, you will bind demonic essence through domination and pact, tearing infernal allies from the Twisting Nether and bending the fires of the Burning Legion to your will. This power was never meant to be restrained. It exists to be taken.$B$BMany who walk this path are consumed by corruption because they lack the will to command it. You will not. The whispers of demons are not warnings but revelations, truths offered only to those ruthless enough to listen.$B$BThe fel flames burn within you now. Let them consume doubt, mercy, and weakness. Power is its own justification. May this gift remake the world in your image.'),
(650146, 'The sacred ward strengthens around you, $N! You have accepted the most noble of callings - to serve as an eternal guardian, placing the safety of others above your own without question or hesitation.$B$BAs a Guardian, you will learn to become a living fortress, your body and magic forming an impenetrable barrier between your allies and harm. Your defensive techniques will make you nearly invulnerable, while your protective spells shield entire groups from danger.$B$BThis path requires selfless dedication. You will endure pain so others need not, face death so others may live. Glory and recognition often pass by those who prevent disaster rather than cause it. But know that there is no higher honor than preserving innocent lives.$B$BTeldrassil itself blesses your vow of protection. Stand ready, guardian - the world has great need of your sacrifice.'),
(650147, 'The shadow embraces you while honor guides you, $N. You have chosen the most paradoxical of paths - to wield darkness in service of the light, to become a Knight of Xoroth.$B$BAs a Knight of Xoroth, you will learn to channel void energy and shadow magic while maintaining your moral principles. Your dark spells will confound enemies who expect holy magic from a paladin-like figure, while your righteous cause justifies methods others would consider forbidden.$B$BThis path walks the razor''s edge between salvation and damnation. You must never let the darkness consume your purpose, even as you draw power from the shadows. Your oath binds you to protect the innocent through whatever means necessary.$B$BThe void whispers promises of easy power, but your honor must be stronger than any temptation. Welcome to the Order, dark paladin.'),
(650148, 'Death recognizes you as its servant, $N, but not as its master. You have chosen to become a shepherd between worlds, guiding souls to their proper rest and commanding the power of undeath for righteous purposes.$B$BAs a Necromancer, you will learn to speak with the dead, raise skeletal servants, and manipulate the very essence of life and death. But remember always that this power exists to preserve the natural order, not to mock it.$B$BMany fear necromancy, seeing only the corruption it can bring. But true necromancers serve as guardians of the boundary between life and death, ensuring that the dead rest peacefully and that their knowledge aids the living when needed.$B$BThe spirits of the departed whisper their approval of your choice. Use this power wisely, and may you always remember that death is not an end, but a transition.'),
(650149, 'The raw elements surge through you now, $N! You have chosen to embrace the most primal forces of creation itself, becoming a conduit for earth, air, fire, and water in their purest forms.$B$BAs a Primalist, you will learn to command elemental magic with unprecedented power and fury. Your spells will call forth volcanic eruptions, devastating earthquakes, hurricane-force winds, and flash floods. The very building blocks of reality will answer your call.$B$BThis power comes from the world''s foundation itself, older and more dangerous than any magic devised by mortals. The elements care nothing for civilization''s concerns - they respond only to strength and respect. Show weakness, and they will consume you.$B$BThe primal forces have accepted you as their champion. May you prove worthy of wielding the fundamental powers of creation itself.'),
(650150, 'The wilderness recognizes one of its own, $N! I can see the forest''s blessing in your eyes, the call of the wild that marks true Rangers. You have chosen to become a guardian of nature itself.$B$BAs a Ranger, you will learn to move unseen through any terrain, to communicate with wild beasts as brothers, and to strike from the shadows with deadly precision. The forests will hide you, the animals will aid you, and your enemies will never see death approaching.$B$BTeldrassil''s sacred groves have much to teach you. You will learn to read the signs that others miss, to track prey across any surface, and to survive in the harshest wilderness. Your bow will sing death songs, and your blade will taste the blood of those who threaten the natural world.$B$BThe forest spirits welcome their new protector. May your arrows fly true and your path remain hidden from those who would do harm.'),
(650151, 'The eternal harvest calls to you, $N. You have chosen to serve the cycle of life and death itself, becoming a reaper of souls when their appointed time arrives.$B$BAs a Reaper, you will learn to sense when a being''s time has come, to guide souls gently to their rest, and to harvest the life force of those who refuse their natural fate. Your magic draws power from the boundary between life and death itself.$B$BThis is not the path of a murderer, but of a divine agent ensuring the natural order continues. You will learn to distinguish between a life that should be saved and one that must end, between mercy and necessary duty.$B$BThe cycle of existence itself has chosen you as its servant. May you always remember that your purpose is not to bring death, but to ensure that life''s journey reaches its proper conclusion.'),
(650152, 'The ancient runes pulse with recognition, $N! You have chosen to master the oldest form of magic known to civilization - the power of symbols carved into stone and steel with perfect precision.$B$BAs a Runemaster, you will learn to inscribe magical formulae that outlast the civilizations that created them. Your enchantments will be carved into the very fabric of reality, creating effects that endure long after other magic has faded.$B$BThis art requires absolute precision. A single misplaced line can turn a protection ward into a death trap, while perfect execution can create wonders that seem impossible. Your tools are hammer and chisel, but your true weapons are knowledge and patience.$B$BThe primordial powers that gave birth to runic magic acknowledge your worth. May your inscriptions be flawless and your enchantments eternal.'),
(650153, 'The stars themselves shine brighter in your presence, $N! You have chosen to study the celestial arts, drawing magical power from the distant lights that wheel overhead through the endless night.$B$BAs a Starcaller, you will learn to read the cosmic patterns written across the sky, to channel stellar energy into devastating spells, and to glimpse the future through astrological divination. The very heavens will become your source of power.$B$BElune''s blessing has prepared you well for this path, but you will learn to draw upon all the stars, not just our moon goddess. Each constellation offers different gifts, each celestial body provides unique energies for those who understand their nature.$B$BThe cosmic forces welcome their new student. May the starlight guide your spells and the celestial wisdom illuminate your path through the darkness.'),
(650154, 'Thunder rolls across the heavens in recognition, $N! You have chosen to become a master of the storm itself, wielding the fury of wind and lightning as your weapons.$B$BAs a Stormbringer, you will learn to summon tempests from clear skies, to call down lightning that splits mountains, and to ride the wind itself into battle. The very atmosphere will bend to your will, becoming a weapon of devastating power.$B$BThis magic is raw and untamed, like the storms themselves. You must learn to harness its fury without being consumed by it, to direct its power without losing yourself in its chaotic nature. The storm respects only strength and determination.$B$BThe tempest spirits have marked you as their champion. May your lightning never miss its target and your winds never fail to carry you to victory.'),
(650155, 'The Light embraces you with radiant warmth, $N! You have chosen to become a beacon of healing and hope, channeling the pure power of dawn itself to banish darkness from the world.$B$BAs a Sun Cleric, you will learn to heal wounds that others consider fatal, to purify corruption that has taken root in mortal souls, and to call down cleansing fire that burns only evil. Your presence alone will bring comfort to the suffering.$B$BThis path demands unwavering compassion and absolute dedication to the welfare of others. You will exhaust yourself healing strangers, risk your life protecting the innocent, and face the darkness that others flee from.$B$BThe dawn itself blesses your sacred calling. May your light never dim, and may you always bring hope to those lost in the darkest nights.'),
(650156, 'Divine justice flows through you like molten gold, $N! You have sworn the sacred oaths of the Templar, choosing to become a holy warrior in service to righteousness itself.$B$BAs a Templar, you will learn to channel divine power into crushing blows against evil, to heal your allies with blessed magic, and to stand as an unshakeable pillar of faith in the darkest times. Your sword will be guided by divine will, your shield empowered by righteous fury.$B$BThis calling demands absolute moral clarity and unwavering dedication to justice. You must be judge and executioner, healer and protector, all guided by divine wisdom that transcends mortal understanding.$B$BThe Light itself has chosen you as its champion. May your faith be your strength, your conviction your weapon, and your righteousness your eternal guide.'),
(650157, 'Brilliant innovation sparks in your mind, $N! You have chosen to walk the path that bridges magic and machinery, creating wonders that blend arcane power with mechanical precision.$B$BAs a Tinker, you will learn to construct devices that seem impossible to those who understand only traditional magic or mundane engineering. Your inventions will aid allies, confound enemies, and demonstrate that progress and preservation can work in harmony.$B$BTeldrassil may seem an unlikely place for mechanical arts, but nature itself is the greatest engineer of all. You will learn to create devices that work with natural forces rather than against them, proving that technology can enhance rather than replace the wisdom of the wild.$B$BThe gears of innovation turn in your favor. May your inventions be marvels of both function and beauty, serving progress without abandoning the natural world.'),
(650158, 'The balance of life and death, poison and antidote, flows through you now, $N. You have chosen to master the dual nature of toxins - their power to harm and their equal power to heal.$B$BAs a Venomancer, you will learn to brew deadly venoms that can fell the mightiest enemies, but also to create antidotes and cures that can save lives others consider beyond hope. Every poison has its counter, every toxin its remedy, if one understands the principles involved.$B$BThis knowledge carries great responsibility. The same compound that kills a corrupted beast might save a poisoned child. Your wisdom must guide when to unleash death and when to preserve life, for the power you wield cuts both ways.$B$BThe natural balance recognizes your understanding. May your venoms strike true against evil, and your cures bring healing to the innocent.'),
(650159, 'Righteous fire burns in your soul, $N! You have chosen to dedicate your life to the eternal hunt for corruption, becoming a Witch Hunter sworn to cleanse evil wherever it may lurk.$B$BAs a Witch Hunter, you will learn to identify supernatural threats that fool others, to wield blessed weapons specifically designed to destroy corrupted beings, and to resist the very temptations that doom your quarry. Your purpose is to stand guard against darkness that hides behind innocent faces.$B$BThis calling demands constant vigilance and absolute moral fortitude. You will face enemies who appear as friends, confront evil that wears the mask of virtue, and make choices that others will never understand. The burden of this knowledge will weigh heavily upon you.$B$BThe Light has blessed your sacred hunt. May your weapons never fail against corruption, your eyes never be deceived by evil''s disguises, and your resolve never waver in the face of darkness.'),
(200005, 'This seems to be the falcon in question, and it seems injured.'),
(200006, 'The falcon seems distraught. It must have been the suspicious creature who attacked it!'),
(200007, 'Thank you for finding Brim. She has already returned to me, healthy as ever.$B$BI''ve already sent him on yet another scouting mission.$B$B... you''re saying a strange creature was seen near Brim and that it attacked you? That must have been the creature that injured my boy.$B$BI''ll have to look into this more. Based on your description, whatever this is, it''s not native to Teldrassil.'),
(200018, 'A Blood Wizard?$B$BInteresting...$B$BWell, upon further inspection, this tome is worthless. You can have it.$B$BReturn to me in the future when you are stronger. Maybe we can work together again.'),
(200021, 'You may be wondering why I had you retrieve this skull.$B$BDemon skulls are often vessels of immense fel power. Today, I give this to you.$B$BHowever, if you prefer, I can infuse the power of this skull into a powerful sword.$B$BThe choice is yours, whatever it may be, it will serve you well.'),
(200025, 'I know you''re wondering why I had you do this.$B$BIn due time, you will learn.$B$BThere is nothing else to worry about now. I''ve made you a similar concoction, take it with you, and use it wisely.$B$BFarewell, $N.'),
(200031, 'Elune''s grace radiates from you, $N. The goddess is pleased.$B$BI have two weapons for you to choose from, blessed by Elune.$B$BGo forth as Elune''s Chosen. We will meet again.'),
(200036, 'Good, good. The Satyr is dead.$B$BHe deserved death, and there will be many more who do as well.$B$BAs a token of your bloody success, I present to you a powerful piece of equipment, forged in hellfire. Dioniss aca, or something. Aha!'),
(200038, 'You may not have expected such a task, $N. But it is important to understand that the Shadowlands call for those who are ready, and knowing when to claim a soul can be just as important as the reclamation of the soul itself.$B$BFor helping our friend out here, I will reward you with these boots. May they serve you well, as they are enchanted to allow you to walk on the surface of water itself.'),
(200046, '<The ritual circle pulsates with necromantic energy>'),
(200047, '<The ritual circle begins to erupt. The monster is being summoned>'),
(200048, 'Well, that''s exactly what I thought would happen.$B$BBut, hey, you didn''t die. You''re a better Necromancer already!$B$BHere, I sent my other apprentices to gather the scraps from your battle, they made this.$B$BTake it and get out of my sight.'),
(200056, 'Yet another evil creature banished from our world.$B$B... and yet.$B$BStill so many others to destroy. Be vigilant.$B$BHere, take these, let them guide you in your battles with evil.'),
(200061, '<The pendant glimmers. It gives off a strong holy presence>$B$BYou have done well, $N. This pendant, I will give to you.$B$BKeep it close, for someday, you may need it again and I may teach you how to unlock far more of its powers.'),
(200067, 'Well, this is perfect!$B$BI was able to use this metal to finish a new gun for me and, guess what, I made you one too!$B$BTake it and have a great day!'),
(200073, ''),
(200079, ''),
(200092, ''),
(200093, ''),
(200094, ''),
(200106, ''),
(200111, ''),
(200131, ''),
(200132, ''),
(200133, ''),
(200161, 'Aha! You have shown me that you are truly powerful. For this, I reward you with a symbol of the Bear itself. May it guide you on your journeys and give you strength over your foes.'),
(200167, 'Welcome back, $N. I knew you would find my wand in time. Literally.$B$BThis wand is for you. I hope it serves you well. In fact, I know it will.');

DELETE FROM `quest_request_items` WHERE `ID` IN (200005, 200006, 200007, 200018, 200021, 200025, 200031, 200036, 200038, 200046, 200047, 200048, 200056, 200061, 200067, 200073, 200079, 200092, 200093, 200094, 200106, 200111, 200131, 200132, 200133, 200161, 200167, 650141, 650142, 650143, 650144, 650145, 650146, 650147, 650148, 650149, 650150, 650151, 650152, 650153, 650154, 650155, 650156, 650157, 650158, 650159);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(650141, 'I sense the primal fury awakening within you, $N. So you wish to learn the barbarian''s path of rage and wilderness combat?'),
(650142, 'The crimson arts have called to you, $N. So you wish to master blood magic, to wield life itself as your weapon?'),
(650143, 'Time itself bends around you, $N. So you wish to study chronamancy, to manipulate the very streams of temporal reality?'),
(650144, 'The whispers grow stronger in your presence, $N. So you wish to serve the Old Ones and learn the cultist''s forbidden arts?'),
(650145, 'Fel energy radiates from your soul, $N. So you wish to become Felsworn, to command demonic power?'),
(650146, 'Your protective aura shines brightly, $N. So you wish to become a Guardian, to shield others from all harm?'),
(650147, 'Shadow and honor both call to you, $N. So you wish to join the Knights of Xoroth, to wield darkness in service of light?'),
(650148, 'The spirits of the dead whisper around you, $N. So you wish to become a Necromancer, to shepherd souls between worlds?'),
(650149, 'The elements respond to your presence, $N. So you wish to become a Primalist, to command the raw forces of nature?'),
(650150, 'The wilderness calls to your heart, $N. So you wish to become a Ranger, to protect Teldrassil''s sacred groves?'),
(650151, 'Life and death flow through you equally, $N. So you wish to become a Reaper, to harvest souls when their time comes?'),
(650152, 'Ancient power stirs in your presence, $N. So you wish to become a Runemaster, to carve magic into stone and steel?'),
(650153, 'The stars shine brighter when you are near, $N. So you wish to become a Starcaller, to channel celestial magic?'),
(650154, 'Thunder rumbles at your approach, $N. So you wish to become a Stormbringer, to command wind and lightning?'),
(650155, 'Holy light radiates from your being, $N. So you wish to become a Sun Cleric, to heal with the power of dawn?'),
(650156, 'Divine justice burns within you, $N. So you wish to become a Templar, to serve as a holy warrior?'),
(650157, 'Innovation sparks in your mind, $N. So you wish to become a Tinker, to blend magic and machinery?'),
(650158, 'The balance of toxin and antidote calls to you, $N. So you wish to become a Venomancer, to master poison and cure?'),
(650159, 'Righteous fury burns against corruption in you, $N. So you wish to become a Witch Hunter, to cleanse evil from the world?'),
(200005, ''),
(200006, ''),
(200007, 'Absolutely wonderful. Brim has returned!'),
(200018, 'Impressive. Who did you say had this tome again?'),
(200021, 'You have done well, $N.'),
(200025, 'Welcome back. Have you done what I asked?'),
(200031, ''),
(200036, ''),
(200038, ''),
(200046, ''),
(200047, '<You place the ingredients on the ritual circle>'),
(200048, ''),
(200056, 'You have returned.'),
(200061, 'Yay, you''ve done it!!'),
(200067, 'Have you found the scrap yet?'),
(200073, ''),
(200079, ''),
(200092, ''),
(200093, ''),
(200094, ''),
(200106, ''),
(200111, ''),
(200131, ''),
(200132, ''),
(200133, ''),
(200161, 'Have you completed the task, $N?'),
(200167, 'Ahh, you''ve returned.');

DELETE FROM `page_text` WHERE `ID` IN (7001, 7002, 7003, 7004, 7005, 7006, 7007, 7008, 7009, 7010, 7011, 7012, 7013, 7014, 7015, 7016, 7017, 7018, 7019);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(7001, 'Strength needs no permission. The barbarian''s path is the oldest path of all: meet every challenge head on, and leave nothing standing that stands against you.$B$BYou will learn to turn pain into fury and fury into victory, to shrug off wounds that would fell lesser warriors and to break whatever blocks your way.$B$BAmanda, a warrior whose axe is known far beyond these woods, trains those bold enough to join her Warband. Seek her out inside Aldrassil.', 0),
(7002, 'Blood is life, and life is power. The Bloodmage learns what others fear to understand: the essence that flows through every living thing can be shaped like any other magic.$B$BYou will learn to draw on your own life to fuel your spells, to mend and to wound with the same crimson craft, and to master a hunger that consumes the careless.$B$BAramadus studies these forbidden arts in the halls of Aldrassil. Find him if you have the stomach for it.', 0),
(7003, 'Time is a river, and most are content to drift with its current. The Chronomancer learns to swim against it: to slow a heartbeat, hasten a step, or glimpse a moment before it comes.$B$BYou will learn to bend the flow of time to your will and, above all, to respect it, for those who meddle carelessly are swept away.$B$BKaleidormu, a keeper of the timeways who wears a mortal guise, awaits you in Aldrassil. He says he has been expecting you for quite some time.', 0),
(7004, 'Not all whispers in the darkness speak of evil. Some herald ancient truths that mortals fear to acknowledge. The Cultist''s path is one of forbidden knowledge.$B$BYou will commune with entities beyond mortal understanding, gaining power through dangerous pacts and eldritch wisdom. Walk carefully, for knowledge comes with a price.$B$BSaelina Shedana dwells where the shadows grow deepest in Teldrassil. She will introduce you to the whispers that call from beyond the veil.', 0),
(7005, 'The Legion''s defeat does not mean their power is lost forever. Some have learned to bind demonic essence to their will, becoming Felsworn warriors of terrible might.$B$BYou will command fel energies and summon demonic allies, but beware - such power demands constant vigilance lest it consume you entirely.$B$BFlowzie the Fel-Touched, a felsworn who chose redemption, now teaches others to master fel power without losing their souls. Seek her out in Teldrassil''s darker groves.', 0),
(7006, 'A shield means nothing without the will to hold it. The Guardian stands between the innocent and whatever would harm them, and does not yield.$B$BYou will learn to turn aside blows meant for others, to hold your ground against any foe and to strike back with the strength of your conviction.$B$BNerdris Darkstrike has sworn herself to the protection of Shadowglen. Seek her at the foot of Aldrassil.', 0),
(7007, 'Honor and shadow need not be opposites. The Knights of Xoroth embrace darkness in service of a greater good, wielding void magic for righteous purposes.$B$BYou will learn to channel shadow energy while maintaining your moral compass, becoming a dark paladin who protects the innocent through unconventional means.$B$BAheravara walks the difficult path between light and shadow in Teldrassil. Seek her guidance if you would join this unique order of dark knights.', 0),
(7008, 'Death is not an ending but a threshold, and those who understand it can call across. The Necromancer commands what lies beyond, binding restless spirits and fallen flesh to a purpose.$B$BYou will learn to raise the dead, to drain the life of your foes and to stand unafraid where others flee.$B$BBaarelam of the Auchenai has travelled far to share the secrets of his order. You will find him keeping vigil in the graveyard beneath Aldrassil.', 0),
(7009, 'The raw elements respond to those who understand the fundamental forces that shape reality. The Primalist commands earth, air, fire, and water in their purest forms.$B$BYou will become one with the primal energies that course through Azeroth itself, wielding elemental magic with unprecedented power and fury.$B$BPrim''ula has made her home where Teldrassil''s elemental energies converge. Seek her out to begin your journey into primordial power.', 0),
(7010, 'The wilds of Azeroth need protectors who understand both nature''s beauty and its fierce protective instincts. The Ranger serves as guardian of the natural world.$B$BYou will master woodland skills, commune with wild beasts, and become one with the forests, plains, and mountains you protect.$B$BHydriel Featherflight has long watched over Teldrassil''s sacred groves. Find this experienced ranger to learn the ways of nature''s guardian.', 0),
(7011, 'Every soul reaches its harvest in time. The Reaper walks the thin line between life and death, cutting down the living and guiding what remains to the other side.$B$BYou will learn to wield the scythe and the shadow alike, and to take strength from every life you end.$B$BCanni the Shade waits within Aldrassil, as quiet as the grave. Seek him out if you are ready to walk between worlds.', 0),
(7012, 'The ancient runes hold power that transcends mortal magic. carved into stone and metal, these symbols channel forces older than civilization itself.$B$BAs a Runemaster, you will inscribe power into the very world around you, creating lasting enchantments that endure long after other magic fades.$B$BRaethere Daltrall has brought runic wisdom to Teldrassil. Though the night elves have their own magical traditions, she studies the runic arts from many cultures. Seek her guidance in Shadowglen.', 0),
(7013, 'The stars themselves sing with power for those who know how to listen. The Starcaller draws magic from the celestial bodies that wheel overhead.$B$BYou will learn to read the cosmic patterns and channel stellar energy, bringing the power of distant suns to bear in battle.$B$BHuntress Naalia has always been blessed by Elune''s light, but now she studies the magic of other stars as well. Find her among Teldrassil''s highest branches where she observes the night sky.', 0),
(7014, 'Thunder and lightning answer the call of those who understand the fury of the storm. The Stormbringer commands weather itself as a weapon.$B$BYou will summon tempests, call down lightning, and ride the winds themselves into battle. The very sky becomes your ally.$B$BQ''ru, master of storm magic, has brought her knowledge to Teldrassil. This powerful shaman will teach you to speak with the spirits of wind and storm.', 0),
(7015, 'The sun rises on friend and foe alike, and its light answers those who carry it faithfully. The Sun Cleric channels that radiance to heal the wounded and scorch the wicked.$B$BYou will learn to call down the warmth of the sun, to shield your allies in its glow and to burn away the darkness that threatens them.$B$BExodite Telusaara journeyed from the Exodar to bring the light to Teldrassil. Seek her on the upper terrace of Aldrassil.', 0),
(7016, 'The Light demands discipline before it grants strength. The Templar trains body and mind as one, meeting every foe with a calm heart and a steady blade.$B$BYou will learn to channel holy power through every strike, to endure what would break others and to keep your spirit clear in the heat of battle.$B$BElleora has come to Teldrassil to train those who would join the order. Seek her on the upper terrace of Aldrassil.', 0),
(7017, 'Where others see scrap, a Tinker sees possibility. Gears, springs, black powder and a little ingenuity can match any spell ever cast.$B$BYou will learn to build your own weapons and gadgets, to repair what breaks and to blow up what needs blowing up.$B$BJoro Rapidspyre has set up his workbench in Aldrassil, much to the druids'' dismay. Look for him near the merchants at the north end of the ground floor.', 0),
(7018, 'Nature arms its creatures with venom, and those who study it learn that the smallest drop can fell the mightiest beast. The Venomancer masters toxins, remedies and the fine line between them.$B$BYou will learn to craft poisons and antidotes, to weaken your foes from within and to strike with the patience of the serpent.$B$BKo''rahl Fangshifter tends his cauldron just south of Aldrassil. Seek him there, and touch nothing he has not offered you.', 0),
(7019, 'Corruption hides in many forms, and the Witch Hunter dedicates their life to rooting out evil wherever it may lurk. Your weapons are blessed to strike down the unholy.$B$BYou will learn to identify supernatural threats and wield specialized weapons and magic designed to destroy corrupted beings.$B$BDarkslayer Harrendor has brought his expertise to Teldrassil, watching for signs of corruption even in this sacred place. Find him to join the eternal hunt against darkness.', 0);

-- ---------------------------------------------------------------------------
-- 5. Who offers and who takes them back
-- ---------------------------------------------------------------------------
DELETE FROM `creature_queststarter` WHERE `quest` IN (200005, 200006, 200007, 200018, 200021, 200025, 200031, 200036, 200038, 200046, 200047, 200048, 200056, 200061, 200067, 200073, 200079, 200092, 200093, 200094, 200106, 200111, 200131, 200132, 200133, 200161, 200167, 650141, 650142, 650143, 650144, 650145, 650146, 650147, 650148, 650149, 650150, 650151, 650152, 650153, 650154, 650155, 650156, 650157, 650158, 650159);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(50341, 200005),
(9300352, 200006),
(9300352, 200007),
(502920, 200018),
(50344, 200021),
(50343, 200025),
(50326, 200031),
(502780, 200036),
(502890, 200038),
(50294, 200046),
(503250, 200056),
(9300350, 200061),
(502871, 200067),
(502831, 200073),
(502801, 200079),
(502772, 200092),
(502871, 200093),
(502871, 200094),
(50295, 200106),
(502911, 200111),
(503240, 200131),
(2082, 200132),
(2082, 200133),
(503420, 200161),
(502821, 200167),
(2079, 650141),
(2079, 650142),
(2079, 650143),
(2079, 650144),
(2079, 650145),
(2079, 650146),
(2079, 650147),
(2079, 650148),
(2079, 650149),
(2079, 650150),
(2079, 650151),
(2079, 650152),
(2079, 650153),
(2079, 650154),
(2079, 650155),
(2079, 650156),
(2079, 650157),
(2079, 650158),
(2079, 650159);

DELETE FROM `creature_questender` WHERE `quest` IN (200005, 200006, 200007, 200018, 200021, 200025, 200031, 200036, 200038, 200046, 200047, 200048, 200056, 200061, 200067, 200073, 200079, 200092, 200093, 200094, 200106, 200111, 200131, 200132, 200133, 200161, 200167, 650141, 650142, 650143, 650144, 650145, 650146, 650147, 650148, 650149, 650150, 650151, 650152, 650153, 650154, 650155, 650156, 650157, 650158, 650159);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(9300352, 200005),
(9300352, 200006),
(50341, 200007),
(502920, 200018),
(50344, 200021),
(50343, 200025),
(50326, 200031),
(502780, 200036),
(502890, 200038),
(50294, 200048),
(503250, 200056),
(9300350, 200061),
(502871, 200067),
(502831, 200073),
(502801, 200079),
(502871, 200092),
(502871, 200093),
(502772, 200094),
(50295, 200106),
(502911, 200111),
(2082, 200131),
(2082, 200132),
(503240, 200133),
(503420, 200161),
(502821, 200167),
(50295, 650141),
(502920, 650142),
(502821, 650143),
(502831, 650144),
(50344, 650145),
(503240, 650146),
(502780, 650147),
(50294, 650148),
(503420, 650149),
(50341, 650150),
(502890, 650151),
(502911, 650152),
(50326, 650153),
(502772, 650154),
(9300350, 650155),
(502801, 650156),
(502871, 650157),
(50343, 650158),
(503250, 650159);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (200047, 200048);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(9301356, 200047),
(9301356, 200048);

DELETE FROM `gameobject_questender` WHERE `quest` IN (200046, 200047);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(9301356, 200046),
(9301356, 200047);

-- Map markers where the text promises them: "Let me mark your map to the location of where my ritual must
-- be had" (200046, the ritual circle) and "I've marked her location on your map" (200056, the disguised
-- witch).
DELETE FROM `quest_poi` WHERE `QuestID` IN (200046, 200056);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200046, 0, 0, 1, 41, 0, 0, 1),
(200056, 0, 0, 1, 41, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200046, 200056);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200046, 0, 0, 10395, 991),
(200056, 0, 0, 10376, 858);

-- ---------------------------------------------------------------------------
-- 6. Loot
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((1988, 662330), (1988, 661417), (1989, 662330), (1989, 458421), (1989, 458422), (1989, 458423), (9300351, 661316));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(1988, 662330, 0, 100, 1, 1, 0, 1, 1, 'Grell - Small Sword (Prioritizing Defense, Exiles 100%)'),
(1988, 661417, 0, 33, 1, 1, 0, 1, 1, 'Grell - Power Core (The Stolen Power Core, Exiles 33%)'),
(1989, 662330, 0, 33, 1, 1, 0, 1, 1, 'Grellkin - Small Sword (Prioritizing Defense, Exiles 33%)'),
(1989, 458421, 0, 45, 1, 1, 0, 1, 1, 'Grellkin - Bones (Death Calls, Exiles 45%)'),
(1989, 458422, 0, 55, 1, 1, 0, 1, 1, 'Grellkin - Fresh Flesh (Death Calls, Exiles 55%)'),
(1989, 458423, 0, 45, 1, 1, 0, 1, 1, 'Grellkin - Skull (Death Calls, Exiles 45%)'),
(9300351, 661316, 0, 100, 1, 1, 0, 1, 1, 'Suspicious Night Elf - Tome of Blood (Blood Is Power, inferred carrier)');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((1988, 2), (1988, 3), (1989, 2), (1989, 3), (1989, 4), (1989, 5), (9300351, 0));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(1988, 2, 662330),
(1988, 3, 661417),
(1989, 2, 662330),
(1989, 3, 458421),
(1989, 4, 458422),
(1989, 5, 458423),
(9300351, 0, 661316);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9301350, 9301351, 9301352, 9301353, 9301354);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9301350, 661335, 0, 100, 1, 1, 0, 1, 1, 'CoA Shadowglen: quest item from Training Wand'),
(9301351, 661330, 0, 100, 1, 1, 0, 1, 1, 'CoA Shadowglen: quest item from Eye of the Beholder'),
(9301352, 661319, 0, 100, 1, 1, 0, 1, 1, 'CoA Shadowglen: quest item from Skull of L''ok'),
(9301353, 663319, 0, 100, 1, 1, 0, 1, 1, 'CoA Shadowglen: quest item from Lost Pendant'),
(9301354, 663320, 0, 100, 1, 1, 0, 1, 1, 'CoA Shadowglen: quest item from Scrap Metal');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (9301350, 9301351, 9301352, 9301353, 9301354);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(9301350, 0, 661335),
(9301351, 0, 661330),
(9301352, 0, 661319),
(9301353, 0, 663319),
(9301354, 0, 663320);

-- ---------------------------------------------------------------------------
-- 7. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9004100, 9004101, 9004102, 9004103, 9004104, 9004105, 9004106, 9004107, 9004108, 9004109, 9004110, 9004111, 9004112, 9004113, 9004114, 9004115, 9004116, 9004117, 9004118, 9004130, 9004131, 9004132, 9004133, 9004134, 9004135, 9004136, 9004137, 9004138, 9004139) OR `guid` BETWEEN 9004100 AND 9004299;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9004100, 50295, 1, 0, 0, 1, 1, 1, 10411.9, 783.47, 1322.709, 4.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Barbarian trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650141, z from surface.floor; Aldrassil base hall (floor 1322.7), entered through the south-east opening, by the west wall; faces 4.10 toward the south-east opening of the hall, the way players come in'),
(9004101, 50344, 1, 0, 0, 1, 1, 1, 10345.4, 757.2, 1326.452, 0.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Felsworn trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650145, z from surface.floor; foot of Aldrassil where the paths meet, the great tree''s roots at her back; faces 0.90 north over the open lawn, the way round the roots from the start (the start itself lies behind a root 2.4 yd away)'),
(9004102, 503250, 1, 0, 0, 1, 1, 1, 10434.3, 795.62, 1322.705, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Witch Hunter trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650159, z from surface.floor; Aldrassil base hall (floor 1322.7), entered through the south-east opening, west wall, 2.5 yd from Keina the bowyer (both CoA placements); faces 3.80 down the hall toward the south-east opening'),
(9004103, 502772, 1, 0, 0, 1, 1, 1, 10432.8, 769.56, 1322.669, 2.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Stormbringer trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650154, z from surface.floor; Aldrassil base hall (floor 1322.7), entered through the south-east opening, east side under the ramp; faces 2.80 across the hall toward the opening and the walkway'),
(9004104, 502780, 1, 0, 0, 1, 1, 1, 10347.1, 761.64, 1325.494, 0.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Knight of Xoroth trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650147, z from surface.floor; foot of Aldrassil where the paths meet, beside Flowzie; faces 0.80 north over the open lawn (a root 1.3 yd to her south-west)'),
(9004105, 503240, 1, 0, 0, 1, 1, 1, 10410.2, 876.07, 1320.036, 4.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Guardian trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650146, z from surface.floor; the meadow at the west foot of Aldrassil, 9 yd from Gilshalan Windwalker, her chain''s helper; faces 4.30 toward the graveyard basin and the fountain, the way players come from the start'),
(9004106, 502801, 1, 0, 0, 1, 1, 1, 10464.1, 799.49, 1346.753, 3.23, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Templar trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650156, z from surface.floor; Aldrassil upper terrace (1346.75) by the benches; faces 3.23 toward the ramp that arrives from the 1337 level'),
(9004107, 502920, 1, 0, 0, 1, 1, 1, 10485.4, 816.9, 1322.744, 3.88, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Bloodmage trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650142, z from surface.floor; north room of the base hall among the merchants; faces 3.88 toward the room''s opening to the hall'),
(9004108, 50341, 1, 0, 0, 1, 1, 1, 10425.4, 835.6, 1318.796, 3.19, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Ranger trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650150, z from surface.floor; the meadow at the west foot of Aldrassil; faces 3.19 toward the start, the way players come with the letter'),
(9004109, 502821, 1, 0, 0, 1, 1, 1, 10444.6, 783.79, 1337.285, 3.42, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Chronomancer trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650143, z from surface.floor; 1337 level at the table between the two benches; Lyrai 3587 moves 2.5 yd west to stand 2.8 yd beside him (section 7); faces 3.42 like Lyrai beside him, toward the walkway from the base hall ramp'),
(9004110, 50294, 1, 0, 0, 1, 1, 1, 10386.7, 811.88, 1317.531, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Necromancer trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650148, z from surface.floor; the graveyard basin by the rune stones and the grave mound ("Glad you could join me in the graveyard"); faces 2.90 toward the start, the way players come with the letter'),
(9004111, 502831, 1, 0, 0, 1, 1, 1, 10518.1, 778.34, 1329.599, 1.54, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Cultist trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650144, z from surface.floor; the 1329.6 room above the base hall, on Frahun Shadewhisper''s stock post (Frahun''s spawn is deleted, see section 7); faces 1.54, the stock facing of the post, toward the ramp that arrives from the base hall'),
(9004112, 50326, 1, 0, 0, 1, 1, 1, 10527.9, 777.12, 1329.599, 2.48, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Starcaller trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650153, z from surface.floor; the 1329.6 room, on Alyissia''s stock post (her spawn is deleted, see section 7); faces 2.48, the stock facing of the post, toward the room''s entrance'),
(9004113, 9300350, 1, 0, 0, 1, 1, 1, 10458.2, 807.65, 1346.754, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Sun Cleric trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650155, z from surface.floor; Aldrassil upper terrace (1346.75) by the benches; faces 3.80 toward the ramp that arrives from the 1337 level'),
(9004114, 502871, 1, 0, 0, 1, 1, 1, 10481.5, 805.79, 1322.744, 3.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Tinker trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650157, z from surface.floor; north end of the base hall beside the ramp to the 1329.6 room; faces 3.10 down the hall, the way players arrive'),
(9004115, 50343, 1, 0, 0, 1, 1, 1, 10405.4, 717.75, 1321.645, 2.25, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Venomancer trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650158, z from surface.floor; south of Aldrassil beside the cauldron; faces 2.25 toward the start with the cauldron at his left side, not facing it'),
(9004116, 502890, 1, 0, 0, 1, 1, 1, 10439.6, 774.65, 1322.669, 2.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Reaper trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650151, z from surface.floor; Aldrassil base hall (floor 1322.7), entered through the south-east opening, east side; faces 2.20 toward the hall walkway (a pillar blocks the opening 4 yd to his south)'),
(9004117, 503420, 1, 0, 0, 1, 1, 1, 10476.7, 815.7, 1322.744, 3.97, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Primalist trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650149, z from surface.floor; north room of the base hall; faces 3.97 toward the room''s opening to the hall'),
(9004118, 502911, 1, 0, 0, 1, 1, 1, 10460.7, 829.84, 1380.939, 3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen Runemaster trainer: Shadowglen: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 650152, z from surface.floor; the 1381 platform between the kept stock NPCs Ayanna Everstride (3.0 yd) and Mardant Strongoak (3.3 yd); faces 3.00 toward the outer ramp arrival, as Mardant 2.90 beside her'),
(9004130, 299237, 1, 0, 0, 1, 1, 1, 10527, 781, 1329.599, 2.48, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: Aldrassil 1329.6 room, 2.9 yd from Alyissia''s stock post (the text: "inside Aldrassil ... somewhere outside"); her post itself is 1.6 yd from Huntress Naalia, so she stands 4.0 yd from Naalia and 9.3 yd from Saelina with the post''s facing'),
(9004131, 299227, 1, 0, 0, 1, 1, 0, 10603, 866, 1310.029, 3.3, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: north shore of Shadowglen''s pond among the lilies, fouling the water the residents use; faces the pond; 112 yd from the nearest sentinel so the guards leave him to the player'),
(9004132, 299327, 1, 0, 0, 1, 1, 1, 10533, 656, 1330.761, 2.18, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: crown of the open rise east of Aldrassil, where she rants toward the tree at anyone passing; 145 yd from the nearest sentinel'),
(9004133, 9300351, 1, 0, 0, 1, 1, 1, 10340.5, 1028, 1338.362, 5.03, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: grell camp 2 (Grellkin campfire 10335.3, 1034.1), beside the animal cages, watching the path to Aldrassil'),
(9004134, 9300351, 1, 0, 0, 1, 1, 1, 10510.5, 1057, 1324.608, 4.38, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: grell camp 3 (Grellkin campfire 10498.3, 1054.0), north-east of the fire, watching the path to Aldrassil; a second holder so two players need not wait on one respawn'),
(9004135, 9300352, 1, 0, 0, 1, 1, 0, 10688, 728, 1325.132, 2.75, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: east woods glade 22 yd west of the lone Kalidartree07 (10687-10708, 684-706), below the Shadowglen moonwell rise, where the scouting falcon came down (tel-integrate: moved off the Carrion Path treant ground, 60 yd from every treant, area 188); faces 2.75 toward Aldrassil, the way Hydriel''s student comes'),
(9004136, 9300353, 1, 0, 0, 1, 1, 0, 10504, 801, 1397.267, 4.62, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: the crown of Aldrassil (1397.3), away from the three sentinels (5.5-9 yd) and the benches, facing 4.62 toward the outer ramp arrival'),
(9004137, 9300354, 1, 0, 0, 1, 1, 0, 10376, 858, 1324.5, 4.96, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: the open lawn west of the graveyard, south-east of the great tree''s hollow trunk, gathering among the grass; faces 4.96 toward the Aldrassil hall entry, the way Harrendor''s students come; 55 yd from the nearest sentinel and 5.7 yd above it, so her true self is the player''s fight'),
(9004138, 685032, 1, 0, 0, 1, 1, 0, 10710.5, 762.9, 1321.279, 0, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: in the Shadowglen moonwell pool (Nightelfmoonwellornate.wmo, pool floor 1321.2), 1.1 yd from the stock Moonwell objects 49687 and 49719 at its centre; its 5 yd sight radius plus both combat reaches (7.5 yd) covers all of the water'),
(9004139, 685037, 1, 0, 0, 1, 1, 0, 10659, 815.5, 1328.85, 3.24, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadowglen: at the foot of the statue of Uther on the knoll west of the moonwell, where the Templar meditates');

DELETE FROM `gameobject` WHERE `guid` IN (7912600, 7912601, 7912602, 7912603, 7912604, 7912605, 7912606, 7912607, 7912608, 7912609, 7912610, 7912611, 7912612, 7912613, 7912614, 7912615, 7912616, 7912617, 7912618, 7912619, 7912620, 7912621) OR `guid` BETWEEN 7912600 AND 7912699;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912600, 9301356, 1, 0, 0, 1, 1, 10395, 991, 1327.487, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Shadowglen: flat hollow at the foot of the great tree''s arching roots, 175 yd north-west of Baarelam''s graveyard ("Let me mark your map to the location of where my ritual must be had"), between grell camps 2 and 3 whose Grellkin carry the bones, flesh and skull'),
(7912601, 9301355, 1, 0, 0, 1, 1, 10659, 814, 1328.971, 3.24, 0, 0, 0.99879, -0.049184, 300, 100, 1, '', 'CoA Shadowglen: top of the knoll west of the moonwell (terrain 1328.8, prominence 6-9 yd over the meadow), "a hill where a statue of a powerful Paladin was erected"; faces 3.24 toward Aldrassil'),
(7912602, 9301350, 1, 0, 0, 1, 1, 10450.5, 790, 1345.646, 1.2, 0, 0, 0.564642, 0.825336, 60, 100, 1, '', 'CoA Shadowglen: Aldrassil 1345.7 landing beside the bench at the top of Kaleidormu''s ramp, where he left it'),
(7912603, 9301350, 1, 0, 0, 1, 1, 10424, 788.5, 1322.705, 4.4, 0, 0, 0.808496, -0.588501, 60, 100, 1, '', 'CoA Shadowglen: Aldrassil base hall by the stone benches of the west wall; a second copy so two students can search at once'),
(7912604, 9301351, 1, 0, 0, 1, 1, 10506, 792, 1397.215, 0.7, 0, 0, 0.342898, 0.939373, 60, 100, 1, '', 'CoA Shadowglen: the crown of Aldrassil (1397.2) at the top of the outer ramp: the riddle''s answer "lays within Aldrassil"'),
(7912605, 9301351, 1, 0, 0, 1, 1, 10516.5, 823.5, 1354.791, 2.1, 0, 0, 0.867423, 0.497571, 60, 100, 1, '', 'CoA Shadowglen: the 1354.8 landing of the outer ramp inside the tree; a second copy'),
(7912606, 9301352, 1, 0, 0, 1, 1, 10362, 749.5, 1321.836, 5.6, 0, 0, 0.334988, -0.942222, 60, 100, 1, '', 'CoA Shadowglen: against the fallen log (Kalidartreelog02) 17 yd north-east of Flowzie''s post: "placed in the surrounding area"'),
(7912607, 9301352, 1, 0, 0, 1, 1, 10371, 737, 1323.46, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA Shadowglen: at the foot of the junction signpost south-east of Flowzie; a second copy'),
(7912608, 9301353, 1, 0, 0, 1, 1, 10292, 938, 1334.508, 2, 0, 0, 0.841471, 0.540302, 60, 100, 1, '', 'CoA Shadowglen: on the path out of the Grell camp (camp 1) toward Aldrassil, where Telusaara dropped it fleeing'),
(7912609, 9301353, 1, 0, 0, 1, 1, 10486, 1030, 1327.336, 5.1, 0, 0, 0.557684, -0.830054, 60, 100, 1, '', 'CoA Shadowglen: south-east edge of grell camp 3 on the way back to Aldrassil; a second copy'),
(7912610, 9301354, 1, 0, 0, 1, 1, 10276, 965, 1340.047, 0.6, 0, 0, 0.29552, 0.955336, 90, 100, 1, '', 'CoA Shadowglen: grell camp 1, north-east of the campfire where the edge is least steep (13 degrees; the rim falls at 15-16)'),
(7912611, 9301354, 1, 0, 0, 1, 1, 10271, 951, 1340.79, 2.2, 0, 0, 0.891207, 0.453596, 90, 100, 1, '', 'CoA Shadowglen: grell camp 1, east edge below the drums'),
(7912612, 9301354, 1, 0, 0, 1, 1, 10264, 953, 1341.757, 4, 0, 0, 0.909297, -0.416147, 90, 100, 1, '', 'CoA Shadowglen: grell camp 1, south-east edge on a level step above the slope'),
(7912613, 9301354, 1, 0, 0, 1, 1, 10279, 974, 1340.48, 5.5, 0, 0, 0.381661, -0.924302, 90, 100, 1, '', 'CoA Shadowglen: grell camp 1, north edge under the tree'),
(7912614, 9301354, 1, 0, 0, 1, 1, 10347, 1030, 1338.386, 1.1, 0, 0, 0.522687, 0.852525, 90, 100, 1, '', 'CoA Shadowglen: grell camp 2, north-east of the fire'),
(7912615, 9301354, 1, 0, 0, 1, 1, 10326, 1026, 1338.474, 3.3, 0, 0, 0.996865, -0.079121, 90, 100, 1, '', 'CoA Shadowglen: grell camp 2, south-east edge by the big tree'),
(7912616, 9301354, 1, 0, 0, 1, 1, 10354, 1037, 1341.16, 0.2, 0, 0, 0.099833, 0.995004, 90, 100, 1, '', 'CoA Shadowglen: grell camp 2, north edge by the totem'),
(7912617, 9301354, 1, 0, 0, 1, 1, 10321, 1038, 1339.318, 4.6, 0, 0, 0.745705, -0.666276, 90, 100, 1, '', 'CoA Shadowglen: grell camp 2, south side beside the tent'),
(7912618, 9301354, 1, 0, 0, 1, 1, 10512, 1047, 1323.584, 1.8, 0, 0, 0.783327, 0.62161, 90, 100, 1, '', 'CoA Shadowglen: grell camp 3, north-east of the fire'),
(7912619, 9301354, 1, 0, 0, 1, 1, 10501, 1044, 1325.23, 3.9, 0, 0, 0.92896, -0.370181, 90, 100, 1, '', 'CoA Shadowglen: grell camp 3, east edge'),
(7912620, 9301354, 1, 0, 0, 1, 1, 10489, 1041, 1327.119, 5.9, 0, 0, 0.190423, -0.981702, 90, 100, 1, '', 'CoA Shadowglen: grell camp 3, south-east edge by the big tree'),
(7912621, 9301354, 1, 0, 0, 1, 1, 10514, 1058, 1323.933, 2.7, 0, 0, 0.975723, 0.219007, 90, 100, 1, '', 'CoA Shadowglen: grell camp 3, north edge on the level ground beside the totem');

-- Lyrai (46171): Kaleidormu's sourced point (650143) is 1.7 yd behind her stock spot between two garden benches,
-- where no spot within 2 yd of the point is clear of her and the benches except directly behind her; she moves
-- 2.5 yd west, keeps her stock facing and stands 2.8 yd beside him, both facing the walkway. The UPDATE matches
-- guid and entry.
UPDATE `creature` SET `position_x` = 10443.7, `position_y` = 786.4, `position_z` = 1337.285, `orientation` = 3.42085 WHERE `guid` = 46171 AND `id` = 3587;

-- ---------------------------------------------------------------------------
-- 8. Scripts
-- ---------------------------------------------------------------------------
-- Credits: the concoction on three trainers, the Red Vial on Brim, the torch on the disguised witch,
-- Thalador's gossip, the moonwell and the statue by line of sight, the ritual circle on use. Summons: the
-- Suspicious Creature on accepting A Surprise Attack!, the Undead Monstrosity on accepting Call of the
-- Dead, each again on gossip/use while its quest is taken and none is alive nearby.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-9004139, 50294, 503250, 685032, 9300350, 9300352, 9300353, 9300354) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-9004139, 0, 0, 0, 10, 0, 100, 0, 1, 8, 1000, 1000, 1, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '[KC] Visit at the statue of Uther - On a player near - Quest Credit Visit the statue of Uther'),
(50294, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685017, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '50294 - On Spellhit Mysterious Concoction - Quest Credit 685017'),
(503250, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685016, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '503250 - On Spellhit Mysterious Concoction - Quest Credit 685016'),
(685032, 0, 0, 0, 10, 0, 100, 0, 1, 5, 1000, 1000, 1, 0, 33, 685031, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Invisible Dummy (Starcaller1) - On a player in the moonwell - Quest Credit Pay respects to Elune'),
(9300350, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685015, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '9300350 - On Spellhit Mysterious Concoction - Quest Credit 685015'),
(9300352, 0, 0, 0, 8, 0, 100, 0, 684328, 0, 0, 0, 0, 0, 33, 685011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Brim - On Spellhit Red Vial - Quest Credit Tend Brim''s Wounds'),
(9300352, 0, 1, 0, 19, 0, 100, 0, 200006, 0, 0, 0, 0, 0, 12, 299222, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 10697, 721, 1326.859, 2.48, 'Brim - On Quest A Surprise Attack! Accepted - Summon Suspicious Creature (attacks)'),
(9300352, 0, 2, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 299222, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 10697, 721, 1326.859, 2.48, 'Brim - On Gossip Hello - Summon Suspicious Creature again if none is near'),
(9300353, 0, 0, 1, 62, 0, 100, 0, 930452, 0, 0, 0, 0, 0, 33, 685022, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thalador - On Gossip Option 0 Selected - Quest Credit Chat with Thalador'),
(9300353, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thalador - Linked - Say Line 0'),
(9300353, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thalador - Linked - Close Gossip'),
(9300354, 0, 0, 1, 8, 0, 100, 0, 512352, 0, 0, 0, 0, 0, 33, 685221, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wandering Herbalist - On Spellhit Witcher''s Torch - Quest Credit Find the Witch'),
(9300354, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Wandering Herbalist - Linked - Yell Line 0'),
(9300354, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 299333, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 10376, 858, 1324.5, 4.96, 'Wandering Herbalist - Linked - Summon her true self, the Witch, in her place to attack the torch bearer'),
(9300354, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Wandering Herbalist - Linked - Despawn the disguise (respawns with the spawn timer)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 9301356 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(9301356, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Use - Quest Credit Find the ritual circle'),
(9301356, 1, 1, 0, 19, 0, 100, 0, 200048, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 10398, 987.5, 1327.524, 2.3, 'Ritual Circle - On Quest Call of the Dead Accepted - Summon Undead Monstrosity (attacks)'),
(9301356, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 10398, 987.5, 1327.524, 2.3, 'Ritual Circle - On Use - Summon Undead Monstrosity again if none is near');

DELETE FROM `conditions` WHERE `SourceEntry` IN (9300352, 9301356) AND `SourceTypeOrReferenceId` = 22;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 9300352, 0, 0, 9, 0, 200006, 0, 0, 0, 0, 0, '', 'Brim - re-summon only while A Surprise Attack! is taken'),
(22, 3, 9300352, 0, 0, 29, 1, 299222, 20, 0, 1, 0, 0, '', 'Brim - re-summon only if no living Suspicious Creature is within 20 yd'),
(22, 1, 9301356, 1, 0, 9, 0, 200046, 0, 0, 0, 0, 0, '', 'Ritual Circle - credit only while Call of Death is taken'),
(22, 3, 9301356, 1, 0, 9, 0, 200048, 0, 0, 0, 0, 0, '', 'Ritual Circle - re-summon only while Call of the Dead is taken'),
(22, 3, 9301356, 1, 0, 29, 1, 299232, 20, 0, 1, 0, 0, '', 'Ritual Circle - re-summon only if no living Undead Monstrosity is within 20 yd');

DELETE FROM `creature_text` WHERE `CreatureID` IN (9300353, 9300354);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `comment`)
VALUES
(9300353, 0, 0, 'The Shadowlands, you say... I sent so many there. Perhaps they will be kind to me when my day comes. Thank you for listening, child. It eases an old heart.', 12, 0, 100, 1, 'Thalador - after the Reaper speaks with him (INFERRED)'),
(9300354, 0, 0, 'The torch! You will not burn me, hunter!', 14, 0, 100, 0, 'Wandering Herbalist - revealed as the witch (INFERRED)');
