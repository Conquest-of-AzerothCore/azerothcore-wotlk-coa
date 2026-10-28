-- Conquest of Azeroth class trainers in Deathknell: the 19 trainers CoA placed there and a Barbarian, the 20
--   intro letters Shadow Priest Sarvis hands out after "The Mindless Ones", the first class chains that follow
--   them, and every creature, object and drop those chains need.
--
-- WHERE EACH VALUE COMES FROM
--   trainer posts  SOURCED-CLIENT: the QuestSuperTrack turn-in point of each intro letter, z from the server
--   floor (surface.floor). Undertaker Chite stands on the terrain under his point (0.6 yd above it). Shadow-
--   Walker Voss (letter 53016) and Alessia have no point and are placed by hand (INFERRED); Deathguard Bradforth
--   steps 1.6 yd off his point, 3.7 yd from Marla's Grave (ST6961); Brallmular 1.4 yd off his, clear of a bush.
--   facings  INFERRED by hand toward the way players arrive (the chapel door, the inn's front door, the stair
--   head, the graveyard gate); every choice is in the trainer's seed.
--   trainers  names and titles SOURCED-CACHE (creaturecache); Brallmular and Shadow-Walker Voss are named by
--   their letters (no cache record, new entries). Race from the name, title and class (INFERRED; Deathknell took
--   the undead and blood elf classes). Looks are stand-ins built from stock NPC looks: no SMSG_MIRRORIMAGE_DATA
--   capture of any trainer exists. Alessia is CoA's Barbarian trainer record 502951, cached only in the coa-
--   alpha capture of the union creaturecache (INFERRED for Deathknell).
--   quests  SOURCED-CACHE (questcache). Starter of the letters INFERRED from the stock letter pattern (3095-3099
--   start at Sarvis after quest 364) and the Details voice ("young one ... tasted death"). Chains start at the
--   letter's trainer (PrevQuestID = the letter) and continue by PrevQuestID; RewardNextQuest from the cache
--   inside this file. The Barbarian letter 9302412 and its Warband trial 9302413 are new (INFERRED), modelled on
--   53000 and 200104.
--   letter pages  page_text is missing from the world DB: 8 pages SOURCED-CACHE (pagetextcache, verbatim even
--   where they name older trainers), 12 composed from the quest Details (INFERRED). The shared chain items
--   661316, 661329 and 662316 get their pages here once for every zone (INFERRED; 662316 quotes quests 200001
--   and 200013; the Riddlestone riddle is zone-neutral as ct-coldridge and ct-northshire asked, since each zone
--   hides its Eye in another building).
--   chain places  INFERRED from the quest text and anchored on real landmarks: the abandoned farmhouses, the
--   Scarlet camp and Meven Korgal's tent, the barn and smithy, the hills south-west, the hidden gully in the
--   western mountains, and CoA-only props (the Elune statue with candles, the wrecked wagon, the inn's canopy
--   bed, the candle-lit tombstones).
--   drop chances  SOURCED-EXILES creature_loot where it has them; unique holders drop 100%.
--   stock trainers  every one keeps its post and role. Dannal Stern (guid 28464), 2.48 yd from Dabbert Staze's
--   sourced point, is hidden while his quest copy 299240 stands in his alcove (rev_20260924_13).
--   stock patrols  two waypoint turnarounds that walked onto a trainer post and Marla's Grave are moved by hand
--   (INFERRED, the nearest open floor on the same route); claimed in coordination/ct-deathknell.md.
--
-- Blocks: creature guids 9003700-9003899, gameobject guids 7912400-7912499, creature entries 9300250-9300299,
--   gameobject entries 9301250-9301299, gossip and npc_text 930350-930399, quest and item 9302412-9302413,
--   page_text 931412. Runs after rev_20260923_05_coa_class_trainer_core.sql.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- 50276 Dar'danis, Felsworn: blood elf: Felsworn is a blood elf class, not an undead one, and the name is
--   Thalassian. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from
--   Pathstalker Kariel (display 15519), changed hair 6/4, face 3, Felscale breastplate, pants, gloves.
-- 50275 Bailey Horrorhate, Witch Hunter: Forsaken male: the cached letter page 15017 calls him "him" and "undead
--   witch hunter". look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male
--   from David Trias (display 1580), changed hair 3/2, face 5, wide-brimmed hat, Inquisitor's Shawl.
-- 502773 Dabbert Staze, Stormbringer: Forsaken male: 200100 calls him "him"; Stormbringer is an undead class.
--   look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from Bethor
--   Iceshard (display 4055), changed hair 4/6, face 2, Earthfury breastplate and epaulets.
-- 9300250 Brallmular, Knight of Xoroth: blood elf male: Knight of Xoroth is a blood elf class, not an undead
--   one. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from Aeldon
--   Sunbrand (display 15906), changed hair 2/5, face 5, Dreadnaught breastplate and pauldrons (heavy dark
--   plate), bareheaded to show the mortal visage.
-- 50279 Deathguard Bradforth, Guardian: Forsaken male: "Deathguard" title; Guardian is an undead class. look is
--   a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from Deathguard Simmer
--   (display 1648), changed skin 3, face 6, hair 3/4, Executor Arren's pauldrons.
-- 502803 Vaelion Grandbell, Templar: blood elf male: Thalassian name (trainers.md), Blood Knight Templar. look
--   is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from Jesthenis
--   Sunstriker (display 15521), changed hair 4/1, face 2, Blood Knight pauldrons and tabard.
-- 502922 Irina Valreed, Bloodmage: Forsaken female: the cached letter page 15001 is written to an "undead blood
--   mage". look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken female from
--   Isabella (display 1592), changed hair 1/7, face 3, Crimson Acolyte raiments and mantle.
-- 50281 Gustaf Blightflight, Ranger: Forsaken male: the letter speaks of the undead ranger; Ranger is an undead
--   class. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from Karos
--   Razok (display 3832), changed hair 7/3, face 4, hood off.
-- 502822 Quardormi, Chronomancer: blood elf male: Chronomancer is a blood elf class, not an undead one. look is
--   a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf male from Magister Duskwither
--   (display 16658), changed hair 9/3, face 6, sand-coloured Desert Shoulders.
-- 502930 Dornall Plagueweaver, Necromancer: Forsaken male: "Plagueweaver", Necromancer is an undead class. look
--   is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from Gunther Arcanus
--   (display 3518), changed face 8, bald, mask off, Plagueheart robe.
-- 50293 Cadmus Emberblaze, Pyromancer: Forsaken male: 200145 "my heart stopped beating years ago", 200140 calls
--   him "he". look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from
--   Father Lazarus (display 2618), changed hair 8/5, face 3, Embersilk robes, Crimson Silk shoulders.
-- 502833 Thaddeus Voidseeker, Cultist: Forsaken male: Cultist is an undead class; the cached page 15002 is
--   written to an undead cultist. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   Forsaken male from Shadow Priest Allister (display 1948), changed hair 2/9, face 7, Twilight Cultist cowl,
--   robe, mantle.
-- 502850 Landralanis, Starcaller: blood elf female: 200033 opens in Thalassian ("Bal'a dash, malanore") and
--   speaks of "my people". look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood
--   elf female from Julia Sunstriker (display 15522), changed hair 8/2, face 4, Starry Robes of the Crescent,
--   Celestial pauldrons.
-- 50327 Sunspeaker Talethia, Sun Cleric: blood elf female: "Sunspeaker" (trainers.md); Sun Cleric is a blood elf
--   class. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: blood elf female from
--   Matron Arena (display 15518), changed hair 5/0, face 1, Sunfire robe.
-- 502873 Riley Jett, Tinker: Forsaken female: 200098 calls her "she"; Tinker is an undead class. look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken female from Susan Tillinghast
--   (display 10563), changed hair 3/1, face 5, Bright-Eye goggles.
-- 650688 Apothecary Kelan, Venomancer: Forsaken male: "Apothecary" (Royal Apothecary Society), cached page 15015
--   says "him". look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken male from
--   Doctor Marsh (display 2624), changed hair 6/2, face 1, Apothecary's robe, gloves, Master Apothecary cape.
-- 502891 Undertaker Chite, Reaper: Forsaken male: "Undertaker"; 200039 "looking at my helmet" (he wears a helm);
--   Reaper is an undead class. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists:
--   Forsaken male from Undertaker Mordo (display 1582), changed hair 1/2, face 6, Carved Bone Helm,
--   Deathstalker's vest.
-- 502913 Wilhelm Balthier, Runemaster: Forsaken male: his own greeting 75016 ("carve it on our bones") is the
--   undead Runemaster's. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: Forsaken
--   male from Brother Malach (display 3876), changed hair 5/0, face 9, Demonic Runed Spaulders, Darkrune
--   breastplate.
-- 9300251 Shadow-Walker Voss, Witch Doctor: troll male: "Shadow-Walker" is a Darkspear title and the letter
--   speaks of fetishes and restless spirits; Witch Doctor is a troll class. look is a stand-in, no
--   SMSG_MIRRORIMAGE_DATA capture of this trainer exists: troll male from Witch Doctor Unbagwa (display 4661),
--   changed hair 5/2, face 5, tusks 4, Big Voodoo mask and cloak.
-- 502951 Alessia, Barbarian: Forsaken female: CoA's Barbarian trainer record 502951 (coa-alpha capture of the
--   union creaturecache, stock-client creatures-007.lua, Exiles), the undead slot of the start-zone Barbarian
--   set 502950 Camp Narache, 502952 Coldridge Valley, 502953 Valley of Trials and twin of Undercity's 602951
--   (INFERRED for Deathknell); female by her first name; display 561656 does not resolve and no cache, Exiles,
--   atlas or capture holds another look. look is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer
--   exists: Forsaken female from Angela Curthas (display 2658), changed face 5, hair 4/5, features 3, bare
--   hands, spiked Horde leather shoulders.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(50276, 'Dar''danis', 'Felsworn Trainer', 930014, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50275, 'Bailey Horrorhate', 'Witch Hunter Trainer', 930015, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502773, 'Dabbert Staze', 'Stormbringer Trainer', 930016, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300250, 'Brallmular', 'Knight of Xoroth Trainer', 930017, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50279, 'Deathguard Bradforth', 'Guardian Trainer', 930018, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502803, 'Vaelion Grandbell', 'Templar Trainer', 930019, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502922, 'Irina Valreed', 'Bloodmage Trainer', 930020, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50281, 'Gustaf Blightflight', 'Ranger Trainer', 930021, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502822, 'Quardormi', 'Chronomancer Trainer', 930022, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502930, 'Dornall Plagueweaver', 'Necromancer Trainer', 930023, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(50293, 'Cadmus Emberblaze', 'Pyromancer Trainer', 930024, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502833, 'Thaddeus Voidseeker', 'Cultist Trainer', 930025, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502850, 'Landralanis', 'Starcaller Trainer', 930026, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50327, 'Sunspeaker Talethia', 'Sun Cleric Trainer', 930027, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(502873, 'Riley Jett', 'Tinker Trainer', 930350, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(650688, 'Apothecary Kelan', 'Venomancer Trainer', 930029, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502891, 'Undertaker Chite', 'Reaper Trainer', 930030, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502913, 'Wilhelm Balthier', 'Runemaster Trainer', 930351, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(9300251, 'Shadow-Walker Voss', 'Witch Doctor Trainer', 930013, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502951, 'Alessia', 'Barbarian Trainer', 930012, 10, 10, 0, 68, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50275, 50276, 50279, 50281, 50293, 50327, 502773, 502803, 502822, 502833, 502850, 502873, 502891, 502913, 502922, 502930, 502951, 650688, 9300250, 9300251);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(50276, 0, 15476, 1, 1),
(50275, 0, 57, 1, 1),
(502773, 0, 57, 1, 1),
(9300250, 0, 15476, 1, 1),
(50279, 0, 57, 1, 1),
(502803, 0, 15476, 1, 1),
(502922, 0, 58, 1, 1),
(50281, 0, 57, 1, 1),
(502822, 0, 15476, 1, 1),
(502930, 0, 57, 1, 1),
(50293, 0, 57, 1, 1),
(502833, 0, 57, 1, 1),
(502850, 0, 15475, 1, 1),
(50327, 0, 15475, 1, 1),
(502873, 0, 58, 1, 1),
(650688, 0, 57, 1, 1),
(502891, 0, 57, 1, 1),
(502913, 0, 57, 1, 1),
(9300251, 0, 1478, 1, 1),
(502951, 0, 58, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (50275, 50276, 50279, 50281, 50293, 50327, 502773, 502803, 502822, 502833, 502850, 502873, 502891, 502913, 502922, 502930, 502951, 650688, 9300250, 9300251);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(50276, 15476, 10, 0, 1, 1, 3, 6, 4, 0, 0, 0, 0, 0, 32038, 2014, 32037, 29230, 2016, 32039, 0, 0),
(50275, 57, 5, 0, 1, 4, 5, 3, 2, 1, 0, 24620, 25394, 3564, 0, 2287, 1199, 1112, 3565, 3566, 0, 0),
(502773, 57, 5, 0, 1, 2, 2, 4, 6, 12, 0, 0, 25213, 8497, 25212, 0, 5663, 6279, 0, 0, 0, 0),
(9300250, 15476, 10, 0, 1, 3, 5, 2, 5, 0, 0, 0, 28388, 0, 28263, 26567, 26660, 26568, 0, 26572, 0, 0),
(50279, 57, 5, 0, 1, 3, 6, 3, 4, 0, 0, 11992, 1029, 0, 3522, 3523, 3524, 3616, 3526, 3527, 0, 0),
(502803, 15476, 10, 0, 1, 0, 2, 4, 1, 0, 0, 0, 32364, 0, 26571, 26567, 26660, 26568, 0, 26572, 0, 30597),
(502922, 58, 5, 1, 1, 2, 3, 1, 7, 5, 0, 0, 56251, 1536, 56235, 3760, 3171, 3576, 0, 13543, 0, 0),
(50281, 57, 5, 0, 1, 5, 4, 7, 3, 1, 0, 0, 5583, 6256, 0, 6257, 6206, 6258, 0, 0, 0, 0),
(502822, 15476, 10, 0, 1, 3, 6, 9, 3, 0, 0, 0, 20479, 0, 29649, 29683, 29684, 6965, 0, 0, 0, 0),
(502930, 57, 5, 0, 1, 3, 8, 0, 0, 10, 0, 0, 0, 7433, 28396, 3299, 3274, 3011, 0, 7429, 0, 0),
(50293, 57, 5, 0, 1, 0, 3, 8, 5, 6, 0, 0, 10558, 8494, 20534, 3237, 8495, 6346, 0, 0, 0, 0),
(502833, 57, 5, 0, 1, 0, 7, 2, 9, 10, 0, 26388, 26443, 5265, 26161, 3322, 7417, 0, 0, 0, 0, 0),
(502850, 15475, 10, 1, 1, 2, 4, 8, 2, 0, 0, 0, 20730, 0, 35966, 3585, 26690, 4339, 0, 0, 0, 0),
(50327, 15475, 10, 1, 1, 0, 1, 5, 0, 0, 0, 0, 0, 0, 41801, 3585, 26693, 4339, 0, 0, 0, 0),
(502873, 58, 5, 1, 1, 2, 5, 3, 1, 0, 0, 15161, 0, 9951, 0, 3603, 10534, 10532, 0, 2825, 0, 0),
(650688, 57, 5, 0, 1, 0, 1, 6, 2, 1, 0, 2330, 0, 6347, 9722, 2923, 3335, 6348, 0, 15993, 14802, 0),
(502891, 57, 5, 0, 1, 1, 6, 1, 2, 0, 0, 45122, 0, 5621, 30144, 6070, 5622, 8083, 0, 0, 0, 0),
(502913, 57, 5, 0, 1, 4, 9, 5, 0, 3, 0, 0, 18639, 8493, 26261, 6344, 5684, 5676, 0, 0, 0, 0),
(9300251, 1478, 8, 0, 1, 1, 5, 5, 2, 4, 0, 20179, 8316, 9795, 5512, 9017, 9112, 0, 0, 9005, 18966, 0),
(502951, 58, 5, 1, 1, 2, 5, 4, 5, 3, 0, 0, 8316, 6237, 0, 6238, 2038, 4237, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50275, 50276, 50279, 50281, 50293, 50327, 502773, 502803, 502822, 502833, 502850, 502873, 502891, 502913, 502922, 502930, 502951, 650688, 9300250, 9300251);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(50276, 1, 12482, 12502, 0),
(50275, 1, 2520, 0, 15807),
(502773, 1, 2030, 0, 0),
(9300250, 1, 13051, 0, 0),
(50279, 1, 852, 2446, 0),
(502803, 1, 27538, 27449, 0),
(502922, 1, 3187, 15947, 0),
(50281, 1, 2027, 0, 8180),
(502822, 1, 15041, 0, 0),
(502930, 1, 2013, 0, 0),
(50293, 1, 13000, 0, 0),
(502833, 1, 2209, 12863, 0),
(502850, 1, 25330, 0, 0),
(50327, 1, 23362, 29923, 0),
(502873, 1, 6219, 0, 2509),
(650688, 1, 2139, 2494, 0),
(502891, 1, 13054, 0, 0),
(502913, 1, 5956, 26569, 0),
(9300251, 1, 25183, 0, 0),
(502951, 1, 1680, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (50275, 50276, 50279, 50281, 50293, 50327, 502773, 502803, 502822, 502833, 502850, 502873, 502891, 502913, 502922, 502930, 502951, 650688, 9300250, 9300251);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(50276, 900014),
(50275, 900015),
(502773, 900016),
(9300250, 900017),
(50279, 900018),
(502803, 900019),
(502922, 900020),
(50281, 900021),
(502822, 900022),
(502930, 900023),
(50293, 900024),
(502833, 900025),
(502850, 900026),
(50327, 900027),
(502873, 900028),
(650688, 900029),
(502891, 900030),
(502913, 900032),
(9300251, 900013),
(502951, 900012);

-- ---------------------------------------------------------------------------
-- 2. Named menus and the dying man's words
-- ---------------------------------------------------------------------------
-- Riley Jett greets with her own cached line (npccache 25021); Wilhelm Balthier with the undead Runemaster pair
--   75016/175016 (SOURCED-CACHE). Dalin Soft's two texts are INFERRED.
DELETE FROM `npc_text` WHERE `ID` IN (25021, 75016, 175016, 930352, 930353);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(25021, 'Riley Jett at your service! Need anything made? Need anything tinkered with? Come on! Let me fix, build, or destroy something already!', 'Riley Jett at your service! Need anything made? Need anything tinkered with? Come on! Let me fix, build, or destroy something already!', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(75016, 'You know, Runemasters carve runes into their skin to harness power...$B$BSounds great in theory, until you have to put them on rotting flesh!$B$BLucky for us we can still carve it on our bones, hahaha!', 'You know, Runemasters carve runes into their skin to harness power...$B$BSounds great in theory, until you have to put them on rotting flesh!$B$BLucky for us we can still carve it on our bones, hahaha!', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(175016, 'The ancient art of Runemastery requires dedication and sacrifice, $C. This path is not meant for you.', 'The ancient art of Runemastery requires dedication and sacrifice, $C. This path is not meant for you.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930352, '<Dalin Soft lies beneath the canopy, his breath rattling in a chest that has no more need of it.>$B$BThe Scourge took me once, and the Dark Lady''s banshees dragged me back. Now I feel it pulling at me again, $c. Tell me... what waits on the other side?', '<Dalin Soft lies beneath the canopy, his breath rattling in a chest that has no more need of it.>$B$BThe Scourge took me once, and the Dark Lady''s banshees dragged me back. Now I feel it pulling at me again, $c. Tell me... what waits on the other side?', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930353, 'The Shadowlands... so it has a name. Thank you, $n. When it comes for me this time, I will not be afraid.$B$BTell Chite I am ready.', 'The Shadowlands... so it has a name. Thank you, $n. When it comes for me this time, I will not be afraid.$B$BTell Chite I am ready.', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930350, 930351);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930350, 25021),
(930350, 125018),
(930351, 75016),
(930351, 175016);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930350, 930351);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930350, 0, 3, 'I seek training as a Tinker.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930351, 0, 3, 'I seek training as a Runemaster.', 0, 5, 16, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930350, 930351) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930350, 25021, 0, 0, 15, 0, 134217728, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Tinker'),
(14, 930350, 125018, 0, 0, 15, 0, 134217728, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Tinker'),
(15, 930350, 0, 0, 0, 15, 0, 134217728, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Tinker'),
(14, 930351, 75016, 0, 0, 15, 0, 2147483648, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Runemaster'),
(14, 930351, 175016, 0, 0, 15, 0, 2147483648, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Runemaster'),
(15, 930351, 0, 0, 0, 15, 0, 2147483648, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Runemaster');

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930352, 930353);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930352, 930352),
(930353, 930353);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 930352;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930352, 0, 0, 'Undertaker Chite sent me. I can tell you what lies beyond.', 0, 1, 1, 930353, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` = 930352 AND `SourceTypeOrReferenceId` = 15;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 930352, 0, 0, 0, 9, 0, 200039, 0, 0, 0, 0, 0, '', 'Dalin Soft - Show gossip option only while Call of the Shadowlands is taken');

-- ---------------------------------------------------------------------------
-- 3. Chain creatures
-- ---------------------------------------------------------------------------
-- 299240 Dannal Stern: Cultist "Going MAD!" 200075: the quest's own kill entry, named as the text names him; the
--   stock warrior trainer 2119's own display and weapon; neutral like Deathknell's other targets (faction 7).
-- 299226 Crazed Undead: Knight of Xoroth "The Demon Inside" 200035: the quest's own kill entry, named from its
--   objective ("Kill the crazed Undead"); a freshly risen Forsaken (Forsaken Recruit display 21748, a stand-in).
-- 9300252 Suspicious Blood Elf: Bloodmage "Blood Is Power" 200019: holds the Tome of Blood, "a suspicious Blood
--   Elf rummaging in the abandoned houses"; Tranquillien Scout display 16088 (a stand-in).
-- 9300253 Felo: Ranger chain 200011-200013: Gustaf's falcon, named in 200011 ("my falcon, Felo"); CoA's own
--   Brown Falcon display 81081 (creaturecache 116129, birdsofprey.mdx) at scale 0.6, as ct-narache's falcon
--   Keed.
-- 9300254 Scorch: Pyromancer "The Way of the Pyromancer" 200145: the fire elemental bound to a campfire in the
--   hills; small fire elemental (display 1405 at scale 0.6, a stand-in).
-- 9300257 Mortimer: Barbarian "Welcome to the Warband" 9302413: the rookie the Warband turned away, as Gerald
--   and Gok in the other starting areas (name INFERRED); Forsaken Thug display 4132 (a stand-in); neutral and
--   immune to NPCs.
-- 9300255 Dalin Soft: Reaper "Call of the Shadowlands" 200039: the dying man of Deathknell, named in the
--   objective; Forsaken Refugee display 27588 (a stand-in).
-- 9300256 Agatha Harlow: Witch Hunter "The Hunt Begins" 200057: the witch in her disguise, a Deathknell
--   herbalist (name INFERRED; Forsaken Herbalist display 4129, a stand-in); the torch reveals the witch 299333.
-- 685012 [KC] Poison Sunspeaker Talethia: Venomancer "Poisoning the World" 200024 credit marker, objective 1.
-- 685013 [KC] Poison Bailey Horrorhate: Venomancer "Poisoning the World" 200024 credit marker, objective 2.
-- 685014 [KC] Poison Dornall Plagueweaver: Venomancer "Poisoning the World" 200024 credit marker, objective 3.
-- 685034 Invisible Dummy (Starcaller3): Starcaller "Champion of Elune" 200033: SOURCED-CACHE name, type, display
--   and health; stands at the toppled Elune statue and credits 685031.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(299240, 'Dannal Stern', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299226, 'Crazed Undead', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300252, 'Suspicious Blood Elf', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 9300252, '', 0, 1, 1, 1, 1, 0, ''),
(9300253, 'Felo', NULL, 0, 3, 3, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 1, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(9300254, 'Scorch', NULL, 0, 4, 4, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 4, 0, 9300254, '', 0, 1.5, 1, 1, 1, 0, ''),
(9300257, 'Mortimer', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 512, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300255, 'Dalin Soft', NULL, 930352, 5, 5, 0, 68, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 2, ''),
(9300256, 'Agatha Harlow', NULL, 0, 4, 4, 0, 68, 0, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(685012, '[KC] Poison Sunspeaker Talethia', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, ''),
(685013, '[KC] Poison Bailey Horrorhate', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, ''),
(685014, '[KC] Poison Dornall Plagueweaver', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 130, ''),
(685034, 'Invisible Dummy (Starcaller3)', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 12, 0, 0, 'SmartAI', 0, 0.93, 1, 1, 1, 130, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (299226, 299240, 685012, 685013, 685014, 685034, 9300252, 9300253, 9300254, 9300255, 9300256, 9300257);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(299240, 0, 1578, 1, 1),
(299226, 0, 21748, 1, 1),
(9300252, 0, 16088, 1, 1),
(9300253, 0, 81081, 0.6, 1),
(9300254, 0, 1405, 0.6, 1),
(9300257, 0, 4132, 1, 1),
(9300255, 0, 27588, 1, 1),
(9300256, 0, 4129, 1, 1),
(685012, 0, 11686, 1, 1),
(685013, 0, 11686, 1, 1),
(685014, 0, 11686, 1, 1),
(685034, 0, 81082, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (299240, 9300252, 9300257);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(299240, 1, 1899, 0, 0),
(9300252, 1, 2209, 0, 0),
(9300257, 1, 12348, 0, 0);

-- ---------------------------------------------------------------------------
-- 4. Chain objects
-- ---------------------------------------------------------------------------
-- 9301250 Ritual Circle: Necromancer chain 200052-200054: the circle that ends 200052 and 200053 and starts
--   200053 and 200054; dirt pentagram (display 456).
-- 9301251 Bound Campfire: Pyromancer 200145: the rogue pyromancers' campfire; using it calls Scorch out of the
--   flames (undead campfire, display 396); usable only while the quest is incomplete.
-- 9301252 Training Wand: Chronomancer 200168: Quardormi's wand, left "next door"; a wand model (display 100515).
-- 9301253 Eye of the Beholder: Runemaster 200113: the answer to the riddle, "within the Inn"; a blue gem
--   (display 2770).
-- 9301254 Lost Pendant: Sun Cleric 200062: Talethia's pendant, dropped as the Scarlets ran her out of their
--   camp; a necklace (display 63520).
-- 9301255 Scrap Metal: Tinker 200069: scrap "in and around the tent of their leader" (Meven Korgal); a small
--   gear (display 5391).
-- 9301256 Skull of Pax: Felsworn 200023: the demon skull "placed in the surrounding area"; a demon skull
--   (display 226).
-- 9301257 Hidden Statue: Templar 200081: the statue of a paladin "secretly erected here after the third war",
--   hidden in a gap in the western mountains; Uther statue model (display 6815) at a small scale.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`)
VALUES
(9301250, 2, 456, 'Ritual Circle', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI'),
(9301251, 10, 396, 'Bound Campfire', '', 1, 0, 200145, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI'),
(9301252, 3, 100515, 'Training Wand', '', 1, 1689, 9301252, 0, 0, 0, 0, 0, 0, 200168, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301253, 3, 2770, 'Eye of the Beholder', '', 0.8, 1689, 9301253, 0, 0, 0, 0, 0, 0, 200113, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301254, 3, 63520, 'Lost Pendant', '', 0.6, 1689, 9301254, 0, 0, 0, 0, 0, 0, 200062, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301255, 3, 5391, 'Scrap Metal', '', 1, 1689, 9301255, 0, 0, 0, 0, 0, 0, 200069, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301256, 3, 226, 'Skull of Pax', '', 0.7, 1689, 9301256, 0, 0, 0, 0, 0, 0, 200023, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(9301257, 5, 6815, 'Hidden Statue', '', 0.35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`);

-- ---------------------------------------------------------------------------
-- 5. Quests
-- ---------------------------------------------------------------------------
-- RewardNextQuest (the next step is offered at turn-in): questcache NextQuestInChain where the next quest is in
--   this file: 200140->200141, 200141->200142, 200052->200053, 200053->200054, 200011->200012, 200012->200013.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(53000, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200570, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fury Tablet', 'Seek out Undertaker Chite in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a bone tablet etched with runes that pulse with primal fury. The ancient markings speak of endless rage that transcends death itself, and it seems to be from Undertaker Chite, who teaches the reaper''s way in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Undertaker Chite in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200570, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53001, 2, 2, 2, -516, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200571, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Crimson Scroll', 'Seek out Irina Valreed in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a dark scroll stained with ancient blood, radiating malevolent power. The crimson arts call to those who understand that death and undeath are merely tools, and it seems to be from Irina Valreed, who practices these forbidden techniques in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Irina Valreed in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200571, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53002, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200572, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Void Manuscript', 'Seek out Thaddeus Voidseeker in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a tattered manuscript covered in symbols that seem to writhe and shift when observed. The whispers of ancient entities echo from within, and it seems to be from Thaddeus Voidseeker, who communes with powers beyond death in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Thaddeus Voidseeker in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200572, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53003, 2, 2, 2, -517, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200573, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel Contract', 'Seek out Dar''danis in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a demonic contract wreathed in green flames, its infernal script burning with unholy purpose. The fel energies resonate with those who have already tasted death, and it seems to be from Dar''danis, who commands these dark powers in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Dar''danis in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200573, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53004, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200574, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Guardian Oath', 'Seek out Deathguard Bradforth in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a steel tablet inscribed with protective wards, radiating defensive magic that persists beyond death. The guardian''s oath binds even the undead to protect others, and it seems to be from Deathguard Bradforth, who maintains this sacred duty in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Deathguard Bradforth in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200574, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53005, 2, 2, 2, -518, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200575, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Decree', 'Seek out Brallmular in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a shadow-wreathed proclamation bearing the seal of Xoroth, radiating cold darkness tempered by noble purpose. The Knights of Xoroth understand that honor transcends life and death, and it seems to be from Brallmular, who upholds these dark oaths in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Brallmular in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200575, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53006, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200576, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Codex', 'Seek out Dornall Plagueweaver in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be an ancient bone tablet carved with necromantic symbols that pulse with deathly power. The art of commanding the dead comes naturally to those who have experienced death themselves, and it seems to be from Dornall Plagueweaver, who masters these arts in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Dornall Plagueweaver in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200576, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53007, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200577, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Temporal Scroll', 'Seek out Quardormi in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a scroll that crackles with raw elemental fury, the forces of nature bound by undying will.     This scroll terrifies me, $n, it does not call to me. However, your calling seems to come from Quardormi, who bends time and space in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Quardormi in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200577, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53008, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200578, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Seared Tome', 'Seek out Cadmus Emberblaze in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a smoldering manuscript that burns with cold fire, flames that consume without warmth. Death cannot extinguish the pyromancer''s flame - it only transforms it into something far more terrifying, and it seems to be from Cadmus Emberblaze, who commands these deathly fires in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Cadmus Emberblaze in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200578, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53009, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200579, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Hunter''s Guide', 'Seek out Gustaf Blightflight in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a leather-bound tome marked with tracks from beasts long dead, reeking of decay and ancient wilderness. Death does not end the ranger''s connection to the wild - it deepens it into something darker, and it seems to be from Gustaf Blightflight, who stalks through shadow in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Gustaf Blightflight in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200579, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53010, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200580, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runic Tablet', 'Seek out Wilhelm Balthier in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a stone slab etched with glowing runes that pulse with deathless power. The runemaster''s art transcends mortality - their inscriptions endure long after flesh has rotted away, and it seems to be from Wilhelm Balthier, who carves these eternal symbols in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Wilhelm Balthier in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200580, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53011, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200581, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Storm Manuscript', 'Seek out Dabbert Staze in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a manuscript that crackles with spectral lightning, thunder echoing from the realm beyond. The stormbringer''s tempests carry the voices of the dead, winds that howl with the fury of lost souls, and it seems to be from Dabbert Staze, who commands these ghostly storms in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Dabbert Staze in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200581, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53012, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200582, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Solar Scripture', 'Seek out Sunspeaker Talethia in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a golden scripture that glows with pale light, divine energy filtered through the veil of death. Even the undead can channel the sun''s power, transforming sacred light into something both beautiful and terrible, and it seems to be from Sunspeaker Talethia, who maintains this paradoxical faith in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Sunspeaker Talethia in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200582, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53013, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200583, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sacred Vow', 'Seek out Vaelion Grandbell in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a blessed document that emanates cold light, holy vows that bind even beyond the grave. The templar''s dedication to justice transcends life and death, creating champions who serve righteousness in undeath, and it seems to be from Vaelion Grandbell, who upholds these sacred duties in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Vaelion Grandbell in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200583, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53014, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200584, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Mechanical Schematic', 'Seek out Riley Jett in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be technical blueprints drawn on preserved skin, mechanical designs powered by necromantic energy. Death brings new perspectives to invention - machinery that runs on soul energy rather than steam, and it seems to be from Riley Jett, who creates these marvels in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Riley Jett in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200584, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53015, 2, 2, 2, -515, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200585, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Venom Formula', 'Seek out Apothecary Kelan in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a tome reeking of exotic poisons, green vapors seeping between pages of treated flesh. The undead understand toxins better than any living being - death teaches the ultimate lesson about poison and decay, and it seems to be from Venom Collector Pendo, who brews these deadly compounds in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Apothecary Kelan in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200585, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53016, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200586, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Spirit Fetish', 'Seek out Shadow-Walker Voss in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be an ancient scroll decorated with bones and dark fetishes, humming with the power of restless spirits. The witch doctor''s art bridges life and death through ancient rituals, and it seems to be from Shadow-Walker Voss, who practices these mystical arts in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Shadow-Walker Voss in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200586, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53017, 2, 2, 2, -519, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9200587, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Inquisitor''s Letter', 'Seek out Bailey Horrorhate in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a sealed letter bearing the burning wax seal of the Inquisition. Having experienced transformation firsthand, you can distinguish between natural evolution and true corruption, and it seems to be from Bailey Horrorhate, who hunts with perfect justice in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Bailey Horrorhate in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9200587, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(53201, 2, 2, 2, -506, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 532001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stellar Chart', 'Read the Stellar Chart and seek out Landralanis in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be an ethereal chart containing star maps that twinkle with actual starlight, pulsing with cosmic power from distant galaxies. The way of the Starcaller opens celestial mysteries, and it comes from Landralanis, who commands stellar forces in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Landralanis in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 532001, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(9302412, 2, 2, 2, -526, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 9302412, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Grave-Etched Tablet', 'Seek out Alessia in Deathknell.', 'I was asked to bring this to your attention, young one. It appears to be a slab of broken headstone gouged with barbarian war-runes, and the rage in them did not die with the one who carved them. It seems to be from Alessia, who teaches the barbarian''s way in Deathknell. I wouldn''t hesitate to read it before you continue your duties here.', '', 'Seek out Alessia in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 9302412, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(9302413, 2, 3, 3, -526, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 532805, 1, 532806, 1, 395861, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Welcome to the Warband', 'Kill Mortimer and return back to your trainer.', 'Har! Har! Welcome, $N. Glad you could join the Warband.  What is the Warband, you might be wondering? Considering your arrival, I would have assumed you''d already know. Well, little $c, this is about to be a rude awakening.  The Warband is where all barbarians, brutes, and strongmen alike come together to compete to see who is the strongest, most brutal, and most powerful individual of them all.  That''s the only way we can TRULY test our mettle. THIS IS IT! You may be new to this, but absolutely nobody will go easy on you.  Your first test will be the same as all the other rookies. There''s an individual who has been mucking things up and spreading rumors just because they couldn''t cut it and were denied access to the Warband.  They''re known as Mortimer. Kill him, hahaha! I will reward you with a weapon well-suited for a noob like yourself if you are capable of such a task.  Come back to me alive, or die.', '', 'Return to your trainer.', 9300257, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200019, 2, 3, 3, -516, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 661317, 1, 1505015, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Is Power', 'Collect the Tome of Blood from the suspicious Blood Elf.', 'Ahh, $C. Your day has finally come.  Blood. Something you should be well acquainted with at this point, in some way or another. Blood is life. But blood, as you will soon learn, is also power.  I want you to imagine what you can be capable of in a world in which you can control the very life essence of another beings body. To simply crush their insides with the flick of a wrist...  Intoxicating.  In due time, you will learn more. For now, I require your assistance in pursuing my own studies and through this I will also be able to help you learn.   Nearby is a tome, that of which is possessed by a suspicious Blood Elf rummaging in the abandoned houses nearby, and one of which I require for my studies. Collect it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661316, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200168, 2, 3, 3, -530, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 553122, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Perfect Timing', 'Find Quardormi''s wand in Deathknell.', 'Ahhh, $N, I saw your arrival long ago. Now it is time to teach you what it means to be a Chronomancer. To weave the very fabric of space and time. To be equivalent to a god...   Let me not get ahead of myself. For you, $N, are new to the world of chronomancy, and before I can allow you to inhabit this world with such latent power... you must learn how to control yourself.  As a Chronomancer, you are a master of time magic. This means you must respect time on the most foundational of levels. It just so happens that I left my wand somewhere next door.   You have 2 minutes. Find it for me.', '', 'Return to Quardormi.', 0, 0, 0, 0, 0, 0, 0, 0, 661335, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200075, 2, 3, 3, -522, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532803, 1, 532804, 1, 532881, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Going MAD!', 'Kill Dannal Stern.', 'You have arrived at the most opportune time, $N.  I have heard the whispers of the great beyond. It tells me of a particularly dangerous individual to our cause. I need you to destroy them, swiftly.  If you do this I will reward you with a weapon fit for a follower of the Old Gods themselves.  The individual you''re looking for lays inside the inn. They go by the name of "Dannal Stern". End him.', '', 'Return to your trainer.', 299240, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200140, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 200141, 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Peace Through Strength', 'Find Cadmus Emberblaze in Deathknell.', 'It is nice to meet you, $N. We have much work to accomplish together and you, my friend, have much to learn!  We are Guardians, and as such we are tasked with, quite literally, guarding Azeroth. From the occasional ne''er-do-well that robs a man, to far more threatening monsters who pose a threat to our people. We are the ones who heed the call.  And, as my example preludes, I have such a task for you today. If you can do this, you are more than ready to proceed further into your training.  There is an individual nearby goes by the name of Cadmus Emberblaze, and I believe he could use my help.  Visit him and see what he needs.', '', 'Find Cadmus Emberblaze in Deathknell.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200141, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 200142, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Prioritizing Defense', 'Kill Scarlet Converts until you find a suitable weapon for Cadmus Emberblaze.', 'Ahhh, $c. I knew help would arrive soon. I could use some protection today, or the means of protecting myself, perhaps?  I am a master of all things fire and flame. Alas, my prowess in melee combat is lacking. I would like to be able to defend myself if the situation demands it without simply incinerating my opponent alive.  Nearby there are members of the Scarlet Crusade. They have weapons that could be of great use to me. Can you collect one of the finer ones you see and bring it back to me?', '', 'Return to Cadmus Emberblaze.', 0, 0, 0, 0, 0, 0, 0, 0, 662330, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200142, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 0, 2, 25, 0, 0, 0, 0, 0, 0, 0, 0, 245712, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Helping A Friend', 'Return to your trainer with news of your success.', 'This sword... or dagger... is absolutely...  Perfect!  Thank you for this! I found a shield while adventuring in the local spider cave not too far from here. I gave it to your trainer.  I''ve already spoken to them and they know to give it to you. I''m sure it would be far more useful for you than it would be for me.', '', 'Return to your trainer with news of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200035, 2, 3, 3, -518, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 2000124, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Demon Inside', 'Kill the crazed Undead.', 'Aha, $N, welcome, do you like your mortal visage? The time has come for us to unleash hell upon Azeroth, one step at a time.  As you well know, there are only so many of us, but our numbers will grow with time. I need not remind you, I assume, that the plight of the Horde is not your primary concern. They are but a tool, a shield, so that we may further our own goals.  At every step, at every moment, we must wreck havoc on this world, yet we must not give up our secret - that we are demons - and as such, I have a little task for you.  There is an individual who has been causing trouble in Deathknell. When he awoke, he simply ran amok causing havoc.  I have been tasked by my superiors here to deal with him. Normally, I''d be friends with someone like this, but we must give the illusion that we are on their side.  Kill him, we''ll make up an excuse for how he died.', '', 'Return to your trainer.', 299226, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200052, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of Death', 'Find and interact with the ritual circle.', 'Greetings, $C. Glad you could join me in the graveyard today.  Beautiful day, isn''t it?  It seems you''ve already been acquainted with undeath, I am impressed by your ability to raise the dead.   Perhaps you could be used to my benefit, which I''m sure you would not mind. I have a particularly powerful Undead that I wish to summon, but I dare not attempt it myself - I am far too important.  You, however, could learn quite a lot by succeeding here. And if you are to fail? I will simply raise you as my own.  Do not overthink it. Let me mark your map to the location of where my ritual must be had. You must collect specific items in order to complete the ritual.  Now, be gone.', '', 'Interact with the ritual circle.', 685121, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the ritual circle', '', '', ''),
(200053, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200054, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Calls', 'Kill Ghouls and loot their bones, flesh, and skull.', 'In order to summon the Undead monstrosity, I must bring the following ingredients to the ritual circle.  - Bones - Fresh Flesh - Skull  The nearby Ghouls have just what is needed.', '', 'Return to the ritual circle.', 0, 0, 0, 0, 0, 0, 0, 0, 458421, 458422, 458423, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(200054, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 660053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Dead', 'Kill the Undead Monstrocity.', '<The materials dissipate into the ritual circle into a puff of smoke>  ...something seems off.  The summon has failed, inspect the ritual circle again. But be careful, it is unstable.', '', 'Return to your trainer.', 299232, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200145, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 293203, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Way of the Pyromancer', 'Defeat Scorch and acquire his heart.', 'Even though my heart stopped beating years ago, the fire burns hot in my chest.  Do you feel it too, $N?  There are those who feel it a bit too much, and allow it to consume them completely.   They allow it to burn so hot they lose control of their impulses and do things they regret.  A group of rogue Pyromancers burned so brightly they summoned an elemental from the domain of Ragnaros. They have bound it to a campfire in the hills, I task you with summoning and killing it.  Return to me with it''s heart and I shall reward you with the control that they lacked.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 662331, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200011, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200012, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1923.5, 1697, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ranger''s Path', 'Find Clarisse''s falcon in the surrounding area.', 'Being a Ranger is more than just picking up a bow, or fighting from the cover of the trees, $n.  Being a Ranger, at its core, means that you have a profound connection to the wilds. You are its protector.  I sent my falcon, Felo, to scout the surrounding areas, but he has not returned.   Please, find him and direct him to return back to me.', '', 'Find Clarisse''s falcon in the surrounding area.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200012, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200013, 3, 0, 0, 0, 0, 0, 0, 662316, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Surprise Attack!', 'Slay the suspicious creature.', 'Something is rustling in the nearby bushes.  You''re under attack! ', '', 'Tend to the falcon.', 299222, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200013, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 0, 2, 70, 0, 0, 0, 0, 0, 662317, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 818000, 1, 727000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Falcons Are Friends', 'Use the Red Vial on the falcon.', 'You find a note attached to the falcon that reads:  <If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.>', '', 'Return to your trainer.', 685011, 0, 0, 0, 1, 0, 0, 0, 662317, 662316, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 'Tend to Felo''s wounds', '', '', ''),
(200039, 2, 3, 3, -508, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 540070, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Shadowlands', 'Visit Dalin Soft in Deathknell.', 'Smirk one more time when looking at my helmet, and I''ll put this blade in your chest, $N.  ...you are bold. I can sense you have come to me to learn. I do have a simple task for you today, young $C.  In Deathknell is a man, you could say, who was near his end, only to then be killed by the Scourge and risen yet again.  He will die and the Shadowlands will claim him, this time. But today is not his day. Yet, I can feel his yearning to leave this plane, but he is unaware of what lays before him once he is gone.  You may not have expected such a task, but I would humbly ask you to pay him a visit and have a chat.', '', 'Return to your trainer.', 685022, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chat with Dalin Soft', '', '', ''),
(200113, 2, 3, 3, -527, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 661329, 0, 0, 293202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes of Power', 'Figure out the riddle etched on the runestone.', 'Greetings, $N. I''m glad you could finally join me, I have awaited your arrival.  Today, a simple lesson in problem solving for an aspiring Runemaster such as yourself. Perhaps you will succeed, perhaps you will not.  Here, I have a rune. Etched on the rune is a riddle. Figure the riddle out and return to me.   A hint? The best I can do is tell you that the answer to this riddle lays within the Inn. Not without.  I will know when you return if you have figured it out or not, do not worry. Succeed, and I will reward you.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661330, 661329, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, '', '', '', ''),
(200033, 2, 3, 3, -506, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 300100, 1, 300101, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Champion of Elune', 'Find the toppled statue and praise Elune.', 'Bal''a dash, malanore, $N. I see Elune has not forgotten you, good, I could use one so blessed.  As Starcallers, we are champions of Elune, and as such, we must carry out her will - wherever it takes us, and whatever it must be.  But, when the land is embroiled with peace, one must learn to still pay respects to Elune, so that she will be there to guide us when the land is yet again filled with war and despair.  In the mountains to the north is a old statue dedicated to the time when Tyrande herself landed her forces upon the Eastern Kingdoms - a direct assault against the scourge itself, and aided my people.   Since the time that the statue was erected, it has fallen, and been forgotten. Yet it remains as a pilgrimage site for followers of Elune. Go there, meditate, and pay respects to the goddess, then return to me.', '', 'Return to your trainer.', 685031, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Pay respects to Elune', '', '', ''),
(200098, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Useful In Your Own Right', 'Assist Riley Jett with her tinkering shenanigans.', 'Greetings, $N, I am glad to make your acquaintance and I have heard much about you before your arrival.  You have come to me to learn and as a $C you have already shown yourself to be a dutiful student of the arcane. But there is so much more to the power that we call forth than just lightning and electricity.  In time, you will learn just how deep your potential lays. But for now... I do have a bit of a task for you.  There''s an individual nearby known as "Riley Jett" and she always calls on my aid for her... tinkering shenanigans... She needs some lightning, $N, but I am busy. Can you go and assist her?', '', 'Assist Riley Jett with her tinkering shenanigans.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200099, 2, 3, 0, -520, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Stolen Power Core', 'Kill Rattlecage Skeletons until one of them drops the power core.', 'Howdy, $N! Glad your trainer got around to sendin'' some help my way.  This is a very simple task, I just need some POWER! But unfortunately my power core has been stolen by one of the nearby Rattlecage Skeletons. Can you return it for me?', '', 'Return to Riley Jett.', 0, 0, 0, 0, 0, 0, 0, 0, 661417, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200100, 2, 3, 0, -525, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 663317, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Job For A Stormcaller', 'Tell your trainer of your success.', 'I appreciate you retrieving this power core! You can return to your trainer now and let him know what you''ve done for me.', '', 'Tell your trainer of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200062, 2, 3, 3, -507, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 454381, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Pendant', 'Find the lost pendant.', 'Greetings, $C. You have arrived at the perfect time.  I have lost a pendant of mine that is quite powerful. Lost may be the wrong word, but alas, we best not get lost in the semantics.  Well, I guess I owe it to you to at least explain what happened if you''re going to help me. So here goes.  I was attempting to show the Scarlet Crusaders at the local camps that we can work together, as we both follow the light.  They did not take kindly to this and they ran me out of their camp...  In my haste, I dropped my pendant. Please, find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200081, 2, 3, 3, -524, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 52855, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Quiet Life', 'Visit the hidden statue in the western mountains of Deathknell.', 'Greetings, $N. I have awaited your arrival.  As Templars, we have ascended to the highest order of the holy faith, and as such we have quite a lot of responsibility on our shoulders.  Paladins and Priests work alongside us to maintain peace through the Holy Light in this world and each of us, though different in our own subtle ways, hope to bring the light to Azeroth once more. Despite it''s perils.  Our path may be different, but some may argue that it is far more rigorous. To be a templar means to maintain extremely precise control of your emotions, your combat flow, and your mind.  In order to keep myself healthy, I enjoy meditating near a statue of a once powerful Paladin that was secretly erected here after the third war. It was hidden away in a gap in the mountain, and to reach it, you will need to use your agile movements.   Please, visit the area yourself. Tell me what you experience when you return.', '', 'Visit the hidden statue in the western mountains of Deathknell.', 685037, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit the hidden statue', '', '', ''),
(200069, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 415000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ingenuity At It''s Finest!', 'Collect 3 Scrap Metal.', 'Greetings, $N. I''ve seen you mucking around and I have just the task for one of your intellectual level.  I am a Tinker. Let that be understood. You? I am unsure, but perhaps you can prove your tinker status to be today. I want to build a special type of gun for myself, and with your assistance, I can build you one as well.  There is some metal out there near the Scarlet camps, specifically in and around the tent of their leader, that could be used to create a gun for you and me. Collect me some and I''ll go tinkerin'' away!', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663320, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', ''),
(200024, 2, 3, 3, -415, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662217, 0, 0, 292200, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Poisoning the World', 'Splash the mysterious concoction on nearby citizens.', 'Welcome, $C. Have you come to poison the well, so to speak?  I am always willing to teach new and aspiring masters of the venomous arts, but in return, I sometimes require a favor. This is fine, yes?  Look around you. There are citizens of every shade. But they are pure, which is good, they are untainted. Here I have a concoction that I have made. What it does, should not be of concern to you.  What I need is for you to splash it on three people in particular; first, Sunspeaker Talethia, second, Bailey Horrorhate, and third, Dornall Plagueweaver.  Return to me when you have done this and I will make it worth your time.', '', 'Return to your trainer.', 685012, 685013, 685014, 0, 1, 1, 1, 0, 662217, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Sunspeaker Talethia', 'Bailey Horrorhate', 'Dornall Plagueweaver', ''),
(200023, 2, 3, 3, -517, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 727004, 1, 727001, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Coming into Demonhood', 'Retrieve the skull of Pax.', 'And so it begins.  Greetings, $N. I can already tell that you have begun to feel the residual fel power that burns within your veins. I envy you, there was once a time where I was not so used to it as I am now.  You are Felsworn, and as such, you are at the border of mortality and the likes of demons. However, unlike some, you and I will not fall to the traps of power that fel magic provides, and that so many other practitioners fall too, often unbeknownstly. Perhaps you will even become powerful enough to take on a demonic form someday, but for now, your Fel Empowerment will do you wonders at bringing out your true potential.  Let me make myself clear, the Horde and Alliance are of no use to us, but they must believe we are their allies in order for our greater goals to become achievable. Do not forget this. When it all comes to a head, do not forget where your true allegiance lays.  And now, a test. A skull of a powerful demon known as Pax has been placed in the surrounding area. Find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661321, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200057, 2, 3, 3, -519, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662219, 0, 0, 717002, 1, 410005, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Hunt Begins', 'Reveal the witch and kill her.', 'I can feel an evil presence.  You can feel it too, can''t you? That is why you have come to me at the most opportune of times.  There is one here. A witch. Brooding with evil and malintent.  May the Light bless us for what we''re about to do.  Here, take this torch. She''s here and I''ve marked her location on your map. Use the torch on her to reveal her true self. Kill it. No mercy.  Return to me when it''s been slain.  Damned witches.', '', 'Return to your trainer.', 685221, 299333, 0, 0, 1, 1, 0, 0, 662219, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Find the Witch', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

UPDATE `quest_template` SET `TimeAllowed` = 120 WHERE `ID` = 200168;

DELETE FROM `quest_template_addon` WHERE `ID` IN (53000, 53001, 53002, 53003, 53004, 53005, 53006, 53007, 53008, 53009, 53010, 53011, 53012, 53013, 53014, 53015, 53016, 53017, 53201, 200011, 200012, 200013, 200019, 200023, 200024, 200033, 200035, 200039, 200052, 200053, 200054, 200057, 200062, 200069, 200075, 200081, 200098, 200099, 200100, 200113, 200140, 200141, 200142, 200145, 200168, 9302412, 9302413);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(53000, 0, 536870912, 364, 1, 0),
(53001, 0, 524288, 364, 1, 0),
(53002, 0, 16777216, 364, 1, 0),
(53003, 0, 8192, 364, 1, 0),
(53004, 0, 131072, 364, 1, 0),
(53005, 0, 65536, 364, 1, 0),
(53006, 0, 4194304, 364, 1, 0),
(53007, 0, 2097152, 364, 1, 0),
(53008, 0, 8388608, 364, 1, 0),
(53009, 0, 1048576, 364, 1, 0),
(53010, 0, 2147483648, 364, 1, 0),
(53011, 0, 32768, 364, 1, 0),
(53012, 0, 67108864, 364, 1, 0),
(53013, 0, 262144, 364, 1, 0),
(53014, 0, 134217728, 364, 1, 0),
(53015, 0, 268435456, 364, 1, 0),
(53016, 0, 4096, 364, 1, 0),
(53017, 0, 16384, 364, 1, 0),
(53201, 0, 33554432, 364, 1, 0),
(9302412, 0, 2048, 364, 1, 0),
(9302413, 0, 2048, 9302412, 0, 0),
(200019, 0, 524288, 53001, 0, 0),
(200168, 0, 2097152, 53007, 0, 0),
(200075, 0, 16777216, 53002, 0, 0),
(200140, 0, 131072, 53004, 0, 0),
(200141, 0, 131072, 200140, 0, 0),
(200142, 0, 131072, 200141, 0, 0),
(200035, 0, 65536, 53005, 0, 0),
(200052, 0, 4194304, 53006, 0, 0),
(200053, 0, 4194304, 200052, 0, 0),
(200054, 0, 4194304, 200053, 0, 0),
(200145, 0, 8388608, 53008, 0, 0),
(200011, 0, 1048576, 53009, 0, 0),
(200012, 0, 1048576, 200011, 1, 0),
(200013, 0, 1048576, 200012, 1, 0),
(200039, 0, 536870912, 53000, 0, 0),
(200113, 0, 2147483648, 53010, 1, 0),
(200033, 0, 33554432, 53201, 0, 0),
(200098, 0, 32768, 53011, 0, 0),
(200099, 0, 32768, 200098, 0, 0),
(200100, 0, 32768, 200099, 0, 0),
(200062, 0, 67108864, 53012, 0, 0),
(200081, 0, 262144, 53013, 0, 0),
(200069, 0, 134217728, 53014, 0, 0),
(200024, 0, 268435456, 53015, 1, 0),
(200023, 0, 8192, 53003, 0, 0),
(200057, 0, 16384, 53017, 1, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (53000, 53001, 53002, 53003, 53004, 53005, 53006, 53007, 53008, 53009, 53010, 53011, 53012, 53013, 53014, 53015, 53016, 53017, 53201, 200011, 200012, 200013, 200019, 200023, 200024, 200033, 200035, 200039, 200052, 200053, 200054, 200057, 200062, 200069, 200075, 200081, 200098, 200099, 200100, 200113, 200140, 200141, 200142, 200145, 200168, 9302412, 9302413);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(53000, 'So, you have heeded the call of endless fury. Good. You show promise, $N.$B$BThe path of the Reaper is not one of mindless rage, but of fury given purpose and form. You will learn to harness the primal wrath that dwells within all warriors and transform it into something far more terrible - a rage that never dims, never falters, never shows mercy. Where others grow weary, you will grow stronger. Where others fall back, you will press forward with renewed ferocity.$B$BUnder my tutelage, you will master the berserker arts passed down through countless generations of warriors who refused to accept the limitations of mortal endurance. Your fury will become a living thing, a companion in battle that whispers strategies born of pure aggression. You will learn to channel this rage into devastating whirlwind attacks, earth-shattering charges, and strikes that can cleave through armor as if it were parchment.$B$BWelcome to the path of eternal rage, $N. Let your enemies learn what it means to face one whose fury knows no bounds!'),
(53001, 'The crimson arts have chosen you, $N. This is no small thing.$B$BBlood magic is among the oldest and most potent forms of sorcery. Every drop of blood contains the essence of life itself - power, memories, potential. As a Bloodmage, you will learn to manipulate this vital force with surgical precision. The blood of your enemies will become your weapon, their life force your shield, their very essence fuel for your most devastating spells.$B$BYou will study the ancient techniques of hemomancy - the art of blood control. You''ll learn to boil blood within veins, freeze it solid to shatter bones from within, or draw it forth as crimson weapons. The blood of fallen foes will rise at your command, forming shields, spears, or swirling vortexes of destruction. You will master blood pacts that grant terrible power at calculated costs, and rituals that can drain entire battlefields to fuel a single, apocalyptic spell.$B$BThis path demands discipline, for blood magic corrupts the careless and consumes the weak. But for those with the will to master it, the crimson arts offer power beyond imagination.$B$BWelcome to the crimson path, $N. Let blood itself bend to your will!'),
(53002, 'Ah, another hears the whispers. The void has marked you, $N.$B$BThe void is not empty - it teems with consciousness older than creation, powers that existed before the first star ignited. As a Cultist, you will serve as conduit to these ancient forces, channeling energies that most minds cannot comprehend without shattering. The whispers you hear are not madness, but truth too terrible for ordinary perception.$B$BYou will learn to see beyond the veil of reality, to perceive the writhing tentacles of power that connect all things. The Old Gods'' influence seeps through cracks in existence, and you will become one such crack - a living portal through which their will manifests. Shadow magic will become your native tongue, and you''ll speak words that unmake reality itself.$B$BYour mind will expand to accommodate truths that would break lesser beings. You''ll summon void entities to serve your will, corrupt the very ground your enemies stand upon, and spread madness like a plague. The void''s gifts come with a price - your sanity will be constantly tested, your humanity questioned. But in return, you gain power that transcends mortal limitation.$B$BWelcome to the void''s embrace, $N. Let the universe learn new definitions of terror!'),
(53003, 'The fel recognizes its own. You''ve taken the first step into damnation, $N - or perhaps salvation, depending on your perspective.$B$BFel magic is corruption given form, chaos refined into a weapon. The Burning Legion may have fallen, but their power remains for those bold enough to claim it. As a Felsworn, you will bind demons to your will, turning the Legion''s own weapons against any who oppose you. Where others see damnation, you see opportunity.$B$BYou will learn the true names of demons, the words that bind them in chains of fel iron and compulsion. Lesser imps will serve as your scouts, succubi as your infiltrators, felguards as your warriors. But more than simple summoning, you will channel fel energy itself - green fire that burns soul as readily as flesh, corruption that spreads like a disease, and transformations that remake you into something more than mortal.$B$BThe fel demands sacrifice. Your soul will bear marks that never fade, your dreams will echo with demonic screams, and your very presence will unsettle those around you. But in exchange, you gain power that toppled titans and burned entire worlds. You will walk the razor''s edge between control and consumption, always one misstep from losing yourself to the fel''s hunger.$B$BWelcome to the fel path, $N. Let the demons learn to fear their new master!'),
(53004, 'Your oath has been witnessed, $N. From this moment forward, you are shield and shelter to those in need.$B$BThe guardian stands where others cannot, endures what others will not, and protects those who cannot protect themselves. Your oath is not merely words - it becomes part of your very essence, transforming you into a living bastion against all forms of harm. As a Guardian, you will master defensive arts that turn you into an immovable object against which the unstoppable force breaks.$B$BYou will learn to weave shields from pure will, barriers that can protect entire armies from dragon''s breath or artillery bombardment. Your presence alone will inspire courage in allies and plant seeds of doubt in enemies. The ancient techniques I will teach you include the Iron Vigil stance that makes you immune to knockback, the Aegis Projection that extends your defenses to distant allies, and the Final Stand - a technique that allows you to continue fighting even after receiving mortal wounds.$B$BBut know this: the guardian''s path is one of sacrifice. You will place yourself between danger and the innocent time and again. You will endure pain so others need not. You will stand alone against impossible odds while others retreat. This is not a burden, but a privilege - to be the shield that never breaks, the wall that never falls.$B$BWelcome to eternal vigilance, $N. Let evil break itself upon your defenses!'),
(53005, 'Shadow accepts you, $N. Now you must prove yourself worthy of Xoroth''s legacy.$B$BThe Knights of Xoroth are living proof that darkness need not mean evil. We have taken shadow, the tool of assassins and demons, and forged it into an instrument of justice. Where paladins wield light openly, we strike from darkness with equal righteousness. As a Knight of Xoroth, you will learn that honor can thrive in shadow, that justice sometimes requires a hidden blade.$B$BYou will master the shadow-forged armor that makes you one with darkness, weapons of pure shadow that strike at the very soul, and movement techniques that allow you to step through shadows across vast distances. But more than mere techniques, you will learn the philosophy of our order - that good and evil are not determined by the forces we wield, but by how we choose to wield them.$B$BOur enemies will never see us coming. Corrupt nobles will choke on shadows in their own bedchambers. Demon cultists will find darkness itself turned against them. Tyrants will learn to fear the very shadows they cast. You will become the thing that evil checks for under its bed, the nightmare that hunts other nightmares.$B$BWelcome to the Knights of Xoroth, $N. Let shadow become justice''s keenest blade!'),
(53006, 'Death yields to you, $N. This is only the beginning of your dominion.$B$BNecromancy is the ultimate expression of power - dominion over death itself. Where others see endings, we see resources. Where others mourn the fallen, we see armies waiting to rise. As a Necromancer, you will command forces that terrify even the bravest warriors, for what army can stand against one that grows stronger with every casualty?$B$BYou will learn to reach across the veil and drag souls back into service, binding them to corpses that become your puppets. Simple skeletons will be just the beginning - you''ll raise death knights from fallen heroes, craft abominations from multiple corpses, and summon bone dragons that darken the sky. The plague will be your herald, spreading death that becomes fresh troops for your armies.$B$BBut necromancy offers more than mere undead servants. You''ll learn to drain life force to heal yourself, to age enemies to dust with a touch, and to step partially into death yourself - becoming immune to pain, fear, and other mortal weaknesses. You will walk in two worlds simultaneously, equally at home among the living and the dead.$B$BWelcome to death''s dominion, $N. Let mortality itself bow before your will!'),
(53007, 'Time acknowledges you, $N. Past, present, and future have taken notice of your potential.$B$BChronomancy is perhaps the most complex of all magical arts, for it deals with forces that most minds cannot properly conceptualize. Time is not the river others believe it to be - it is an ocean with currents, eddies, and depths that can be navigated by those who understand its nature. As a Chronomancer, you will learn to swim against time''s current, to dive into its depths, and to alter its flow.$B$BYou will master temporal acceleration, moving so quickly that others appear frozen. You''ll learn temporal reversal, undoing wounds by reversing personal timestreams. The art of prophecy will be yours - glimpsing possible futures and choosing which ones to make reality. You''ll age objects millennia in seconds, or restore them to pristine condition by reversing their entropy.$B$BBut the true power of chronomancy lies in paradox manipulation. You''ll learn to exist in multiple timestreams simultaneously, to create stable time loops that ensure your victory before battles begin, and even to summon alternate versions of yourself from different timelines. The responsibility is immense - one careless alteration could unravel causality itself.$B$BWelcome to timeless power, $N. Let past, present, and future dance to your design!'),
(53008, 'The eternal flame recognizes a kindred spirit. You burn with potential, $N.$B$BFire was the first magic, the gift that elevated mortals above beasts. But the flames you will command transcend simple burning. As a Pyromancer, you will master fire in all its forms - from the gentle warmth that sustains life to the cosmic infernos that forge stars. Your flames will burn with purpose, discrimination, and terrible beauty.$B$BYou will learn to conjure fire that burns underwater, flames that freeze instead of burn, and pyroblasts that can melt through castle walls. The phoenix''s rebirth will be yours - rising from your own ashes when struck down. You''ll command living fire elementals, create flame barriers that incinerate projectiles, and rain meteors from clear skies. Your mastery will extend to flame''s very essence - manipulating heat at the molecular level, creating explosions from tiny sparks, or focusing fire into beams that cut through anything.$B$BBut beyond destruction, you''ll understand fire''s role in creation. The forge''s flame that shapes metal, the controlled burns that renew forests, the inner fire that drives passion and creativity - all will be yours to kindle or extinguish.$B$BWelcome to the inferno''s heart, $N. Let your flames reshape the world!'),
(53009, 'The wild has claimed you as one of its own, $N. Listen - even now, the beasts acknowledge your presence.$B$BThe ranger''s path is one of primal connection. You will become predator and protector, tracker and survivor, equally at home in civilization''s edges and nature''s heart. The bond between ranger and wild is not mere sentiment - it is a magical compact older than cities, a mutual understanding between kindred spirits.$B$BYou will master tracking techniques that can follow a ghost through fog, archery skills that allow you to put an arrow through a sparrow''s eye at three hundred paces, and survival methods that let you thrive where armies would starve. Beasts will answer your call - from loyal wolves who fight beside you to great eagles who serve as your eyes in the sky. You''ll learn to move through wilderness without disturbing a single leaf, to hide so perfectly that you become one with your surroundings.$B$BMore than skills, you''ll develop instincts. You''ll smell weather changes days before they arrive, sense ambushes before they''re sprung, and read the land like a beloved book. The wild will speak to you in languages only hunters understand - the alarm calls of birds, the nervousness of deer, the territorial markings of predators.$B$BWelcome to the eternal hunt, $N. Let no quarry escape your pursuit!'),
(53010, 'The runes respond to your touch, $N. They recognize one who can shape reality through inscription.$B$BRunic magic predates all other forms of spellcraft. When the universe was young, the first words were carved into the foundations of reality itself, and from these primal runes, all magic flows. As a Runemaster, you will learn to inscribe symbols that carry the weight of creation''s own language, marks that persist when all other magic fails.$B$BYou will master combat runes that turn simple weapons into legendary artifacts, protective wards that can shield entire cities, and reality runes that alter the fundamental laws of physics in their vicinity. Your inscriptions will enhance, corrupt, purify, or destroy as you see fit. A single rune from your hand can grant superhuman strength, curse bloodlines for generations, or create portals between distant locations.$B$BThe art demands precision - a single misplaced stroke can invert a rune''s meaning, turning healing into harm, protection into vulnerability. You''ll learn to inscribe runes on any surface - stone, steel, flesh, even air itself. Master runecrafters can write entire runic arrays that work in concert, creating effects too complex for ordinary magic to achieve.$B$BWelcome to eternal inscription, $N. Let your marks reshape existence!'),
(53011, 'Storm clouds gather at your approach, $N. The tempest has chosen its new voice.$B$BTo command storms is to wield nature''s own fury. Lightning, thunder, wind, and rain - these are not mere weather phenomena, but expressions of primal power that existed before the first mortal drew breath. As a Stormbringer, you will learn to call these forces from clear skies, to speak the language of tempests, and to ride the lightning itself.$B$BYou will summon tornadoes that can level fortresses, call down lightning strikes with pinpoint accuracy, and surround yourself with winds that deflect arrows and spells alike. The eye of the storm will be your sanctuary - a place of perfect calm while chaos rages around you. You''ll learn to transform into living lightning, traveling instantly across battlefields, and to store storm''s fury within yourself, releasing it in devastating bursts.$B$BGreat storms will herald your approach - not by coincidence, but because the atmosphere itself responds to your presence. You''ll read weather patterns like prophecy, sensing disturbances in air pressure that reveal hidden enemies or approaching danger. In time, you may even learn to create permanent storms, tempests that rage for centuries over cursed lands.$B$BWelcome to the storm''s heart, $N. Let thunder announce your victories!'),
(53012, 'The sun''s first ray at dawn has touched you, $N. You carry that light within you now, forever.$B$BSolar magic is the purest expression of divine power accessible to mortals. The sun gives freely - light, warmth, life itself - asking nothing in return. As a Sun Cleric, you will become a conduit for this generosity, channeling radiance that heals, protects, and when necessary, destroys with the fury of a thousand suns.$B$BYou will learn to store sunlight within yourself, becoming a beacon in the darkest places. Your healing light will mend wounds, cure diseases, and even restore life to the recently fallen. Solar shields will protect your allies, while solar flares blind and burn your enemies. The zenith blessing will allow you to call down pillars of concentrated sunlight that can pierce through any darkness, any evil, any shadow.$B$BBut solar magic extends beyond simple light. You''ll understand the sun''s role in all life - photosynthesis in plants, vitamin creation in skin, the circadian rhythms that govern sleep and waking. You''ll learn to accelerate growth, to energize the weary, and to bring the clarity of daylight to confused minds. In your presence, undead wither, shadows flee, and hope kindles in the most desperate hearts.$B$BWelcome to radiant service, $N. Let your light banish all darkness!'),
(53013, 'Your conviction has weight, $N. The Light itself has witnessed your oath and found you worthy.$B$BThe templar''s path combines martial prowess with divine purpose. You are not merely a warrior who happens to have faith - you are faith given form, justice made flesh, righteousness armed and armored. Every strike of your blade carries the weight of divine judgment. Every shield you raise stands as a bulwark against evil itself.$B$BYou will master combat prayers that strengthen your blows and weaken your enemies'' resolve. Holy weapon enchantments will make your arms burn with sacred fire that sears the corrupt while leaving the innocent unharmed. The divine armor technique will surround you with light itself, turning aside both physical and magical attacks. You''ll learn the ancient rites of exorcism, the words that banish demons and cleanse corruption from people, places, and objects.$B$BYour presence will become a rallying point in battle - allies will fight harder knowing a templar stands with them, while enemies will falter before your righteous fury. You''ll develop the ability to sense evil in all its forms, to see through disguises and illusions to the moral truth beneath. In time, you may even learn to call down divine judgment directly - holy fire that burns only the guilty.$B$BWelcome to sacred service, $N. Let justice guide your blade!'),
(53014, 'Gears turn and magic sparks at your touch, $N. You see possibilities where others see impossibility.$B$BThe tinker''s art exists at the intersection of magic and technology, proving that innovation and arcane power need not stand apart. You will build devices that shouldn''t exist, machines that operate on principles that make mockings of natural law, and gadgets that solve problems others consider unsolvable.$B$BYou will learn to craft mechanical minions that think and act independently, explosives that can level city blocks or surgical charges that remove single bricks from walls. Your inventions will include shields that deploy instantly from small devices, weapons that transform between multiple configurations, and detection equipment that can sense through walls, illusions, and even between dimensions. The fusion of magic and machinery will allow you to create perpetual motion machines, devices that generate more energy than they consume, and equipment that repairs and improves itself over time.$B$BYour workshop will become a place of wonders and horrors - mechanical eyes that never blink, steam-powered hearts that never stop, and hybrid creatures that blur the line between construct and living being. You''ll understand not just how to build, but how to innovate, to see connections others miss, to solve problems with creative applications of universal principles.$B$BWelcome to endless innovation, $N. Let your creations redefine what''s possible!'),
(53015, 'The venoms sing to you, $N. Each toxin has its own voice, its own purpose, its own terrible beauty.$B$BVenomancy is the art of transformation through toxicity. Simple poisons that merely kill are child''s play - you will learn to brew venoms that reshape body and mind, that evolve or devolve, that unlock hidden potential or seal away power. Every substance in nature can become a tool in your arsenal, from the deadliest snake venom to the humble bee sting.$B$BYou will master the creation of toxins that work instantly or lie dormant for years, poisons that affect only specific bloodlines or species, and venoms that spread like diseases through entire populations. But destruction is only half your art - you''ll also brew antidotes that can cure any poison, stimulants that grant temporary superhuman abilities, and mutagens that cause permanent beneficial transformations.$B$BYour own body will become a living laboratory. You''ll develop immunity to all known toxins while learning to secrete venoms through your skin, breath, or even your gaze. The most advanced practitioners can poison abstract concepts - corrupting memories, tainting emotions, or toxifying magic itself. You''ll understand the thin line between medicine and poison, how dosage determines whether a substance heals or harms.$B$BWelcome to the poison path, $N. Let chemistry become alchemy in your hands!'),
(53016, 'The spirits whisper your name, $N. They have been waiting for you.$B$BThe witch doctor walks between worlds, equally at home among the living and the dead. You will become a bridge between realms, a speaker for spirits who have no voice, a commander of forces that exist just beyond mortal perception. This ancient art predates civilization itself, born when the first mortals realized that death was not an ending but a transformation.$B$BYou will learn to see and speak with spirits invisible to others, to channel their knowledge and power through your own body. Ancestral spirits will guide your decisions, ghostly warriors will fight at your side, and the wisdom of the ages will flow through you like water. You''ll master hexes that curse enemies with spiritual afflictions, wards that protect against possession, and rituals that can trap or banish even the most powerful spirits.$B$BYour tools will be both primitive and profound - fetishes that house spirit allies, drums that call the dead to dance, and masks that let you assume the aspects of powerful spirit entities. You''ll learn to enter the spirit realm physically, to navigate its strange geography, and to bargain with entities that have never known mortal form. In time, you may even learn to become a living spirit yourself, existing simultaneously in multiple realms.$B$BWelcome to the spirit path, $N. Let the veil between worlds part before you!'),
(53017, 'The hunt begins now, $N. Corruption has a new predator to fear.$B$BThe witch hunter''s burden is heavy but necessary. You will become the blade that cuts out infection, the fire that purifies corruption, the unwavering eye that sees through all deception. Where others might show mercy to the corrupted, you understand that sometimes the kindest cut is the killing blow. Your duty is to protect the innocent by eliminating threats others are too weak or blind to recognize.$B$BYou will master techniques specifically designed to combat the forces of darkness. Silver weapons that burn the corrupted, holy water that reveals hidden evil, and wards that prevent dark magic from taking hold. You''ll develop an almost supernatural sense for detecting corruption - a witch''s curse, a demon''s influence, or the subtle taint of void corruption. Your training will include resistance to mental manipulation, immunity to curses, and the ability to break enchantments with your mere presence.$B$BYou''ll learn to distinguish between harmless hedge wizards and genuine threats, between those who can be redeemed and those who must be eliminated. The witch hunter''s greatest skill is judgment - knowing when to strike and when to stay your hand. You''ll compile knowledge of every form of corruption, creating a mental library of threats and their weaknesses. In time, your very name will become a ward against evil, spoken by parents to protect their children, whispered by the corrupt in fear.$B$BWelcome to the eternal hunt, $N. Let no evil escape your sight!'),
(53201, 'The stars have guided you to me, $N. I sense the cosmic energies stirring within you.$B$BAs a Starcaller, you will command forces that predate mortal civilization. The night sky becomes your grimoire, constellations your spells. You will channel starlight into devastating beams, call down meteor showers upon your enemies, and navigate by stellar winds that carry the whispers of distant galaxies.$B$BThe cosmos is vast and eternal, filled with powers beyond mortal comprehension. Ancient star-gods once wielded these same forces to shape reality itself. Now their knowledge flows through you.$B$BWelcome to stellar mastery. The universe itself bends to your will!'),
(9302412, 'Har! So the priest sent you to me. Good.$B$BThe grave took your breath, $N, but it could not take your anger. A barbarian needs no tricks and no spells. We hit, we roar, and we keep hitting until nothing is left standing.$B$BShow me what that dead heart of yours can still do.'),
(9302413, ''),
(200019, 'A Blood Wizard?$B$BInteresting...$B$BWell, upon further inspection, this tome is worthless. You can have it.$B$BReturn to me in the future when you are stronger. Maybe we can work together again.'),
(200168, 'Welcome back, $N. I knew you would find my wand in time. Literally.$B$BThis wand is for you. I hope it serves you well. In fact, I know it will.'),
(200075, ''),
(200140, ''),
(200141, ''),
(200142, ''),
(200035, 'Good, good. He is dealt with.$B$BHe deserved death, and there will be many more who do as well.$B$BAs a token of your bloody success, I present to you a powerful piece of equipment, forged in helfire. Lok''tar ogar, or something. Aha!'),
(200052, '<The ritual circle pulsates with necromantic energy>'),
(200053, '<The ritual circle begins to erupt. The monster is being summoned>'),
(200054, 'Well, that''s exactly what I thought would happen.$B$BBut, hey, you didn''t die. You''re a better Necromancer already!$B$BHere, I sent my other apprentices to gather the scraps from your battle, they made this.$B$BTake it and get out of my sight.'),
(200145, ''),
(200011, 'This seems to be the falcon in question, and it seems injured.'),
(200012, 'The falcon seems distraught. It must have been the suspicious creature who attacked it!'),
(200013, 'Thank you for finding Felo. He has already returned to me, healthy as ever.$B$BI''ve already sent him on yet another scouting mission.$B$B... you''re saying a strange creature was seen near Felo and that it attacked you? That must have been the creature that injured my boy.$B$BI''ll have to look into this more. Based on your description, whatever this is, it''s not native to Tirisfal Glades.'),
(200039, 'You may not have expected such a task, $N. But it is important to understand that the Shadowlands call for those who are ready, and knowing when to claim a soul can be just as important as the reclamation of the soul itself.$B$BFor helping our friend out here, I will reward you with these boots. May they serve you well, as they are enchanted to allow you to walk on the surface of water itself.'),
(200113, ''),
(200033, 'Elune''s grace radiates from you, $N. The goddess is pleased.$B$BI have two weapons for you to choose from, blessed by Elune.$B$BGo forth as Elune''s Chosen. We will meet again.'),
(200098, ''),
(200099, ''),
(200100, ''),
(200062, 'One good deed deserves another, $N.'),
(200081, ''),
(200069, ''),
(200024, 'I know you''re wondering why I had you do this.$B$BIn due time, you will learn.$B$BThere is nothing else to worry about now. I''ve made you a similar concoction, take it with you, and use it wisely.$B$BFarewell, $N.'),
(200023, 'You may be wondering why I had you retrieve this skull.$B$BDemon skulls are often vessels of immense fel power. Today, I give this to you.$B$BHowever, if you prefer, I can infuse the power of this skull into a powerful sword.$B$BThe choice is yours, whatever it may be, it will serve you well.'),
(200057, 'Yet another evil creature banished from our world.$B$B... and yet.$B$BStill so many others to destroy. Be vigilant.$B$BHere, take these, let them guide you in your battles with evil.');

DELETE FROM `quest_request_items` WHERE `ID` IN (53000, 53001, 53002, 53003, 53004, 53005, 53006, 53007, 53008, 53009, 53010, 53011, 53012, 53013, 53014, 53015, 53016, 53017, 53201, 200011, 200012, 200013, 200019, 200023, 200024, 200033, 200035, 200039, 200052, 200053, 200054, 200057, 200062, 200069, 200075, 200081, 200098, 200099, 200100, 200113, 200140, 200141, 200142, 200145, 200168, 9302412, 9302413);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(53000, 'I can sense the fury building within you, $N. Have you brought the Fury Tablet? The path of endless rage awaits those strong enough to walk it.'),
(53001, 'The scent of blood magic clings to you, $N. Have you brought the Crimson Scroll? The crimson arts reveal themselves only to the worthy.'),
(53002, 'The void whispers your name, $N. Have you brought the Void Manuscript? Ancient powers stir at your approach.'),
(53003, 'Fel energy crackles around you, $N. Have you brought the Fel Contract? The demons grow restless for a new pact.'),
(53004, 'Your determination to protect others precedes you, $N. Have you brought the Guardian Oath? The path of the eternal defender awaits.'),
(53005, 'Shadow clings to you like a second skin, $N. Have you brought the Shadow Decree? The Knights of Xoroth await their newest member.'),
(53006, 'Death''s chill follows in your wake, $N. Have you brought the Death Codex? The secrets of necromancy await the worthy.'),
(53007, 'Time itself bends around you, $N. Have you brought the Temporal Scroll? The chronometer senses your potential.'),
(53008, 'The smell of smoke and ash announces you, $N. Have you brought the Seared Tome? The eternal flame seeks a new master.'),
(53009, 'The wild has marked you as its own, $N. Have you brought the Hunter''s Guide? The beasts sense a kindred spirit.'),
(53010, 'Runic power emanates from you, $N. Have you brought the Runic Tablet? The ancient inscriptions await your hand.'),
(53011, 'Storm clouds gather at your presence, $N. Have you brought the Storm Manuscript? The tempest calls to its new master.'),
(53012, 'Divine radiance illuminates your path, $N. Have you brought the Solar Scripture? The sun''s blessing awaits the faithful.'),
(53013, 'Your commitment to justice is palpable, $N. Have you brought the Sacred Vow? The Light seeks a new champion.'),
(53014, 'The spark of innovation burns within you, $N. Have you brought the Mechanical Schematic? Gears and magic await your genius.'),
(53015, 'The scent of exotic venoms precedes you, $N. Have you brought the Venom Formula? Transformation through toxins awaits.'),
(53016, 'The spirits whisper of your arrival, $N. Have you brought the Spirit Fetish? The other side beckons.'),
(53017, 'Righteous determination burns in your eyes, $N. Have you brought the Inquisitor''s Letter? The hunt for corruption never ends.'),
(53201, 'Greetings, $N. Have you something for me?'),
(9302412, 'You reek of grave-dirt and anger, $N. Is that my tablet you carry?'),
(9302413, ''),
(200019, 'Impressive. Who did you say had this tome again?'),
(200168, 'Ahh, you''ve returned.'),
(200075, ''),
(200140, ''),
(200141, ''),
(200142, ''),
(200035, ''),
(200052, ''),
(200053, '<You place the ingredients on the ritual circle>'),
(200054, ''),
(200145, ''),
(200011, ''),
(200012, ''),
(200013, 'You have done a great deed today by finding Felo. Thank you.'),
(200039, ''),
(200113, ''),
(200033, ''),
(200098, ''),
(200099, ''),
(200100, ''),
(200062, 'Have you found the pendant yet, $N?'),
(200081, ''),
(200069, ''),
(200024, 'Welcome back. Have you done what I asked?'),
(200023, 'Good find.'),
(200057, 'You have returned.');

DELETE FROM `creature_queststarter` WHERE `quest` IN (53000, 53001, 53002, 53003, 53004, 53005, 53006, 53007, 53008, 53009, 53010, 53011, 53012, 53013, 53014, 53015, 53016, 53017, 53201, 200011, 200012, 200013, 200019, 200023, 200024, 200033, 200035, 200039, 200052, 200053, 200054, 200057, 200062, 200069, 200075, 200081, 200098, 200099, 200100, 200113, 200140, 200141, 200142, 200145, 200168, 9302412, 9302413);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(1569, 53000),
(1569, 53001),
(1569, 53002),
(1569, 53003),
(1569, 53004),
(1569, 53005),
(1569, 53006),
(1569, 53007),
(1569, 53008),
(1569, 53009),
(1569, 53010),
(1569, 53011),
(1569, 53012),
(1569, 53013),
(1569, 53014),
(1569, 53015),
(1569, 53016),
(1569, 53017),
(1569, 53201),
(1569, 9302412),
(502951, 9302413),
(502922, 200019),
(502822, 200168),
(502833, 200075),
(50279, 200140),
(50293, 200141),
(50293, 200142),
(9300250, 200035),
(502930, 200052),
(50293, 200145),
(50281, 200011),
(9300253, 200012),
(9300253, 200013),
(502891, 200039),
(502913, 200113),
(502850, 200033),
(502773, 200098),
(502873, 200099),
(502873, 200100),
(50327, 200062),
(502803, 200081),
(502873, 200069),
(650688, 200024),
(50276, 200023),
(50275, 200057);

DELETE FROM `creature_questender` WHERE `quest` IN (53000, 53001, 53002, 53003, 53004, 53005, 53006, 53007, 53008, 53009, 53010, 53011, 53012, 53013, 53014, 53015, 53016, 53017, 53201, 200011, 200012, 200013, 200019, 200023, 200024, 200033, 200035, 200039, 200052, 200053, 200054, 200057, 200062, 200069, 200075, 200081, 200098, 200099, 200100, 200113, 200140, 200141, 200142, 200145, 200168, 9302412, 9302413);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(502891, 53000),
(502922, 53001),
(502833, 53002),
(50276, 53003),
(50279, 53004),
(9300250, 53005),
(502930, 53006),
(502822, 53007),
(50293, 53008),
(50281, 53009),
(502913, 53010),
(502773, 53011),
(50327, 53012),
(502803, 53013),
(502873, 53014),
(650688, 53015),
(9300251, 53016),
(50275, 53017),
(502850, 53201),
(502951, 9302412),
(502951, 9302413),
(502922, 200019),
(502822, 200168),
(502833, 200075),
(50293, 200140),
(50293, 200141),
(50279, 200142),
(9300250, 200035),
(502930, 200054),
(50293, 200145),
(9300253, 200011),
(9300253, 200012),
(50281, 200013),
(502891, 200039),
(502913, 200113),
(502850, 200033),
(502873, 200098),
(502873, 200099),
(502773, 200100),
(50327, 200062),
(502803, 200081),
(502873, 200069),
(650688, 200024),
(50276, 200023),
(50275, 200057);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (200053, 200054);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(9301250, 200053),
(9301250, 200054);

DELETE FROM `gameobject_questender` WHERE `quest` IN (200052, 200053);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(9301250, 200052),
(9301250, 200053);

-- Map markers where the text promises them: "Let me mark your map to the location of where my ritual must be
--   had" (200052) and "I've marked her location on your map" (200057).
DELETE FROM `quest_poi` WHERE `QuestID` IN (200052, 200057);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200052, 0, 0, 0, 20, 0, 0, 1),
(200057, 0, 0, 0, 20, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200052, 200057);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200052, 0, 0, 1756, 1590),
(200057, 0, 0, 1826, 1566);

-- ---------------------------------------------------------------------------
-- 6. Letter and chain item pages
-- ---------------------------------------------------------------------------
DELETE FROM `page_text` WHERE `ID` IN (10201, 11112, 15000, 15001, 15002, 15003, 15004, 15005, 15006, 15007, 15008, 15009, 15010, 15011, 15012, 15013, 15014, 15015, 15016, 15017, 25151, 27575, 931412);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`)
VALUES
(10201, 'The cosmos calls to those who would command stellar power.$B$BThe stars themselves hold infinite knowledge and energy waiting to be harnessed. As a Starcaller, you will channel celestial forces with perfect clarity, drawing power from distant galaxies and cosmic phenomena.$B$BSeek me in Deathknell, and I will teach you to command the eternal stars.$B$BLandralanis$BStarcaller Trainer', 0),
(11112, 'If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.', 0),
(15000, 'Fury does not die with the body. For those who have walked through the grave and returned, rage becomes a cold and patient thing, sharpened on the whetstone of death.$B$BAs an undead reaper, you will learn to harvest the souls of the living and to walk the thin road between this world and the next. What others fear, you will bring.$B$BUndertaker Chite teaches the reaper''s way in Deathknell. Find him among the graves.', 0),
(15001, 'Blood magic takes on new meaning for those who no longer possess living blood. The crimson arts flow through ichor and shadow, drawing power from the very essence of undeath.$B$BAs an undead blood mage, you will learn to manipulate the dark vitality that animates your form, turning your unlife into a weapon of devastating magical force. Death becomes your greatest ally in the pursuit of power.$B$BSanguinis the Bloodkeeper has mastered these forbidden techniques in Deathknell. Seek her to learn the blood magic of the damned.', 0),
(15002, 'The whispers of the Old Ones call especially loudly to those who have crossed the threshold of death. The cultist''s communion with ancient powers becomes clearer when viewed from beyond the grave.$B$BAs an undead cultist, you will serve as a bridge between the world of the living and the realm of ancient entities. Your undeath makes you a perfect vessel for powers that mortal minds cannot comprehend.$B$BMaleficus the Voidcaller communes with these forces in Deathknell. Find him if you would hear the whispers that death makes audible.', 0),
(15003, 'The fel does not frighten those who have already tasted death. Its fire burns in the hollow places the grave left behind, and it answers the will of those bold enough to bind it.$B$BAs a Felsworn, you will walk the border between mortal and demon, drawing on fel power without falling to it.$B$BDar''danis commands these dark powers in Deathknell. Seek him in the chapel.', 0),
(15004, 'The guardian''s oath transcends life and death. Even in undeath, the sacred duty to protect others burns eternal, perhaps burning brighter for having survived the grave.$B$BAs an undead guardian, you will become a fortress of bone and will, your defensive magic powered by the determination that death could not break. Your protection extends to both the living and the dead.$B$BCaptain Durgen maintains this sacred vigil in Deathknell. Seek him to learn how the guardian''s duty survives even death.', 0),
(15005, 'By the seal of Xoroth: honor outlives the flesh. The Knights of Xoroth wear a mortal visage and serve a purpose older than any kingdom of the living.$B$BAs a Knight of Xoroth, you will learn to wield the cold darkness of the Twisting Nether behind a shield of noble bearing.$B$BBrallmular upholds these dark oaths in Deathknell. Find him at the graveyard gate.', 0),
(15006, 'Those who have died and risen know the path between life and death better than any living scholar. The art of commanding the dead comes naturally to such as you.$B$BAs an undead necromancer, you will raise servants from bone and grave-dirt and bend them to your will.$B$BDornall Plagueweaver masters these arts in Deathknell. Seek him in the graveyard.', 0),
(15007, 'Time is a river, and most are carried by it. A chronomancer learns to wade against the current, to slow a heartbeat or hasten a blade.$B$BAs a Chronomancer, you will bend the sands of time and space to your purpose, and learn the patience such power demands.$B$BQuardormi bends time and space in Deathknell. Seek him on the upper floor of the inn.', 0),
(15008, 'Death cannot extinguish the pyromancer''s flame. It only transforms it into a cold fire that consumes without warmth.$B$BAs an undead pyromancer, you will command flames that answer to your will rather than to the heat of a living heart.$B$BCadmus Emberblaze commands these deathly fires in Deathknell. Seek him in the inn.', 0),
(15009, 'The ranger''s connection to nature deepens in undeath, but takes on darker aspects. You track not just the living, but the undead, the spirits, and the things that should not be.$B$BAs an undead ranger, you will move through shadow as easily as woodland, your senses attuned to both the natural world and the realm of death. Your falcon companion may be skeletal, but its loyalty remains absolute.$B$BRanger Valeth stalks through shadow in Deathknell. Find her to learn the dark arts of the death-touched tracker.', 0),
(15010, 'Runes outlast the hands that carve them. The runemaster''s inscriptions endure long after the flesh has rotted away.$B$BAs an undead runemaster, you will carve power into stone, steel and bone, and learn to call on it in battle.$B$BWilhelm Balthier carves these eternal symbols in Deathknell. Seek him in the chapel.', 0),
(15011, 'The storm carries the voices of the dead. Its winds howl with the fury of lost souls, and its lightning answers those who have nothing left to fear.$B$BAs an undead stormbringer, you will call down spectral lightning and ride the tempest.$B$BDabbert Staze commands these ghostly storms in Deathknell. Seek him in the inn.', 0),
(15012, 'Even beyond the veil of death, the sun''s light can be channelled. Sacred light filtered through undeath becomes something both beautiful and terrible.$B$BAs a Sun Cleric, you will carry the radiance of the sun to heal your allies and burn your foes.$B$BSunspeaker Talethia maintains this paradoxical faith in Deathknell. Seek her in the chapel.', 0),
(15013, 'Holy vows bind even beyond the grave. The templar''s dedication to justice transcends life and death, and creates champions who serve righteousness in undeath.$B$BAs a Templar, you will master the precise control of body and mind that the Light demands of its highest order.$B$BVaelion Grandbell upholds these sacred duties in Deathknell. Seek him beside the chapel.', 0),
(15014, 'Innovation takes on new dimensions when freed from the constraints of mortality. Your inventions run on soul energy rather than steam, machinery that bridges the gap between magic and mechanics.$B$BAs an undead tinker, you will create devices powered by necromantic energy, inventions that serve both the living and the dead. Death brings new perspectives to the art of creation.$B$BEngineer Mortis creates these marvels in Deathknell. Seek him to learn how undeath opens new frontiers in invention.', 0),
(15015, 'The venomancer''s art reaches its ultimate expression in undeath. Your intimate knowledge of decay and corruption allows you to brew toxins of unprecedented potency while creating cures that work beyond death itself.$B$BAs an undead venomancer, you will master poisons that can affect both living and undead targets, your antidotes carrying the power to heal wounds that should be fatal. Death has taught you the ultimate lesson in toxicology.$B$BApothecary Kelan brews these deadly compounds in Deathknell. Learn from him how death perfects the balance between poison and cure.', 0),
(15016, 'The spirits do not rest in Tirisfal. They whisper in the dead trees and linger over every grave, and the witch doctor hears them all.$B$BAs a Witch Doctor, you will bridge life and death through fetish and ritual, hexing your foes and mending your friends.$B$BShadow-Walker Voss practices these mystical arts in Deathknell. Seek him at the south end of the village.', 0),
(15017, 'The hunt for corruption takes on new meaning when pursued by one who has experienced the ultimate corruption and emerged purified by death itself. The undead witch hunter understands evil intimately.$B$BAs an undead witch hunter, you will track supernatural threats with the authority of one who has crossed death''s threshold. Your blessed weapons will strike down the unholy, your knowledge of darkness used to protect the innocent from the very forces that once claimed you.$B$BBailey Horrorhate continues the eternal crusade in Deathknell. Seek him to learn how death transforms the hunt against evil into something far more relentless and pure.', 0),
(25151, 'Blood is life. Blood is power.$B$BThe crimson arts teach that the essence which flows through every living body may be drawn out, shaped and turned against its owner. Those who master it need neither steel nor fire.', 0),
(27575, 'I have no lid, yet I never sleep.$BI judge what is fair without a word.$BBeauty, they say, was never in the thing at all, but always in me.$B$BWhat am I? Look within these walls.', 0),
(931412, 'Death does not cool a barbarian''s blood. It only silences the pain that once told the body to stop.$B$BAs an undead barbarian, you will fight with the fury of the living and the endurance of the dead, and break your foes with strength alone.$B$BAlessia teaches the barbarian''s way in Deathknell. Find her at the south end of the street, across from the chapel door.', 0);

-- 9302412 Grave-Etched Tablet: the Barbarian letter item, with the look and flags of the Fury Tablet 9200570
--   (SOURCED-CACHE itemcache).
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `ItemLevel`, `maxcount`, `stackable`, `bonding`, `description`, `PageText`, `Material`)
VALUES
(9302412, 12, 0, 'Grave-Etched Tablet', 3108, 1, 0, 0, 1, 1, 1, 'A slab of broken headstone gouged with war-runes by a heavy hand.', 931412, 0)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `ItemLevel` = VALUES(`ItemLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`), `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `PageText` = VALUES(`PageText`), `Material` = VALUES(`Material`);

-- ---------------------------------------------------------------------------
-- 7. Loot
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((9300252, 661316), (9300254, 662331), (1502, 458421), (1502, 458422), (1502, 458423), (1890, 661417), (1506, 662330));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9300252, 661316, 0, 100, 1, 1, 0, 1, 1, 'Suspicious Blood Elf - Tome of Blood (the quest''s holder, INFERRED 100%)'),
(9300254, 662331, 0, 100, 1, 1, 0, 1, 1, 'Scorch - Heart of Scorch (unique, INFERRED 100%)'),
(1502, 458421, 0, 55, 1, 1, 0, 1, 1, 'Wretched Ghoul - Bones (SOURCED-EXILES 55%)'),
(1502, 458422, 0, 35, 1, 1, 0, 1, 1, 'Wretched Ghoul - Fresh Flesh (SOURCED-EXILES 35%)'),
(1502, 458423, 0, 45, 1, 1, 0, 1, 1, 'Wretched Ghoul - Skull (SOURCED-EXILES 45%)'),
(1890, 661417, 0, 33, 1, 1, 0, 1, 1, 'Rattlecage Skeleton - Power Core (SOURCED-EXILES 33%)'),
(1506, 662330, 0, 33, 1, 1, 0, 1, 1, 'Scarlet Convert - Small Sword (SOURCED-EXILES 33%)');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((9300252, 0), (9300254, 0), (1502, 0), (1502, 1), (1502, 2), (1890, 1), (1506, 1));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(9300252, 0, 661316),
(9300254, 0, 662331),
(1502, 0, 458421),
(1502, 1, 458422),
(1502, 2, 458423),
(1890, 1, 661417),
(1506, 1, 662330);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9301252, 9301253, 9301254, 9301255, 9301256);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9301252, 661335, 0, 100, 1, 1, 0, 1, 1, 'CoA Deathknell: Training Wand'),
(9301253, 661330, 0, 100, 1, 1, 0, 1, 1, 'CoA Deathknell: Eye of the Beholder'),
(9301254, 663319, 0, 100, 1, 1, 0, 1, 1, 'CoA Deathknell: Lost Pendant'),
(9301255, 663320, 0, 100, 1, 1, 0, 1, 1, 'CoA Deathknell: Scrap Metal'),
(9301256, 661321, 0, 100, 1, 1, 0, 1, 1, 'CoA Deathknell: Skull of Pax');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (9301252, 9301253, 9301254, 9301255, 9301256);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(9301252, 0, 661335),
(9301253, 0, 661330),
(9301254, 0, 663319),
(9301255, 0, 663320),
(9301256, 0, 661321);

-- ---------------------------------------------------------------------------
-- 8. Spawns
-- ---------------------------------------------------------------------------

-- Maquell Ebonwood 2315 (guid 31916) path: the inn turnaround (1861.98, 1563.01) was 0.69 yd from Cadmus
--   Emberblaze's sourced post (53008). He now turns on the open floor 7.8 yd inside the front door, 3.4 yd from
--   Archibald Kava and 7.8 yd from Cadmus; both legs from the door are clear of walls and pass every NPC at 3.4
--   yd or more.
UPDATE `waypoint_data` SET `position_x` = 1862.0, `position_y` = 1571.0, `position_z` = 94.314 WHERE `id` = 319160 AND `point` = 4;
-- Deathguard Phillip 1739 (guid 28705) path: both legs through the east turnaround (1893.23, 1586.92) pass
--   0.3-0.4 yd from Marla's Grave at its CoA point (ST6961). He now turns 1.9 yd further south on the same open
--   street, so both legs pass 1.5 yd from the grave, 3.3 yd from Deathguard Bradforth and 4.6 yd from Deathguard
--   Randolph.
UPDATE `waypoint_data` SET `position_x` = 1893.2, `position_y` = 1585.0, `position_z` = 88.312 WHERE `id` = 287050 AND `point` = 5;

DELETE FROM `creature` WHERE `guid` IN (9003700, 9003701, 9003702, 9003703, 9003704, 9003705, 9003706, 9003707, 9003708, 9003709, 9003710, 9003711, 9003712, 9003713, 9003714, 9003715, 9003716, 9003717, 9003718, 9003719, 9003720, 9003721, 9003722, 9003723, 9003724, 9003725, 9003726, 9003727, 9003728, 9003729) OR `guid` BETWEEN 9003700 AND 9003899;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9003700, 50276, 0, 0, 0, 1, 1, 1, 1839.63, 1645.13, 97.628, 5.07, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Dar''danis, Felsworn trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53003, z from surface.floor. Faces 5.07 toward the nave and the chapel door the letter-bearers walk in by, clear 15 yd'),
(9003701, 50275, 0, 0, 0, 1, 1, 1, 1849.52, 1563.24, 94.859, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Bailey Horrorhate, Witch Hunter trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53017, z from surface.floor. Faces 1.60 west down the lane to the street and the mailbox by the chapel door; the stock-derived 2.88 faced the farmhouse wall 4.6 yd away'),
(9003702, 502773, 0, 0, 0, 1, 1, 1, 1859.99, 1556.58, 94.789, 1.55, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Dabbert Staze, Stormbringer trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53011, z from surface.floor. Faces 1.55 toward the inn''s front door (1860, 1577), 15 yd of open floor'),
(9003703, 9300250, 0, 0, 0, 1, 1, 1, 1876.2, 1611, 93.979, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Brallmular, Knight of Xoroth trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53005, z from surface.floor. Faces 3.80 down the street toward the chapel door players come from, open 9-15 yd; the stock-derived 4.71 faced across the street away from the approach'),
(9003704, 50279, 0, 0, 0, 1, 1, 1, 1881.26, 1589.64, 89.973, 2.76, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Deathguard Bradforth, Guardian trainer. Deathknell: hand-placed (INFERRED) north gate, 1.6 yd west of his SuperTrack post (53004), which is 2.3 yd from Marla''s Grave at its CoA point (ST6961); now 3.7 yd from the grave, 3.3 yd from the Deathguard patrol and 5.1 yd from the Wretched Ghoul''s turnaround, inspected with inspect_area and passing surface.check. Faces 2.76 toward the mailbox and chapel door at the far end of the street'),
(9003705, 502803, 0, 0, 0, 1, 1, 1, 1864.39, 1614.29, 95.617, 3.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Vaelion Grandbell, Templar trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53013, z from surface.floor. Faces 3.40 toward the chapel door and mailbox players come from; the stock-derived 4.69 faced across the street'),
(9003706, 502922, 0, 0, 0, 1, 1, 1, 1849.53, 1631.43, 96.933, 3.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Irina Valreed, Bloodmage trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53001, z from surface.floor. Faces 3.30 into the nave toward the door, as Dark Cleric Duesten beside her does'),
(9003707, 50281, 0, 0, 0, 1, 1, 1, 1886.79, 1646.3, 92.426, 3.91, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Gustaf Blightflight, Ranger trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53009, z from surface.floor. Faces 3.91 toward the mailbox and chapel door across the graveyard'),
(9003708, 502822, 0, 0, 0, 1, 1, 1, 1863.5, 1567.95, 99.071, 1.25, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Quardormi, Chronomancer trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53007, z from surface.floor. Faces 1.25 toward the head of the stairs players climb (1866.5, 1576); the stock-derived 2.28 turned his back on them'),
(9003709, 502930, 0, 0, 0, 1, 1, 1, 1885.34, 1620.71, 94.043, 3.44, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Dornall Plagueweaver, Necromancer trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53006, z from surface.floor. Faces 3.44 toward the mailbox and chapel door from the graveyard'),
(9003710, 50293, 0, 0, 0, 1, 1, 1, 1862.66, 1563.19, 94.311, 1.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Cadmus Emberblaze, Pyromancer trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53008, z from surface.floor. Faces 1.80 toward the inn''s front door, 13.8 yd of open floor'),
(9003711, 502833, 0, 0, 0, 1, 1, 1, 1861.02, 1625.68, 95.621, 5.11, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Thaddeus Voidseeker, Cultist trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53002, z from surface.floor. Faces 5.11 east-north-east past the hearse at his side (1.2 yd south) to the street, clear 15 yd'),
(9003712, 502850, 0, 0, 0, 1, 1, 1, 1855.68, 1568.99, 99.083, 0.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Landralanis, Starcaller trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53201, z from surface.floor. Faces 0.60 toward the head of the stairs players climb (1866.5, 1576), 11-14 yd clear'),
(9003713, 50327, 0, 0, 0, 1, 1, 1, 1837.4, 1627.78, 96.933, 6.05, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Sunspeaker Talethia, Sun Cleric trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53012, z from surface.floor. Faces 6.05 across the nave toward the door, as the stock NPCs of the south aisle face; the stock-derived 0.66 faced the altar end'),
(9003714, 502873, 0, 0, 0, 1, 1, 1, 1842.78, 1574.23, 96.582, 2.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Riley Jett, Tinker trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53014, z from surface.floor. Faces 2.30 toward the farmhouse door (1840, 1577) 3 yd away; the stock-derived 2.91 faced the butcher''s table'),
(9003715, 650688, 0, 0, 0, 1, 1, 1, 1876.2, 1569.7, 94.314, 2.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Apothecary Kelan, Venomancer trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53015, z from surface.floor. Faces 2.75 toward the inn''s front door, 15 yd open'),
(9003716, 502891, 0, 0, 0, 1, 1, 1, 1870.29, 1635.95, 95.484, 5.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Undertaker Chite, Reaper trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53000, z from surface.floor. Faces 5.30 toward the graveyard gate players enter by, his open grave and dirt mound in front of him; the wheelbarrow at his side blocks the other approach'),
(9003717, 502913, 0, 0, 0, 1, 1, 1, 1847.92, 1641.24, 97.628, 4.01, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Wilhelm Balthier, Runemaster trainer. Deathknell: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 53010, z from surface.floor. Faces 4.01 down the nave toward the door, past Novice Elreth'),
(9003718, 9300251, 0, 0, 0, 1, 1, 1, 1835.5, 1598.5, 95.254, 0.85, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Shadow-Walker Voss, Witch Doctor trainer. Deathknell: hand-placed (INFERRED) south end of the street, west side, in front of the chapel''s south-east corner: the empty part of the village, 9 yd from both guard patrol lines, inspected with inspect_area and passing surface.check. Faces 0.85 toward the chapel door (1843, 1607.5) where players leave with their letters'),
(9003719, 502951, 0, 0, 0, 1, 1, 1, 1838, 1583.5, 94.395, 1.37, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Alessia, Barbarian trainer. Deathknell: hand-placed (INFERRED) south end of the street, east side, in front of the farmhouse, across the street from Shadow-Walker Voss; 2.1 yd west of Maquell Ebonwood''s walk into the farmhouse, 5 yd from the Deathguard patrol, inspected with inspect_area and passing surface.check. Faces 1.37 across the street to the chapel door players leave with their letters'),
(9003720, 299240, 0, 0, 0, 1, 1, 1, 1863.2, 1556.3, 94.793, 2.5, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Deathknell inn (the two-storey house), ground floor: the stock warrior trainer Dannal Stern''s alcove, 0.75 yd from his post and 3.2 yd from Dabbert Staze; the stock spawn (guid 28464) stood 2.48 yd from Dabbert''s sourced point, so the kill copy replaces it. Stock facing'),
(9003721, 299226, 0, 0, 0, 1, 1, 0, 1915, 1596, 83.835, 3.6, 60, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Deathknell, the field north of the village exit where the risen wander, running amok among the Mindless Zombies'),
(9003722, 9300252, 0, 0, 0, 1, 1, 1, 1898, 1573.5, 89.074, 0, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: abandoned farmhouses north-east of Deathknell, south house, rummaging at the Shadowfang table'),
(9003723, 9300252, 0, 0, 0, 1, 1, 1, 1903.5, 1553, 88.964, 1.57, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: abandoned farmhouses north-east of Deathknell, north house, rummaging at the Shadowfang table'),
(9003724, 9300253, 0, 0, 0, 1, 1, 0, 1923.5, 1697, 86.623, 4.15, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: north-west of Deathknell: perched injured at the wrecked wagon CoA placed there (Badlandssunkenwagon.m2), facing south-east back toward the village he flew from and the player coming from Gustaf (bearing 4.09) and the street (4.13), clear for 10 yd; the wagon and the rising ground are behind him'),
(9003725, 9300255, 0, 0, 0, 1, 1, 0, 1860.3, 1556.2, 99.727, 1.57, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Deathknell inn (the two-storey house), upper floor: lying in the canopy bed CoA furnished (Innbedcanopy and three Innpillow models), head on the pillows'),
(9003726, 9300256, 0, 0, 0, 1, 1, 0, 1826, 1566, 95.623, 1.25, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: Deathknell, the shadowed nook behind the dead canopy tree by the south gate torch, watching the street'),
(9003727, 685034, 0, 0, 0, 1, 1, 0, 1913, 1728, 99.976, 0, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: north-west of Deathknell: at the foot of the Elune statue with pilgrim candles (Diremaulstonestatue04.m2, CoA-only) on the side that faces the village'),
(9003728, 685037, 0, 0, 0, 1, 1, 0, 1845, 1778.5, 122.244, 0, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: western mountains: in the hidden gully west of the village, before the paladin statue'),
(9003729, 9300257, 0, 0, 0, 1, 1, 1, 1898.5, 1597, 87.587, 3.73, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Deathknell: outside the north gate, below the graveyard''s east lantern post, glaring back at the gate he was turned away from');

DELETE FROM `creature_addon` WHERE `guid` = 9003725 OR `guid` BETWEEN 9003700 AND 9003899;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9003725, 0, 0, 3, 1, 0, 0, NULL);

DELETE FROM `gameobject` WHERE `guid` IN (7912400, 7912401, 7912402, 7912403, 7912404, 7912405, 7912406, 7912407, 7912408, 7912409, 7912410, 7912411, 7912412, 7912413, 7912414, 7912415, 7912416, 7912417, 7912418, 7912419, 7912420, 7912421) OR `guid` BETWEEN 7912400 AND 7912499;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912400, 9301250, 0, 0, 0, 1, 1, 1756, 1590, 111.813, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: hills south of Deathknell: before the two tombstone monuments where CoA lit four candles (CoA-only Candle01.m2)'),
(7912401, 9301251, 0, 0, 0, 1, 1, 1793, 1662, 112.677, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: the hills south-west of Deathknell: the sheltered hollow between the two knolls'),
(7912402, 9301252, 0, 0, 0, 1, 1, 1836, 1575, 97.488, 1.2, 0, 0, 0.564642, 0.825336, 60, 100, 1, '', 'CoA Deathknell: the farmhouse next door to the inn: on the butcher''s table'),
(7912403, 9301253, 0, 0, 0, 1, 1, 1858.3, 1572.2, 95.2, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: Deathknell inn (the two-storey house), ground floor: on the table by the hearth'),
(7912404, 9301253, 0, 0, 0, 1, 1, 1864.25, 1554.62, 100.011, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: Deathknell inn (the two-storey house), upper floor: on the free west half of the small table, clear of the candelabra and the book stack'),
(7912405, 9301254, 0, 0, 0, 1, 1, 1803, 1378, 81.192, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, north edge, on the way she fled toward Deathknell'),
(7912406, 9301254, 0, 0, 0, 1, 1, 1822, 1410, 80.221, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, further north toward Deathknell, in the dip below the camp where she ran'),
(7912407, 9301256, 0, 0, 0, 1, 1, 1864, 1531.5, 88.542, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: abandoned barn south-east of Deathknell: set among the sacks beside the dead mule'),
(7912408, 9301256, 0, 0, 0, 1, 1, 1945, 1536, 90.165, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Deathknell: abandoned smithy east of Deathknell: on the smithy floor by the cold forge (the ground outside the back wall is a walled-off pocket with no path)'),
(7912409, 9301257, 0, 0, 0, 1, 1, 1847.5, 1778.5, 122.06, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Deathknell: western mountains: the hidden gully west of the village behind the knoll, below the fallen tree; faces north to the gully mouth'),
(7912410, 9301255, 0, 0, 0, 1, 1, 1761, 1388, 93.93, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, inside the tent, in the middle under the canvas'),
(7912411, 9301255, 0, 0, 0, 1, 1, 1759.5, 1389.5, 94.486, 2.1, 0, 0, 0.867423, 0.497571, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, inside the tent, back corner'),
(7912412, 9301255, 0, 0, 0, 1, 1, 1762.5, 1386.5, 93.309, 5.2, 0, 0, 0.515501, -0.856889, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, inside the tent, by the flap'),
(7912413, 9301255, 0, 0, 0, 1, 1, 1766.5, 1385.5, 92.609, 1.3, 0, 0, 0.605186, 0.796084, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, at the tent mouth by the lantern and goblet'),
(7912414, 9301255, 0, 0, 0, 1, 1, 1767, 1390.5, 93.751, 3.6, 0, 0, 0.973848, -0.227202, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, north corner of the tent'),
(7912415, 9301255, 0, 0, 0, 1, 1, 1763, 1395.5, 95.189, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, behind the tent, west side'),
(7912416, 9301255, 0, 0, 0, 1, 1, 1758, 1395, 95.784, 4.4, 0, 0, 0.808496, -0.588501, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, behind the tent, south-west corner'),
(7912417, 9301255, 0, 0, 0, 1, 1, 1754.5, 1390, 95.814, 2.7, 0, 0, 0.975723, 0.219007, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, south side of the tent'),
(7912418, 9301255, 0, 0, 0, 1, 1, 1754.5, 1384, 94.454, 5.9, 0, 0, 0.190423, -0.981702, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, south-east of the tent'),
(7912419, 9301255, 0, 0, 0, 1, 1, 1758.5, 1381, 92.511, 1.8, 0, 0, 0.783327, 0.62161, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, east of the tent, beside the path'),
(7912420, 9301255, 0, 0, 0, 1, 1, 1769, 1385.5, 92.444, 4, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, between the tent and Meven Korgal'),
(7912421, 9301255, 0, 0, 0, 1, 1, 1770, 1394.5, 94.159, 0.2, 0, 0, 0.099833, 0.995004, 60, 100, 1, '', 'CoA Deathknell: Scarlet camp south-east of Deathknell, Meven Korgal''s tent, north-west of the tent under the canopy tree');

-- ---------------------------------------------------------------------------
-- 9. Scripts
-- ---------------------------------------------------------------------------
-- Credits: the three Venomancer targets on the concoction (SPELLHIT, D22); Felo on the Red Vial and on accepting
--   "A Surprise Attack!"; Dalin Soft by gossip, the option shown only with the quest (D10); the disguised witch
--   on the torch; walk-in markers at the two statues (D10); the ritual circle and the campfire by
--   SmartGameObjectAI (GameObject::Use calls AI()->GossipHello for every type, GameObject.cpp:1476-1480; quest
--   accept, PlayerQuest.cpp:487).
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (50275, 50327, 502930, 685034, 9300253, 9300255, 9300256) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(50275, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685013, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Bailey Horrorhate - On Spellhit Poison the World - Credit Poisoning the World'),
(50327, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685012, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sunspeaker Talethia - On Spellhit Poison the World - Credit Poisoning the World'),
(502930, 0, 0, 0, 8, 0, 100, 0, 685013, 0, 0, 0, 0, 0, 33, 685014, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dornall Plagueweaver - On Spellhit Poison the World - Credit Poisoning the World'),
(685034, 0, 0, 0, 10, 0, 100, 0, 1, 10, 1000, 1000, 1, 0, 33, 685031, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Invisible Dummy (Starcaller3) - On LOS Out of Combat - Credit Champion of Elune'),
(9300253, 0, 0, 0, 8, 0, 100, 0, 684328, 0, 0, 0, 0, 0, 33, 685011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Felo - On Spellhit Tend Wounds (Red Vial) - Credit Falcons Are Friends'),
(9300253, 0, 1, 0, 19, 0, 100, 0, 200012, 0, 0, 0, 0, 0, 12, 299222, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, 1918, 1703, 88.144, 5, 'Felo - On Quest A Surprise Attack! Accepted - Summon Suspicious Creature from the bushes'),
(9300255, 0, 0, 0, 62, 0, 100, 0, 930352, 0, 0, 0, 0, 0, 33, 685022, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dalin Soft - On Gossip Option 0 Selected - Credit Call of the Shadowlands'),
(9300256, 0, 0, 1, 8, 0, 100, 0, 512352, 0, 5000, 5000, 0, 0, 33, 685221, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Agatha Harlow - On Spellhit Torch - Credit Find the Witch'),
(9300256, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Agatha Harlow - Linked - Yell Line 0'),
(9300256, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 299333, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, 1826, 1566, 95.623, 1.25, 'Agatha Harlow - Linked - Summon the Witch in her place'),
(9300256, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Agatha Harlow - Linked - Despawn for 60 seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9003728 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-9003728, 0, 0, 0, 10, 0, 100, 0, 1, 8, 1000, 1000, 1, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '[KC] Visit (hidden statue) - On LOS Out of Combat - Credit A Quiet Life');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (9301250, 9301251) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(9301250, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Gossip Hello - Credit Call of Death'),
(9301250, 1, 1, 0, 19, 0, 100, 0, 200054, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 1758.5, 1592.5, 111.461, 3.9, 'Ritual Circle - On Quest Call of the Dead Accepted - Summon the Undead Monstrosity'),
(9301250, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 299232, 4, 120000, 1, 0, 0, 8, 0, 0, 0, 0, 1758.5, 1592.5, 111.461, 3.9, 'Ritual Circle - On Use - Summon the Undead Monstrosity again if none is near'),
(9301251, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 9300254, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, 1791, 1664.5, 112.891, 5.5, 'Bound Campfire - On Gossip Hello - Summon Scorch'),
(9301251, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Bound Campfire - Linked - Burn out for 60 seconds');

DELETE FROM `conditions` WHERE `SourceEntry` = 9301250 AND `SourceTypeOrReferenceId` = 22;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 9301250, 1, 0, 9, 0, 200054, 0, 0, 0, 0, 0, '', 'Ritual Circle - re-summon only while Call of the Dead is taken'),
(22, 3, 9301250, 1, 0, 29, 1, 299232, 20, 0, 1, 0, 0, '', 'Ritual Circle - re-summon only if no living Undead Monstrosity is within 20 yd');

DELETE FROM `creature_text` WHERE `CreatureID` = 9300256;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `comment`)
VALUES
(9300256, 0, 0, 'Horrorhate''s hound has found me! Then rot with me, hunter!', 14, 0, 100, 'Agatha Harlow - revealed by the torch (INFERRED)');
