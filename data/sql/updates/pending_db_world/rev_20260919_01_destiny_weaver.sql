-- Destiny Weaver: the leveling-experience NPC pair.
--
-- The live realm fronted two per-character choices - Open World Scaling and Experience Bonus
-- Control - with ten "Destiny Weaver" creatures, five models, two names each. The menu and the
-- two settings themselves are served by modules/mod-destiny-weaver; this revision places the
-- creatures and their text.
--
-- Every value here is recovered, not invented:
--   creatures 449340 / 449341 / 449342 / 449345 / 449347 and 449350 / 449351 / 449352 /
--             449355 / 449357 : cachedata/union/creaturecache.tsv.gz (Client captures), which
--             carries the name, the "Destiny Weaver" subname, the Speak icon, type_flags
--             134217728, HealthModifier 1.64062, ManaModifier 1.0, movementId 999 and the five
--             model ids the ten used (449292, 449293, 449296, 449297, 449299).
--   npc_text 30520 (the greeting) and 19175 (the hint) : the same captures, verbatim.
--   Tav'vin's position : the community atlas observation for 449340 (Durotar, map 1,
--             -635.231 / -4230.280 / 38.135); Galrin Olemar's, the same for 449357
--             (Stormwind, map 0, -8818.580 / 671.774 / 95.425). The other eight spawns were
--             never observed, so each stands beside a town's innkeeper, which is where a
--             new character is sent first.
--
-- One thing had to be added rather than recovered. The five display ids the captures name
-- (449292 troll, 449293 dwarf, 449296 night elf, 449297 blood elf, 449299 human) have no rows in
-- this client's CreatureDisplayInfo.dbc, so the ids are added to the table - the server's copy
-- under COA/Data/dbc and the copy shipped to clients in patch-B - each carrying this client's own
-- character-model art for that race. With the rows in place the original ids are used as they
-- were, and the ten Weavers look as they did.
--
-- The rest is taken from a sibling, because the captures do not carry it:
--   * faction, level, unit flags and flags_extra were not in the captures. The rows are shaped
--     like 900007 (Tiraxis), the other CoA service NPC on this realm: faction 35, unit_flags 768
--     so they cannot be attacked, minlevel/maxlevel 40, unit_flags2 2048, RegenHealth 1.
--
-- The creatures are gossip-only: npcflag 1 and ScriptName 'npc_destiny_weaver', whose menu is
-- built at talk time, so no gossip_menu rows are needed.

-- ---------------------------------------------------------------------------
-- 1. The recovered text
-- ---------------------------------------------------------------------------
REPLACE INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
(30520, 'Greetings, Hero.    I offer two services to customize your adventure:    **Experience Bonus Control**: I can disable all bonus experience sources - Potions of Experience, Auras of Experience, and Refer a Friend bonuses - allowing you to progress at the base rate.    **Open World Scaling**: I can enable creatures in the open world to automatically match your level for consistent challenge.', 'Greetings, Hero.    I offer two services to customize your adventure:    **Experience Bonus Control**: I can disable all bonus experience sources - Potions of Experience, Auras of Experience, and Refer a Friend bonuses - allowing you to progress at the base rate.    **Open World Scaling**: I can enable creatures in the open world to automatically match your level for consistent challenge.', 1),
(19175, 'To enable or disable your experience bonuses and creature scaling in the open world, seek out the Destiny Weaver.     The location has been marked on your map with a red flag.', 'To enable or disable your experience bonuses and creature scaling in the open world, seek out the Destiny Weaver.     The location has been marked on your map with a red flag.', 1);

-- ---------------------------------------------------------------------------
-- 2. The ten creatures
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(449340, 'Tav''vin',              'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449341, 'Magistrix Benjamin',   'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449342, 'Thrain Galewin',       'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449345, 'Elundra Moonsong',     'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449347, 'Galric Olim',          'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449350, 'Tav''ral',             'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449351, 'Magistrix Belanor',    'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449352, 'Thrainnor Galestrom',  'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449355, 'Elundrel Moonsinger',  'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449357, 'Galrin Olemar',        'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340);

-- ---------------------------------------------------------------------------
-- 3. Their models: the original display ids, one per pair
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(449340, 0, 449292, 1, 1, NULL), -- Tav'vin, troll
(449350, 0, 449292, 1, 1, NULL), -- Tav'ral, troll
(449341, 0, 449297, 1, 1, NULL), -- Magistrix Benjamin, blood elf
(449351, 0, 449297, 1, 1, NULL), -- Magistrix Belanor, blood elf
(449342, 0, 449293, 1, 1, NULL), -- Thrain Galewin, dwarf
(449352, 0, 449293, 1, 1, NULL), -- Thrainnor Galestrom, dwarf
(449345, 0, 449296, 1, 1, NULL), -- Elundra Moonsong, night elf
(449355, 0, 449296, 1, 1, NULL), -- Elundrel Moonsinger, night elf
(449347, 0, 449299, 1, 1, NULL), -- Galric Olim, human
(449357, 0, 449299, 1, 1, NULL); -- Galrin Olemar, human

-- ---------------------------------------------------------------------------
-- 4. Model info. The core reads bounding radius and combat reach from
--    `creature_model_info`, not from the DBC, and its table was filled from a set that predates
--    the added displays: without a row the creature is refused at spawn
--    ("No model data exist for CreatureDisplayID").
--    Each row carries the values of the display whose art it holds - 466910 (troll male) and
--    466903 (night elf female) 0.306 / 1.5, 466900 (dwarf male) 0.347 / 1.5, 16046 (blood elf
--    female) 0.383 / 1.5, 5076 (human male) 0.306 / 1.5. Gender is the art's own: 0 male, 1 female.
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(449292, 0.306, 1.5, 0, 0),
(449293, 0.347, 1.5, 0, 0),
(449296, 0.306, 1.5, 1, 0),
(449297, 0.383, 1.5, 1, 0),
(449299, 0.306, 1.5, 0, 0);

-- ---------------------------------------------------------------------------
-- 5. Spawns. Two per race, beside the innkeepers a new character meets first,
--    except where the atlas recorded the live one.
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` BETWEEN 9000011 AND 9000020;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9000011, 449340, 1, 0, 0, 1, 1, 0, -635.231, -4230.280, 38.135, 0.000, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Tav''vin (observed position, Durotar)'),
(9000012, 449350, 1, 0, 0, 1, 1, 0, -821.640, -4916.760, 19.740, 0.260, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Tav''ral (Sen''jin Village)'),
(9000013, 449341, 530, 0, 0, 1, 1, 0, 3027.560, 5439.180, 146.720, 2.210, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Magistrix Benjamin (Silvermoon City)'),
(9000014, 449351, 530, 0, 0, 1, 1, 0, 9688.100, -7359.600, 12.010, 4.490, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Magistrix Belanor (Falconwing Square)'),
(9000015, 449342, 0, 0, 0, 1, 1, 0, -4836.670, -853.090, 502.000, 4.870, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Thrain Galewin (Ironforge)'),
(9000016, 449352, 0, 0, 0, 1, 1, 0, -5597.600, -527.200, 399.740, 2.130, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Thrainnor Galestrom (Kharanos)'),
(9000017, 449345, 1, 0, 0, 1, 1, 0, 10131.900, 2228.790, 1328.810, 2.220, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Elundra Moonsong (Darnassus)'),
(9000018, 449355, 1, 0, 0, 1, 1, 0, 9806.210, 986.610, 1313.980, 4.800, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Elundrel Moonsinger (Dolanaar)'),
(9000019, 449347, 0, 0, 0, 1, 1, 0, -9458.660, 20.190, 57.050, 3.040, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Galric Olim (Goldshire)'),
(9000020, 449357, 0, 0, 0, 1, 1, 0, -8818.580, 671.774, 95.425, 5.200, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Galrin Olemar (observed position, Stormwind)');
