-- Conquest of Azeroth class trainers in Northshire Valley: the 16 trainers CoA placed at the abbey, the
-- "seek out your trainer" letters Marshal McBride hands out after Kobold Camp Cleanup, and the first quest
-- chain of every class with the creatures and objects it needs. Builds on
-- rev_20260923_05_coa_class_trainer_core.sql (trainer spells, class menus, Mathrengyl Bearwalker's Primalist role).
--
-- WHERE EACH VALUE COMES FROM
--   trainer spots  SOURCED-CLIENT: the QuestSuperTrack turn-in point of each letter (z from the server
--     floor). Chaplain Nysoni stands 1.03 yd off hers (a Pilgrim's Bounty turkey shares the point); Patal
--     the Mad stands 0.2 yd in front of his, clear of the bench it touches. Facings are hand-checked, the
--     reason on each row.
--   trainer templates  name and subname from creaturecache; faction, level and flags from the class
--     trainer recipe (ct_common). Amanda the Reaver's template also serves her Shadowglen spawn.
--   looks  no capture of any CoA trainer exists, so every look is a stand-in: a stock NPC of the right
--     race, sex and trade copied through CreatureDisplayInfoExtra, then restyled and redressed so no two
--     Northshire trainers look alike (reason on each preset). Weapons are stock items.
--   menus  Amanda (87576) and Norman Goldshire (25018/125018) keep their own CoA texts; Doctor Yara, a
--     human, gets neutral texts instead of the troll-spoken class menu (INFERRED, 930202/930203).
--   stock trainers  every stock class trainer keeps its post and role. Priestess Anetta, 0.28 yd from
--     Nysoni's point, steps aside and Brother Sammuel is hidden while the Cultist kill copy stands in
--     (rev_20260924_13).
--   quests  the realm's questcache (D13 mapping). Letters: starter McBride after Kobold Camp Cleanup
--     (the stock letter pattern 3100-3105, INFERRED), ender the trainer, the letter a provided item. Chains
--     are linked by PrevQuestID only; each quest is gated to its class.
--   places the texts name  the Kobold mine = Echo Ridge Mine; the Defias encampment = the camp by the river
--     south-east of the abbey; the waterfall = the Northshire falls, where CoA's own "Uther's Statue"
--     goober stood (SOURCED-ATLAS) on a ledge no path reaches, so a walk-in marker at the foot of the falls
--     credits the visit; Jo = the Damaged Guard Tower supply yard at the quest point of The Ranger's Path
--     (SOURCED-CACHE); Old Man Jenkins' home = the furnished CoA farmhouse north of the abbey;
--     kobold camps = the three camps north of the abbey and the mine mouth. Everything else is hand-placed
--     (INFERRED) with its reason on the row.
--   drops  SOURCED-EXILES creature_loot for the Defias Thug and Kobold Worker drops; the named holders drop
--     their item always.
--   letter pages  pagetextcache where CoA had them; the rest are written in the trainers' voices
--     (INFERRED). The quest item pages the zones share (Tome of Blood, Riddlestone, Note) are ct-deathknell's.
--
-- Blocks: creature guids 9003100-9003299, gameobject guids 7912100-7912199, creature entries 9300100-9300104,
-- gameobject entries 9301100-9301105, gossip menus and texts 930200-930206.

-- ---------------------------------------------------------------------------
-- 1. Trainers
-- ---------------------------------------------------------------------------
-- 50295 Amanda the Reaver (Barbarian): name and subname from creaturecache 50295 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from Syndicate Mercenary
--   (display 3988): leather and black plate shoulders, Defias hood removed, face 4, hair 14 in red, changed as
--   listed; weapons Blackrock Champion's Axe (her text: the axe of a Blackrock Champion).
-- 502960 Doctor Yara (Witch Doctor): name and subname from creaturecache 502960 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from Herbalist Pomeroy's
--   build (display 3269) in the tribal outfit of the human Kurzen Witch Doctor (display 4450), face 8, hair 7
--   dark, changed as listed; weapons Witching Stave.
-- 50325 Deacon Frost (Witch Hunter): name and subname from creaturecache 50325 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Night Watch watcher (display
--   2392) with a black buckled hat, grey hair and a full beard, changed as listed; weapons Torch of Holy Flame
--   and Silver Crossbow.
-- 502770 Niki Thesla (Stormbringer): name and subname from creaturecache 502770 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from Dalaran Summoner
--   (display 3718) robes without the Kirin Tor tabard, hair 18 storm-white, changed as listed; weapons Windstorm
--   Hammer and Orb of Power.
-- 50324 Vanguard Gus (Guardian): name and subname from creaturecache 50324 (SOURCED-CACHE); look is a stand-in,
--   no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Stormwind guard (display 3453) in
--   helm and plate without the city tabard, beard 5, changed as listed; weapons Mercenary Sword and Veteran
--   Shield.
-- 50280 Brother William (Templar): name and subname from creaturecache 50280 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Brother Wilhelm's paladin plate
--   (display 1299), golden hair, face 5, clean-shaven, changed as listed; weapons Light Hammer and Shield of the
--   Faith.
-- 50292 Whisp the Silent (Bloodmage): name and subname from creaturecache 50292 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Scarlet Magus robes
--   (display 10329) in crimson without the Crusade tabard, dark hair, clean-shaven, changed as listed; weapons
--   Bloody Dagger (the chain reward) and Mystic Tome.
-- 503410 Owen of Moonbrook (Ranger): name and subname from creaturecache 503410 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from People's Militia scout
--   (display 2373, Westfall - he is of Moonbrook), hair 10, beard 3, changed as listed; weapons Engraved Sword
--   and Blackwood Recurve Bow.
-- 50282 Soridormi (Chronomancer): name and subname from creaturecache 50282 (SOURCED-CACHE); look is a stand-in,
--   no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from Dawn Brightstar (display 3347)
--   arcane dress and silver circlet, sand-gold hair, face 6, changed as listed; weapons feathered gold staff.
-- 502923 Halbert the Scoundrel (Necromancer): name and subname from creaturecache 502923 (SOURCED-CACHE); look
--   is a stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Scourge Necromancer
--   (display 2582) build in the black Death Speaker Robes (display 9861, Robe_B_01Black), pale skin, white hair,
--   face 3, goatee, changed as listed; weapons Cryptbone Staff.
-- 50340 Koby the Incinerator (Pyromancer): name and subname from creaturecache 50340 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Twilight Fire Guard
--   (display 7826) flame-red plate, ember-red hair, face 10, changed as listed; weapons Emberstone Staff.
-- 50283 Patal the Mad (Cultist): name and subname from creaturecache 50283 (SOURCED-CACHE); look is a stand-in,
--   no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Jaedenar Cultist robes (display
--   11279), wild grey hair, face 11, changed as listed; weapons Ritual Blade.
-- 50286 Chaplain Nysoni (Sun Cleric): name and subname from creaturecache 50286 (SOURCED-CACHE); look is a
--   stand-in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from High Priestess Laurena
--   (display 1495) white vestments with a sun crown, golden hair, face 9, changed as listed; weapons Crested
--   Scepter and Tome of the Dawn (a book model, for her "every dawn" letter).
-- 50287 Norman Goldshire (Tinker): name and subname from creaturecache 50287 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Neal Allen (display 3459,
--   engineering supplies) work clothes with engineer goggles, changed as listed; weapons Tinker's Wrench and
--   Rough Boomstick.
-- 50289 Troes the Remover (Reaper): name and subname from creaturecache 50289 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human male from Shadowy Executioner (display
--   18111) with his crimson hood-helm ("my helmet"), darker skin, face 2, changed as listed; weapons Darkwater
--   Talwar and Deathstalker Shortsword ("these blades").
-- 50291 Wanda Belezin (Runemaster): name and subname from creaturecache 50291 (SOURCED-CACHE); look is a stand-
--   in, no SMSG_MIRRORIMAGE_DATA capture of this trainer exists: human female from Dalaran Mage (display 3560)
--   robes without the Kirin Tor tabard, black hair, face 12, changed as listed; weapons Clear Crystal Rod.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(50295, 'Amanda the Reaver', 'Barbarian Trainer', 930200, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502960, 'Doctor Yara', 'Witch Doctor Trainer', 930202, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50325, 'Deacon Frost', 'Witch Hunter Trainer', 930015, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502770, 'Niki Thesla', 'Stormbringer Trainer', 930016, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50324, 'Vanguard Gus', 'Guardian Trainer', 930018, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50280, 'Brother William', 'Templar Trainer', 930019, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50292, 'Whisp the Silent', 'Bloodmage Trainer', 930020, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(503410, 'Owen of Moonbrook', 'Ranger Trainer', 930021, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50282, 'Soridormi', 'Chronomancer Trainer', 930022, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(502923, 'Halbert the Scoundrel', 'Necromancer Trainer', 930023, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50340, 'Koby the Incinerator', 'Pyromancer Trainer', 930024, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50283, 'Patal the Mad', 'Cultist Trainer', 930025, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50286, 'Chaplain Nysoni', 'Sun Cleric Trainer', 930027, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50287, 'Norman Goldshire', 'Tinker Trainer', 930201, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50289, 'Troes the Remover', 'Reaper Trainer', 930030, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 1, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, ''),
(50291, 'Wanda Belezin', 'Runemaster Trainer', 930032, 10, 10, 0, 12, 51, 1, 1.14286, 20, 0, 2000, 2000, 8, 768, 2048, 7, 134217728, 0, '', 0, 1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (50280, 50282, 50283, 50286, 50287, 50289, 50291, 50292, 50295, 50324, 50325, 50340, 502770, 502923, 502960, 503410);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(50295, 0, 50, 1, 1),
(502960, 0, 50, 1, 1),
(50325, 0, 49, 1, 1),
(502770, 0, 50, 1, 1),
(50324, 0, 49, 1, 1),
(50280, 0, 49, 1, 1),
(50292, 0, 49, 1, 1),
(503410, 0, 49, 1, 1),
(50282, 0, 50, 1, 1),
(502923, 0, 49, 1, 1),
(50340, 0, 49, 1, 1),
(50283, 0, 49, 1, 1),
(50286, 0, 50, 1, 1),
(50287, 0, 49, 1, 1),
(50289, 0, 49, 1, 1),
(50291, 0, 50, 1, 1);

DELETE FROM `creature_display_preset` WHERE `entry` IN (50280, 50282, 50283, 50286, 50287, 50289, 50291, 50292, 50295, 50324, 50325, 50340, 502770, 502923, 502960, 503410);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`)
VALUES
(50295, 50, 1, 1, 1, 3, 4, 14, 3, 0, 0, 0, 145970, 147283, 148669, 150366, 3381, 154524, 0, 156979, 0, 0),
(502960, 50, 1, 1, 1, 5, 8, 7, 1, 0, 0, 0, 0, 147375, 148708, 150440, 5571, 154611, 0, 157057, 0, 0),
(50325, 49, 1, 0, 1, 2, 9, 6, 8, 7, 0, 142792, 0, 5944, 0, 5926, 5927, 5928, 0, 5929, 0, 0),
(502770, 50, 1, 1, 1, 0, 7, 18, 9, 1, 0, 0, 145956, 0, 148633, 150312, 152256, 154463, 0, 0, 0, 0),
(50324, 49, 1, 0, 1, 2, 6, 3, 1, 5, 0, 11653, 4916, 4628, 0, 4629, 4630, 4656, 0, 5063, 0, 0),
(50280, 49, 1, 0, 1, 3, 5, 5, 2, 0, 0, 0, 2932, 255, 627, 2436, 149, 546, 0, 670, 0, 0),
(50292, 49, 1, 0, 1, 0, 4, 8, 0, 0, 0, 145254, 146201, 0, 147782, 150836, 152863, 155024, 0, 157421, 0, 0),
(503410, 49, 1, 0, 1, 1, 7, 10, 1, 3, 0, 0, 5923, 5921, 0, 5922, 5747, 5675, 0, 5924, 0, 0),
(50282, 50, 1, 1, 1, 2, 6, 3, 2, 0, 0, 6949, 0, 6950, 0, 7020, 5565, 6951, 0, 0, 0, 0),
(502923, 49, 1, 0, 1, 0, 3, 6, 9, 2, 0, 0, 0, 0, 9861, 3408, 598, 16593, 0, 0, 0, 0),
(50340, 49, 1, 0, 1, 8, 10, 7, 3, 5, 0, 0, 146123, 147684, 148882, 150726, 152734, 154902, 156345, 0, 0, 0),
(50283, 49, 1, 0, 1, 3, 11, 12, 8, 4, 0, 0, 0, 0, 13566, 150582, 152574, 0, 0, 157195, 0, 0),
(50286, 50, 1, 1, 1, 1, 9, 2, 2, 0, 0, 61928, 6799, 6796, 6604, 3134, 6797, 6247, 0, 0, 0, 0),
(50287, 49, 1, 0, 1, 0, 4, 1, 4, 1, 0, 2378, 0, 7283, 3348, 3531, 2303, 2931, 0, 2992, 0, 0),
(50289, 49, 1, 0, 1, 5, 2, 0, 0, 0, 0, 145474, 146467, 0, 12798, 151218, 13020, 155396, 0, 157717, 0, 0),
(50291, 50, 1, 1, 1, 1, 12, 16, 0, 0, 0, 0, 0, 0, 148616, 150266, 152208, 154412, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (50280, 50282, 50283, 50286, 50287, 50289, 50291, 50292, 50295, 50324, 50325, 50340, 502770, 502923, 502960, 503410);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(50295, 1, 1455, 0, 0),
(502960, 1, 1484, 0, 0),
(50325, 1, 2808, 0, 24138),
(502770, 1, 6804, 4838, 0),
(50324, 1, 23430, 3651, 0),
(50280, 1, 2500, 1547, 0),
(50292, 1, 1505015, 6899, 0),
(503410, 1, 23421, 0, 4763),
(50282, 1, 13337, 0, 0),
(502923, 1, 2013, 0, 0),
(50340, 1, 5201, 0, 0),
(50283, 1, 5112, 0, 0),
(50286, 1, 3414, 43654, 0),
(50287, 1, 1911, 0, 4362),
(50289, 1, 11121, 3455, 0),
(50291, 1, 16894, 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (50280, 50282, 50283, 50286, 50287, 50289, 50291, 50292, 50295, 50324, 50325, 50340, 502770, 502923, 502960, 503410);
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
VALUES
(50295, 900012),
(502960, 900013),
(50325, 900015),
(502770, 900016),
(50324, 900018),
(50280, 900019),
(50292, 900020),
(503410, 900021),
(50282, 900022),
(502923, 900023),
(50340, 900024),
(50283, 900025),
(50286, 900027),
(50287, 900028),
(50289, 900030),
(50291, 900032);

-- ---------------------------------------------------------------------------
-- 2. Named trainer menus and the chain gossip
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` IN (25018, 87576, 930202, 930203, 930204, 930206);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`)
VALUES
(25018, 'You know, a lot of tinkering fanatics used to have so many turrets up their sleeve, but they were always so low quality and imploded on themselves after about 15 seconds!$B$BHow do you expect to shoot your gun in combat, or throw bombs, or do anything when you have to focus on a turret that can only keep itself effective for 15 seconds!?$B$BThankfully, I, Norman Goldshire made the modern day paradigm of Sentry Turrets! Built to last, but they take up more space in your pocket! Just make sure to deconstruct it before you place it back down!', 'You know, a lot of tinkering fanatics used to have so many turrets up their sleeve, but they were always so low quality and imploded on themselves after about 15 seconds!$B$BHow do you expect to shoot your gun in combat, or throw bombs, or do anything when you have to focus on a turret that can only keep itself effective for 15 seconds!?$B$BThankfully, I, Norman Goldshire made the modern day paradigm of Sentry Turrets! Built to last, but they take up more space in your pocket! Just make sure to deconstruct it before you place it back down!', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(87576, 'Greetings, I am Amanda, a master of brutality. They call me the Reaver, a true scourge of the north!$B$BOh, you''re wondering where I got this axe? Ha, well listen up $n, this is the axe of a Blackrock Champion. They said if I wanted it I would have to take it from their cold, dead hands.$B$BSo that''s exactly what I did.$B$BThink you got what it takes to learn from a barbarian like myself?', 'Greetings, I am Amanda, a master of brutality. They call me the Reaver, a true scourge of the north!$B$BOh, you''re wondering where I got this axe? Ha, well listen up $n, this is the axe of a Blackrock Champion. They said if I wanted it I would have to take it from their cold, dead hands.$B$BSo that''s exactly what I did.$B$BThink you got what it takes to learn from a barbarian like myself?', 0, 0, 1, 1, 1, 0, 0, 0, 0),
(930202, 'Sseratus has been whispering your name, $C. Sit by the fire, and I will show you how one brew can mend a friend and another can ruin a foe.', 'Sseratus has been whispering your name, $C. Sit by the fire, and I will show you how one brew can mend a friend and another can ruin a foe.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930203, 'The spirits do not answer to you, $C. Leave the brewing to those the Loa have chosen.', 'The spirits do not answer to you, $C. Leave the brewing to those the Loa have chosen.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930204, '<The old man''s breath rattles in his chest, but his grip on the chair is still made of iron.>$B$BEh? Another young one come to see old Jenkins? I held the line at the gates of Stormwind when the orcs came, and in every war after. Now I can''t even lift my own sword.$B$BThey say the end comes quiet for men like me. I wonder what waits on the other side.', '<The old man''s breath rattles in his chest, but his grip on the chair is still made of iron.>$B$BEh? Another young one come to see old Jenkins? I held the line at the gates of Stormwind when the orcs came, and in every war after. Now I can''t even lift my own sword.$B$BThey say the end comes quiet for men like me. I wonder what waits on the other side.', 0, 0, 1, 0, 0, 0, 0, 0, 0),
(930206, '<Dark runes have been scratched into the earth in a wide circle. A folded note lies at its edge, weighted down with a stone.>', '<Dark runes have been scratched into the earth in a wide circle. A folded note lies at its edge, weighted down with a stone.>', 0, 0, 1, 0, 0, 0, 0, 0, 0);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (930200, 930201, 930202, 930204, 930206);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(930200, 87576),
(930200, 287575),
(930201, 25018),
(930201, 125018),
(930202, 930202),
(930202, 930203),
(930204, 930204),
(930206, 930206);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (930200, 930201, 930202, 930204, 930206);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(930200, 0, 3, 'I seek training as a Barbarian.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930201, 0, 3, 'I seek training as a Tinker.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930202, 0, 3, 'I seek training as a Witch Doctor.', 0, 5, 16, 0, 0, 0, 0, '', 0),
(930204, 0, 0, 'Troes the Remover sent me. I can tell you what waits on the other side.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (930200, 930201, 930202, 930204, 930206) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 930200, 87576, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Barbarian'),
(14, 930200, 287575, 0, 0, 15, 0, 2048, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Barbarian'),
(15, 930200, 0, 0, 0, 15, 0, 2048, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Barbarian'),
(14, 930201, 25018, 0, 0, 15, 0, 134217728, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Tinker'),
(14, 930201, 125018, 0, 0, 15, 0, 134217728, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Tinker'),
(15, 930201, 0, 0, 0, 15, 0, 134217728, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Tinker'),
(14, 930202, 930202, 0, 0, 15, 0, 4096, 0, 0, 0, 0, 0, '', 'Show gossip text if player is a Witch Doctor'),
(14, 930202, 930203, 0, 0, 15, 0, 4096, 0, 0, 1, 0, 0, '', 'Show gossip text if player is not a Witch Doctor'),
(15, 930202, 0, 0, 0, 15, 0, 4096, 0, 0, 0, 0, 0, '', 'Show gossip option if player is a Witch Doctor'),
(15, 930204, 0, 0, 0, 9, 0, 200037, 0, 0, 0, 0, 0, '', 'Old Man Jenkins - Show gossip option while Call of the Shadowlands is taken');

-- ---------------------------------------------------------------------------
-- 3. Chain creatures
-- ---------------------------------------------------------------------------
-- 85031 Lil Wa'zoo: creaturecache 85031 (name, subname, rank, modifiers, display 10913): the kobold of the
--   Guardian and Witch Doctor chains; friendly and not immune so Loa's Brew can reach him.
-- 299223 Zipi: the kobold who bullied Lil Wa'zoo (200028); name, subname and display 2299 from creaturecache
--   399223 Zipi <The Bully>.
-- 299235 Brother Sammuel: Going MAD! kill target, named by 200071; stock Brother Sammuel (925) look and mace;
--   neutral so nobody but the Cultist has reason to fight him.
-- 299325 Gerald: Welcome to the Warband rookie, named by 200104; stock mercenary look (display 3987) and a
--   barbaric axe, INFERRED; neutral, he only fights back.
-- 9300100 Defias Blood Wizard: Blood Is Power tome holder, named by 200017; Defias Rogue Wizard looks and staff;
--   hostile like the Defias Thugs (faction 14, playtest).
-- 9300101 Scorch: The Way of the Pyromancer: a rogue fire elemental bound to a campfire (200120); small flame
--   elemental look (display 1070 at 0.6), INFERRED.
-- 9300102 Jo: Owen of Moonbrook's falcon, named by 199999; eagle model at the 0.25 display scale, INFERRED.
-- 9300103 Old Man Jenkins: Call of the Shadowlands: the dying veteran, named by 200037; old man look (display
--   2052), INFERRED.
-- 9300104 Old Agatha: The Hunt Begins: the witch in her villager disguise (INFERRED name and look, display
--   3335).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(85031, 'Lil Wa''zoo', 'Suspicious Kobold', 0, 3, 3, 0, 35, 3, 1, 1.14286, 20, 2, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1.2, 2.2, 1, 1, 0, ''),
(299223, 'Zipi', 'The Bully', 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1.5, 1, 1, 1, 0, ''),
(299235, 'Brother Sammuel', NULL, 0, 4, 4, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(299325, 'Gerald', NULL, 0, 3, 3, 0, 7, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 0, ''),
(9300100, 'Defias Blood Wizard', NULL, 0, 4, 4, 0, 14, 0, 1, 1.14286, 6, 0, 2000, 2000, 8, 0, 2048, 7, 0, 9300100, '', 0, 1, 1, 1, 1, 0, ''),
(9300101, 'Scorch', NULL, 0, 4, 4, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 4, 0, 9300101, '', 0, 1, 1, 1, 1, 0, ''),
(9300102, 'Jo', 'Owen''s Falcon', 0, 2, 2, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(9300103, 'Old Man Jenkins', NULL, 930204, 5, 5, 0, 12, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, ''),
(9300104, 'Old Agatha', NULL, 0, 3, 3, 0, 12, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (85031, 299223, 299235, 299325, 9300100, 9300101, 9300102, 9300103, 9300104);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(85031, 0, 10913, 1, 1),
(299223, 0, 2299, 1, 1),
(299235, 0, 3346, 1, 1),
(299325, 0, 3987, 1, 1),
(9300100, 0, 2360, 1, 1),
(9300100, 1, 2359, 1, 1),
(9300101, 0, 1070, 0.6, 1),
(9300102, 0, 28214, 1, 1),
(9300103, 0, 2052, 1, 1),
(9300104, 0, 3335, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (85031, 299223, 299235, 299325, 9300100, 9300101, 9300102, 9300103, 9300104);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(299235, 1, 1903, 0, 0),
(299325, 1, 3195, 0, 0),
(9300100, 1, 1907, 0, 0);

DELETE FROM `creature_text` WHERE `CreatureID` IN (9300103, 9300104);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `comment`)
VALUES
(9300103, 0, 0, 'The Shadowlands, eh? So death is not the end of the road, only a turn in it. Thank you, $n. When my time comes, I will walk it without fear.', 12, 0, 100, 'Old Man Jenkins - after the chat (INFERRED)'),
(9300104, 0, 0, 'You can see me? Then burn, witch hunter!', 14, 0, 100, 'Old Agatha - revealed (INFERRED)');

-- ---------------------------------------------------------------------------
-- 4. Chain objects
-- ---------------------------------------------------------------------------
-- 9301100 Ritual Circle: CoA's own Ritual Circle display (gameobjectcache 3277894) at 0.7; questgiver of Death
--   Calls and Call of the Dead, credits Call of Death when used.
-- 9301101 Training Wand: Perfect Timing: Soridormi's wand; CoA's wand display (gameobjectcache 254654 Burnscorch
--   Wand).
-- 9301102 Eye of the Beholder: Runes of Power: the riddle's answer; stock Eye of Azora crystal (display 621).
-- 9301103 Lost Pendant: Lost Pendant: Chaplain Nysoni's pendant; CoA's pendant display (gameobjectcache 60269).
-- 9301104 Scrap Metal: Ingenuity At It's Finest!: scrap near the kobold camps; stock junk pile (display 7114) at
--   0.8.
-- 9301105 Uther's Statue: A Quiet Life: the statue by the Northshire waterfall. SOURCED-ATLAS: CoA's goober
--   251653 "Uther's Statue"; this entry keeps it in the ct-northshire block (the zone packages each need a
--   statue). Stock Uther statue model (display 6815) at 0.6.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`)
VALUES
(9301100, 2, 1045032, 'Ritual Circle', '', '', 0.7, 0, 0, 0, 930206, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI', ''),
(9301101, 3, 254010, 'Training Wand', '', '', 1, 43, 9301101, 0, 1, 0, 0, 0, 0, 200165, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', ''),
(9301102, 3, 621, 'Eye of the Beholder', '', '', 1, 43, 9301102, 0, 1, 0, 0, 0, 0, 200109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', ''),
(9301103, 3, 1010146, 'Lost Pendant', '', '', 1, 43, 9301103, 0, 1, 0, 0, 0, 0, 200058, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', ''),
(9301104, 3, 7114, 'Scrap Metal', '', '', 0.8, 43, 9301104, 0, 1, 0, 0, 0, 0, 200065, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', ''),
(9301105, 10, 6815, 'Uther''s Statue', '', '', 0.6, 0, 200077, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'SmartGameObjectAI', '')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`);

-- ---------------------------------------------------------------------------
-- 5. Quests
-- ---------------------------------------------------------------------------
-- The Stolen Power Core (200087): ObjectiveText1 is '0' in the cache (a CoA data quirk on its seven
-- copies only); left blank so the quest log shows no stray line.
-- RewardNextQuest (the next step is offered at turn-in): questcache NextQuestInChain where the next quest is in
--   this file: 200027->200028, 200086->200087, 200087->200088, 200114->200115, 200115->200116, 199999->200000,
--   200000->200001, 200040->200041, 200041->200042.
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(49976, 2, 2, 2, -525, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650011, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Storm Codex', 'Read the Storm Codex and seek out Niki Thesla in Northshire Valley.', 'By the Light! This tome nearly shocked me when I picked it up, $N. The very air around it crackles with electrical energy, and I swear I can hear distant thunder rumbling from within its pages. Only those with the fortitude to channel the raw power of storms should even consider opening it. Are you prepared for such elemental fury?', '', 'Seek out Niki Thesla in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650011, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Storm Codex and seek out Niki Thesla in Northshire Valley.', '', '', ''),
(49977, 2, 2, 2, -529, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650012, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Guardian''s Oath', 'Read the Guardian''s Oath and seek out Gus in Northshire Valley.', 'A noble calling awaits you, $N. This oath was inscribed on the finest steel I have ever seen, and it practically radiates honor and duty. The words speak of protection, sacrifice, and standing firm against impossible odds. Few have the heart to take such a burden upon themselves. Do you possess such courage?', '', 'Seek out Gus in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650012, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Guardian''s Oath and seek out Aspiring Gladiator Alistair in Northshire Valley.', '', '', ''),
(49978, 2, 2, 2, -524, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650013, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Templar''s Vow', 'Read the Templar''s Vow and seek out Brother William in Northshire Valley.', 'The Light itself seems to have blessed this document, $N. When I hold it, I feel a warmth spread through my chest and a sense of divine purpose fills my heart. This vow calls for absolute dedication to the Light''s will and unwavering faith in the face of darkness. Such devotion is not given lightly.', '', 'Seek out Brother William in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650013, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Templar''s Vow and seek out Brother William in Northshire Valley.', '', '', ''),
(49979, 2, 2, 2, -516, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650014, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Grimoire', 'Read the Blood Grimoire and seek out Whisp the Silent in Northshire Valley.', 'I must confess, this grimoire makes me deeply uncomfortable, $N. The leather binding appears to be... well, I''d rather not speculate. It pulses rhythmically, like a heartbeat, and I swear the pages are stained crimson. The magic within deals with life force itself - a power both terrible and alluring. Handle it with utmost care.', '', 'Seek out Whisp the Silent in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650014, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Blood Grimoire and seek out Whisp the Silent in Northshire Valley.', '', '', ''),
(49980, 2, 2, 2, -505, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650015, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ranger''s Guide', 'Read the Ranger''s Guide and seek out Owen of Moonbrook in Northshire Valley.', 'What a curious thing, $N. This guide still has bits of forest debris clinging to it - pine needles, moss, even a small twig. When I opened it briefly, I heard what sounded like birdsong and rustling leaves. It speaks of tracking, wilderness survival, and becoming one with nature itself. The wild calls to you through these pages.', '', 'Seek out Owen of Moonbrook in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650015, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Ranger''s Guide and seek out Owen of Moonbrook in Northshire Valley.', '', '', ''),
(49981, 2, 2, 2, -530, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650016, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Temporal Manuscript', 'Read the Temporal Manuscript and seek out Soridormi in Northshire Valley.', 'Most peculiar, $N. I could have sworn this manuscript wasn''t here a moment ago, yet here it is. The text seems to shimmer and shift before my eyes, as if existing in multiple moments simultaneously. Such temporal magic is beyond my understanding, but perhaps you have the mind to comprehend its mysteries.', '', 'Seek out Soridormi in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650016, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Temporal Manuscript and seek out Soridormi in Northshire Valley.', '', '', ''),
(49982, 2, 2, 2, -521, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650017, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Necromantic Journal', 'Read the Necromantic Journal and seek out Halbert the Scoundrel in Northshire Valley.', 'I''ll be honest with you, $N - this journal gives me the chills. Literally. The temperature drops whenever I get near it, and I keep hearing faint whispers that I can''t quite make out. The binding appears to be made from... bone. This contains knowledge of death magic that most would consider forbidden. Are you certain you wish to pursue such a dark path?', '', 'Seek out Halbert the Scoundrel in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650017, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Necromantic Journal and seek out Halbert the Scoundrel in Northshire Valley.', '', '', ''),
(49983, 2, 2, 2, -528, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650018, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Flame Codex', 'Read the Flame Codex and seek out Firelord Kobe in Northshire Valley.', 'Careful there, $N! This codex is almost too hot to handle. Flames dance across its surface without burning the pages, and the air around it shimmers with heat. I can practically feel the fire magic contained within, begging to be unleashed. Only those with a passion for destruction should even consider such power.', '', 'Seek out Kobe the Incinerator in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650018, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Flame Codex and seek out Firelord Kobe in Northshire Valley.', '', '', ''),
(49984, 2, 2, 2, -522, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650019, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Forbidden Treatise', 'Read the Forbidden Treatise and seek out Patal the Mad in Northshire Valley.', 'Welcome back $N! Before you go, one of the guards dropped this off and I was told to give this to you. I have not had a chance to peak at it myself yet.  By all that''s holy... I can barely look at this thing directly. The symbols seem to writhe and shift, and I keep hearing... whispers. Voices speaking words I don''t understand but that fill me with dread.   Something this insane could only come from Patal the Mad, and only the truly mad... or truly brave... would dare to study it.   Visit Patal the Mad, he will have more answers.', '', 'Seek out Patal the Mad in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650019, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Forbidden Treatise and seek out Patal the Mad in Northshire Valley.', '', '', ''),
(49985, 2, 2, 2, -520, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650021, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Engineering Manual', 'Read the Engineering Manual and seek out Norman Goldshire in Northshire Valley.', 'Fascinating! This manual is filled with blueprints and schematics I''ve never seen before, $N. Small gears, springs, and clockwork mechanisms seem to spill from its pages, and I can hear the faint ticking of unseen machinery. The combination of magic and engineering here is truly remarkable. Innovation awaits those clever enough to understand it.', '', 'Seek out Norman Goldshire in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650021, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Engineering Manual and seek out Norman Goldshire in Northshire Valley.', '', '', ''),
(49986, 2, 2, 2, -507, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650020, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Solar Scripture', 'Read the Solar Scripture and seek out Chaplain Nysoni in Northshire Valley.', 'What a beautiful sight, $N. This scripture glows with the warm light of dawn, and reading it fills me with hope and renewed vigor. The golden text speaks of healing through solar energy and channeling the sun''s life-giving power. Such radiant magic brings only blessing and renewal to the world.', '', 'Seek out Chaplain Nysoni in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650020, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Solar Scripture and seek out Chaplain Nysoni in Northshire Valley.', '', '', ''),
(49987, 2, 2, 2, -508, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650022, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Manual', 'Read the Death Manual and seek out Troes the Remover in Northshire Valley.', 'This manual chills me to the bone, $N. Literally. The air grows cold around it, and I can smell the distinct scent of funeral preparations. The knowledge within deals with death itself - not as evil, but as a natural force to be guided and channeled. Only those who understand the balance between life and death should study such arts.', '', 'Seek out Troes the Remover in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650022, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Death Manual and seek out Troes the Remover in Northshire Valley.', '', '', ''),
(49988, 2, 2, 2, -527, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 650023, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runic Inscription', 'Read the Runic Inscription and seek out Wanda Belezin in Northshire Valley.', 'Ancient power flows through this tablet, $N. The runes carved into its surface glow with their own inner light, and I can feel the weight of centuries in every symbol. This is the oldest form of magic known to our kind - the art of binding power into permanent form. Such knowledge was old when the world was young.', '', 'Seek out Wanda Belezin in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 650023, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Runic Inscription and seek out Wanda Belezin in Northshire Valley.', '', '', ''),
(49990, 2, 2, 2, -526, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 2001, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Tablet', 'Seek out Amanda the Reaver in Northshire Valley.', 'I was asked to bring this to your attention as soon as you returned from defeating those kobolds, $N. It appears to be an ancient tablet bearing the crude markings of the barbarian warriors. The stone itself radiates primal fury, and I can sense the wild strength that courses through those who follow this path. I wouldn''t hesitate to read it before you go about any other business here in the Abbey.', '', 'Seek out Amanda the Reaver in Northshire Valley.', 0, 0, 0, 0, 0, 0, 0, 0, 2001, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Ancient Tablet and seek out Tormund the Reaver in Northshire Valley.', '', '', ''),
(49991, 2, 2, 2, -523, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 2002, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Tribal Scroll', 'Seek out Doctor Yara in Northshire Abbey.', 'I was asked to bring this to your attention as soon as you returned from defeating those kobolds, $N. It appears to be a tribal scroll marked with the mystical symbols of witch doctors. Strange herbs are bound to its edges, and I can almost hear the whispered incantations of ancient spirits. The art of healing through shadow and light is not to be taken lightly. I wouldn''t hesitate to read it before you go about any other business here in the Abbey.', '', 'Seek out Doctor Yara in Northshire Abbey.', 0, 0, 0, 0, 0, 0, 0, 0, 2002, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Tribal Scroll and seek out Doctor Yara in Northshire Valley.', '', '', ''),
(49992, 2, 2, 2, -519, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 2003, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sacred Letter', 'Seek out Elling Trias in Northshire Abbey.', 'I was asked to bring this to your attention as soon as you returned from defeating those kobolds, $N. It appears to be a sacred letter bearing the silver seal of the witch hunters. The parchment itself seems to repel darkness, blessed by those who dedicate their lives to purging evil from this world. Such righteous fury requires proper guidance. I wouldn''t hesitate to read it before you go about any other business here in the Abbey.', '', 'Seek out Elling Trias in Northshire Abbey.', 0, 0, 0, 0, 0, 0, 0, 0, 2003, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Read the Sacred Letter and seek out Deacon Frost in Northshire Valley.', '', '', ''),
(200104, 2, 3, 3, -526, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 532805, 1, 532806, 1, 395861, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Welcome to the Warband', 'Kill Gerald and return back to your trainer.', 'Har! Har! Welcome, $N. Glad you could join the Warband.  What is the Warband, you might be wondering? Considering your arrival, I would have assumed you''d already know. Well, little $c, this is about to be a rude awakening.  The Warband is where all barbarians, brutes, and strongmen alike come together to compete to see who is the strongest, most brutal, and most powerful individual of them all.  That''s the only way we can TRULY test our mettle. THIS IS IT! You may be new to this, but absolutely nobody will go easy on you.  Your first test will be the same as all the other rookies. There''s an individual who has been mucking things up and spreading rumors just because they couldn''t cut it and were denied access to the Warband.  They''re known as Gerald. Kill him, hahaha! I will reward you with a weapon well-suited for a noob like yourself if you are capable of such a task.  Come back to me alive, or die.', '', 'Return to your trainer.', 299325, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200027, 2, 3, 3, -523, 0, 0, 0, 0, 0, 0, 200028, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Doctor Is In!', 'Heal the injured friend of your trainer with rank 1 Loa''s Brew.', 'Welcome, $C. I can see you''ve already become well acquainted with the powers of Sseratus.  Let me guide you, friend. I have a task, a critical one at that. I have a friend down in the mines who is injured, according to our scouts. I only just got word of it and would have been on my way, but I believe this is a task that would be perfect for one such as yourself.  Find my friend, heal him with the power of your Loa''s Brew, and then return to me.', '', 'Return to your trainer.', 685021, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Save Lil Wa''zoo', '', '', ''),
(200028, 2, 3, 3, -523, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 292201, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Who Called For Da Docta?', 'Kill the Kobold who bullied Lil Wa''zoo!', 'Thank you so much friend! Some Kobold not nice, they hurt Lil Wa''zoo for bein'' himself.  Let me make clear: Kobold just want dig. We hit rock, make candle, explore world. My brethren, we no get why some hate us. We no mean to be nuisance. Am sorry.  I thank my good friends who no hurt me... Thank your friend for me for looking out for me, and thank you for help too!  Oh...no, wait. Look behind you! He back!!!', '', 'Return to your trainer.', 299223, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200055, 2, 3, 3, -519, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 662219, 0, 0, 717002, 1, 410005, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Hunt Begins', 'Reveal the witch and kill her.', 'I can feel an evil presence.  You can feel it too, can''t you? That is why you have come to me at the most opportune of times.  There is one here. A witch. Brooding with evil and malintent.  May the Light bless us for what we''re about to do.  Here, take this torch. She''s here and I''ve marked her location on your map. Use the torch on her to reveal her true self. Kill it. No mercy.  Return to me when it''s been slain.  Damned witches.', '', 'Return to your trainer.', 685221, 299333, 0, 0, 1, 1, 0, 0, 662219, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Find the Witch', '', '', ''),
(200086, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 200087, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Useful In Your Own Right', 'Assist Norman Goldshire with his tinkering shenanigans.', 'Greetings, $N, I am glad to make your acquaintance and I have heard much about you before your arrival.  You have come to me to learn and as a $C you have already shown yourself to be a dutiful student of the arcane. But there is so much more to the power that we call forth than just lightning and electricity.  In time, you will learn just how deep your potential lays. But for now... I do have a bit of a task for you.  There''s an individual nearby known as "Norm Normative" and he always calls on my aid for his... tinkering shenanigans... He needs some lightning, $N, but I am busy. Can you go and assist him?', '', 'Assist Norman Goldshire with his tinkering shenanigans.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200087, 2, 3, 0, -520, 0, 0, 0, 0, 0, 0, 200088, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Stolen Power Core', 'Kill Kobold Workers until one of them drops the power core.', 'Howdy, $N! Glad your trainer got around to sendin'' some help my way.  This is a very simple task, I just need some POWER! But unfortunately my power core has been stolen by one of the nearby Kobold Workers. Can you return it for me?', '', 'Return to Norman Goldshire.', 0, 0, 0, 0, 0, 0, 0, 0, 661417, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200088, 2, 3, 0, -525, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 663317, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Job For A Stormbringer', 'Tell your trainer of your success.', 'I appreciate you retrieving this power core! You can return to your trainer now and let him know what you''ve done for me.', '', 'Tell your trainer of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200114, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200115, 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Peace Through Strength', 'Find "Little Wa''zoo" in the Kobold mine.', 'It is nice to meet you, $N. We have much work to accomplish together and you, my friend, have much to learn!  We are Guardians, and as such we are tasked with, quite literally, guarding Azeroth. From the occasional ne''er-do-well that robs a man, to far more threatening monsters who pose a threat to our people. We are the ones who heed the call.  And, as my example preludes, I have such a task for you today. If you can do this, you are more than ready to proceed further into your training.  There is an individual nearby in the Kobold mine who goes by the name of "Little Wa''zoo", and I believe he could use my help.  Visit him and see what he needs.', '', 'Find "Little Wa''zoo" in the Kobold mine.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200115, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 200116, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Prioritizing Defense', 'Kill Defias until you find a suitable weapon for Lil'' Wa''zoo.', 'Hi friend! Lil'' Wa''zoo glad to see you.  LIl'' Wa''zoo have small problem. You see, some kobold no like Lil'' Wa''zoo, and am getting sick of it. I need to be able to defend myself!  I could not ask you to kill good kobold... that no good. But the Defias nearby, nobody like them! They have weapon. Can you get me one of their swords? I would really appreciate it!', '', 'Return to Lil Wa''zoo.', 0, 0, 0, 0, 0, 0, 0, 0, 662330, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200116, 2, 3, 3, -529, 0, 0, 0, 0, 0, 0, 0, 2, 25, 0, 0, 0, 0, 0, 0, 0, 0, 245712, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Helping A Friend', 'Return to your trainer with news of your success.', 'Wow, this perfect weapon! Now I defend myself against the evil Zipi and other bad kobold. Thank you!  I found a piece of metal in the mine, I think someone else drop it in mine. I gave it to your trainer and now he will give it to you!', '', 'Return to your trainer with news of your success.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200077, 2, 3, 3, -524, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 52855, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Quiet Life', 'Visit the waterfall in Northshire Valley.', 'Welcome to the order, $N. I have awaited your arrival.  As Templars, we have ascended to the highest order of the holy faith, and as such we have quite a lot of responsibility on our shoulders.  Paladins and Priests work alongside us to maintain peace through the Holy Light in this world and each of us, though different in our own subtle ways, hope to bring the light to Azeroth once more. Despite it''s perils.  Our path may be different but some may argue that it is far more rigorous. To be a templar means to maintain extremely precise control of your emotions, your combat flow, and your mind.  In order to keep myself healthy I enjoy meditating under the waterfall here in Northshire Valley. There is a statue there to remember one of the fallen heroes of the Alliance, and it is there that I find the peace to meditate. You must use your agile movement to reach the statue.  Please, visit the area yourself. Tell me what you experience when you return.', '', 'Visit the waterfall in Northshire Valley.', 685037, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Visit the waterfall in Northshire Valley.', '', '', ''),
(200017, 2, 3, 3, -516, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 661317, 1, 1505015, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Blood Is Power', 'Collect the Tome of Blood from the Defias Blood Wizard.', 'Ahh, $C. Your day has finally come.  Blood. Something you should be well acquainted with at this point, in some way or another. Blood is life. But blood, as you will soon learn, is also power.  I want you to imagine what you can be capable of in a world in which you can control the very life essence of another beings body. To simply crush their insides with the flick of a wrist...  Intoxicating.  In due time, you will learn more. For now, I require your assistance in pursuing my own studies and through this I will also be able to help you learn.   Nearby is a tome, that of which the local bandits have become privy too, and one of which I require for my studies. One of them has my tome - a Blood Wizard. Collect it for me, I''m sure one of them has it on them.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661316, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(199999, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -8799.29, -412.934, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Ranger''s Path', 'Find Owen''s falcon in the Northshire Valley area.', 'Being a Ranger is more than just picking up a bow, or fighting from the cover of the trees, $n.  Being a Ranger, at its core, means that you have a profound connection to the wilds. You are its protector.  I sent my falcon, Jo, to scout the surrounding areas, but he has not returned.   Please, find him and direct him to return back to me.', '', 'Find Owen''s falcon in the Northshire Valley area.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200000, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 200001, 3, 0, 0, 0, 0, 0, 0, 662316, 0, 0, 375250, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Surprise Attack!', 'Slay the suspicious creature.', 'Something is rustling in the nearby bushes.  You''re under attack! ', '', 'Tend to the falcon.', 299222, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200001, 2, 3, 3, -505, 0, 0, 0, 0, 0, 0, 0, 2, 70, 0, 0, 0, 0, 0, 662317, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 818000, 1, 727000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Falcons Are Friends', 'Use the Red Vial on the falcon.', 'You find a note attached to the falcon that reads:  <If you are reading this, you have found my friend. Attached to this note is a small red vial. Give it to him if he is injured, and he will know what to do next.>', '', 'Return to your trainer.', 685011, 0, 0, 0, 1, 0, 0, 0, 662317, 662316, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 'Tend to Jo''s wounds', '', '', ''),
(200165, 2, 3, 3, -530, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 553122, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Perfect Timing', 'Find Soridormi''s wand in Northshire Abbey.', 'Ahhh, $N, I saw your arrival long ago. Now it is time to teach you what it means to be a Chronomancer. To weave the very fabric of space and time. To be equivalent to a god...   Let me not get ahead of myself. For you, $N, are new to the world of chronomancy, and before I can allow you to inhabit this world with such latent power... you must learn how to control yourself.  As a Chronomancer, you are a master of time magic. This means you must respect time on the most foundational of levels. It just so happens that I left my wand somewhere in the abbey.   You have 2 minutes. Find it for me.', '', 'Return to Soridormi.', 0, 0, 0, 0, 0, 0, 0, 0, 661335, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200040, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200041, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of Death', 'Find and interact with the ritual circle.', 'Greetings, $C. Glad you could join me in the graveyard today.  Beautiful day, isn''t it?  It seems you''ve already been acquainted with undeath, I am impressed by your ability to raise the dead.   Perhaps you could be used to my benefit, which I''m sure you would not mind. I have a particularly powerful Undead that I wish to summon, but I dare not attempt it myself - I am far too important.  You, however, could learn quite a lot by succeeding here. And if you are to fail? I will simply raise you as my own.  Do not overthink it. Let me mark your map to the location of where my ritual must be had. You must collect specific items in order to complete the ritual.  Now, be gone.', '', 'Interact with the ritual circle.', 685121, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Find the ritual circle', '', '', ''),
(200041, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 200042, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Death Calls', 'Kill Defias Bandits and loot their bones, flesh, and skull.', 'There is a note on the floor by the ritual circle. In order to summon the Undead monstrosity, I must bring the following ingredients to the ritual circle.  - Bones - Fresh Flesh - Skull  The nearby Defias bandits have just what is needed.', '', 'Return to the ritual circle.', 0, 0, 0, 0, 0, 0, 0, 0, 458421, 458422, 458423, 0, 0, 0, 1, 1, 1, 0, 0, 0, '', '', '', ''),
(200042, 2, 3, 3, -521, 0, 0, 0, 0, 0, 0, 0, 2, 55, 0, 0, 0, 0, 0, 0, 0, 0, 660053, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Dead', 'Kill the Undead Monstrocity.', '<The materials dissipate into the ritual circle into a puff of smoke>  ...something seems off.  The summon has failed, inspect the ritual circle again. But be careful, it is unstable.', '', 'Return to your trainer.', 299232, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200120, 2, 3, 3, -528, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 293203, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Way of the Pyromancer', 'Defeat Scorch and acquire his heart.', 'I''ve seen you around, $N.  You''ve been reckless with your magics and careless with your studies.   Pyromancy is a dangerous art, and if you lose control you could end up burning both yourself and the world around you.  This is why I have decided to take you under my wing and show you the way of the Pyromancer. Your first mission to defeat a rogue fire elemental that has been summoned by a group of outlaw Pyromancers and left to wreak havoc on the surrounding area.  They bound it to a campfire in the hills near the Defias encampment, many innocents could be harmed if they peer into the flame.  Defeat it, and bring me back it''s heart.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 662331, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200071, 2, 3, 3, -522, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532803, 1, 532804, 1, 532881, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Going MAD!', 'Kill Brother Sammuel.', 'You have arrived at the most opportune time, $N.  I have heard the whispers of the great beyond. It tells me of a particularly dangerous individual to our cause. I need you to destroy them, swiftly.  If you do this I will reward you with a weapon fit for a follower of the Old Gods themselves.  The individual you''re looking for lays inside the church here. Somewhere in the Library Wing. They go by the name of "Brother Sammuel". End him.', '', 'Return to your trainer.', 299235, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(200058, 2, 3, 3, -507, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 454381, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Lost Pendant', 'Find the lost pendant.', 'Greetings, $C. You have arrived at the perfect time.  I have lost a pendant of mine that is quite powerful. Lost may be the wrong word, but alas, we best not get lost in the semantics.  Well, I guess I owe it to you to at least explain what happened if you''re going to help me. So here goes.  I was attempting to convert the local Defias to follow the Sun of An''she and explaining the connection to the Holy Light... but they did not take kindly to this and ran me off.  In my haste, I dropped my pendant. Please, find it for me.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663319, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, '', '', '', ''),
(200065, 2, 3, 3, -520, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 415000, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ingenuity At It''s Finest!', 'Collect 3 Scrap Metal.', 'Why I''ll be! Howdy there neighbor!   I see you be the tinkerin'' type and I was honestly on the look out for one like you. I''m tryin'' to make a special type of gun, a homemade gun some might say, but I need some more metal.  There is some metal out there near the kobold camps that could be used to create a gun for you and me. Collect me some and I''ll go tinkerin'' away!', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 663320, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, '', '', '', ''),
(200037, 2, 3, 3, -508, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 0, 0, 0, 540070, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Call of the Shadowlands', 'Visit Old Man Jenkins in Northshire Valley.', 'Smirk one more time when looking at my helmet, and I''ll put these blades in your chest, $N.    ...you are bold. I can sense you have come to me to learn. I do have a simple task for you today, young $C.    In the valley is a man who is nearing his end. In his prime, he was a behemoth on the battlefield and took many lives. But now, he lives a quaint life in his own home in the valley.    He will die and the Shadowlands will claim him. But today is not his day. Yet, I can feel his yearning to leave this plane, but he is unaware of what lays before him once he is gone.    You may not have expected such a task, but I would humbly ask you to pay him a visit and have a chat.', '', 'Return to your trainer.', 685022, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chat with Old Man Jenkins', '', '', ''),
(200109, 2, 3, 3, -527, 0, 0, 0, 0, 0, 0, 0, 3, 55, 0, 0, 0, 0, 0, 661329, 0, 0, 293202, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Runes of Power', 'Figure out the riddle etched on the runestone.', 'Greetings, $N. I''m glad you could finally join me, I have awaited your arrival.  Today, a simple lesson in problem solving for an aspiring Runemaster such as yourself. Perhaps you will succeed, perhaps you will not.  Here, I have a rune. Etched on the rune is a riddle. Figure the riddle out and return to me.   A hint? The best I can do is tell you that the answer to this riddle lays within this abbey. Not without.  I will know when you return if you have figured it out or not, do not worry. Succeed, and I will reward you.', '', 'Return to your trainer.', 0, 0, 0, 0, 0, 0, 0, 0, 661330, 661329, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, '', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

UPDATE `quest_template` SET `TimeAllowed` = 120 WHERE `ID` = 200165;

DELETE FROM `quest_template_addon` WHERE `ID` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(49976, 0, 32768, 7, 1, 0),
(49977, 0, 131072, 7, 1, 0),
(49978, 0, 262144, 7, 1, 0),
(49979, 0, 524288, 7, 1, 0),
(49980, 0, 1048576, 7, 1, 0),
(49981, 0, 2097152, 7, 1, 0),
(49982, 0, 4194304, 7, 1, 0),
(49983, 0, 8388608, 7, 1, 0),
(49984, 0, 16777216, 7, 1, 0),
(49985, 0, 134217728, 7, 1, 0),
(49986, 0, 67108864, 7, 1, 0),
(49987, 0, 536870912, 7, 1, 0),
(49988, 0, 2147483648, 7, 1, 0),
(49990, 0, 2048, 7, 1, 0),
(49991, 0, 4096, 7, 1, 0),
(49992, 0, 16384, 7, 1, 0),
(199999, 0, 1048576, 49980, 0, 0),
(200000, 0, 1048576, 199999, 1, 0),
(200001, 0, 1048576, 200000, 1, 0),
(200017, 0, 524288, 49979, 0, 0),
(200027, 0, 4096, 49991, 0, 0),
(200028, 0, 4096, 200027, 0, 0),
(200037, 0, 536870912, 49987, 0, 0),
(200040, 0, 4194304, 49982, 0, 0),
(200041, 0, 4194304, 200040, 0, 0),
(200042, 0, 4194304, 200041, 0, 0),
(200055, 0, 16384, 49992, 1, 0),
(200058, 0, 67108864, 49986, 0, 0),
(200065, 0, 134217728, 49985, 0, 0),
(200071, 0, 16777216, 49984, 0, 0),
(200077, 0, 262144, 49978, 0, 0),
(200086, 0, 32768, 49976, 0, 0),
(200087, 0, 32768, 200086, 0, 0),
(200088, 0, 32768, 200087, 0, 0),
(200104, 0, 2048, 49990, 0, 0),
(200109, 0, 2147483648, 49988, 1, 0),
(200114, 0, 131072, 49977, 0, 0),
(200115, 0, 131072, 200114, 0, 0),
(200116, 0, 131072, 200115, 0, 0),
(200120, 0, 8388608, 49983, 0, 0),
(200165, 0, 2097152, 49981, 0, 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(49976, 'Excellent, $N! You have heeded the storm''s call and proven yourself worthy. The power of wind and lightning flows through you now. As a Stormbringer, you will command the very forces of nature itself.$B$BWelcome to the path of the tempest. Let your enemies tremble before your elemental fury!'),
(49977, 'Well done, $N! You understand the sacred duty that comes with this calling. A Guardian stands as the shield between innocence and evil, never yielding, never breaking.$B$BYour training begins now. Remember - your life belongs to those you protect. Honor that trust with every breath you take.'),
(49978, 'The Light shines brightly within you, $N! You have embraced the Templar''s path and dedicated your soul to divine service. Through faith and devotion, you will become an instrument of holy justice.$B$BYour sacred duty begins this day. May your conviction never waver, and your faith burn eternal.'),
(49979, 'Impressive, $N. You show no fear of the crimson path, and that speaks well of your potential. Blood magic is not for the weak-willed - it demands sacrifice, understanding, and respect for the power that flows through all living things.$B$BYour training begins now. Remember - blood given freely holds more power than blood taken by force.'),
(49980, 'Nature has chosen well, $N. You carry the spirit of the wild within you, and the ancient ways call to your blood. As a Ranger, you will be the bridge between civilization and the untamed lands.$B$BWelcome to the brotherhood of the wild. May your aim be true and your path lead to freedom.'),
(49981, 'Fascinating, $N. You perceive the flow of time itself, a gift granted to very few mortals. As a Chronomancer, you will learn to bend causality to your will and walk between the moments.$B$BTime is your ally now. Use this power wisely, for the consequences of temporal manipulation echo across all realities.'),
(49982, 'You have potential, $N. Death holds no fear for you, and that is... refreshing. Too many flee from the natural order of things. As a Necromancer, you will learn to work with death rather than against it.$B$BYour education in the dark arts begins now. Remember - death is not evil, merely inevitable. Guide it well.'),
(49983, 'Magnificent, $N! The flames dance eagerly around you, drawn to the fire in your soul. As a Pyromancer, you will learn that destruction and creation are merely two sides of the same coin.$B$BLet the cleansing fire burn within you! From the ashes of the old world, we will forge something new and beautiful.'),
(49984, 'Yesss, $N... the whispers told me you would come. You have been marked by powers beyond mortal comprehension, chosen to serve truths that lesser minds cannot grasp. The Old Gods smile upon you.$B$BMadness is merely clarity unbound, young cultist. Embrace the chaos, and let it reshape you into something... greater.'),
(49985, 'Brilliant, $N! I can practically hear the gears turning in that clever mind of yours. As a Tinker, you will learn to blend the precision of engineering with the wonder of magic - a fusion that will shape the future itself.$B$BYour apprenticeship in innovation begins today! Together, we will build wonders that will amaze and delight the world.'),
(49986, 'Blessed are you, $N! The sun''s radiance flows through your very being, marking you as one chosen for healing and renewal. As a Sun Cleric, you will bring hope to the hopeless and light to the darkest places.$B$BYour path of healing begins now. May your light never dim, and may you always bring dawn to those lost in darkness.'),
(49987, 'You understand, $N. Good. Too many fear death, not realizing it is simply another aspect of the natural order. As a Reaper, you will learn to guide souls to their proper rest and maintain the balance between life and death.$B$BYour service to the eternal cycle begins now. Death comes for all, but through your work, it need not be feared.'),
(49988, 'Ancient power recognizes ancient power, $N. You possess the rare gift to read the first language of magic - the runes that bind power to matter itself. This is knowledge from the dawn of the world.$B$BYour study of runic magic begins today. The old ways endure because they are eternal. May you prove worthy of such trust.'),
(49990, 'Excellent! I can see the fire in your eyes, $N. The ancient ways call to those with strength in their hearts.$B$BThe path of the barbarian is not for the weak-willed. You will learn to channel your rage, to let the beast within guide your strikes. Your enemies will flee before your fury, and your allies will fight harder knowing you stand beside them.$B$BThis is only the beginning of your journey. The wild has many lessons to teach, and I will be here to guide you when you are ready. Welcome to the brotherhood of the berserker!'),
(49991, 'The spirits are pleased, $N. I can hear their approval in the whispers that surround you.$B$BYou have chosen the path of shadow and healing, of death and rebirth. As a witch doctor, you will walk between worlds - speaking with the dead, commanding the spirits, wielding both corruption and restoration as your tools.$B$BThe loa have marked you as their own. You will learn to brew potions that heal and hexes that harm, to call upon ancestral wisdom and bind the very essence of your enemies. This is a sacred responsibility, one that has been passed down through countless generations.$B$BSeek me out when you are ready to learn the deeper mysteries. The spirits are restless, and they have much to teach you.'),
(49992, 'The Light shines upon you, $N. I can feel its blessing in your very presence.$B$BYou have accepted the sacred covenant of the witch hunter. You are now bound by holy purpose - to seek out evil in all its forms and purge it with righteous fire. This is not merely a calling, it is a divine mandate.$B$BYour faith will be your weapon, your conviction your armor. You will learn to channel the Light into devastating attacks against the unholy, to protect the innocent with blessed barriers, and to see through the deceptions of demons and undead.$B$BRemember always: evil may hide in shadow, but it cannot withstand the purifying flame of justice. Stand ready, hunter. The darkness will not wait, and neither must we.'),
(200104, ''),
(200027, 'Oh, thank you, thank you! I feel better now.'),
(200028, 'What? You didn''t expect me to be friends with a Kobold?$B$BLil Wa''zoo has already reported back to me and told me of your deeds. He is now back in the mines, spying for us. Hahaha!$B$BHe told me to give you this.'),
(200055, 'Yet another evil creature banished from our world.$B$B... and yet.$B$BStill so many others to destroy. Be vigilant.$B$BHere, take these, let them guide you in your battles with evil.'),
(200086, ''),
(200087, ''),
(200088, ''),
(200114, ''),
(200115, ''),
(200116, ''),
(200077, ''),
(200017, 'A Defias Blood Wizard?$B$BInteresting...$B$BWell, upon further inspection, this tome is worthless. You can have it.$B$BReturn to me in the future when you are stronger. Maybe we can work together again.'),
(199999, 'This falcon is injured and there is a note carefully tied around its leg.'),
(200000, 'That creature must have been what attacked Jo.$B$BI should tend to Jo''s wounds.'),
(200001, 'Thank you for finding Jo. He has already returned to me, healthy as ever.$B$BI''ve already sent him on yet another scouting mission.$B$B... you''re saying a strange creature was seen near Jo and that it attacked you? That must have been the creature that injured my boy.$B$BI''ll have to look into this more. Based on your description, whatever this is, it''s not native to Elwynn Forest.'),
(200165, 'Welcome back, $N. I knew you would find my wand in time. Literally.$B$BThis wand is for you. I hope it serves you well. In fact, I know it will.'),
(200040, '<The ritual circle pulsates with necromantic energy>'),
(200041, '<The ritual circle begins to erupt. The monster is being summoned>'),
(200042, 'Well, that''s exactly what I thought would happen.$B$BBut, hey, you didn''t die. You''re a better Necromancer already!$B$BHere, I sent my other apprentices to gather the scraps from your battle, they made this.$B$BTake it and get out of my sight.'),
(200120, ''),
(200071, ''),
(200058, '<The pendant glimmers. It gives off a strong holy presence>$B$BYou have done well, $N. This pendant, I will give to you.$B$BKeep it close, for someday, you may need it again and I may teach you how to unlock far more of its powers.'),
(200065, 'Well, this is perfect!$B$BI was able to use this metal to finish a new gun for me and, guess what, I made you one too!$B$BTake it and have a great day!'),
(200037, 'You may not have expected such a task, $N. But it is important to understand that the Shadowlands call for those who are ready, and knowing when to claim a soul can be just as important as the reclamation of the soul itself.$B$BFor helping our friend out here, I will reward you with these boots. May they serve you well, as they are enchanted to allow you to walk on the surface of water itself.'),
(200109, '');

DELETE FROM `quest_request_items` WHERE `ID` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(49976, 'I can sense the storm''s energy crackling around you, $N. Have you brought the Storm Codex? The tempest calls to those who would master its power.'),
(49977, 'Stand tall, $N. Do you carry the Guardian''s Oath? A true protector must understand the weight of their sacred duty.'),
(49978, 'The Light shines upon you, $N. Have you brought the Templar''s Vow? Only through absolute devotion can one serve the divine will.'),
(49979, 'I smell the copper scent of power upon you, $N. Do you have the Blood Grimoire? Those who walk the crimson path must understand its price.'),
(49980, 'The wild speaks of you, $N. Have you brought the Ranger''s Guide? Nature recognizes its own, and calls you to the ancient ways.'),
(49981, 'Time flows strangely around you, $N. Do you possess the Temporal Manuscript? The streams of chronos have brought you to this moment.'),
(49982, 'The temperature drops in your presence, $N. Have you brought the Necromantic Journal? Death magic chooses its practitioners carefully.'),
(49983, 'I feel the heat radiating from you, $N. Do you carry the Flame Codex? Fire seeks those with the passion to wield its destructive beauty.'),
(49984, 'The whispers grow louder when you approach, $N. Have you brought the Forbidden Treatise? The Old Gods have marked you as their vessel.'),
(49985, 'I hear the sound of gears turning, $N. Have you brought the Engineering Manual? Innovation calls to minds capable of bridging magic and machinery.'),
(49986, 'Your presence warms this sacred place, $N. Do you have the Solar Scripture? The sun''s blessing flows through those chosen for healing.'),
(49987, 'The veil grows thin around you, $N. Do you carry the Death Manual? Those who serve the natural order understand death''s necessity.'),
(49988, 'Ancient power resonates within you, $N. Have you brought the Runic Inscription? The first magic recognizes one worthy of its secrets.'),
(49990, 'Ah, I sense the primal fury awakening within you. You carry the ancient tablet - have you read its words and embraced the beast that dwells in your blood?'),
(49991, 'The spirits whisper of your arrival, young one. You carry a sacred scroll, have you listened to the ancestors and accepted their wisdom?'),
(49992, 'The Light burns brightly around you, child. You bear the sacred letter of our order - have you read its words and accepted the holy burden of the hunt?'),
(200104, ''),
(200027, ''),
(200028, ''),
(200055, 'You have returned.'),
(200086, ''),
(200087, ''),
(200088, ''),
(200114, ''),
(200115, ''),
(200116, ''),
(200077, ''),
(200017, 'Impressive. Who did you say had this tome again?'),
(199999, ''),
(200000, ''),
(200001, 'You''ve returned...and you''ve brought me back my vial. Good.'),
(200165, 'Ahh, you''ve returned.'),
(200040, ''),
(200041, '<You place the ingredients on the ritual circle>'),
(200042, 'Why have you returned?'),
(200120, ''),
(200071, ''),
(200058, 'You have returned.'),
(200065, 'You''re a true scrapper!'),
(200037, ''),
(200109, '');

-- Map markers the texts promise ("Let me mark your map", "I have marked her location"): the target spawn.
DELETE FROM `quest_poi` WHERE `QuestID` IN (200040, 200055);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(200040, 0, 0, 0, 30, 0, 0, 1),
(200055, 0, 0, 0, 30, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (200040, 200055);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(200040, 0, 0, -8918, -418),
(200055, 0, 0, -8960, -213);

DELETE FROM `creature_queststarter` WHERE `quest` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(197, 49976),
(197, 49977),
(197, 49978),
(197, 49979),
(197, 49980),
(197, 49981),
(197, 49982),
(197, 49983),
(197, 49984),
(197, 49985),
(197, 49986),
(197, 49987),
(197, 49988),
(197, 49990),
(197, 49991),
(197, 49992),
(50280, 200077),
(50282, 200165),
(50283, 200071),
(50286, 200058),
(50287, 200065),
(50287, 200087),
(50287, 200088),
(50289, 200037),
(50291, 200109),
(50292, 200017),
(50295, 200104),
(50324, 200114),
(50325, 200055),
(50340, 200120),
(85031, 200028),
(85031, 200115),
(85031, 200116),
(502770, 200086),
(502923, 200040),
(502960, 200027),
(503410, 199999),
(9300102, 200000),
(9300102, 200001);

DELETE FROM `creature_questender` WHERE `quest` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(50280, 49978),
(50280, 200077),
(50282, 49981),
(50282, 200165),
(50283, 49984),
(50283, 200071),
(50286, 49986),
(50286, 200058),
(50287, 49985),
(50287, 200065),
(50287, 200086),
(50287, 200087),
(50289, 49987),
(50289, 200037),
(50291, 49988),
(50291, 200109),
(50292, 49979),
(50292, 200017),
(50295, 49990),
(50295, 200104),
(50324, 49977),
(50324, 200116),
(50325, 49992),
(50325, 200055),
(50340, 49983),
(50340, 200120),
(85031, 200027),
(85031, 200114),
(85031, 200115),
(502770, 49976),
(502770, 200088),
(502923, 49982),
(502923, 200042),
(502960, 49991),
(502960, 200028),
(503410, 49980),
(503410, 200001),
(9300102, 199999),
(9300102, 200000);

DELETE FROM `gameobject_queststarter` WHERE `quest` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
VALUES
(9301100, 200041),
(9301100, 200042);

DELETE FROM `gameobject_questender` WHERE `quest` IN (49976, 49977, 49978, 49979, 49980, 49981, 49982, 49983, 49984, 49985, 49986, 49987, 49988, 49990, 49991, 49992, 199999, 200000, 200001, 200017, 200027, 200028, 200037, 200040, 200041, 200042, 200055, 200058, 200065, 200071, 200077, 200086, 200087, 200088, 200104, 200109, 200114, 200115, 200116, 200120, 200165);
INSERT INTO `gameobject_questender` (`id`, `quest`)
VALUES
(9301100, 200040),
(9301100, 200041);

-- Letter pages: 1001, 5001, 5003, 5004, 5005, 5008, 5009, 5012 pagetextcache;
-- 1002, 1003, 5002, 5006, 5007, 5010, 5011, 5013 written for this build in the trainers' voices (INFERRED).
DELETE FROM `page_text` WHERE `ID` IN (1001, 1002, 1003, 5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010, 5011, 5012, 5013);
INSERT INTO `page_text` (`ID`, `Text`, `NextPageID`, `VerifiedBuild`)
VALUES
(1001, 'The path of raw fury is simple: Strength flows from within. Rage is honest. Civilization makes you weak. Embrace the beast that dwells in your blood. Let primal instinct guide your strikes, and your enemies will know true terror. Cast aside the chains of society and unleash your inner savage. If you feel the burning rage within, come speak to me in Northshire Valley. Battle awaits. -Amanda the Reaver, Barbarian Trainer', 0, 0),
(1002, 'The spirits are loud tonight, $N. They rattle the bones and hiss through the smoke, and they keep saying your name.$B$BA witch doctor walks between two worlds. The same hand that brews a draught to close a wound can stir a hex that rots a foe from within. Sseratus teaches both, and asks only that you listen.$B$BIf you hear the drums as well, find me at Northshire Abbey. Bring an open mind.$B$B-Doctor Yara, Witch Doctor Trainer', 0, 0),
(1003, 'Evil wears a friendly face, $N. It smiles at the market, bakes bread for the neighbours and curses them the moment their backs are turned.$B$BA witch hunter learns to see past the smile. Silver, fire and faith are our tools, and patience is the sharpest of them.$B$BIf you have felt that cold prickle at the back of your neck, you are ready to learn. Find me outside the west side of Northshire Abbey.$B$B-Deacon Frost, Witch Hunter Trainer', 0, 0),
(5001, 'The storm speaks in thunder and lightning, $N. I have walked with tempests since I was but a child, learning to hear their voice in the howling wind. The elements are not servants - they are partners. Respect them, and they will lend you their fury. Seek me in Northshire Valley when you are ready to embrace the chaos of nature itself. The sky grows restless, and it needs those who understand its language. -Niki Thesla, Stormbringer Trainer', 0, 0),
(5002, 'I will stand where others fall. I will hold the line when the line is all that remains. I will shield the weak, and I will not break.$B$BThose are the words, $N. Speaking them is easy; living them is not. If they stir something in you, come find me in the south hall of Northshire Abbey and we will see what you are made of.$B$B-Vanguard Gus, Guardian Trainer', 0, 0),
(5003, 'By the Light''s eternal grace... Faith without action is hollow. Action without faith is chaos. You have been called to be more than a mere follower - you are to become a living weapon of divine will. The path is narrow and demanding. Come to me in Northshire Valley only if you are prepared to surrender everything to the Light''s service. Perfection is not optional. -Brother William, Templar Trainer', 0, 0),
(5004, 'Blood remembers everything, $N. Every spell cast, every wound healed, every life saved - it all comes with a price paid in crimson. Do not mistake this for evil magic. Blood is honest. Blood is fair. It takes only what is given and gives power in return. Find me in Northshire Valley if you have the courage to pay the true cost of power. -Whisp the Silent, Bloodmage Trainer', 0, 0),
(5005, 'The old paths call to you... Civilization builds walls. Nature knows no boundaries. I have tracked through every forest, climbed every mountain, and learned the secret names the wind whispers to the trees. You have the wanderer''s heart, $N. Come to Northshire Valley, and I will teach you to read the stories written in footprints and hear the conversations of ravens. The wild is patient, but it will not wait forever. -Owen of Moonbrook, Ranger Trainer', 0, 0),
(5006, 'You are reading this exactly when you were meant to, $N. I made sure of it.$B$BTime is not a river that simply carries us along. To a Chronomancer it is a loom, and every moment is a thread that can be pulled, knotted or cut. Pull the wrong one and the whole tapestry unravels.$B$BCome to the library of Northshire Abbey, upstairs. Do not be late. I will know.$B$B-Soridormi, Chronomancer Trainer', 0, 0),
(5007, 'Death is a door, $N, and most people are too frightened to look through the keyhole. Not us.$B$BThe dead remember how to stand, how to fight and how to obey. All they lack is a will to guide them, and that is where a Necromancer comes in. The priests will call it an abomination. The priests also die, eventually.$B$BYou will find me by the graveyard of Northshire Abbey. Fitting, isn''t it?$B$B-Halbert the Scoundrel, Necromancer Trainer', 0, 0),
(5008, 'BURN EVERYTHING. Sorry, got a bit carried away there! But fire is passion, $N, and passion cannot be contained by politeness. I have seen entire forests reborn from ash. I have watched mountains melt and reform. Destruction is not the opposite of creation - it IS creation! Come find me in Northshire Valley and let''s set something beautiful on fire together. -Firelord Kobe, Pyromancer Trainer', 0, 0),
(5009, 'Do you hear them whispering, $N? They speak from spaces between spaces, from the void that dreams of becoming real. Most call it madness, but madness is just another word for truth that hurts to understand. The stars are right. The ancient ones stir. And you... you have been chosen to hear their beautiful, terrible songs. Seek me in Northshire Valley. Bring your sanity - you won''t be needing it much longer. -Patal the Mad, Cultist Trainer', 0, 0),
(5010, 'Every dawn is a promise kept, $N. The sun does not ask whom it warms; it simply rises and gives.$B$BA Sun Cleric carries that light into the darkest places: onto the battlefield, into the sickroom, and into the hearts of those who have forgotten it. The Light and An''she are two names for the same warmth.$B$BSeek me in the library wing of Northshire Abbey, and let us begin at sunrise.$B$B-Chaplain Nysoni, Sun Cleric Trainer', 0, 0),
(5011, 'Howdy, $N! If you''re reading this, you''ve got the tinkerin'' itch, and there''s only one cure: more tinkerin''.$B$BGears, springs, a pinch of blasting powder and a whole lot of stubbornness - that''s all a Tinker needs. Well, that and somebody to test the prototypes on. Don''t worry, most of ''em don''t explode.$B$BCome find me by the wagons west of Northshire Abbey. Bring your own goggles.$B$B-Norman Goldshire, Tinker Trainer', 0, 0),
(5012, 'Death is not cruel, $N. Death is necessary. I have guided ten thousand souls to their proper rest. Warriors who died with honor. Civilians taken too soon. Even monsters who deserved a chance at redemption. Each crossing taught me something new about the balance between life and death. Seek me in Northshire Valley when you are ready to serve the eternal cycle. -Troes the Remover, Reaper Trainer', 0, 0),
(5013, 'Carve it once, carve it true, and the rune remembers forever, $N.$B$BA Runemaster does not borrow power the way a mage does. We write it into stone, into steel and into our own skin, and there it stays. Every rune is a riddle, and every riddle has an answer for those patient enough to find it.$B$BFind me in the south hall of Northshire Abbey. Bring a sharp mind.$B$B-Wanda Belezin, Runemaster Trainer', 0, 0);

-- ---------------------------------------------------------------------------
-- 6. Loot
-- ---------------------------------------------------------------------------
DELETE FROM `creature_loot_template` WHERE (`Entry`, `Item`) IN ((38, 458421), (38, 458422), (38, 458423), (38, 662330), (257, 661417), (9300100, 661316), (9300101, 662331));
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(38, 458421, 0, 35, 1, 1, 0, 1, 1, 'Defias Thug - Bones (Death Calls; Exiles creature_loot 35%)'),
(38, 458422, 0, 35, 1, 1, 0, 1, 1, 'Defias Thug - Fresh Flesh (Death Calls; Exiles creature_loot 35%)'),
(38, 458423, 0, 55, 1, 1, 0, 1, 1, 'Defias Thug - Skull (Death Calls; Exiles creature_loot 55%)'),
(38, 662330, 0, 25, 1, 1, 0, 1, 1, 'Defias Thug - Small Sword (Prioritizing Defense; Exiles creature_loot 25%)'),
(257, 661417, 0, 44, 1, 1, 0, 1, 1, 'Kobold Worker - Power Core (The Stolen Power Core; Exiles creature_loot 44%)'),
(9300100, 661316, 0, 100, 1, 1, 0, 1, 1, 'Defias Blood Wizard - Tome of Blood (Blood Is Power; the holder, INFERRED 100%)'),
(9300101, 662331, 0, 100, 1, 1, 0, 1, 1, 'Scorch - Heart of Scorch (The Way of the Pyromancer; INFERRED 100%)');

DELETE FROM `creature_questitem` WHERE (`CreatureEntry`, `Idx`) IN ((38, 1), (38, 2), (38, 3), (38, 4), (257, 0), (9300100, 0), (9300101, 0));
INSERT INTO `creature_questitem` (`CreatureEntry`, `Idx`, `ItemId`)
VALUES
(38, 1, 458421),
(38, 2, 458422),
(38, 3, 458423),
(38, 4, 662330),
(257, 0, 661417),
(9300100, 0, 661316),
(9300101, 0, 662331);

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (9301101, 9301102, 9301103, 9301104);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(9301101, 661335, 0, 100, 1, 1, 0, 1, 1, 'CoA Northshire class chain: Training Wand'),
(9301102, 661330, 0, 100, 1, 1, 0, 1, 1, 'CoA Northshire class chain: Eye of the Beholder'),
(9301103, 663319, 0, 100, 1, 1, 0, 1, 1, 'CoA Northshire class chain: Lost Pendant'),
(9301104, 663320, 0, 100, 1, 1, 0, 1, 1, 'CoA Northshire class chain: Scrap Metal');

DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` IN (9301101, 9301102, 9301103, 9301104);
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(9301101, 0, 661335),
(9301102, 0, 661330),
(9301103, 0, 663319),
(9301104, 0, 663320);

-- ---------------------------------------------------------------------------
-- 8. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9003100, 9003101, 9003102, 9003103, 9003104, 9003105, 9003106, 9003107, 9003108, 9003109, 9003110, 9003111, 9003112, 9003113, 9003114, 9003115, 9003120, 9003121, 9003122, 9003123, 9003124, 9003125, 9003126, 9003127, 9003128, 9003129) OR `guid` BETWEEN 9003100 AND 9003299;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9003100, 50295, 0, 0, 0, 1, 1, 1, -8913.97, -99.21, 81.92, 4.23, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Amanda the Reaver (Barbarian): yard west of the abbey between the human start and Marshal McBride, beside the gypsy wagon; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49990, z from surface.floor; faces 4.230 south-east across the yard, between the human start and McBride (the way players arrive)'),
(9003101, 502960, 0, 0, 0, 1, 1, 1, -8875.32, -207.59, 81.34, 3.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Doctor Yara (Witch Doctor): abbey rear yard beside the stable, under the tree; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49991, z from surface.floor; faces 3.210 south along the rear yard, the open side players come round the abbey from'),
(9003102, 50325, 0, 0, 0, 1, 1, 1, -8949.41, -173.84, 80.171, 1.01, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Deacon Frost (Witch Hunter): open ground west of the abbey by the graveyard trees; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49992, z from surface.floor; faces 1.010 north-north-west toward the human start and McBride, where players arrive'),
(9003103, 502770, 0, 0, 0, 1, 1, 1, -8878.25, -183.11, 81.941, 6.07, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Niki Thesla (Stormbringer): Northshire Abbey, main hall floor near Brother Paxton; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49976, z from surface.floor; faces 6.070 into the open hall, the longest clear line (places survey)'),
(9003104, 50324, 0, 0, 0, 1, 1, 1, -8906.3, -207.67, 81.94, 2.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Vanguard Gus (Guardian): Northshire Abbey, south hall (Hall of Arms) floor; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49977, z from surface.floor; faces 2.750 across the south hall (14 yd clear); the open-room line meets a pillar at 2.8 yd'),
(9003105, 50280, 0, 0, 0, 1, 1, 1, -8907.19, -210.78, 89.167, 2.06, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Brother William (Templar): Northshire Abbey, upper floor of the south hall, above Vanguard Gus; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49978, z from surface.floor; faces 2.060 into the open gallery'),
(9003106, 50292, 0, 0, 0, 1, 1, 1, -8938.88, -175.9, 80.486, 4.66, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Whisp the Silent (Bloodmage): west yard under the tree canopy, south of the abbey door path; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49979, z from surface.floor; faces 4.660 straight away from the canopy trunk 3.3 yd behind him, over the graveyard lawn (playtest: facing the trunk was awkward)'),
(9003107, 503410, 0, 0, 0, 1, 1, 1, -8872.82, -160.38, 80.068, 0.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Owen of Moonbrook (Ranger): north-west corner of the abbey by the hunters'' stalls (Eagan Peltskinner 4.6 yd); Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49980, z from surface.floor; faces 0.960, the open side, the same way as his neighbour Eagan Peltskinner'),
(9003108, 50282, 0, 0, 0, 1, 1, 1, -8852.45, -191.49, 89.314, 0.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Soridormi (Chronomancer): Northshire Abbey, library upper floor (Khelden Bremen, kept, 3.4 yd); Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49981, z from surface.floor; faces 0.960 into the open library floor'),
(9003109, 502923, 0, 0, 0, 1, 1, 1, -8920.47, -178.42, 80.885, 3.83, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Halbert the Scoundrel (Necromancer): recess of the abbey west wall above the graveyard; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49982, z from surface.floor; faces 3.830 out of the recess, its only open side (south-east)'),
(9003110, 50340, 0, 0, 0, 1, 1, 1, -8950.24, -210.71, 79.019, 1.96, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Koby the Incinerator (Pyromancer): south of the CoA hearse on the path west of the abbey; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49983, z from surface.floor; faces 1.960 west-north-west past the hearse toward the abbey yard path'),
(9003111, 50283, 0, 0, 0, 1, 1, 1, -8917.438, -164.774, 81.939, 4.468, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Patal the Mad (Cultist): Northshire Abbey, entry chapel, standing in front of the Wooden Bench (guid 26723): the point lies 0.51 yd from the bench centre along its facing, not on one of its four seat slots, so he stands 0.2 yd further forward (0.71 yd), clear of the seat edge at 0.39 yd; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49984, z from surface.floor; faces 4.468, the way the bench behind him faces'),
(9003112, 50286, 0, 0, 0, 1, 1, 1, -8853.59, -194.47, 81.932, 2.55, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Chaplain Nysoni (Sun Cleric): Northshire Abbey, library ground floor, Priestess Anetta''s post; 1.03 yd off the turn-in point, straight away from the Pilgrim''s Bounty turkey 241844, to keep 2.5 yd from it; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49986, z from surface.floor; faces 2.548, the stock facing of Priestess Anetta at this post'),
(9003113, 50287, 0, 0, 0, 1, 1, 1, -8905.17, -105.17, 81.849, 5.53, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Norman Goldshire (Tinker): yard west of the abbey by the water basin and the gypsy wagons; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49985, z from surface.floor; faces 5.530 east across the yard toward the abbey front, where players come from'),
(9003114, 50289, 0, 0, 0, 1, 1, 1, -8925.75, -199.67, 80.659, 2.88, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Troes the Remover (Reaper): graveyard south-west of the abbey (Dane Winslow 2.8 yd, Drusilla La Salle 4.2 yd); Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49987, z from surface.floor; faces 2.880, the open side, toward the yard path'),
(9003115, 50291, 0, 0, 0, 1, 1, 1, -8909.81, -216.7, 81.94, 1.58, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire trainer: Wanda Belezin (Runemaster): Northshire Abbey, south hall floor; Northshire: SOURCED-CLIENT QuestSuperTrack turn-in point of quest 49988, z from surface.floor; faces 1.580 into the open room (the wall is 4.0 yd ahead)'),
(9003120, 299235, 0, 0, 0, 1, 1, 1, -8859, -193, 81.932, 3.14, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Northshire Abbey, Library Wing ground floor ("Somewhere in the Library Wing", 200071), between the shelves 5.6 yd from Chaplain Nysoni; faces south toward the way in from the main hall'),
(9003121, 85031, 0, 0, 0, 1, 1, 0, -8628.8, -110.2, 88.907, 3.51, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Echo Ridge Mine side chamber by the Worn Shovel, just inside the mouth (Exiles zone claim 47,30 = the mine mouth; text: "in the Kobold mine"); kneeling, injured; faces the chamber opening players come through'),
(9003122, 299325, 0, 0, 0, 1, 1, 1, -8966.5, -289, 73.469, 0.99, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: north end of the river bridge on the road from the abbey to the vineyards, telling passers-by his grievances; faces the abbey road'),
(9003123, 9300102, 0, 0, 0, 1, 1, 0, -8800.79, -408.43, 75.172, 3.1, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: supply yard of the Defias-held Damaged Guard Tower, among the crates at the yard''s east edge where the scouting falcon came down: the nearest reachable floor to the SOURCED-CACHE quest point of 199999 (-8799.29, -412.93), 4.7 yd off, because the point itself lies on the yard''s steep east retaining edge with no navmesh; faces 3.10 into the yard, where the navmesh paths from the abbey arrive'),
(9003124, 9300103, 0, 0, 0, 1, 1, 0, -8677.65, -185.65, 92.28, 3.94, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: CoA farmhouse (Redridge_Human_Farm.wmo) north of the abbey, seated in the chair at his small table (low chair, stand state 4) facing the table; the furnished house with its armour stand is his "own home in the valley"'),
(9003125, 9300104, 0, 0, 0, 1, 1, 0, -8960.4, -212.9, 77.008, 1.25, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: outside the graveyard''s stone wall south-west of the abbey, an old villager tending the graves, 3.5 yd off the Northshire Peasant''s walk to the graveyard gate (path 802620); faces the fence''s west corner, where players from Deacon Frost come round'),
(9003126, 9300101, 0, 0, 0, 1, 1, 0, -8974, -465.5, 73.693, 0.98, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: draw in the hills south-east of the Defias camp, beside the campfire it is bound to; faces the fire'),
(9003127, 9300100, 0, 0, 0, 1, 1, 1, -8961.5, -442.5, 66.07, 1.26, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Defias camp, south end of the tent, facing the camp fire; one of the camp''s own bandits'),
(9003128, 9300100, 0, 0, 0, 1, 1, 1, -9040, -311, 73.771, 1.03, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: Northshire Vineyards among the Defias Thugs, by the water wagon he faces; the second holder so two players can take the tome at once'),
(9003129, 685037, 0, 0, 0, 1, 1, 0, -8739.5, -410.5, 81.707, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Northshire class chain: invisible walk-in credit for A Quiet Life at the foot of the Northshire falls, on the low rock between the pool''s east end and the cliff under Uther''s Statue; from here it sees the whole bank below the statue and falls and most of the pool within 15 yd, where the statue ledge itself cannot be reached on foot');

DELETE FROM `creature_addon` WHERE `guid` IN (9003121, 9003124) OR `guid` BETWEEN 9003100 AND 9003299;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(9003121, 0, 0, 8, 0, 0, 0, ''),
(9003124, 0, 0, 4, 0, 0, 0, '');

DELETE FROM `gameobject` WHERE `guid` IN (7912100, 7912101, 7912102, 7912103, 7912104, 7912105, 7912106, 7912107, 7912108, 7912109, 7912110, 7912111, 7912112, 7912113, 7912114, 7912115, 7912116, 7912117) OR `guid` BETWEEN 7912100 AND 7912199;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7912100, 9301100, 0, 0, 0, 1, 1, -8918.5, -418, 66.037, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Northshire class chain: clearing in the woods north of the Defias camp, 35 yd from its bandits (the note: "the nearby Defias bandits have just what is needed")'),
(7912101, 21282, 0, 0, 0, 1, 1, -8972, -462.5, 72.399, 0, 0, 0, 0, 1, 300, 100, 1, '', 'CoA Northshire class chain: the campfire Scorch is bound to, in the draw south-east of the Defias camp'),
(7912102, 9301105, 0, 0, 0, 1, 1, -8732.4, -416.4, 83.38, 2.45, 0, 0, 0.940806, 0.338946, 300, 100, 1, '', 'CoA Northshire class chain: the ledge above the pool 10 yd south of the SOURCED-ATLAS sighting of goober 251653, which lies on a 55-63 degree cliff face where the stand-in model floated up to 6 yd; z is the lowest floor under its footprint (83.38-84.33); faces the pool and the visit marker'),
(7912103, 9301101, 0, 0, 0, 1, 1, -8909.4, -183.3, 81.939, 1.2, 0, 0, 0.564642, 0.825336, 60, 100, 1, '', 'CoA Northshire class chain: Northshire Abbey, entry chapel floor beside the tall book stack, far from Soridormi''s library'),
(7912104, 9301102, 0, 0, 0, 1, 1, -8898.6, -181.2, 81.939, 2.9, 0, 0, 0.992713, 0.120503, 60, 100, 1, '', 'CoA Northshire class chain: Northshire Abbey, main hall, at the foot of the first stone bust (the riddle''s "silent watchers")'),
(7912105, 9301103, 0, 0, 0, 1, 1, -8941, -417.5, 66.024, 0.6, 0, 0, 0.29552, 0.955336, 60, 100, 1, '', 'CoA Northshire class chain: trail north of the Defias camp fire, where the chaplain fled'),
(7912106, 9301103, 0, 0, 0, 1, 1, -8931, -409, 66.564, 2.2, 0, 0, 0.891207, 0.453596, 60, 100, 1, '', 'CoA Northshire class chain: further along the same trail toward the river; a second spot so two players need not wait'),
(7912107, 9301104, 0, 0, 0, 1, 1, -8779.3, -115.8, 82.641, 0.4, 0, 0, 0.198669, 0.980067, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, beside the wheelbarrow'),
(7912108, 9301104, 0, 0, 0, 1, 1, -8763.5, -124.8, 83.527, 2, 0, 0, 0.841471, 0.540302, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, behind the tent'),
(7912109, 9301104, 0, 0, 0, 1, 1, -8775.5, -121.5, 82.964, 4.1, 0, 0, 0.887362, -0.461073, 120, 100, 1, '', 'CoA Northshire class chain: north kobold camp, west of the campfire'),
(7912110, 9301104, 0, 0, 0, 1, 1, -8756.5, -193.8, 85.762, 1.1, 0, 0, 0.522687, 0.852525, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, beside the campfire'),
(7912111, 9301104, 0, 0, 0, 1, 1, -8771.8, -170.2, 82.61, 5.2, 0, 0, 0.515501, -0.856889, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, by the crates at the tent'),
(7912112, 9301104, 0, 0, 0, 1, 1, -8759.5, -166, 84.098, 3, 0, 0, 0.997495, 0.070737, 120, 100, 1, '', 'CoA Northshire class chain: middle kobold camp, north edge'),
(7912113, 9301104, 0, 0, 0, 1, 1, -8781, -250.8, 82.548, 0.8, 0, 0, 0.389418, 0.921061, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, among the sacks'),
(7912114, 9301104, 0, 0, 0, 1, 1, -8808.2, -240.8, 82.188, 2.6, 0, 0, 0.963558, 0.267499, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, by the west tent'),
(7912115, 9301104, 0, 0, 0, 1, 1, -8797.8, -246.2, 82.4, 4.5, 0, 0, 0.778073, -0.628174, 120, 100, 1, '', 'CoA Northshire class chain: south kobold camp, north side of the fire'),
(7912116, 9301104, 0, 0, 0, 1, 1, -8674.8, -117.5, 91.554, 1.7, 0, 0, 0.75128, 0.659983, 120, 100, 1, '', 'CoA Northshire class chain: Echo Ridge Mine mouth, west side'),
(7912117, 9301104, 0, 0, 0, 1, 1, -8664, -126, 91.492, 5.9, 0, 0, 0.190423, -0.981702, 120, 100, 1, '', 'CoA Northshire class chain: Echo Ridge Mine mouth, inside the entrance');

-- ---------------------------------------------------------------------------
-- 9. Scripts
-- ---------------------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (-9003129, 85031, 9300102, 9300103, 9300104) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-9003129, 0, 0, 0, 10, 0, 100, 0, 1, 15, 1000, 1000, 1, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '[KC] Visit at the foot of the Northshire falls - On Player In Sight Within 15 Yards - Quest Credit ''Visit the waterfall in Northshire Valley'''),
(85031, 0, 0, 0, 8, 0, 100, 0, 801670, 0, 0, 0, 0, 0, 33, 685021, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Lil Wa''zoo - On Spellhit ''Loa''s Brew'' (Rank 1) - Quest Credit ''Save Lil Wa''zoo'''),
(85031, 0, 1, 0, 19, 0, 100, 0, 200028, 0, 0, 0, 0, 0, 12, 299223, 4, 300000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Lil Wa''zoo - On Quest ''Who Called For Da Docta?'' Accepted - Summon Zipi On The Player'),
(9300102, 0, 0, 0, 8, 0, 100, 0, 684328, 0, 0, 0, 0, 0, 33, 685011, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jo - On Spellhit ''Tend Jo''s Wounds'' (Red Vial) - Quest Credit ''Tend to Jo''s wounds'''),
(9300102, 0, 1, 0, 19, 0, 100, 0, 200000, 0, 0, 0, 0, 0, 12, 299222, 4, 300000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Jo - On Quest ''A Surprise Attack!'' Accepted - Summon Suspicious Creature On The Player'),
(9300103, 0, 0, 1, 62, 0, 100, 0, 930204, 0, 0, 0, 0, 0, 33, 685022, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Man Jenkins - On Gossip Option 0 Selected - Quest Credit ''Chat with Old Man Jenkins'''),
(9300103, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Man Jenkins - Linked - Say Line 0'),
(9300103, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Man Jenkins - Linked - Close Gossip'),
(9300104, 0, 0, 1, 8, 0, 100, 0, 512352, 0, 0, 0, 0, 0, 33, 685221, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Agatha - On Spellhit ''Witcher''s Torch'' - Quest Credit ''Find the Witch'''),
(9300104, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Agatha - Linked - Say Line 0'),
(9300104, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 299333, 4, 300000, 1, 0, 0, 8, 0, 0, 0, 0, -8960.4, -212.9, 77.008, 1.25, 'Old Agatha - Linked - Summon Witch At Her Place, Attacking The Player'),
(9300104, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Old Agatha - Linked - Despawn, Respawn In 60 Seconds');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (9301100, 9301105) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(9301100, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685121, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Use - Quest Credit ''Find the ritual circle'''),
(9301100, 1, 1, 0, 19, 0, 100, 0, 200042, 0, 0, 0, 0, 0, 12, 299232, 4, 300000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Quest ''Call of the Dead'' Accepted - Summon Undead Monstrosity On The Player'),
(9301100, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 299232, 4, 300000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ritual Circle - On Use - Summon Undead Monstrosity again if none is near'),
(9301105, 1, 0, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 685037, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Uther''s Statue - On Use - Quest Credit ''Visit the waterfall in Northshire Valley''');

DELETE FROM `conditions` WHERE `SourceEntry` = 9301100 AND `SourceTypeOrReferenceId` = 22;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(22, 3, 9301100, 1, 0, 9, 0, 200042, 0, 0, 0, 0, 0, '', 'Ritual Circle - re-summon only while Call of the Dead is taken'),
(22, 3, 9301100, 1, 0, 29, 1, 299232, 20, 0, 1, 0, 0, '', 'Ritual Circle - re-summon only if no living Undead Monstrosity is within 20 yd');

DELETE FROM `conditions` WHERE `SourceEntry` IN (299235, 9301102) AND `SourceTypeOrReferenceId` = 30;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(30, 0, 299235, 0, 0, 9, 0, 200071, 0, 0, 0, 0, 0, '', 'Brother Sammuel - visible only while Going MAD! (200071) is taken'),
(30, 1, 9301102, 0, 0, 9, 0, 200109, 0, 0, 0, 0, 0, '', 'Eye of the Beholder - visible only while Runes of Power (200109) is taken');
