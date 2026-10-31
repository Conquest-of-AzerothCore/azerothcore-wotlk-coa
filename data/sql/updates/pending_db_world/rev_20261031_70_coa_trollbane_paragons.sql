-- Hardcore - Trollbane (challenge 214, Prestige 428) requires killing the troll Paragons before set levels, but
-- none of them existed, so the trial could not be completed.
-- Names, subtitles, rank, type, models and mana modifiers: Ascension client creature cache
-- (boxcoa/ascension-data, every CoA mode). Levels and positions: Ascension footage and in-game .gps.
-- Health: on Ascension these trial NPCs are not raised by the open-world health scaling. Zazera took 13480
-- damage to kill (with overkill), what her cached modifier 9.0 gives without scaling (13302); Yahola has 68290,
-- each Hand of Yahola 24935 and each Risen Servant 5420. Our open-world scaling (CoA.CreatureScaling.World.Health,
-- 1.17 + 0.013 * level) multiplies every world creature's health, so each modifier here is divided by it at the
-- creature's level: Vazul 11034, Zazera 13301, Yahola 68291, a Hand 24935, a Risen Servant 5420 and a level 35
-- Elite Witherbark Headhunter 4625 after scaling (the cached values, within 1).
-- Damage modifiers are estimates in line with nearby elite bosses (Mogh the Undying 2.4, Kazkaz the Unholy 2.8).
-- Abilities: from Ascension footage. In a 140 s kill Yahola starts a Spectral Bolt every 3.5-4 s and an
-- uninterruptible Spectral Volley about 10 s into the fight and every 11 s after. She casts Army of the Dead
-- (254626 -> 254627) once, as she drops below 99% health; it raises Risen Servants (254171, 5420 health at level 59).
-- Vazul opens with Chains of Ice (113) and follows at once with Shadow Bolt Volley (9081, the Witherbark caster
-- Zalas Witherbark's). She died 11 s in without casting again, so her repeat timers (12-16 s) are estimated.
-- Zazera carries Burning Sands (254622: her hits and harmful spells add Burning Sands fire damage, 254621; "Maybe there
-- is some way to cool down this effect..."). In footage she spins under Firestorm (254619, a Bladestorm that whirlwinds
-- once a second for 6 s); she opens with it as soon as she is pulled; its repeat (25-30 s) is estimated. Two Water
-- Buckets on the tower (one use each, back after 40 s) cast Water Bucket (254623) for whoever uses them: a splash that
-- only hits Zazera, within 5 yards of the user. In game it plays the splash; the spell itself has only a dummy effect,
-- so Zazera's AI does the rest: while she burns, the splash puts out Burning Sands and stuns her with Extinguished
-- (254624, 5 s). Burning Sands returns 30 s after a splash (no data gives its real timer) and when she resets. With
-- each bucket gone for 40 s, the fight is a loop: kite her to one bucket, splash and stun her, kite her to the other
-- before she rekindles. The bucket model is the Hallow's End Water Bucket (display 7484), matching footage; Ascension's
-- own bucket object was not captured, so it is CoA object 2541700, outside the range of restored Ascension objects. Out
-- of combat Yahola channels Blackfathom Channeling (8734), the shadowy casting pose of the static Mossflayer
-- Shadowhunters around the Mazra'Alor altar on Ascension. The spell is a channel, so its pose and shadow only show
-- while it is cast; the Shadowhunters' stock creature_addon aura showed nothing. Creatures that carry that addon aura
-- (the static altar Shadowhunters, and Yahola) cast the channel whenever they are out of combat and stop it when they
-- engage; evading restores the aura. Spectral Volley needs no change to be uninterruptible: its PreventionType is 0, so
-- interrupts and silences cannot stop it.
-- Loot: of their Ascension drops only Vazul's three Whispershade greens are her own; the rest (Ephemeral Key,
-- recipes, world greens) are shared world drops. Their chances were not recorded, so they use a common rare-elite
-- rate: 20% each in one group, at most one per kill (as Geomancer Flintdagger's own greens).

-- Vazul <Witherbark Paragon> (254168): level 40 elite in the Witherbark Village cave, Arathi Highlands,
-- guarded by two Elite Witherbark Headhunters (254176, level 34-35). Objective: kill before level 40.
-- Zazera <Sandfury Paragon> (254170): level 45 elite on top of the Sandsorrow Watch tower, Tanaris, in place of
-- the Sandfury Firecaller spawn there (guid 21812). Objective: kill before level 45.
-- Yahola <Mossflayer Paragon> (254169): level 59 elite on the Mazra'Alor temple steps, Eastern Plaguelands, flanked
-- by the Left and Right Hand of Yahola (254172, 254173, level 59 elites). Objective: kill before level 59.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(254168,0,0,0,0,0,'Vazul','Witherbark Paragon',NULL,0,40,40,0,654,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,254168,0,0,0,0,200,300,'SmartAI',0,1,5.325041,2,1,1,0,0,1,0,0,'',12340),
(254170,0,0,0,0,0,'Zazera','Sandfury Paragon',NULL,0,45,45,0,37,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,0,0,0,0,0,300,450,'SmartAI',0,1,5.127537,3,1,1,0,0,1,0,0,'',12340),
(254169,0,0,0,0,0,'Yahola','Mossflayer Paragon',NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,2.5,2000,2000,1,1,2,32768,2048,0,0,7,0,0,0,0,0,0,600,900,'SmartAI',0,1,14.882018,3.6,1,1,0,0,1,0,0,'',12340),
(254171,0,0,0,0,0,'Risen Servant',NULL,NULL,0,59,59,0,37,0,1,1.14286,1,1,20,0,0,1,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,0,0,'SmartAI',0,1,0.944782,1,1,1,0,0,1,0,0,'',12340),
(254172,0,0,0,0,0,'Left Hand of Yahola',NULL,NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,200,400,'',0,1,4.347349,1,1,1,0,0,1,0,0,'',12340),
(254173,0,0,0,0,0,'Right Hand of Yahola',NULL,NULL,0,59,59,0,37,0,1,1.14286,1,1,20,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,200,400,'',0,1,4.347349,1,1,1,0,0,1,0,0,'',12340),
(254176,0,0,0,0,0,'Elite Witherbark Headhunter',NULL,NULL,0,34,35,0,654,0,1,1.14286,1,1,18,1,0,1.5,2000,2000,1,1,1,32768,2048,0,0,7,0,0,0,0,0,0,74,490,'',0,1,2.332377,1,1,1,0,0,1,0,0,'',12340) ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`), `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`), `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`), `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`), `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`), `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`), `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`), `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`), `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`), `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (254168, 254169, 254170, 254171, 254172, 254173, 254176);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(254168,0,254026,1,1,12340),
(254169,0,254027,1,1,12340),
(254170,0,254028,1,1,12340),
(254171,0,26858,1,1,12340),
(254172,0,945433,1.5,1,12340),
(254173,0,945433,1.5,1,12340),
(254176,0,3998,1,1,12340),
(254176,1,28226,1,1,12340);

DELETE FROM `creature` WHERE `guid` IN (21812, 2541680, 2541681, 2541682, 2541683, 2541684, 2541685, 2541686);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(2541680,254168,0,45,317,1,1,0,-2059.795,-3269.7915,49.6225,3.1131,300,0,0,1,0,0,0,0,0,'',NULL,0,'Vazul <Witherbark Paragon>'),
(2541681,254176,0,45,317,1,1,0,-2058.8413,-3264.2786,49.9604,3.5953,300,0,0,1,0,0,0,0,0,'',NULL,0,'Elite Witherbark Headhunter (Vazul)'),
(2541682,254176,0,45,317,1,1,0,-2060.2793,-3274.6387,50.393,2.7118,300,0,0,1,0,0,0,0,0,'',NULL,0,'Elite Witherbark Headhunter (Vazul)'),
(2541683,254170,1,440,979,1,1,0,-7190.723,-3004.4932,31.2314,5.9651,300,0,0,1,0,0,0,0,0,'',NULL,0,'Zazera <Sandfury Paragon>'),
(2541684,254169,0,139,2274,1,1,0,3410.3218,-5026.6255,174.1336,0.7061,300,0,0,1,0,0,0,0,0,'',NULL,0,'Yahola <Mossflayer Paragon>'),
(2541685,254172,0,139,2274,1,1,0,3409.3809,-5025.46,174.1052,0.4705,300,0,0,1,0,0,0,0,0,'',NULL,0,'Left Hand of Yahola'),
(2541686,254173,0,139,2274,1,1,0,3411.4453,-5027.8877,174.1595,0.6995,300,0,0,1,0,0,0,0,0,'',NULL,0,'Right Hand of Yahola');

DELETE FROM `creature_template_addon` WHERE `entry` IN (254169, 254170);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(254169, 0, 0, 0, 1, 0, 0, '8734'),
(254170, 0, 0, 0, 1, 0, 0, '254622');

DELETE FROM `spell_proc` WHERE `SpellId` = 254622;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(254622, 0, 0, 0, 0, 0, 0x10014, 1, 2, 0, 0, 0, 0, 100, 0, 0);

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2541700, 22, 7484, 'Water Bucket', '', '', '', 1, 254623, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `gameobject` WHERE `guid` IN (2541700, 2541701);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(2541700, 2541700, 1, 440, 979, 1, 1, -7182.6714, -3000.8193, 31.1741, 0.4996, 0, 0, 0.247216, 0.968961, 40, 100, 1, '', NULL, 'Water Bucket (Zazera)'),
(2541701, 2541700, 1, 440, 979, 1, 1, -7187.974, -3012.8828, 31.1893, 4.835, 0, 0, 0.662457, -0.7491, 40, 100, 1, '', NULL, 'Water Bucket (Zazera)');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 13 AND `SourceEntry` = 254623;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 254170 AND `SourceId` = 0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 4 AND `SourceEntry` IN (254169, 8561) AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(13, 1, 254623, 0, 0, 31, 0, 3, 254170, 0, 0, 0, 0, '', 'Water Bucket - splash hits only Zazera'),
(22, 2, 254170, 0, 0, 1, 1, 254622, 0, 0, 0, 0, 0, '', 'Zazera - Water Bucket only puts her out while she has Burning Sands'),
(22, 4, 254169, 0, 0, 1, 1, 8734, 0, 0, 0, 0, 0, '', 'Yahola - Channels Blackfathom Channeling only while she has its idle aura'),
(22, 4, 8561, 0, 0, 1, 1, 8734, 0, 0, 0, 0, 0, '', 'Mossflayer Shadowhunter - Channels Blackfathom Channeling only with its idle aura');

DELETE FROM `creature_formations` WHERE `memberGUID` IN (2541680, 2541681, 2541682, 2541684, 2541685, 2541686);
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(2541680, 2541680, 0, 0, 7, 0, 0),
(2541680, 2541681, 5.6, 262, 7, 0, 0),
(2541680, 2541682, 4.9, 86, 7, 0, 0),
(2541684, 2541684, 0, 0, 7, 0, 0),
(2541684, 2541685, 1.5, 88, 7, 0, 0),
(2541684, 2541686, 1.7, 271, 7, 0, 0);

DELETE FROM `creature_loot_template` WHERE `Entry` = 254168;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(254168, 2061076, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Vazul''s Whispershade Blindfold'),
(254168, 2067258, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Mystic Whispershade Belt'),
(254168, 2072023, 0, 20, 0, 1, 1, 1, 1, 'Vazul - Spiritbound Whispershade Bindings');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (254168, 254169, 254170, 254171) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 8561 AND `source_type` = 0 AND `id` IN (3, 4);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(254168, 0, 0, 0, 0, 0, 100, 0, 1000, 2000, 12000, 16000, 0, 0, 11, 113, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Vazul - In Combat - Cast Chains of Ice'),
(254168, 0, 1, 0, 0, 0, 100, 0, 2000, 3000, 12000, 16000, 0, 0, 11, 9081, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Vazul - In Combat - Cast Shadow Bolt Volley'),
(254169, 0, 0, 0, 0, 0, 100, 0, 1000, 2000, 3500, 4000, 0, 0, 11, 254625, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Yahola - In Combat - Cast Spectral Bolt'),
(254169, 0, 1, 0, 2, 0, 100, 1, 0, 99, 0, 0, 0, 0, 11, 254626, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yahola - Below 99% Health - Cast Army of the Dead (once)'),
(254169, 0, 2, 0, 0, 0, 100, 0, 10000, 11000, 11000, 11000, 0, 0, 11, 254632, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yahola - In Combat - Cast Spectral Volley'),
(254169, 0, 3, 0, 1, 0, 100, 0, 1000, 2000, 5000, 5000, 0, 0, 11, 8734, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yahola - Out of Combat - Channel Blackfathom Channeling'),
(254169, 0, 4, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 92, 1, 8734, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Yahola - On Aggro - Stop Blackfathom Channeling'),
(8561, 0, 3, 0, 1, 0, 100, 0, 1000, 2000, 5000, 5000, 0, 0, 11, 8734, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mossflayer Shadowhunter - Out of Combat - Channel Blackfathom Channeling'),
(8561, 0, 4, 0, 4, 0, 100, 0, 0, 0, 0, 0, 0, 0, 92, 1, 8734, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Mossflayer Shadowhunter - On Aggro - Stop Blackfathom Channeling'),
(254170, 0, 0, 0, 0, 0, 100, 0, 0, 0, 25000, 30000, 0, 0, 11, 254619, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Zazera - In Combat - Cast Firestorm'),
(254170, 0, 1, 2, 8, 0, 100, 0, 254623, 0, 0, 0, 0, 0, 28, 254622, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Zazera - On Water Bucket Hit - Remove Burning Sands'),
(254170, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 254624, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Zazera - On Water Bucket Hit - Cast Extinguished'),
(254170, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 30000, 30000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Zazera - On Water Bucket Hit - Rekindle in 30 seconds'),
(254170, 0, 4, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 11, 254622, 34, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Zazera - Rekindle - Cast Burning Sands'),
(254171, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 25, 30, 1, 0, 0, 0, 0, 0, 0, 'Risen Servant - On Just Summoned - Attack the closest player within 30 yards');
