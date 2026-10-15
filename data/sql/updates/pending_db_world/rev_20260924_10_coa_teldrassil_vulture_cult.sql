-- Conquest of Azeroth: the Vulture Cult storyline of Shadowglen and its Teldrassil sequel. Thariel
-- Wingstroke searches for his sister Elydna; the Carrion Path leads to the cult's Eyrie, its Moonlit
-- Ossuary and the Great Nest, where Elydna meets her communion; her pendant goes back to her brother,
-- whose warning brings Tallonkai Swiftroot and the Sentinels of Theren-Dion Sanctuary into it. Quests
-- 1660012-1660017, 1660040, 1660085 and 1660071-1660073, the density fix of stock quest 457 and the
-- Eyrie's graveyard. None of it existed in this world.
--
-- WHERE EACH VALUE COMES FROM
--   quests, creatures, objects, gossip  the realm's own client cache (data-cache-945cd3b8b0ce4a496586);
--     every quest and reward item already exists in item_template.
--   places  CoA's server terrain: the Carrion Path (area 10208), the Eyrie (10206) with its outpost hall,
--     towers, moonwell and Great Nest, the Moonlit Ossuary (10207) and Theren-Dion Sanctuary (10213).
--     Floors come from the server collision data (surface.py).
--   who stands where  the client's QuestSuperTrack turn-in and objective points; the rest are
--     Questie-X-AscensionDB sightings (SOURCED-QUESTIE) or hand-placed at a named landmark (INFERRED).
--   mechanics  INFERRED where no CoA source shows them: the Offering Bowl wakes Elydna, the newborns
--     become butterflies that follow their rescuer, the sentinels yield their duels, the eggs call their
--     parents. Spell 256707 (Good Flesh Amalgam) is bound to spell_coa_channeling_blessing_of_the_moon in
--     mod-ascension-compat, which raises the Aberrant Flesh Remnant at the Eyrie moonwell instead of the
--     stock Felwood event 3839.
--   appearance  STAND-IN displays where the CoA model is missing from the client (listed per NPC).
--
-- Blocks: creature guid 9007000-9007399, gameobject guid 7913000-7913199, gossip menu 932000-932049. 11 quests,
-- 102 creature and 32 gameobject spawns.

-- ---------------------------------------------------------------------------
-- 1. Creatures
-- ---------------------------------------------------------------------------
-- 161725 Thariel Wingstroke: the merchant brother (Details of 1660012: "I'm just a merchant"); level and faction
--   SOURCED-QUESTIE; CoA display 652031 is missing, so the Night Elf Commoner man 19180 stands in
-- 161726 Aryandel: the Eyrie's guardian at the gate ("he thinks it more weakness than virtue"); CoA display
--   652032 is missing, so the Fallen Druid man 17847 stands in for a heretic druid
-- 161727 Lady Aegya: leader of the cult; rank 3, type_flags 4, KillCredit1 161797 and her own model 141803
--   SOURCED-CACHE; Questie shows her level as ?? (boss), so 30 is INFERRED
-- 161728 Gilgaen: the blind keeper of the petrified Ancient (npccache 62624); CoA display 652034 is missing, so
--   the gaunt Tortured Druid man 12269 stands in
-- 161848 Eldya: the cultist who turns the newborns into butterflies; CoA display 652083 is missing, so the
--   Evergrove Druid woman 20992 stands in (INFERRED gender from the name)
-- 161916 Sheelem: the cultist at the ossuary mouth ("Heading into the ossuary, are you?"); cache type 0 kept;
--   CoA display 652059 is missing, so a Druid of the Fang man 4211 stands in (INFERRED gender)
-- 161784 Elydna Wingstroke: Thariel's sister, the communion's offering (1660016 objective 2): rank 1,
--   HealthModifier 5.2 SOURCED-CACHE; friendly until the Offering Bowl turns her on its user (INFERRED); the
--   Fallen Druid woman 17849 stands in for the missing 652029
-- 161783 Aberrant Flesh Remnant: the shadow that rises from the Eyrie moonwell (1660015); display 25553
--   SOURCED-CACHE; KillCredit1 161799 and its Blessed Good Flesh Amalgam drop INFERRED (no CoA spell or loot
--   names a source)
-- 161787 Fretful Withered Treant: the guardians of the Carrion Path (1660012 objective 1); type 4 and display
--   6351 SOURCED-CACHE, level SOURCED-QUESTIE, hostile like the stock Timberlings
-- 161735 Rotworm: the vermin the rot draws into the ossuary (1660014, 1660040 texts); display 9906 SOURCED-CACHE
-- 161832 Rotting Flesh Spawn: the monstrosity of the ossuary tunnels (1660040): rank 1, HealthModifier 2.79 and
--   display 11138 SOURCED-CACHE
-- 161782 Fallen Aspirant: rises from an opened corpse (1660014); type 6 and health SOURCED-CACHE; CoA displays
--   652035/36/48/49 are missing, so the undead night elf Tortured Sentinel 12270 stands in
-- 161847 Butterfly: a transformed newborn that follows its rescuer to Eldya (1660017 objective 2); display 86531
--   SOURCED-CACHE
-- 161789 Sacred Vulture: the cult's sacred birds perched over the Great Nest ("When the vultures spoke of you",
--   npccache 62613); rank, type and display SOURCED-CACHE, placement INFERRED
-- 162880 Adrilia Soultemper: leader of Theren-Dion, a heroine of the War of the Ancients (npccache 85182); level
--   and faction SOURCED-QUESTIE; CoA display 652439 is missing, so the Sentinel Leader woman 12931 stands in
-- 162931 Miraelith: the sanctuary's chronicler (npccache 85181, 85182); CoA display 652462 is missing, so the
--   Scholar Runethorn woman 14426 stands in (INFERRED gender and level)
-- 162970 Theren-Dion Sentinel: a guard of the sanctuary with no duel credit; the cache gives her the four duel
--   sentinels' models, so she wears the four stock Teldrassil Sentinel looks 4849-4852 at random (the cache's
--   own Teldrassil Sentinel copies 162938/162939 use 4849/4850)
-- 162874 Frenzied Vulture: the carrion birds nesting on the rocks around Theren-Dion (1660073); type and display
--   SOURCED-CACHE
-- 162925 Vulture Egg: the eggs to destroy (1660073 objective 1): display 10056 and HealthModifier 0.2
--   SOURCED-CACHE, scale 1.5 and faction 72 (hostile to players, passive) SOURCED-QUESTIE
-- 162856 Theren-Dion Sentinel: a Sentinel in training who accepts a duel during 1660072; KillCredit1 162924
--   SOURCED-CACHE; level SOURCED-QUESTIE; her missing CoA model is replaced by a stock Teldrassil Sentinel look
-- 162870 Theren-Dion Sentinel: a Sentinel in training who accepts a duel during 1660072; KillCredit1 162924
--   SOURCED-CACHE; level SOURCED-QUESTIE; her missing CoA model is replaced by a stock Teldrassil Sentinel look
-- 162871 Theren-Dion Sentinel: a Sentinel in training who accepts a duel during 1660072; KillCredit1 162924
--   SOURCED-CACHE; level SOURCED-QUESTIE; her missing CoA model is replaced by a stock Teldrassil Sentinel look
-- 162872 Theren-Dion Sentinel: a Sentinel in training who accepts a duel during 1660072; KillCredit1 162924
--   SOURCED-CACHE; level SOURCED-QUESTIE; her missing CoA model is replaced by a stock Teldrassil Sentinel look
-- 162873 Theren-Dion Sentinel: a Sentinel in training who accepts a duel during 1660072; KillCredit1 162924
--   SOURCED-CACHE; level SOURCED-QUESTIE; her missing CoA model is replaced by a stock Teldrassil Sentinel look
-- 161729 [KC] Carrion Path traversed: areatrigger 6138 credits it (1660012 objective 2)
-- 161797 [KC] Speak with Lady Aegya: Lady Aegya's gossip credits it (1660013)
-- 161798 [KC] Sanctified flesh offered: the Offering Bowl credits it (1660016 objective 1)
-- 161799 [KC] Flesh sanctified at the Moonwell: KillCredit1 of the Aberrant Flesh Remnant (1660015)
-- 161846 [KC] Newborns saved: the Baby Night Elf objects credit it (1660017 objective 1)
-- 162924 [KC] Theren-Dion Sentinel defeated: a yielding duel sentinel credits it (1660072)
-- 162932 Tortured Ghost: the talk credit of 1660085 ("Speak with Thariel Wingstroke"). Name and type 6
--   SOURCED-CACHE (CoA reused the id); unspawned, so the Tormented Spirit ghost 9534 stands in for the missing
--   652459 and it carries the trigger flags of a marker
-- 161905 Elydna's MoonFire Zone: summoned under a random player during her fight; it casts 256739 (a 2 s ground
--   ring, then a 2-yd Arcane burst and DoT), the cast MobSpells.lua captured from 161905 in Shadowglen
--   (SOURCED-ARCHIVE); level 7 as Elydna (the spell scales with the caster level), rooted, untargetable but able
--   to hit players; flags_extra 8322 (trigger 128, civilian 2, cannot enter combat 0x2000): it never aggroes,
--   melees or chases (Creature.cpp:688, CombatManager.cpp:60; a civilian never starts an attack,
--   Creature.cpp:1948, SmartAI.cpp:810) and its spells still hit
-- 161907 Elydna's Tornado: two appear when her 4 s Tornado cast 256757 completes; they drift for 20 s wearing
--   256758 (tornado model) and 256759 (every 1 s 256760: damage and a knock-back within 4 yd, once per 3.8 s per
--   target); the pairing with 256757 is INFERRED from the spell block; flags_extra 8322 as the MoonFire Zone, so
--   it drifts and never chases a player
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `KillCredit1`, `ScriptName`)
VALUES
(161725, 'Thariel Wingstroke', NULL, 932000, 11, 11, 0, 12, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.98, 1, 1, 1, 1, 2, 0, ''),
(161726, 'Aryandel', 'Vulture Cult', 0, 13, 13, 0, 12, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161727, 'Lady Aegya', 'Vulture Cult', 932003, 30, 30, 0, 12, 3, 1, 1.14286, 20, 3, 2000, 2000, 1, 0, 2048, 7, 4, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 161797, ''),
(161728, 'Gilgaen', 'Vulture Cult', 932005, 20, 20, 0, 12, 3, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161848, 'Eldya', 'Vulture Cult', 0, 7, 7, 0, 12, 2, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161916, 'Sheelem', 'Vulture Cult', 0, 7, 7, 0, 12, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(161784, 'Elydna Wingstroke', 'Vulture Cult', 0, 7, 7, 0, 35, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 5.2, 1, 1, 1, 1, 0, 0, ''),
(161783, 'Aberrant Flesh Remnant', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 161783, '', 0, 1, 1, 1, 1, 1, 0, 161799, ''),
(161787, 'Fretful Withered Treant', NULL, 0, 3, 3, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 4, 0, 0, '', 0, 0.93, 1, 1, 1, 1, 0, 0, ''),
(161735, 'Rotworm', NULL, 0, 1, 2, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 0.4, 1, 1, 1, 1, 0, 0, ''),
(161832, 'Rotting Flesh Spawn', NULL, 0, 4, 4, 0, 14, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 0, 2048, 0, 0, 0, '', 0, 2.79, 1, 1, 1, 1, 0, 0, ''),
(161782, 'Fallen Aspirant', NULL, 0, 5, 6, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 6, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161847, 'Butterfly', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 770, 2048, 0, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(161789, 'Sacred Vulture', NULL, 0, 7, 7, 0, 35, 0, 1, 1.14286, 20, 1, 2000, 2000, 1, 770, 2048, 1, 0, 0, '', 0, 0.98, 1, 1, 1, 1, 0, 0, ''),
(162880, 'Adrilia Soultemper', NULL, 0, 27, 27, 0, 12, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, ''),
(162931, 'Miraelith', 'Chronicler of Theren-Dion', 932008, 20, 20, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 8, 0, 2048, 7, 0, 0, '', 0, 1, 1, 1, 1, 1, 2, 0, ''),
(162970, 'Theren-Dion Sentinel', NULL, 932011, 7, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162874, 'Frenzied Vulture', NULL, 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 1, 0, 0, '', 0, 0.96, 1, 1, 1, 1, 0, 0, ''),
(162925, 'Vulture Egg', NULL, 0, 7, 7, 0, 72, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 0, 0, 0, 'SmartAI', 0, 0.2, 1, 1, 1, 1, 0, 0, ''),
(162856, 'Theren-Dion Sentinel', NULL, 932010, 6, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 162924, ''),
(162870, 'Theren-Dion Sentinel', NULL, 932010, 6, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 162924, ''),
(162871, 'Theren-Dion Sentinel', NULL, 932010, 6, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 162924, ''),
(162872, 'Theren-Dion Sentinel', NULL, 932010, 6, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 162924, ''),
(162873, 'Theren-Dion Sentinel', NULL, 932010, 6, 7, 0, 80, 1, 1, 1.14286, 20, 0, 2000, 2000, 1, 0, 2048, 7, 0, 0, 'SmartAI', 0, 0.96, 1, 1, 1, 1, 0, 162924, ''),
(161729, '[KC] Carrion Path traversed', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161797, '[KC] Speak with Lady Aegya', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161798, '[KC] Sanctified flesh offered', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161799, '[KC] Flesh sanctified at the Moonwell', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161846, '[KC] Newborns saved', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(162924, '[KC] Theren-Dion Sentinel defeated', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(162932, 'Tortured Ghost', NULL, 0, 1, 1, 0, 35, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 6, 0, 0, '', 0, 1, 1, 1, 1, 1, 130, 0, ''),
(161905, 'Elydna Wingstroke', 'MoonFire Zone', 0, 7, 7, 0, 14, 0, 1, 1.14286, 20, 0, 2000, 2000, 1, 33554434, 2048, 9, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 8322, 0, ''),
(161907, 'Elydna Wingstroke', 'Tornado', 0, 7, 7, 0, 14, 0, 0.8, 1.14286, 20, 0, 2000, 2000, 1, 33554434, 2048, 9, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 8322, 0, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`), `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`), `ArmorModifier` = VALUES(`ArmorModifier`), `DamageModifier` = VALUES(`DamageModifier`), `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`), `KillCredit1` = VALUES(`KillCredit1`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161725, 161726, 161727, 161728, 161729, 161735, 161782, 161783, 161784, 161787, 161789, 161797, 161798, 161799, 161832, 161846, 161847, 161848, 161905, 161907, 161916, 162856, 162870, 162871, 162872, 162873, 162874, 162880, 162924, 162925, 162931, 162932, 162970);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(161725, 0, 19180, 1, 1),
(161726, 0, 17847, 1, 1),
(161727, 0, 141803, 1, 1),
(161728, 0, 12269, 1, 1),
(161848, 0, 20992, 1, 1),
(161916, 0, 4211, 1, 1),
(161784, 0, 17849, 1, 1),
(161783, 0, 25553, 1, 1),
(161787, 0, 6351, 1, 1),
(161735, 0, 9906, 1, 1),
(161832, 0, 11138, 1, 1),
(161782, 0, 12270, 1, 1),
(161847, 0, 86531, 1, 1),
(161789, 0, 137311, 1, 1),
(162880, 0, 12931, 1, 1),
(162931, 0, 14426, 1, 1),
(162970, 0, 4849, 1, 1),
(162970, 1, 4850, 1, 1),
(162970, 2, 4851, 1, 1),
(162970, 3, 4852, 1, 1),
(162874, 0, 137311, 1, 1),
(162925, 0, 10056, 1.5, 1),
(162856, 0, 4849, 1, 1),
(162870, 0, 4850, 1, 1),
(162871, 0, 4851, 1, 1),
(162872, 0, 4852, 1, 1),
(162873, 0, 4849, 1, 1),
(161729, 0, 11686, 1, 1),
(161797, 0, 11686, 1, 1),
(161798, 0, 11686, 1, 1),
(161799, 0, 11686, 1, 1),
(161846, 0, 11686, 1, 1),
(162924, 0, 11686, 1, 1),
(162932, 0, 9534, 1, 1),
(161905, 0, 11686, 1, 1),
(161907, 0, 11686, 1, 1);

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (161725, 161726, 161727, 161728, 161729, 161735, 161782, 161783, 161784, 161787, 161789, 161797, 161798, 161799, 161832, 161846, 161847, 161848, 161905, 161907, 161916, 162856, 162870, 162871, 162872, 162873, 162874, 162880, 162924, 162925, 162931, 162932, 162970);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`)
VALUES
(162880, 1, 5598, 0, 2550),
(162970, 1, 5598, 0, 2550),
(162856, 1, 5598, 0, 2550),
(162870, 1, 5598, 0, 2550),
(162871, 1, 5598, 0, 2550),
(162872, 1, 5598, 0, 2550),
(162873, 1, 5598, 0, 2550);

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (161905, 162925);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`)
VALUES
(162925, 1, 1, 0, 1, 0, 0, NULL),
(161905, 1, 1, 0, 1, 0, 0, NULL);

-- Three CoA displays resolve in CreatureDisplayInfo.dbc but had no creature_model_info row, without which
-- the creature cannot load (Creature.cpp:519-532). Values from stock creatures of the same build:
-- 141803 Lady Aegya: ladyaegya.m2 has NightElfFemale.mdx's CreatureModelData collision and GeoBox, so the stock
--   night elf female values (12931 Sentinel Leader, 4849-4852 Sentinels) apply
-- 86531 Butterfly: butterfly.mdx has the collision data of the butterfly critters (magicbutterfly.mdx,
--   Glimmerflies 11000201-11000203), whose displays 93496-93498 carry these values
-- 137311 Sacred and Frenzied Vulture: vulture.mdx at display scale 1, a carrion bird the size of
--   CarrionBird.mdx; the stock carrion bird displays at scale 1 (2305 Fleshripper, 1192 Dread Swoop, 3248 Roc)
--   carry these values
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (86531, 137311, 141803);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(141803, 0.306, 1.5, 1, 0),
(86531, 0.406256, 0.2, 2, 0),
(137311, 0.1, 1.25, 2, 0);

-- ---------------------------------------------------------------------------
-- 2. Dialogue
-- ---------------------------------------------------------------------------
-- Greetings and answers are the cached npc_text of each NPC; the option texts are INFERRED from them.
DELETE FROM `npc_text` WHERE `ID` IN (62613, 62614, 62616, 62624, 62625, 62626, 62627, 62628, 62629, 62630, 85181, 85182, 85200, 85201);
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES
(62613, 'Well, well, well…$b$bWhen the vultures spoke of you, I dismissed them as gossips. Meddlers. But here you are! In the flesh… more bone than flesh, truth be told…', 'Well, well, well…$b$bWhen the vultures spoke of you, I dismissed them as gossips. Meddlers. But here you are! In the flesh… more bone than flesh, truth be told…', 0, 0, 1),
(62614, '<The elf lets out a laugh, almost as ghastly as her grin, full of sharp yellowed teeth.>$b$bFate, it seems, is not without its irony. Elydna, you say? You arrive on the eve of her communion!', '<The elf lets out a laugh, almost as ghastly as her grin, full of sharp yellowed teeth.>$b$bFate, it seems, is not without its irony. Elydna, you say? You arrive on the eve of her communion!', 0, 0, 1),
(62616, '<The hollow sockets of Lady Aegya’s eyes fall upon you with a gaze that cuts deeper than any blade.>', '<The hollow sockets of Lady Aegya’s eyes fall upon you with a gaze that cuts deeper than any blade.>', 0, 0, 1),
(62624, '<The elf’s blind gaze pierces through flesh, wood, and stone, then lingers somewhere far beyond, suspended in infinity. His gaunt face betrays no emotion. Were it not for the subtle rise and fall of his chest, you’d think he had suffered the same fate as the Ancient looming behind him.>', '<The elf’s blind gaze pierces through flesh, wood, and stone, then lingers somewhere far beyond, suspended in infinity. His gaunt face betrays no emotion. Were it not for the subtle rise and fall of his chest, you’d think he had suffered the same fate as the Ancient looming behind him.>', 0, 0, 1),
(62625, 'Alive, in its own way. Cathartos is old, even among the oldest of his kind; one of the first seeds to sprout and take root in the Ancient world. He stirs from his slumber only for a few fleeting hours across long, long centuries… Yet still, we keep our vigil over him.$b$bHe is our Father, in a sense. It was Cathartos who gathered the first druids of our circle, and who shared the teachings of the Great Vulture before they were cast out and forbidden. We owe him our identity… and our wisdom.$b$b', 'Alive, in its own way. Cathartos is old, even among the oldest of his kind; one of the first seeds to sprout and take root in the Ancient world. He stirs from his slumber only for a few fleeting hours across long, long centuries… Yet still, we keep our vigil over him.$b$bHe is our Father, in a sense. It was Cathartos who gathered the first druids of our circle, and who shared the teachings of the Great Vulture before they were cast out and forbidden. We owe him our identity… and our wisdom.$b$b', 0, 0, 1),
(62626, 'Relying on sight to grasp nature is like trying to glimpse the world through a crack in the door. Our blindness is an offering to the hunger of the Great Vulture; in return, his spirit grants us understanding.$b$bThe druids of the Cenarion Circle marvel at the patterns and rhythms of nature. But their “harmony” is nothing more than the shadow they themselves cast when they stoop to study it. The belief that everything in nature has some higher purpose is anything but “natural”.$b$bNature does not deal in destiny, it deals in opportunity. What they call balance is nothing but the cold arithmetic of death and rut. Unlike them, we take no beauty in it.$b$bThe Great Vulture teaches us to face these truths, and weave them into our druidic ways.$b$bYou’ve never heard of us because our faith was outlawed millennia ago. Since then, we have lived apart, in otherness, on the margins of society. Forever at the edge… of the cliff.$b$b', 'Relying on sight to grasp nature is like trying to glimpse the world through a crack in the door. Our blindness is an offering to the hunger of the Great Vulture; in return, his spirit grants us understanding.$b$bThe druids of the Cenarion Circle marvel at the patterns and rhythms of nature. But their “harmony” is nothing more than the shadow they themselves cast when they stoop to study it. The belief that everything in nature has some higher purpose is anything but “natural”.$b$bNature does not deal in destiny, it deals in opportunity. What they call balance is nothing but the cold arithmetic of death and rut. Unlike them, we take no beauty in it.$b$bThe Great Vulture teaches us to face these truths, and weave them into our druidic ways.$b$bYou’ve never heard of us because our faith was outlawed millennia ago. Since then, we have lived apart, in otherness, on the margins of society. Forever at the edge… of the cliff.$b$b', 0, 0, 1),
(62627, '<The elf looks unsettled, his face shadowed with worry. The nervous glance and disheveled appearance paint a stark contrast against the stillness of Shadowglen. Whoever he is, he has come a long way to reach this place.>', '<The elf looks unsettled, his face shadowed with worry. The nervous glance and disheveled appearance paint a stark contrast against the stillness of Shadowglen. Whoever he is, he has come a long way to reach this place.>', 0, 0, 1),
(62628, '<Thariel closes his eyes and shakes his head gently. When he opens them again, his gaze is wet and heavy with sorrow.>$b$bI held on to hope… the foolish hope of a dreamer. I should have pressed harder, back when I still had the chance. Begged her not to go. Told her to burn that invitation.$b$bYou are a bearer of grim tidings, $C. Yet still, I owe you. I will not forget this debt.', '<Thariel closes his eyes and shakes his head gently. When he opens them again, his gaze is wet and heavy with sorrow.>$b$bI held on to hope… the foolish hope of a dreamer. I should have pressed harder, back when I still had the chance. Begged her not to go. Told her to burn that invitation.$b$bYou are a bearer of grim tidings, $C. Yet still, I owe you. I will not forget this debt.', 0, 0, 1),
(62629, 'She… you…?$b$b<A wave of nausea cuts off his stunned question.>$b$bAnd you killed her. Couldn’t you have refused? Couldn’t you have run? Couldn’t you have spared her? <His voice rises with each word, swelling with grief and fury. At the climax, he makes a half-motion as if to strike you, to draw steel, only to find nothing at hand. In the end, his shoulders collapse in defeat.>$b$bGo. Please. <He lowers his head.> Your voice is poison.', 'She… you…?$b$b<A wave of nausea cuts off his stunned question.>$b$bAnd you killed her. Couldn’t you have refused? Couldn’t you have run? Couldn’t you have spared her? <His voice rises with each word, swelling with grief and fury. At the climax, he makes a half-motion as if to strike you, to draw steel, only to find nothing at hand. In the end, his shoulders collapse in defeat.>$b$bGo. Please. <He lowers his head.> Your voice is poison.', 0, 0, 1),
(62630, 'You’ve returned!$b$b<The elf’s expression shifts into a wary grimace as he catches the grave look on your face.>$b$bAnd you bring ill news, don’t you?', 'You’ve returned!$b$b<The elf’s expression shifts into a wary grimace as he catches the grave look on your face.>$b$bAnd you bring ill news, don’t you?', 0, 0, 1),
(85181, 'Curiosity in your eyes. Good. It’s the prelude to intellectual restlessness, which, in turn, heralds enlightenment.$b$bWhat questions do you have for the chronicler of Theren-Dion?', 'Curiosity in your eyes. Good. It’s the prelude to intellectual restlessness, which, in turn, heralds enlightenment.$b$bWhat questions do you have for the chronicler of Theren-Dion?', 0, 0, 1),
(85182, 'Theren-Dion was raised shortly after the dramatic sprouting of Teldrassil to serve as a training ground. Under Adrilia’s instruction, aspirants from every corner come to test themselves in combat and become proud Sentinels.$b$bTo train under Adrilia’s tutelage is an honor for any aspirant. Like so many names history remembers, Adrilia was a heroine of the War of the Ancients. Unlike most, she survived—making her something of a living legend.$b$bThere was never a shortage of candidates, but since our people lost immortality… everyone wants to make the most of Adrilia’s remaining decades. It gives one pause: old age may be the first—and last—enemy our lady fails to defeat. And that remains to be seen...', 'Theren-Dion was raised shortly after the dramatic sprouting of Teldrassil to serve as a training ground. Under Adrilia’s instruction, aspirants from every corner come to test themselves in combat and become proud Sentinels.$b$bTo train under Adrilia’s tutelage is an honor for any aspirant. Like so many names history remembers, Adrilia was a heroine of the War of the Ancients. Unlike most, she survived—making her something of a living legend.$b$bThere was never a shortage of candidates, but since our people lost immortality… everyone wants to make the most of Adrilia’s remaining decades. It gives one pause: old age may be the first—and last—enemy our lady fails to defeat. And that remains to be seen...', 0, 0, 1),
(85200, 'Yes? What brings you to Theren-Dion?', 'Yes? What brings you to Theren-Dion?', 0, 0, 1),
(85201, 'Have you come to see Lady Adrilia?', 'Have you come to see Lady Adrilia?', 0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (932000, 932001, 932002, 932003, 932004, 932005, 932006, 932007, 932008, 932009, 932010, 932011);
INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
VALUES
(932000, 62627),
(932000, 62630),
(932001, 62628),
(932002, 62629),
(932003, 62616),
(932003, 62613),
(932004, 62614),
(932005, 62624),
(932006, 62625),
(932007, 62626),
(932008, 85181),
(932009, 85182),
(932010, 85200),
(932011, 85201);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (932000, 932001, 932002, 932003, 932004, 932005, 932006, 932007, 932008, 932009, 932010, 932011);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
VALUES
(932000, 0, 0, '<Tell him that Elydna is gone.>', 0, 1, 1, 932001, 0, 0, 0, '', 0),
(932000, 1, 0, '<Tell him the truth: Elydna fell by your hand at her communion.>', 0, 1, 1, 932002, 0, 0, 0, '', 0),
(932003, 0, 0, 'I seek Elydna Wingstroke. Her brother sent me.', 0, 1, 1, 932004, 0, 0, 0, '', 0),
(932005, 0, 0, 'What is the Ancient standing behind you?', 0, 1, 1, 932006, 0, 0, 0, '', 0),
(932005, 1, 0, 'Why are you blind?', 0, 1, 1, 932007, 0, 0, 0, '', 0),
(932008, 0, 0, 'Tell me about Theren-Dion.', 0, 1, 1, 932009, 0, 0, 0, '', 0),
(932010, 0, 0, 'I challenge you to a duel, Sentinel.', 0, 1, 1, 0, 0, 0, 0, '', 0);

DELETE FROM `conditions` WHERE `SourceGroup` IN (932000, 932001, 932002, 932003, 932004, 932005, 932006, 932007, 932008, 932009, 932010, 932011) AND `SourceTypeOrReferenceId` IN (14, 15);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(14, 932000, 62627, 0, 0, 9, 0, 1660085, 0, 0, 1, 0, 0, '', 'Greeting 62627 unless quest 1660085 is taken'),
(14, 932000, 62630, 0, 0, 9, 0, 1660085, 0, 0, 0, 0, 0, '', 'Greeting 62630 while quest 1660085 is taken'),
(14, 932003, 62616, 0, 0, 9, 0, 1660013, 0, 0, 1, 0, 0, '', 'Greeting 62616 unless quest 1660013 is taken'),
(14, 932003, 62613, 0, 0, 9, 0, 1660013, 0, 0, 0, 0, 0, '', 'Greeting 62613 while quest 1660013 is taken'),
(15, 932000, 0, 0, 0, 9, 0, 1660085, 0, 0, 0, 0, 0, '', 'Option 0 only while quest 1660085 is taken'),
(15, 932000, 1, 0, 0, 9, 0, 1660085, 0, 0, 0, 0, 0, '', 'Option 1 only while quest 1660085 is taken'),
(15, 932003, 0, 0, 0, 9, 0, 1660013, 0, 0, 0, 0, 0, '', 'Option 0 only while quest 1660013 is taken'),
(15, 932010, 0, 0, 0, 9, 0, 1660072, 0, 0, 0, 0, 0, '', 'Option 0 only while quest 1660072 is taken');

-- ---------------------------------------------------------------------------
-- 3. World objects and loot
-- ---------------------------------------------------------------------------
-- 2300512 Fallen Aspirant: the corpse chest of 1660014 (type 3, lock 1689, loot 2300512, consumable, quest
--   1660014), every data column SOURCED-CACHE
-- 2300513 Offering Bowl: the goober of 1660016 objective 1 (Data1 1660016 SOURCED-CACHE)
-- 2300526 Baby Night Elf: the goober of 1660017 objective 1 (Data1 1660017 SOURCED-CACHE); a click runs
--   go_coa_baby_night_elf in mod-ascension-compat (section 9)
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `castBarCaption`, `size`, `AIName`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`)
VALUES
(2300512, 3, 84863, 'Fallen Aspirant', '', 1, 'SmartGameObjectAI', 1689, 2300512, 0, 1, 0, 0, 0, 0, 1660014, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(2300513, 10, 87025, 'Offering Bowl', '', 1, 'SmartGameObjectAI', 0, 1660016, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(2300526, 10, 7336, 'Baby Night Elf', '', 1, '', 0, 1660017, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'go_coa_baby_night_elf')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `castBarCaption` = VALUES(`castBarCaption`), `size` = VALUES(`size`), `AIName` = VALUES(`AIName`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `ScriptName` = VALUES(`ScriptName`);

-- Cut of Good Meat from the corpses (SOURCED-EXILES gameobject_loot 2300512); the Blessed Good Flesh
-- Amalgam from the Aberrant Flesh Remnant (INFERRED: "slay whatever shadow rises from its depths").
DELETE FROM `gameobject_loot_template` WHERE `Entry` = 2300512;
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(2300512, 559143, 0, 100, 1, 1, 0, 1, 1, 'Fallen Aspirant - Cut of Good Meat');

DELETE FROM `creature_loot_template` WHERE `Entry` = 161783;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(161783, 559145, 0, 100, 1, 1, 0, 1, 1, 'Aberrant Flesh Remnant - Blessed Good Flesh Amalgam');

-- The corpse lists its quest item in the object query (QueryHandler.cpp:205). The remnant gets no
-- creature_questitem row: the creature cache shows none for 161783 (questItem1-6 = 0).
DELETE FROM `gameobject_questitem` WHERE `GameObjectEntry` = 2300512;
INSERT INTO `gameobject_questitem` (`GameObjectEntry`, `Idx`, `ItemId`)
VALUES
(2300512, 0, 559143);

-- ---------------------------------------------------------------------------
-- 4. Quests
-- ---------------------------------------------------------------------------
-- Chain (SOURCED-QUESTIE prerequisites, confirmed by the texts): 1660012 -> 13 -> 14 -> 15 -> 16 -> {17, 85};
-- 1660085 -> 1660071 -> 1660072 -> 1660073. 1660040 stands alone. RewardNextQuest is the cached
-- NextQuestInChain. AllowableRaces stays 0 as on every live CoA quest. 1660015 and 1660016 take
-- their start items back at turn-in (ItemDrop1, DESIGN).
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RequiredFactionId1`, `RequiredFactionId2`, `RequiredFactionValue1`, `RequiredFactionValue2`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`, `RewardItem3`, `RewardAmount3`, `RewardItem4`, `RewardAmount4`, `ItemDrop1`, `ItemDropQuantity1`, `ItemDrop2`, `ItemDropQuantity2`, `ItemDrop3`, `ItemDropQuantity3`, `ItemDrop4`, `ItemDropQuantity4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `RewardTalents`, `RewardArenaPoints`, `RewardFactionID1`, `RewardFactionValue1`, `RewardFactionOverride1`, `RewardFactionID2`, `RewardFactionValue2`, `RewardFactionOverride2`, `RewardFactionID3`, `RewardFactionValue3`, `RewardFactionOverride3`, `RewardFactionID4`, `RewardFactionValue4`, `RewardFactionOverride4`, `RewardFactionID5`, `RewardFactionValue5`, `RewardFactionOverride5`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, `RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6`, `RequiredItemCount1`, `RequiredItemCount2`, `RequiredItemCount3`, `RequiredItemCount4`, `RequiredItemCount5`, `RequiredItemCount6`, `ObjectiveText1`, `ObjectiveText2`, `ObjectiveText3`, `ObjectiveText4`)
VALUES
(1660012, 2, 6, 3, 188, 0, 0, 0, 0, 0, 0, 1660013, 5, 0, 0, 0, 0, 0, 0, 0, 8, 0, 5571, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Carrion Road', 'Walk the Carrion Path and defeat its guardians.', '<The elf greets you with a respectful bow of the head.>$b$bForgive me. I’ve come a long way, and no one here seems willing to help me. Perhaps… you could?$b$bI’ve been searching for my sister, Elydna. About half a year ago, she was invited to join a secret druidic circle, and left without even saying goodbye. She never returned.$b$bI managed to trace her steps here, to Shadowglen… but I’m just a merchant. I can barely hold a blade! And the path leading to this hidden grove of druids is well-guarded, and dangerous.$b$bWould you walk that road for me, and make sure my sister still lives?', '', 'Speak with the Eyrie’s guardian.', 161787, 161729, 0, 0, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Carrion Treants slain', 'Carrion Path traversed', '', ''),
(1660013, 2, 6, 3, 188, 0, 0, 0, 0, 0, 0, 1660014, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Sister Who Never Returned', 'Speak with Lady Aegya, leader of the Vulture’s Cult, and ask what became of Thariel’s sister, Elydna.', 'So… you’re not here of your own will, but out of… “altruism.” <The word drips with disdain, as though he thinks it more weakness than virtue.>$b$bI am bound by oath; I cannot speak of our members. You must beg before our lady, our teacher, our guide: Lady Aegya. She will decide what to do with you, and whether you’ll share in Elydna’s fate.$b$bYou’ll find Lady Aegya further inside, in the hall.', '', 'Speak with Aegya.', 161797, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Speak with Lady Aegya', '', '', ''),
(1660014, 2, 6, 3, 188, 0, 0, 0, 0, 0, 0, 1660015, 6, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Finding the Good Meat', 'Gather five cuts of good meat from the Moonlit Ossuary within the Vulture Cult Eyrie.', 'The Great Vulture is fickle, but he remembers those who crawl and beg. With the right offering… perhaps he’ll look kindly on Elydna during her communion.$b$b<Lady Aegya’s crooked smile suggests the exact opposite.>$b$bGo into the barrow we call the Moonlit Ossuary and bring me five cuts of good meat from the corpses that rot within its rancid halls.$b$bBe careful, though. We leave their bodies to ferment, that their taste might better please the Great Vulture’s beak. And rot, as you well know, draws all manner of vermin…', '', 'Return to Aegya.', 0, 0, 0, 0, 0, 0, 0, 0, 559143, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, '', '', '', ''),
(1660015, 2, 6, 3, 188, 0, 0, 0, 0, 0, 0, 1660016, 5, 0, 0, 0, 0, 0, 0, 559144, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 559144, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Transsubstantiating the Flesh', 'Carry the gathered flesh to the Moonwell and sanctify it in the waters.', 'One last step remains.$b$bThe flesh you’ve gathered drips with corruption, but it’s too dry. The Great Vulture likes his offerings moist, so they wet his cruel beak.$b$bTake this meat to our Moonwell. The face of Elune you know is only one among many. Long before she laid with Malorne, she took the Great Vulture to her bed. Still today, she loves him true.$b$bBless the flesh in the Moonwell’s waters and slay whatever shadow rises from its depths. Only then will Elydna be ready for her communion.', '', 'Speak with Gilgaen.', 161799, 0, 0, 0, 1, 0, 0, 0, 559145, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Flesh sanctified at the Moonwell', '', '', ''),
(1660016, 2, 6, 3, 188, 0, 2, 0, 0, 0, 0, 0, 7, 50, 0, 0, 0, 0, 0, 559145, 8, 0, 559182, 1, 0, 0, 0, 0, 0, 0, 559145, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Communion Banquet', 'Place the sanctified flesh upon the bowl in the Great Vulture’s nest. Then, aid Elydna in completing her communion.', 'Here.$b$b<Gilgaen gropes at your hands and presses the sanctified flesh back into your palms.>$b$bLay it in the nest, with the other offerings Elydna has gathered to please the Great Vulture.$b$bYou’ve been granted a great honor, do you realize? To share in the communion of one of our own. Elydna can’t wait to meet you. I imagine you’re just as eager to meet her.', '', 'Speak with Aegya.', 161798, 161784, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Sanctified flesh offered', 'Communion completed', '', ''),
(1660017, 2, 6, 3, 188, 0, 0, 0, 0, 0, 0, 0, 5, 25, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Trail of Petals', 'Channel Eldya’s power over the newborns in the Great Nest to transform them into butterflies. Then guide the butterflies back to Eldya.', 'A visitor… Rarely do we welcome strangers among us, and with good reason: our practices were outlawed millennia ago.$b$bAt times I think, rightly so… Lady Aegya is willing to do things that would make even a satyr shudder. Do you know of what I speak? Elf children, offered up as tribute; war orphans no one would miss.$b$bHelp me save them. Go to the Great Nest and search among the carrion. Through you, I will channel my power and turn them into beautiful butterflies.$b$bI have enchanted this flower crown; its fragrance will be… irresistible. They will follow wherever you lead.$b$bBring them here. I will see to the rest.', '', 'Speak with Eldya', 161846, 161847, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Newborns saved', 'Butterflies delivered', '', ''),
(1660085, 2, 7, 5, 141, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 558970, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna''s Heirloom', 'Speak with Thariel Wingstroke and deliver to him the pendant of his sister, Elydna.', 'As you ponder our offer, remember that the Great Vulture rewards those who bring food to the nest. Thus, the possessions that once belonged to Elydna in life now find a new owner in the one who took hers away.$b$b<The elf''s sharp hands, more like a vulture''s talons than those of her kin, grasp yours and place an ornate pendant in your palms.>$b$bOne of Elydna''s belongings. Her pendant. Do with it as you will.', '', 'Speak with Thariel Wingstroke.', 162932, 0, 0, 0, 1, 0, 0, 0, 558970, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Speak with Thariel Wingstroke', '', '', ''),
(1660040, 2, 6, 3, 188, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 559176, 1, 559177, 1, 559178, 1, 559179, 1, 559180, 1, 559181, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Restless Entrails', 'Defeat the Rotting Flesh Spawn in the Lunar Ossuary.', 'Heading into the ossuary, are you?$b$b<The elf eyes you doubtfully, weighing your worth before deciding if you’re fit for the task.>$b$bA monstrosity of entrails and bone slithers through the ossuary tunnels, ravenous for corpses to gnaw. The worms, foolish defilers, are nothing but its spawn.$b$bKill the creature and… I’m certain the cult will reward you handsomely.', '', 'Return to Sheelem.', 161832, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660071, 2, 8, 5, 141, 0, 0, 0, 0, 0, 0, 1660072, 4, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302012, 1, 2302017, 1, 2302022, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'A Dark Warning', 'Speak with Tallonkai Swiftroot in Dolanaar.', 'Wait.$b$bThere''s something else. <Thariel''s voice comes out tight; the words stumble off his lips.>$b$bThat cult. The lunatics who lured in my sister. Something must be done.$b$bI''ll stay here in Aldrassil and report the cult to Tenaron Stormgrip. You head to Dolanaar and tell Tallonkai Swiftroot everything.$b$bBetween them, they''ll know how to shut this down.', '', 'Speak with Tallonkai Swiftroot.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', ''),
(1660072, 2, 8, 5, 141, 0, 0, 0, 0, 0, 0, 1660073, 5, 83, 114, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2302027, 1, 2302032, 1, 2302037, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'The Aid of Theren-Dion', 'Speak with the Sentinels at Theren-Dion Sanctuary and challenge them to duels to aid their training.', 'You survived the Vulture Cult, and that more than proves your worth.$b$bAbove us, perched on the cliff, stands the Theren-Dion Sanctuary, where the Sentinels test their mettle.$b$bThey''ll welcome someone like you putting them through their paces. Might clear your head, and you might pick up a thing or two from them.$b$bChallenge them to a bout, then report to their leader, Adrilia Soultemper. Tell her I''ll need her Sentinels to move on the cult threat.', '', 'Report to Adrilia Soultemper.', 162924, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel defeated', '', '', ''),
(1660073, 2, -1, 5, 141, 0, 0, 0, 0, 0, 0, 0, 5, 260, 337, 0, 0, 0, 0, 0, 8, 0, 2302042, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'No Place for Scavengers', 'Destroy Vulture Eggs around the Theren-Dion Sanctuary near Dolanaar.', 'The Vulture Cult''s nearness explains a problem we''ve been facing of late.$b$bIt''s rare for the carrion birds of mainland Kalimdor to reach Teldrassil''s boughs; yet lately, dozens have settled on the rocks around this sanctuary.$b$bBefore you return to Dolanaar, help my Sentinels blunt their threat. Destroy the vulture eggs and be ready for the parents'' fury.$b$bThen report back to me.', '', 'Return to Adrilia Soultemper.', 162925, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Vulture Egg destroyed', '', '', '')
ON DUPLICATE KEY UPDATE `QuestType` = VALUES(`QuestType`), `QuestLevel` = VALUES(`QuestLevel`), `MinLevel` = VALUES(`MinLevel`), `QuestSortID` = VALUES(`QuestSortID`), `QuestInfoID` = VALUES(`QuestInfoID`), `SuggestedGroupNum` = VALUES(`SuggestedGroupNum`), `RequiredFactionId1` = VALUES(`RequiredFactionId1`), `RequiredFactionId2` = VALUES(`RequiredFactionId2`), `RequiredFactionValue1` = VALUES(`RequiredFactionValue1`), `RequiredFactionValue2` = VALUES(`RequiredFactionValue2`), `RewardNextQuest` = VALUES(`RewardNextQuest`), `RewardXPDifficulty` = VALUES(`RewardXPDifficulty`), `RewardMoney` = VALUES(`RewardMoney`), `RewardMoneyDifficulty` = VALUES(`RewardMoneyDifficulty`), `RewardDisplaySpell` = VALUES(`RewardDisplaySpell`), `RewardSpell` = VALUES(`RewardSpell`), `RewardHonor` = VALUES(`RewardHonor`), `RewardKillHonor` = VALUES(`RewardKillHonor`), `StartItem` = VALUES(`StartItem`), `Flags` = VALUES(`Flags`), `RequiredPlayerKills` = VALUES(`RequiredPlayerKills`), `RewardItem1` = VALUES(`RewardItem1`), `RewardAmount1` = VALUES(`RewardAmount1`), `RewardItem2` = VALUES(`RewardItem2`), `RewardAmount2` = VALUES(`RewardAmount2`), `RewardItem3` = VALUES(`RewardItem3`), `RewardAmount3` = VALUES(`RewardAmount3`), `RewardItem4` = VALUES(`RewardItem4`), `RewardAmount4` = VALUES(`RewardAmount4`), `ItemDrop1` = VALUES(`ItemDrop1`), `ItemDropQuantity1` = VALUES(`ItemDropQuantity1`), `ItemDrop2` = VALUES(`ItemDrop2`), `ItemDropQuantity2` = VALUES(`ItemDropQuantity2`), `ItemDrop3` = VALUES(`ItemDrop3`), `ItemDropQuantity3` = VALUES(`ItemDropQuantity3`), `ItemDrop4` = VALUES(`ItemDrop4`), `ItemDropQuantity4` = VALUES(`ItemDropQuantity4`), `RewardChoiceItemID1` = VALUES(`RewardChoiceItemID1`), `RewardChoiceItemQuantity1` = VALUES(`RewardChoiceItemQuantity1`), `RewardChoiceItemID2` = VALUES(`RewardChoiceItemID2`), `RewardChoiceItemQuantity2` = VALUES(`RewardChoiceItemQuantity2`), `RewardChoiceItemID3` = VALUES(`RewardChoiceItemID3`), `RewardChoiceItemQuantity3` = VALUES(`RewardChoiceItemQuantity3`), `RewardChoiceItemID4` = VALUES(`RewardChoiceItemID4`), `RewardChoiceItemQuantity4` = VALUES(`RewardChoiceItemQuantity4`), `RewardChoiceItemID5` = VALUES(`RewardChoiceItemID5`), `RewardChoiceItemQuantity5` = VALUES(`RewardChoiceItemQuantity5`), `RewardChoiceItemID6` = VALUES(`RewardChoiceItemID6`), `RewardChoiceItemQuantity6` = VALUES(`RewardChoiceItemQuantity6`), `POIContinent` = VALUES(`POIContinent`), `POIx` = VALUES(`POIx`), `POIy` = VALUES(`POIy`), `POIPriority` = VALUES(`POIPriority`), `RewardTitle` = VALUES(`RewardTitle`), `RewardTalents` = VALUES(`RewardTalents`), `RewardArenaPoints` = VALUES(`RewardArenaPoints`), `RewardFactionID1` = VALUES(`RewardFactionID1`), `RewardFactionValue1` = VALUES(`RewardFactionValue1`), `RewardFactionOverride1` = VALUES(`RewardFactionOverride1`), `RewardFactionID2` = VALUES(`RewardFactionID2`), `RewardFactionValue2` = VALUES(`RewardFactionValue2`), `RewardFactionOverride2` = VALUES(`RewardFactionOverride2`), `RewardFactionID3` = VALUES(`RewardFactionID3`), `RewardFactionValue3` = VALUES(`RewardFactionValue3`), `RewardFactionOverride3` = VALUES(`RewardFactionOverride3`), `RewardFactionID4` = VALUES(`RewardFactionID4`), `RewardFactionValue4` = VALUES(`RewardFactionValue4`), `RewardFactionOverride4` = VALUES(`RewardFactionOverride4`), `RewardFactionID5` = VALUES(`RewardFactionID5`), `RewardFactionValue5` = VALUES(`RewardFactionValue5`), `RewardFactionOverride5` = VALUES(`RewardFactionOverride5`), `LogTitle` = VALUES(`LogTitle`), `LogDescription` = VALUES(`LogDescription`), `QuestDescription` = VALUES(`QuestDescription`), `AreaDescription` = VALUES(`AreaDescription`), `QuestCompletionLog` = VALUES(`QuestCompletionLog`), `RequiredNpcOrGo1` = VALUES(`RequiredNpcOrGo1`), `RequiredNpcOrGo2` = VALUES(`RequiredNpcOrGo2`), `RequiredNpcOrGo3` = VALUES(`RequiredNpcOrGo3`), `RequiredNpcOrGo4` = VALUES(`RequiredNpcOrGo4`), `RequiredNpcOrGoCount1` = VALUES(`RequiredNpcOrGoCount1`), `RequiredNpcOrGoCount2` = VALUES(`RequiredNpcOrGoCount2`), `RequiredNpcOrGoCount3` = VALUES(`RequiredNpcOrGoCount3`), `RequiredNpcOrGoCount4` = VALUES(`RequiredNpcOrGoCount4`), `RequiredItemId1` = VALUES(`RequiredItemId1`), `RequiredItemId2` = VALUES(`RequiredItemId2`), `RequiredItemId3` = VALUES(`RequiredItemId3`), `RequiredItemId4` = VALUES(`RequiredItemId4`), `RequiredItemId5` = VALUES(`RequiredItemId5`), `RequiredItemId6` = VALUES(`RequiredItemId6`), `RequiredItemCount1` = VALUES(`RequiredItemCount1`), `RequiredItemCount2` = VALUES(`RequiredItemCount2`), `RequiredItemCount3` = VALUES(`RequiredItemCount3`), `RequiredItemCount4` = VALUES(`RequiredItemCount4`), `RequiredItemCount5` = VALUES(`RequiredItemCount5`), `RequiredItemCount6` = VALUES(`RequiredItemCount6`), `ObjectiveText1` = VALUES(`ObjectiveText1`), `ObjectiveText2` = VALUES(`ObjectiveText2`), `ObjectiveText3` = VALUES(`ObjectiveText3`), `ObjectiveText4` = VALUES(`ObjectiveText4`);

DELETE FROM `quest_template_addon` WHERE `ID` IN (1660012, 1660013, 1660014, 1660015, 1660016, 1660017, 1660040, 1660071, 1660072, 1660073, 1660085);
INSERT INTO `quest_template_addon` (`ID`, `MaxLevel`, `AllowableClasses`, `PrevQuestID`, `ProvidedItemCount`, `SpecialFlags`)
VALUES
(1660012, 0, 0, 0, 0, 0),
(1660013, 0, 0, 1660012, 0, 0),
(1660014, 0, 0, 1660013, 0, 0),
(1660015, 0, 0, 1660014, 1, 0),
(1660016, 0, 0, 1660015, 1, 0),
(1660017, 0, 0, 1660016, 0, 0),
(1660085, 0, 0, 1660016, 1, 0),
(1660040, 0, 0, 0, 0, 0),
(1660071, 0, 0, 1660085, 0, 0),
(1660072, 0, 0, 1660071, 0, 0),
(1660073, 0, 0, 1660072, 0, 0);

-- Progress and completion texts: SOURCED-ARCHIVE, the English quest-window texts of the AscensionES
-- translation addon (questdata_parsed.json pEN / cEN). Its Details and Objectives of these 11 quests are
-- identical to the realm's quest cache (checked by the generator). 1660071 has no progress text (no
-- objective); 1660016's stays empty: the archive only repeats 1660015's there.
DELETE FROM `quest_offer_reward` WHERE `ID` IN (1660012, 1660013, 1660014, 1660015, 1660016, 1660017, 1660040, 1660071, 1660072, 1660073, 1660085);
INSERT INTO `quest_offer_reward` (`ID`, `RewardText`)
VALUES
(1660012, 'Stop.$b$bI can feel you. I know you’re there. And I know you’re not one of us.$b$bWhat business brings you to the Vulture Cult Eyrie?'),
(1660013, 'Communion is the most sacred moment for any initiate. In hers, Elydna will stake her very life. She must fight for her right to stand as a Druid of the Vulture… or else end as sacrificial carrion.$b$bBut there are still… preparations to be made. If what you seek, out of pity for her brother, is to see her survive the rite, well… perhaps you can be of use.'),
(1660014, 'Ahh… I can almost taste it. And you’ve brought five? Yes… intact. I don’t know how you resisted sneaking a bite.$b$b<Aegya runs her tongue across her lips, slowly and obscenely: a black slug slick with slime.>$b$bThe Great Vulture… will feast tonight.'),
(1660015, 'Rotten flesh… sanctified. The Great Vulture will savor this offering.$b$bThe time has come. Elydna Wingstroke’s communion begins.'),
(1660016, 'A sublime fight. The Great Vulture is pleased.$b$bOh, don’t tell me you pity Elydna. <Aegya pouts mockingly.> Didn’t I warn you of the risks of the communion?$b$bYou either triumph, and rise as one of us… or you fail, only to rot in the Moonlit Ossuary.$b$bElydna had her chance. You simply proved the stronger. Consider your own “communion” a success. From this moment, you may choose: join us… or walk away.'),
(1660017, '<The elf breathes in, catching the scent of the flower crown.>$b$bThey followed. Good.$b$bThe Great Vulture teaches many lessons, but to sacrifice such tender lives to the cruelty of its beak… that is a depravity I could never forgive myself.$b$bWhatever it takes, I will see these children safe.'),
(1660085, '<You open your hand, revealing Elydna''s pendant. At the sight of it, Thariel''s grief-stricken expression eases ever so slightly.>$b$bI suppose... in the absence of a body to mourn, this will have to do.$b$b<He takes the pendant with trembling hands and presses it to his chest.>$b$bElydna... what madness drove you to join those degenerates?'),
(1660040, 'The abomination… is it dead?$b$b<The elf glances over your garb, splattered with bits of bloody mucus.>$b$bThe abomination is dead.$b$bSplendid.'),
(1660071, 'Yes, $c? What business brings you to Dolanaar?$b$b<The druid gives your account his full attention. As your tale unfolds, his face darkens and the lines at the corners of his eyes deepen.>$b$bAegya… A name I''d hoped never to hear again. So they''re here, then. In Teldrassil.$b$bThe audacity…$b$bForget the Cult, $n, and rest easy. I''ll see to dismantling them myself.'),
(1660072, 'So, the Vulture Cult…$b$b<Her eyes are deep wells of memory. Far below, an ancient rancor ferments.>$b$bI''ll ready my Sentinels, impertinence or no from Tallonkai. He forgets that in politics—as in religion, in war, and in nearly everything that matters—it''s the women who give the orders.'),
(1660073, 'Is it done?$b$bGood work. My Sentinels will see to the rest, and they''ll be ready to strike the Vulture Cult''s nest and bring Lady Aegya to justice, once and for all.');

DELETE FROM `quest_request_items` WHERE `ID` IN (1660012, 1660013, 1660014, 1660015, 1660016, 1660017, 1660040, 1660071, 1660072, 1660073, 1660085);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`)
VALUES
(1660012, '<The elf shows you a mouthful of yellow, jagged teeth. Let that be warning enough.>$b$bOnly those who survive the Carrion Path are welcome in the Nest of the Vulture’s Cult.'),
(1660013, '<The empty sockets of Aegya’s eyes fix on you with a gaze that cuts deeper than any blade.>'),
(1660014, 'Time is short, and the Great Vulture grows restless. Even now he circles overhead, watching you…'),
(1660015, 'The communion is about to begin. You have yet to sanctify the flesh of tribute?'),
(1660016, ''),
(1660017, 'Did you reach them in time? Were they still alive?'),
(1660085, '<The elf''s eyes wander, clouded with worry.>'),
(1660040, 'The abomination… is it dead?'),
(1660071, ''),
(1660072, 'Yes, $c?'),
(1660073, 'Have you dealt with the vultures?');

-- Tallonkai Swiftroot (stock 3567) takes 1660071 and gives 1660072; his spawn belongs to tel-dolanaar.
DELETE FROM `creature_queststarter` WHERE `quest` IN (1660012, 1660013, 1660014, 1660015, 1660016, 1660017, 1660040, 1660071, 1660072, 1660073, 1660085);
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES
(161725, 1660012),
(161726, 1660013),
(161727, 1660014),
(161727, 1660015),
(161728, 1660016),
(161848, 1660017),
(161916, 1660040),
(161725, 1660071),
(3567, 1660072),
(162880, 1660073),
(161727, 1660085);

DELETE FROM `creature_questender` WHERE `quest` IN (1660012, 1660013, 1660014, 1660015, 1660016, 1660017, 1660040, 1660071, 1660072, 1660073, 1660085);
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES
(161726, 1660012),
(161727, 1660013),
(161727, 1660014),
(161728, 1660015),
(161727, 1660016),
(161848, 1660017),
(161916, 1660040),
(3567, 1660071),
(162880, 1660072),
(162880, 1660073),
(161725, 1660085);

-- ---------------------------------------------------------------------------
-- 5. The Carrion Path trigger
-- ---------------------------------------------------------------------------
-- AreaTrigger.dbc 6138 (SOURCED-CLIENT) = SuperTrack 8666, the 1660012 objective 2 point.
DELETE FROM `areatrigger` WHERE `entry` = 6138;
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`)
VALUES
(6138, 1, 10687.4, 597.43, 1373.2, 0, 10, 10, 5, 0);

DELETE FROM `areatrigger_scripts` WHERE `entry` = 6138;
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`)
VALUES
(6138, 'SmartTrigger');

-- ---------------------------------------------------------------------------
-- 6. Spawns
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` IN (9007000, 9007001, 9007010, 9007011, 9007012, 9007013, 9007014, 9007015, 9007016, 9007017, 9007018, 9007019, 9007020, 9007021, 9007022, 9007023, 9007024, 9007025, 9007026, 9007040, 9007041, 9007042, 9007043, 9007044, 9007045, 9007046, 9007047, 9007048, 9007049, 9007050, 9007051, 9007052, 9007053, 9007054, 9007055, 9007070, 9007071, 9007072, 9007080, 9007081, 9007082, 9007083, 9007084, 9007085, 9007086, 9007100, 9007101, 9007102, 9007103, 9007104, 9007105, 9007106, 9007107, 9007108, 9007109, 9007110, 9007111, 9007112, 9007113, 9007114, 9007115, 9007116, 9007117, 9007118, 9007130, 9007131, 9007132, 9007133, 9007134, 9007135, 9007136, 9007137, 9007138, 9007139, 9007140, 9007141, 9007142, 9007143, 9007144, 9007145, 9007146, 9007147, 9007148, 9007149, 9007150, 9007151, 9007170, 9007171, 9007172, 9007173, 9007174, 9007200, 9007201, 9007202, 9007203, 9007204, 9007205, 9007206, 9007207, 9007208, 9007209, 9007210) OR `guid` BETWEEN 9007000 AND 9007399;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`)
VALUES
(9007000, 161725, 1, 0, 0, 1, 1, 0, 10376.4, 745.41, 1321.77, 2.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8840, the 1660085 turn-in point at the foot of Aldrassil by the road leaving Shadowglen, 1.9 yd from the signpost; faces 2.20 toward Aldrassil and Conservator Ilthalaine, the way players come'),
(9007001, 161726, 1, 0, 0, 1, 1, 0, 10694.8, 594.12, 1380.9, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8667, the 1660012 turn-in point on the Kalidarroots03 roots above the Carrion Path trigger; faces 3.14 down the path, the way players climb'),
(9007080, 161727, 1, 0, 0, 1, 1, 0, 10796.6, 481.19, 1405.531, 2.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8668, the 1660013/14/16 turn-in point on the dais of the outpost hall ("further inside, in the hall"); faces 2.21 down the hall toward its entrance'),
(9007081, 161728, 1, 0, 0, 1, 1, 0, 10823.8, 493.3, 1396.137, 2.3, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8670, the 1660015 turn-in point in front of the petrified Ancient Cathartos (Petrifiedtreant01, "the Ancient looming behind him"); faces 2.30, his back to the Ancient'),
(9007082, 161848, 1, 0, 0, 1, 1, 0, 10689.6, 528.19, 1437.811, 1.53, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8693, the 1660017 turn-in point on the 1437.8 level of the west guard tower (Shadowglen_Nightelfguardtower); faces 1.53 into the tower toward the stair'),
(9007083, 161916, 1, 0, 0, 1, 1, 0, 10712.1, 447.13, 1411.197, 0.33, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8716, the 1660040 turn-in point at the ossuary mouth by the cart and tent; faces 0.33 toward the Eyrie basin, the way players come'),
(9007084, 161784, 1, 0, 0, 1, 1, 0, 10821.4, 454.97, 1387.108, 5.5, 180, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8672, the 1660016 objective 2 point in the Great Nest beside the meat piles; faces 5.50 toward the Offering Bowl'),
(9007085, 161832, 1, 0, 0, 1, 1, 0, 10618, 428, 1380.195, 0.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: the Moonlit Ossuary deep chamber floor (1380.2) at the warning totems, 4.3 yd from its Questie sighting (10622.2, 428.9), which is a slope; faces 0.14 toward the ramp from the hall'),
(9007086, 6491, 1, 0, 0, 1, 4294967295, 0, 10761.5, 441.5, 1400.948, 4.07, 60, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: beside the ruins and elven fountain of the Vulture Cult Eyrie Graveyard (WorldSafeLocs 6078, 8.6 yd); faces 4.07 toward the graveyard point'),
(9007100, 162880, 1, 0, 0, 1, 1, 1, 10055.6, 910.91, 1416.836, 5.24, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: SOURCED-CLIENT ST8783, the 1660072/73 turn-in point inside the hunters'' lodge; faces 5.24 toward the yard door'),
(9007101, 162931, 1, 0, 0, 1, 1, 0, 10096, 880, 1417.643, 4.87, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: inside the hunters'' lodge by the globe and the chart boxes, the chronicler''s corner (INFERRED); faces 4.87 toward the yard door'),
(9007102, 162856, 1, 0, 0, 1, 1, 1, 10103.45, 830.67, 1416.488, 1.35, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting by the table and bench at the glaive thrower; faces 1.35 across the yard'),
(9007103, 162856, 1, 0, 0, 1, 1, 1, 10134, 896.86, 1416.434, 4.13, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting at the north tent by the roots; faces 4.13 toward the yard'),
(9007104, 162870, 1, 0, 0, 1, 1, 1, 10066.12, 851.04, 1415.069, 0.2, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting at the tent by the moongate path; faces 0.20 toward the yard'),
(9007105, 162870, 1, 0, 0, 1, 1, 1, 10117.03, 876.49, 1415.426, 4.31, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting by the crates and grain sacks; faces 4.31 toward the yard'),
(9007106, 162871, 1, 0, 0, 1, 1, 1, 10074.5, 856.5, 1415.072, 0.1, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: outside the tent, 5 yd from her Questie sighting (10069.51, 856.13), which is inside it; faces 0.10 toward the yard'),
(9007107, 162871, 1, 0, 0, 1, 1, 1, 10123.82, 907.04, 1416.516, 4.42, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting at the north-west tent by the stone rune; faces 4.42 toward the yard'),
(9007108, 162872, 1, 0, 0, 1, 1, 1, 10083.09, 835.76, 1415.015, 0.73, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting beside the glaive thrower; faces 0.73 toward the yard'),
(9007109, 162872, 1, 0, 0, 1, 1, 1, 10174.73, 845.95, 1404.895, 5.6, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion owl-statue gate: Questie sighting by the stump; faces 5.60 toward the gate'),
(9007110, 162873, 1, 0, 0, 1, 1, 1, 10178.12, 851.04, 1405.121, 4.85, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion owl-statue gate: Questie sighting by the stone rune and the wall; faces 4.85 toward the gate'),
(9007111, 162873, 1, 0, 0, 1, 1, 1, 10147.58, 871.4, 1414.823, 3.43, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: Questie sighting on the north shelf; faces 3.43 toward the yard'),
(9007112, 162856, 1, 0, 0, 1, 1, 1, 10117.8, 858.86, 1415.462, 2.49, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: the SOURCED-CLIENT ST8784 objective point of 1660072 in the middle of the yard; faces 2.49 toward the lodge'),
(9007113, 162870, 1, 0, 0, 1, 1, 1, 10106, 845.5, 1415.505, 1.3, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: by the wooden statue and the stone runes; faces 1.30 across the yard'),
(9007114, 162871, 1, 0, 0, 1, 1, 1, 10132, 858, 1415.551, 3.05, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: east end of the yard; faces 3.05 toward the objective point'),
(9007115, 162872, 1, 0, 0, 1, 1, 1, 10090, 848.5, 1415.232, 0.52, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion training yard: south end between the glaive thrower and the tents; faces 0.52 toward the yard'),
(9007116, 162970, 1, 0, 0, 1, 1, 1, 10074, 832.5, 1412.635, 3.75, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion moongate: guarding the arch at the top of the switchback; faces 3.75 down the path'),
(9007117, 162970, 1, 0, 0, 1, 1, 1, 10171, 841.5, 1404.981, 0.07, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion owl-statue gate: guarding the west side of the gate in the Aszhara walls; faces 0.07 out through it'),
(9007118, 162970, 1, 0, 0, 1, 1, 1, 10170.5, 849, 1405.15, 5.62, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Theren-Dion owl-statue gate: guarding the east side of the gate; faces 5.62 out through it'),
(9007010, 161787, 1, 0, 0, 1, 1, 0, 10557.44, 639.07, 1327.743, 5.5, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), foot of the path where it leaves the valley floor, 29.7 yd from Alanor'),
(9007011, 161787, 1, 0, 0, 1, 1, 0, 10584.99, 625.87, 1328.492, 2.7, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), between the great tree Kalidartree04 and the fallen log Kalidartreelog01, on the path'),
(9007012, 161787, 1, 0, 0, 1, 1, 0, 10598.52, 636.89, 1329.22, 2.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), guarding the pair of warning totems (Nightelfwarningtotem 01/03) at the first bend, facing down the path'),
(9007013, 161787, 1, 0, 0, 1, 1, 0, 10589.24, 655.45, 1325.926, 3.4, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), north bank beside the fallen log Kalidartreelog01'),
(9007014, 161787, 1, 0, 0, 1, 1, 0, 10612.44, 644, 1329.276, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), among the Kalidarroots03 roots on the north bank'),
(9007015, 161787, 1, 0, 0, 1, 1, 0, 10606.45, 614.42, 1335.602, 2.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), south bank under Kalidartree03 by the warning totem Nightelfwarningtotem_02, facing the path'),
(9007016, 161787, 1, 0, 0, 1, 1, 0, 10621.24, 665.02, 1325.957, 3.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, meadow by the old stump Kalidartreestump01'),
(9007017, 161787, 1, 0, 0, 1, 1, 0, 10646.18, 672.56, 1330.515, 3.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, open slope under the canopy'),
(9007018, 161787, 1, 0, 0, 1, 1, 0, 10615.92, 696.05, 1326.182, 3.2, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, open ground under the canopy'),
(9007019, 161787, 1, 0, 0, 1, 1, 0, 10603.55, 690.25, 1326.067, 3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, open ground under the canopy'),
(9007020, 161787, 1, 0, 0, 1, 1, 0, 10597.94, 685.61, 1324.446, 2.6, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, foot of the slope under the canopy'),
(9007021, 161787, 1, 0, 0, 1, 1, 0, 10626.75, 706.35, 1324.604, 3.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, northern edge of the treant ground'),
(9007022, 161787, 1, 0, 0, 1, 1, 0, 10613.12, 709.83, 1323.697, 2.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; east woods north of the Carrion Path, northern edge of the treant ground'),
(9007023, 161787, 1, 0, 0, 1, 1, 0, 10645.98, 602.82, 1347.403, 2.3, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), the climb between the Kalidarroots01 roots'),
(9007024, 161787, 1, 0, 0, 1, 1, 0, 10661.45, 616.59, 1353.891, 2.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), beside the warning totem Nightelfwarningtotem_03 at the upper bend, facing down the path'),
(9007025, 161787, 1, 0, 0, 1, 1, 0, 10654.1, 634.57, 1356.596, 2.9, 300, 5, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), upper terrace among the stone runes'),
(9007026, 161787, 1, 0, 0, 1, 1, 0, 10648.4, 639.36, 1357.783, 2.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Fretful Withered Treant, SOURCED-QUESTIE sighting; Carrion Path (area 10208), upper terrace by the warning totems (Nightelfwarningtotem 02/03), facing down the path'),
(9007040, 161735, 1, 0, 0, 1, 1, 0, 10617, 424.5, 1380.834, 1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber at the side of the Rotting Flesh Spawn by the coffins ("the worms ... are nothing but its spawn"), a deliberate pair with it'),
(9007041, 161735, 1, 0, 0, 1, 1, 0, 10614, 431, 1379.856, 5.8, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber floor'),
(9007042, 161735, 1, 0, 0, 1, 1, 0, 10609.3, 427.05, 1380.328, 2.4, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber, Questie sighting'),
(9007043, 161735, 1, 0, 0, 1, 1, 0, 10604, 432, 1379.706, 0.6, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber west'),
(9007044, 161735, 1, 0, 0, 1, 1, 0, 10614, 436, 1379.253, 3.9, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber north, at the foot of the hall; still, because it lies 4.2 yd in front of the tel-ossuary-hall album vantage'),
(9007045, 161735, 1, 0, 0, 1, 1, 0, 10609.46, 385.06, 1386.127, 1.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south room at the coffins, Questie sighting'),
(9007046, 161735, 1, 0, 0, 1, 1, 0, 10612.92, 382.61, 1384.884, 4.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south room at the coffins, Questie sighting'),
(9007047, 161735, 1, 0, 0, 1, 1, 0, 10618, 386.5, 1384.252, 3.3, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south room by the bloody meat'),
(9007048, 161735, 1, 0, 0, 1, 1, 0, 10635.82, 470.76, 1377.372, 0.2, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: west chamber by the coffin, Questie sighting'),
(9007049, 161735, 1, 0, 0, 1, 1, 0, 10642.16, 463.62, 1378.772, 2.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: west chamber at the bloody meat, Questie sighting'),
(9007050, 161735, 1, 0, 0, 1, 1, 0, 10590.2, 421.18, 1388.429, 4.5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south chamber, Questie sighting'),
(9007051, 161735, 1, 0, 0, 1, 1, 0, 10584.82, 423.24, 1388.385, 1.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south chamber at the coffin, Questie sighting'),
(9007052, 161735, 1, 0, 0, 1, 1, 0, 10638, 434, 1390.654, 0.5, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: lower hall'),
(9007053, 161735, 1, 0, 0, 1, 1, 0, 10679.78, 418.4, 1406.414, 0.9, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: the descent from the corridor, Questie sighting'),
(9007054, 161735, 1, 0, 0, 1, 1, 0, 10688.9, 420.33, 1404.122, 3.8, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: the descent from the corridor, Questie sighting'),
(9007055, 161735, 1, 0, 0, 1, 1, 0, 10738.29, 455.64, 1404.07, 2, 300, 3, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Rotworm; the Eyrie (area 10206): basin by the ossuary mouth, Questie sighting'),
(9007070, 161789, 1, 0, 0, 1, 1, 0, 10841, 474.5, 1396.585, 4.32, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Sacred Vulture; the Great Nest: perched on the west rim by the fallen log, watching the nest'),
(9007071, 161789, 1, 0, 0, 1, 1, 0, 10823, 477, 1395.616, 4.95, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Sacred Vulture; the Great Nest: perched on the west rim above the bowl'),
(9007072, 161789, 1, 0, 0, 1, 1, 0, 10812, 470, 1392.793, 5.4, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Sacred Vulture; the Great Nest: perched on the south-west rim'),
(9007130, 162925, 1, 0, 0, 1, 1, 0, 10159.12, 794.02, 1431.279, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south ledge on the carrion (Bloodymeat02), the Questie sighting'),
(9007131, 162925, 1, 0, 0, 1, 1, 0, 10150, 790, 1434.122, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south ledge west of the carrion'),
(9007132, 162925, 1, 0, 0, 1, 1, 0, 10141, 787.5, 1435.155, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south-west ledge'),
(9007133, 162925, 1, 0, 0, 1, 1, 0, 10135, 800, 1432.557, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south-west ledge above the shelf edge'),
(9007134, 162925, 1, 0, 0, 1, 1, 0, 10145, 812.5, 1432.877, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: ledge above the moongate path'),
(9007135, 162925, 1, 0, 0, 1, 1, 0, 10140, 805, 1432.178, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: ledge above the moongate path, west end'),
(9007136, 162925, 1, 0, 0, 1, 1, 0, 10158, 807.5, 1424.875, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: low ledge over the shelf'),
(9007137, 162925, 1, 0, 0, 1, 1, 0, 10140, 772.5, 1447.207, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: the high south-west ledge'),
(9007138, 162925, 1, 0, 0, 1, 1, 0, 10156, 776, 1435.533, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: middle south ledge'),
(9007139, 162925, 1, 0, 0, 1, 1, 0, 10162.5, 770, 1433.941, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: middle south ledge, east end'),
(9007140, 162925, 1, 0, 0, 1, 1, 0, 10170.99, 765.51, 1432.297, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south-east ledge, the Questie sighting'),
(9007141, 162925, 1, 0, 0, 1, 1, 0, 10180, 760, 1434.311, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south-east ledge, north end'),
(9007142, 162925, 1, 0, 0, 1, 1, 0, 10168, 757.5, 1431.019, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: south-east ledge, south end'),
(9007143, 162925, 1, 0, 0, 1, 1, 0, 10175, 752.5, 1430.313, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: far south-east ledge'),
(9007144, 162925, 1, 0, 0, 1, 1, 0, 10182.5, 930, 1436.532, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north ledge above the lodge'),
(9007145, 162925, 1, 0, 0, 1, 1, 0, 10181, 940, 1432.812, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north ledge, west part'),
(9007146, 162925, 1, 0, 0, 1, 1, 0, 10182, 922.5, 1436.398, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north ledge, east part'),
(9007147, 162925, 1, 0, 0, 1, 1, 0, 10165, 952.5, 1428.707, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north-west ledge'),
(9007148, 162925, 1, 0, 0, 1, 1, 0, 10172.5, 950, 1431.948, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north-west ledge, upper step'),
(9007149, 162925, 1, 0, 0, 1, 1, 0, 10170, 902.5, 1435.532, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: north-east ledge by the dead log'),
(9007150, 162925, 1, 0, 0, 1, 1, 0, 10160, 915, 1425.076, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: low north-east ledge over the shelf'),
(9007151, 162925, 1, 0, 0, 1, 1, 0, 10190, 905, 1453.776, 0, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Vulture Egg; rocks around Theren-Dion: the high north-east rocks'),
(9007170, 162874, 1, 0, 0, 1, 1, 0, 10145.88, 783.84, 1435.533, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Frenzied Vulture; rocks around Theren-Dion: south-west ledge beside its nest, the Questie sighting'),
(9007171, 162874, 1, 0, 0, 1, 1, 0, 10172.5, 762.5, 1432.164, 2.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Frenzied Vulture; rocks around Theren-Dion: south-east ledge beside the Questie egg (its own sighting (10169.98, 765.51) stands on the egg)'),
(9007172, 162874, 1, 0, 0, 1, 1, 0, 10165, 795, 1432.944, 3.8, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Frenzied Vulture; rocks around Theren-Dion: south ledge above the carrion'),
(9007173, 162874, 1, 0, 0, 1, 1, 0, 10178, 945.5, 1431.893, 4.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Frenzied Vulture; rocks around Theren-Dion: north-west ledge between the warning totem and the Felwoodtree04 roots, between its two nests; faces 4.1 toward the training yard'),
(9007174, 162874, 1, 0, 0, 1, 1, 0, 10167.5, 905, 1435.74, 4.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Frenzied Vulture; rocks around Theren-Dion: perched on the dead log of the north-east ledge'),
(9007200, 2032, 1, 0, 0, 1, 1, 0, 10620, 762, 1316.13, 4.4, 180, 12, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground 6 yd from the ST7 objective point'),
(9007201, 2032, 1, 0, 0, 1, 1, 0, 10590, 780, 1312.33, 5.9, 180, 12, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground west of ST7'),
(9007202, 2032, 1, 0, 0, 1, 1, 0, 10665, 745, 1320.846, 3, 180, 12, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground east of ST7 between the boars'),
(9007203, 2032, 1, 0, 0, 1, 1, 0, 10640, 795, 1315.391, 4, 180, 12, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground north-east of ST7'),
(9007204, 2032, 1, 0, 0, 1, 1, 0, 10545, 760, 1313.492, 0.8, 180, 12, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, under the canopy south-west of ST7'),
(9007205, 2032, 1, 0, 0, 1, 1, 0, 10605, 768, 1313.426, 1.2, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground 13 yd west of ST7'),
(9007206, 2032, 1, 0, 0, 1, 1, 0, 10635, 775, 1318.909, 3.6, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, rise 18 yd east of ST7'),
(9007207, 2032, 1, 0, 0, 1, 1, 0, 10650, 762, 1318.707, 2.4, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground between ST7 and the eastern boars'),
(9007208, 2032, 1, 0, 0, 1, 1, 0, 10612, 790, 1312.701, 5, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, low ground north of ST7'),
(9007209, 2032, 1, 0, 0, 1, 1, 0, 10630, 748, 1319.196, 0.3, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, slope south-east of ST7 toward the Carrion Path woods'),
(9007210, 2032, 1, 0, 0, 1, 1, 0, 10578, 772.5, 1312.725, 5.6, 180, 8, 0, 1, 0, 1, 0, 0, 0, '', NULL, 0, 'CoA Vulture Cult: Mangy Nightsaber for 457; east woods of Shadowglen north of the Carrion Path, open ground 5 yd from the Kalidarroots03 roots west of ST7');

DELETE FROM `gameobject` WHERE `guid` IN (7913000, 7913010, 7913011, 7913012, 7913013, 7913014, 7913015, 7913016, 7913017, 7913018, 7913019, 7913020, 7913021, 7913022, 7913023, 7913024, 7913025, 7913026, 7913027, 7913050, 7913051, 7913052, 7913053, 7913054, 7913055, 7913056, 7913057, 7913058, 7913059, 7913060, 7913061, 7913062) OR `guid` BETWEEN 7913000 AND 7913199;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7913000, 2300513, 1, 0, 0, 1, 1, 10836.7, 439.73, 1386.156, 0, 0, 0, 0, 1, 60, 100, 1, '', 'CoA Vulture Cult: Offering Bowl: SOURCED-ATLAS point among the meat offerings of the Great Nest, on the terrain bowl (not the invisible collision shell), 0.2 yd from the ST8671 objective point'),
(7913010, 2300512, 1, 0, 0, 1, 1, 10667.5, 434, 1395.815, 1.2, 0, 0, 0.564642, 0.825336, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: hall, beside the bloody meat and the warning totem, 2 yd from the Questie corpse point (10669.7, 437.5)'),
(7913011, 2300512, 1, 0, 0, 1, 1, 10656, 429, 1395.131, 2.6, 0, 0, 0.963558, 0.267499, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: hall, south side under the lantern'),
(7913012, 2300512, 1, 0, 0, 1, 1, 10640, 431, 1390.953, 0.4, 0, 0, 0.198669, 0.980067, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: lower end of the hall under the hanging lantern'),
(7913013, 2300512, 1, 0, 0, 1, 1, 10633.8, 426.7, 1391.697, 5.1, 0, 0, 0.557684, -0.830054, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: lower hall by the crate, the Questie corpse point'),
(7913014, 2300512, 1, 0, 0, 1, 1, 10612.5, 423.5, 1380.955, 3.9, 0, 0, 0.92896, -0.370181, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber beside the coffins (the Questie corpse point (10617.3, 421.7) lies on a coffin, 4.9 yd)'),
(7913015, 2300512, 1, 0, 0, 1, 1, 10606, 426, 1380.495, 1.8, 0, 0, 0.783327, 0.62161, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber by the pottery and the barrel'),
(7913016, 2300512, 1, 0, 0, 1, 1, 10614, 446, 1379.05, 4.5, 0, 0, 0.778073, -0.628174, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: deep chamber west under the hanging lantern, 6 yd clear of the tel-ossuary-hall album vantage'),
(7913017, 2300512, 1, 0, 0, 1, 1, 10636.5, 466, 1377.292, 0.9, 0, 0, 0.434966, 0.900447, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: west chamber (1377), before the coffin and bench'),
(7913018, 2300512, 1, 0, 0, 1, 1, 10631.5, 465, 1377.1, 3.4, 0, 0, 0.991665, -0.128844, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: west chamber by the warning totem'),
(7913019, 2300512, 1, 0, 0, 1, 1, 10599.5, 463, 1389.785, 5.9, 0, 0, 0.190423, -0.981702, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: north side room (1389) by the bloody meat and coffin'),
(7913020, 2300512, 1, 0, 0, 1, 1, 10592.5, 464.5, 1388.631, 2.2, 0, 0, 0.891207, 0.453596, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: north side room by the stone rune'),
(7913021, 2300512, 1, 0, 0, 1, 1, 10597.5, 458, 1388.312, 4, 0, 0, 0.909297, -0.416147, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: north side room by the pottery and the coffin'),
(7913022, 2300512, 1, 0, 0, 1, 1, 10585, 421, 1388.311, 1.5, 0, 0, 0.681639, 0.731689, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south chamber (1388) beside the coffin and meat'),
(7913023, 2300512, 1, 0, 0, 1, 1, 10585, 427.5, 1390.087, 5.2, 0, 0, 0.515501, -0.856889, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south chamber by the bloody meat and bench'),
(7913024, 2300512, 1, 0, 0, 1, 1, 10614.5, 404, 1384.598, 0.3, 0, 0, 0.149438, 0.988771, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south-east room (1384.6) by the pottery'),
(7913025, 2300512, 1, 0, 0, 1, 1, 10613, 411.5, 1384.291, 3.1, 0, 0, 0.999784, 0.020795, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south-east room by the warning totem'),
(7913026, 2300512, 1, 0, 0, 1, 1, 10609, 382, 1386.138, 2.7, 0, 0, 0.975723, 0.219007, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south room among the coffins, 5 yd from the SOURCED-ATLAS corpse (10613.2, 377.5), which lies on a coffin'),
(7913027, 2300512, 1, 0, 0, 1, 1, 10616, 383, 1384.371, 4.4, 0, 0, 0.808496, -0.588501, 60, 100, 1, '', 'CoA Vulture Cult: Fallen Aspirant corpse; the Moonlit Ossuary (area 10207), floor of Shadowglen_Moonlitossuary.wmo: south room by the bloody meat under the lantern'),
(7913050, 2300526, 1, 0, 0, 1, 1, 10827.7, 448.38, 1386.465, 2, 0, 0, 0.841471, 0.540302, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): the SOURCED-CLIENT ST8695 objective point among the carrion'),
(7913051, 2300526, 1, 0, 0, 1, 1, 10827.2, 438.5, 1386.322, 1, 0, 0, 0.479426, 0.877583, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): beside the bloody meat, 2.4 yd from the SOURCED-ATLAS baby (10825.2, 440.44), which lies on it'),
(7913052, 2300526, 1, 0, 0, 1, 1, 10820.8, 448.2, 1386.799, 4.2, 0, 0, 0.863209, -0.504846, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): the Questie sighting, between two meat piles'),
(7913053, 2300526, 1, 0, 0, 1, 1, 10831.5, 455.5, 1386.793, 3, 0, 0, 0.997495, 0.070737, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): by the meat piles in the middle of the bowl'),
(7913054, 2300526, 1, 0, 0, 1, 1, 10828.5, 463.5, 1387.447, 5.5, 0, 0, 0.381661, -0.924302, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): north-west of the bowl between two meat piles'),
(7913055, 2300526, 1, 0, 0, 1, 1, 10841, 449.5, 1386.935, 0.6, 0, 0, 0.29552, 0.955336, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): north edge under the thorns by the meat'),
(7913056, 2300526, 1, 0, 0, 1, 1, 10816, 453.5, 1387.271, 2.9, 0, 0, 0.992713, 0.120503, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): south-west edge by the meat piles under the thorns'),
(7913057, 2300526, 1, 0, 0, 1, 1, 10832, 435, 1386.485, 4.8, 0, 0, 0.675463, -0.737394, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): east side under the thorns'),
(7913058, 2300526, 1, 0, 0, 1, 1, 10823, 458, 1387.091, 1.6, 0, 0, 0.717356, 0.696707, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): west side near Elydna'),
(7913059, 2300526, 1, 0, 0, 1, 1, 10836, 459, 1387.509, 3.7, 0, 0, 0.961275, -0.27559, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): north-west side under the thorns'),
(7913060, 2300526, 1, 0, 0, 1, 1, 10816.5, 441, 1387.343, 0.2, 0, 0, 0.099833, 0.995004, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): south edge under the thorns'),
(7913061, 2300526, 1, 0, 0, 1, 1, 10843, 442.5, 1386.459, 5, 0, 0, 0.598472, -0.801144, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): north-east edge under the thorns'),
(7913062, 2300526, 1, 0, 0, 1, 1, 10831, 444.5, 1386.314, 2.5, 0, 0, 0.948985, 0.315322, 60, 100, 1, '', 'CoA Vulture Cult: Baby Night Elf; the Great Nest, on the terrain bowl (not the invisible collision shell): centre of the bowl');

-- ---------------------------------------------------------------------------
-- 7. Stock rows of quest 457 on the CoA Carrion Path
-- ---------------------------------------------------------------------------
-- The Mangy Nightsabers and one Thistle Boar CoA left floating, sunk or buried when it raised the Carrion
-- Path (DERIVED: surface.floor on CoA and stock data). Each UPDATE matches guid and entry.
-- 49630 (2032): re-floored: CoA re-sculpted the Carrion Path foot (stock z 1324.91 floated 1.12 yd).
UPDATE `creature` SET `position_x` = 10516.6, `position_y` = 648.41, `position_z` = 1323.787, `orientation` = 5.6549 WHERE `guid` = 49630 AND `id` = 2032;
-- 49632 (2032): re-floored: CoA re-sculpted the Carrion Path (stock z 1330.73 floated 0.95 yd).
UPDATE `creature` SET `position_x` = 10549.1, `position_y` = 623.0, `position_z` = 1329.776, `orientation` = 3.7699 WHERE `guid` = 49632 AND `id` = 2032;
-- 49633 (1985): re-floored: CoA re-sculpted the Carrion Path (stock z 1326.72 was 1.82 yd under the ground).
UPDATE `creature` SET `position_x` = 10568.5, `position_y` = 633.22, `position_z` = 1328.538, `orientation` = 3.4558 WHERE `guid` = 49633 AND `id` = 1985;
-- 49644 (2032): moved 3.9 yd off the Kalidartree03 trunk it was sunk into, to open ground on the path.
UPDATE `creature` SET `position_x` = 10619.5, `position_y` = 613.0, `position_z` = 1337.477, `orientation` = 5.4105 WHERE `guid` = 49644 AND `id` = 2032;
-- 49642 (2032): moved out of the Kalidargiantroot01 root that buries its stock spot 22 yd under the raised path,
-- to open ground in the east woods, 37 yd from the nearest treant.
UPDATE `creature` SET `position_x` = 10672.0, `position_y` = 700.0, `position_z` = 1328.895, `orientation` = 4.8869 WHERE `guid` = 49642 AND `id` = 2032;

-- ---------------------------------------------------------------------------
-- 8. The Vulture Cult Eyrie graveyard
-- ---------------------------------------------------------------------------
-- WorldSafeLocs.dbc 6078 "Vulture Cult Eyrie Graveyard" (SOURCED-CLIENT) was never imported. It is linked
-- to the Eyrie area (10206), which the core searches before the zone (GameGraveyard.cpp:144-151), so the
-- rest of Shadowglen keeps Aldrassil (93) as in stock. The Moonlit Ossuary, a zone of its own (AreaTable
-- parent 0), gets both, where it had none and fell back to Westfall.
DELETE FROM `game_graveyard` WHERE `ID` = 6078;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`)
VALUES
(6078, 1, 10756.3, 434.565, 1402.04, 'Shadowglen, Vulture Cult Eyrie');

DELETE FROM `graveyard_zone` WHERE (`ID`, `GhostZone`) IN ((6078, 10206), (6078, 10207), (93, 10207));
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES
(6078, 10206, 0, 'The Eyrie - Vulture Cult Eyrie GY'),
(6078, 10207, 0, 'Moonlit Ossuary - Vulture Cult Eyrie GY'),
(93, 10207, 0, 'Moonlit Ossuary - Teldrassil, Aldrassil GY');

-- ---------------------------------------------------------------------------
-- 9. Scripts
-- ---------------------------------------------------------------------------
-- Elydna's communion (1660016). The Offering Bowl wakes her once: she keeps the offering player, walks
-- to the bowl, kneels and calls on the Great Vulture, rises after 5 s and fights: Moonfire 256721 on her
-- victim, a MoonFire Zone (161905, spell 256739) under a random player every 14-18 s, and at half health
-- her 4 s Tornado cast 256757, which raises two tornadoes (161907). A bowl use during the rite is ignored.
-- Evading or dying despawns her helpers; she runs back to ST8672 and waits again. Lady Aegya announces the
-- start and the end. The walk-in, the helpers placement and timings, and her lines are INFERRED; the
-- helpers and their spells are CoA data (creature cache, Spell.dbc, MobSpells.lua).
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (161725, 161727, 161782, 161784, 161847, 161905, 161907, 162856, 162870, 162871, 162872, 162873, 162925) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(161725, 0, 0, 0, 62, 0, 100, 0, 932000, 0, 0, 0, 0, 0, 33, 162932, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thariel Wingstroke - On Gossip Option 0 Selected - Quest Credit Speak with Thariel Wingstroke'),
(161725, 0, 1, 0, 62, 0, 100, 0, 932000, 1, 0, 0, 0, 0, 33, 162932, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Thariel Wingstroke - On Gossip Option 1 Selected - Quest Credit Speak with Thariel Wingstroke'),
(161727, 0, 0, 0, 62, 0, 100, 0, 932003, 0, 0, 0, 0, 0, 33, 161797, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Lady Aegya - On Gossip Option 0 Selected - Quest Credit Speak with Lady Aegya'),
(161727, 0, 1, 0, 38, 0, 100, 0, 1, 1, 30000, 30000, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lady Aegya - On Data Set 1 1 from Elydna - Yell: the communion begins'),
(161727, 0, 2, 0, 38, 0, 100, 0, 2, 1, 30000, 30000, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Lady Aegya - On Data Set 2 1 from the dying Elydna - Yell: the Great Vulture is pleased'),
(161782, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Fallen Aspirant - On Just Summoned - Attack the player who opened its corpse'),
(161784, 0, 0, 1, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Reset - Wait for an offering'),
(161784, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Stand'),
(161784, 0, 2, 3, 38, 1, 100, 0, 1, 1, 0, 0, 0, 0, 22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Data Set 1 1 from the Offering Bowl while waiting - Begin the communion (a bowl use during it is ignored)'),
(161784, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 2, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Keep the offering player (the bowl overwrites list 1 on every use)'),
(161784, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 12, 2, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Say line 0 to the offering player'),
(161784, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 161727, 100, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Tell Lady Aegya the communion begins'),
(161784, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 59, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Walk'),
(161784, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 10834, 443, 1386.288, 5.4, 'Elydna Wingstroke - Linked - Walk to the Offering Bowl (terrain between the meat piles, 2.9 yd from the Offering Bowl and 17.4 yd from her post on ST8672, on the Shadowglen-start navmesh; faces 5.40 onto the bowl)'),
(161784, 0, 8, 9, 34, 2, 100, 0, 8, 1, 0, 0, 0, 0, 17, 68, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On reaching the Offering Bowl - Kneel'),
(161784, 0, 9, 10, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Yell line 1'),
(161784, 0, 10, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 5000, 5000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Rise in 5 seconds'),
(161784, 0, 11, 12, 59, 2, 100, 0, 1, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Timed Event 1 - Stand'),
(161784, 0, 12, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 22, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - The duel begins'),
(161784, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Turn hostile'),
(161784, 0, 14, 15, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 12, 2, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Attack the offering player'),
(161784, 0, 15, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 12, 2, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Say line 2 to the offering player'),
(161784, 0, 16, 0, 1, 4, 100, 0, 10000, 10000, 10000, 10000, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Out of Combat 10 s after turning hostile (the offering player is gone) - Evade home'),
(161784, 0, 17, 0, 0, 0, 100, 0, 3000, 5000, 9000, 12000, 0, 0, 11, 256721, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - In Combat - Cast Moonfire on the victim'),
(161784, 0, 18, 0, 0, 0, 100, 1, 8000, 8000, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - In Combat, once - Say line 4 with the first MoonFire Zone'),
(161784, 0, 19, 0, 0, 0, 100, 0, 8000, 8000, 14000, 18000, 0, 0, 12, 161905, 3, 5000, 0, 0, 0, 5, 40, 1, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - In Combat - Summon a MoonFire Zone under a random player'),
(161784, 0, 20, 21, 2, 0, 100, 1, 0, 50, 0, 0, 0, 0, 11, 256757, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - At 50% Health - Cast Tornado (4 s)'),
(161784, 0, 21, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Yell line 3'),
(161784, 0, 22, 0, 8, 0, 100, 0, 256757, 0, 0, 0, 0, 0, 12, 161907, 3, 20000, 0, 0, 0, 202, 8, 2, 1, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Tornado completed - Summon two tornadoes within 8 yd'),
(161784, 0, 23, 24, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Evade - Restore her friendly faction'),
(161784, 0, 24, 25, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 204, 161905, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Despawn her MoonFire Zones'),
(161784, 0, 25, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 204, 161907, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Despawn her tornadoes'),
(161784, 0, 26, 27, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - On Death - Say line 5'),
(161784, 0, 27, 28, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 204, 161905, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Despawn her MoonFire Zones'),
(161784, 0, 28, 29, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 204, 161907, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Despawn her tornadoes'),
(161784, 0, 29, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 2, 1, 0, 0, 0, 0, 19, 161727, 100, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke - Linked - Tell Lady Aegya the communion is over'),
(161847, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 29, 2, 0, 161848, 161847, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Butterfly - On Just Summoned - Follow the summoner; within 5.5 yd of Eldya credit Butterflies delivered and despawn'),
(161905, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11, 256739, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke <MoonFire Zone> - On Just Summoned - Cast Moonfire (2 s ground ring, then the burst)'),
(161907, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 256758, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke <Tornado> - On Just Summoned - Tornado model'),
(161907, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 256759, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke <Tornado> - Linked - Winds that strike and knock back every second'),
(161907, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 89, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Elydna Wingstroke <Tornado> - Linked - Drift within 10 yd'),
(162856, 0, 0, 1, 62, 0, 100, 0, 932010, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Gossip Option 0 Selected - Close Gossip'),
(162856, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Store the challenger'),
(162856, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Turn hostile for the bout'),
(162856, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Attack the challenger'),
(162856, 0, 4, 5, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 33, 162924, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - At 20% Health - Quest Credit Theren-Dion Sentinel defeated to the challenger'),
(162856, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Rest: no more challenges for now'),
(162856, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Restore her faction'),
(162856, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Yield and walk back'),
(162856, 0, 8, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Evade - Restore her faction'),
(162856, 0, 9, 0, 21, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Reached Home - Rest 60 seconds'),
(162856, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - After her rest - Accept challenges again'),
(162870, 0, 0, 1, 62, 0, 100, 0, 932010, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Gossip Option 0 Selected - Close Gossip'),
(162870, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Store the challenger'),
(162870, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Turn hostile for the bout'),
(162870, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Attack the challenger'),
(162870, 0, 4, 5, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 33, 162924, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - At 20% Health - Quest Credit Theren-Dion Sentinel defeated to the challenger'),
(162870, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Rest: no more challenges for now'),
(162870, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Restore her faction'),
(162870, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Yield and walk back'),
(162870, 0, 8, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Evade - Restore her faction'),
(162870, 0, 9, 0, 21, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Reached Home - Rest 60 seconds'),
(162870, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - After her rest - Accept challenges again'),
(162871, 0, 0, 1, 62, 0, 100, 0, 932010, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Gossip Option 0 Selected - Close Gossip'),
(162871, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Store the challenger'),
(162871, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Turn hostile for the bout'),
(162871, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Attack the challenger'),
(162871, 0, 4, 5, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 33, 162924, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - At 20% Health - Quest Credit Theren-Dion Sentinel defeated to the challenger'),
(162871, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Rest: no more challenges for now'),
(162871, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Restore her faction'),
(162871, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Yield and walk back'),
(162871, 0, 8, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Evade - Restore her faction'),
(162871, 0, 9, 0, 21, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Reached Home - Rest 60 seconds'),
(162871, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - After her rest - Accept challenges again'),
(162872, 0, 0, 1, 62, 0, 100, 0, 932010, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Gossip Option 0 Selected - Close Gossip'),
(162872, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Store the challenger'),
(162872, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Turn hostile for the bout'),
(162872, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Attack the challenger'),
(162872, 0, 4, 5, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 33, 162924, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - At 20% Health - Quest Credit Theren-Dion Sentinel defeated to the challenger'),
(162872, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Rest: no more challenges for now'),
(162872, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Restore her faction'),
(162872, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Yield and walk back'),
(162872, 0, 8, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Evade - Restore her faction'),
(162872, 0, 9, 0, 21, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Reached Home - Rest 60 seconds'),
(162872, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - After her rest - Accept challenges again'),
(162873, 0, 0, 1, 62, 0, 100, 0, 932010, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Gossip Option 0 Selected - Close Gossip'),
(162873, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Store the challenger'),
(162873, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 14, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Turn hostile for the bout'),
(162873, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Attack the challenger'),
(162873, 0, 4, 5, 2, 0, 100, 1, 0, 20, 0, 0, 0, 0, 33, 162924, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - At 20% Health - Quest Credit Theren-Dion Sentinel defeated to the challenger'),
(162873, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Rest: no more challenges for now'),
(162873, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Restore her faction'),
(162873, 0, 7, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - Linked - Yield and walk back'),
(162873, 0, 8, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Evade - Restore her faction'),
(162873, 0, 9, 0, 21, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - On Reached Home - Rest 60 seconds'),
(162873, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Theren-Dion Sentinel - After her rest - Accept challenges again'),
(162925, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Vulture Egg - On Reset - Set Passive'),
(162925, 0, 1, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Vulture Egg - On Reset - Stop Auto Attack'),
(162925, 0, 2, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 162874, 4, 60000, 1, 0, 0, 202, 3, 1, 1, 0, 0, 0, 0, 0, 'Vulture Egg - On Death - Summon a Frenzied Vulture beside the egg to attack the killer'),
(162925, 0, 3, 0, 6, 0, 50, 0, 0, 0, 0, 0, 0, 0, 12, 162874, 4, 60000, 1, 0, 0, 202, 3, 1, 1, 0, 0, 0, 0, 0, 'Vulture Egg - On Death - 50% a second Frenzied Vulture to attack the killer');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300512, 2300513, 2300526) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300512, 1, 0, 0, 70, 0, 100, 1, 2, 0, 0, 0, 0, 0, 12, 161782, 4, 60000, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Fallen Aspirant - On Opened, once per spawn - Summon a Fallen Aspirant for the opener'),
(2300513, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 33, 161798, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Offering Bowl - On Use - Quest Credit Sanctified flesh offered'),
(2300513, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Offering Bowl - Linked - Store the offering player'),
(2300513, 1, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 0, 0, 19, 161784, 40, 0, 0, 0, 0, 0, 0, 'Offering Bowl - Linked - Send the offering player to Elydna Wingstroke'),
(2300513, 1, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 161784, 40, 0, 0, 0, 0, 0, 0, 'Offering Bowl - Linked - Wake Elydna Wingstroke for her communion');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 6138 AND `source_type` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(6138, 2, 0, 0, 46, 0, 100, 0, 6138, 0, 0, 0, 0, 0, 33, 161729, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Areatrigger 6138 - On Trigger - Quest Credit Carrion Path traversed');

-- 161784 line 0: INFERRED: as she leaves her post for the bowl
-- 161784 line 1: INFERRED: kneeling at the bowl; echoes Aegya (1660013 completion: "fight for her right ... or
--   else end as sacrificial carrion")
-- 161784 line 2: INFERRED: as she rises and attacks
-- 161784 line 3: INFERRED: with her Tornado cast
-- 161784 line 4: INFERRED: with her first MoonFire Zone; echoes 1660015 ("The face of Elune you know is only one
--   among many")
-- 161784 line 5: INFERRED: her death; her pendant goes back to her brother in 1660085
-- 161727 line 0: text SOURCED-ARCHIVE, speaker and timing INFERRED: the 1660015 completion text, Gilgaen's
--   turn-in line (he ends 1660015); Aegya ends 1660013 and 1660016
-- 161727 line 1: text SOURCED-ARCHIVE, timing INFERRED: the 1660016 completion text (Aegya ends 1660016)
-- 161783 line 0: DERIVED: from the 1660015 Details ("slay whatever shadow rises from its depths"); a boss
--   whisper to its summoner, the only player who sees it
DELETE FROM `creature_text` WHERE `CreatureID` IN (161727, 161783, 161784);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(161784, 0, 0, 'So you are the one who brought the offering. The Great Vulture watches us both, $n.', 12, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161784, 1, 0, 'Great Vulture! Take the flesh we offer, and take the weaker of us!', 14, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161784, 2, 0, 'Only one of us leaves this nest.', 12, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161784, 3, 0, 'Winds of the moon, tear them from my nest!', 14, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161784, 4, 0, 'Feel the light of Elune''s other face!', 12, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161784, 5, 0, 'The Great Vulture… has chosen. Thariel… forgive me…', 12, 0, 100, 0, 0, 0, 0, 0, 'Elydna Wingstroke - INFERRED'),
(161727, 0, 0, 'The time has come. Elydna Wingstroke’s communion begins.', 14, 0, 100, 0, 0, 0, 0, 0, 'Lady Aegya - text SOURCED-ARCHIVE, speaker and timing INFERRED'),
(161727, 1, 0, 'A sublime fight. The Great Vulture is pleased.', 14, 0, 100, 0, 0, 0, 0, 0, 'Lady Aegya - text SOURCED-ARCHIVE, timing INFERRED'),
(161783, 0, 0, '%s rises from the depths of the Moonwell!', 42, 0, 100, 0, 0, 0, 0, 0, 'Aberrant Flesh Remnant - DERIVED');

-- A Trail of Petals (1660017). Clicking a Baby Night Elf starts the 3 s "Rescuing a newborn" cast
-- (256715) on it (go_coa_baby_night_elf); when it completes, spell_coa_rescuing_a_newborn credits the
-- newborn, summons a Butterfly that only the rescuer sees and that follows the rescuer to Eldya, and
-- despawns the baby until its 60 s respawn. How CoA triggered the cast is INFERRED; the spell is CoA
-- data. Spell 256707 (Good Flesh Amalgam) raises each player's own Aberrant Flesh Remnant, seen only by
-- that player and whispering its rise line to that player.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (256707, 256715);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES
(256707, 'spell_coa_channeling_blessing_of_the_moon'),
(256715, 'spell_coa_rescuing_a_newborn');

-- Eldya's flower crown (256730, a hidden self aura, Spell.dbc): worn in Shadowglen while 1660017 is
-- incomplete or complete, taken at turn-in or abandon (the quest-end status mask removes it,
-- PlayerQuest.cpp SendQuestUpdate). "I have enchanted this flower crown; its fragrance will be...
-- irresistible" (1660017 Details).
DELETE FROM `spell_area` WHERE `spell` = 256730;
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_status`, `quest_end`, `quest_end_status`, `aura_spell`, `racemask`, `gender`, `autocast`)
VALUES
(256730, 10143, 1660017, 10, 1660017, 10, 0, 0, 2, 1);

-- ---------------------------------------------------------------------------
-- 10. Stock herb node on the CoA Carrion Path
-- ---------------------------------------------------------------------------
-- DERIVED: surface.check on CoA data. The UPDATE matches guid and entry and keeps the pool and the facing.
-- 49876 (152094): Hyacinth Mushroom of pool 377: its stock spot clips the Kalidartree03 CoA added on the path
-- (0.45 yd); moved 2.1 yd north-west onto the open slope beside the trunk, clear of it.
UPDATE `gameobject` SET `position_x` = 10611.2, `position_y` = 608.4, `position_z` = 1338.212 WHERE `guid` = 49876 AND `id` = 152094;
