-- Atal'zul, the Soulreaver (map 890) and Trut-K'hahn.
--
-- Atal'zul: Ascension's entries from the log of 25.08.2026 (two kills).
-- Spell damage was the same on both kills; his health was not (25.44 and
-- 15.34 million, 20 and 18 players), and his adds had more health on the
-- second. Both levels keep the first kill's pool; the adds take each kill's.
-- Zul'rogg never dies while Atal'zul lives, so his pool only bounds his heals.
--
-- Trut-K'hahn: no log, no map, no entry known. Entries are new; his health is
-- The Will of Soggoth's measured levels, the nearest boss of his kind.

DELETE FROM `coa_world_boss_level` WHERE `entry` IN (67532, 67533, 67534, 67535, 67536, 9780029, 9780030);
INSERT INTO `coa_world_boss_level` (`entry`, `difficulty`, `health`, `damage_pct`, `note`) VALUES
(67532, 0, 25444626, 100, 'Atal''zul, kill 01:28, 20 players'),
(67532, 2, 25444626, 100, 'Atal''zul, the 01:34 kill took 15.34 million: kept at the first'),
(67533, 0, 25444626, 100, 'Zul''rogg, never killed: Atal''zul''s pool'),
(67533, 2, 25444626, 100, 'Zul''rogg, never killed: Atal''zul''s pool'),
(67534, 0, 323797, 100, 'Damned Wight, 22 of them, kill 01:28'),
(67534, 2, 489408, 100, 'Damned Wight, one of them, kill 01:34'),
(67535, 0, 3597, 100, 'Restless Spirit, 63 of them'),
(67535, 2, 3597, 100, 'Restless Spirit, 63 of them'),
(67536, 0, 910369, 100, 'Soul Vessel, median of four, kill 01:28'),
(67536, 2, 1644498, 100, 'Soul Vessel, median of three, kill 01:34'),
(9780029, 0, 14611055, 100, 'Trut-K''hahn: no log; The Will of Soggoth''s level'),
(9780029, 2, 21351728, 100, 'Trut-K''hahn: no log; The Will of Soggoth''s level'),
(9780030, 0, 402192, 100, 'Flock: no log; a Psychophage''s level'),
(9780030, 2, 587412, 100, 'Flock: no log; a Psychophage''s level');

DELETE FROM `creature_template` WHERE `entry` IN (67532, 67533, 67534, 67535, 67536, 9780029, 9780030, 9780031);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`,
  `speed_walk`, `speed_run`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
  `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`,
  `lootid`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`,
  `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
SELECT n.entry, n.name, '', n.lvl, n.lvl, 0, 14, 0, t.speed_walk, t.speed_run, t.detection_range, n.rnk, 0, n.dmg, t.BaseAttackTime,
  t.RangeAttackTime, t.BaseVariance, t.RangeVariance, n.cls, n.uflags, 0, 0, 0, n.type, t.type_flags, 0, '', 0, 1, 1, 1,
  t.ArmorModifier, 1, 0, 0, n.regen, n.immune, n.extra, n.script, 12340
FROM `creature_template` t
JOIN (SELECT 67532 AS entry, 'Atal''zul, the Soulreaver' AS name, 63 AS lvl, 3 AS rnk, 20.45 AS dmg, 8 AS cls, 0 AS uflags, 6 AS type, 1 AS regen, -294 AS immune, 1 AS extra, 'boss_atalzul_coa' AS script
      UNION ALL SELECT 67533, 'Zul''rogg', 63, 3, 20.45, 1, 0, 7, 1, -294, 0, 'boss_zulrogg_coa'
      UNION ALL SELECT 67534, 'Damned Wight', 62, 1, 4, 1, 0, 6, 1, 0, 0, 'npc_custom_add_coa'
      UNION ALL SELECT 67535, 'Restless Spirit', 62, 1, 1, 1, 0, 6, 0, 0, 0, 'npc_restless_spirit_coa'
      UNION ALL SELECT 67536, 'Soul Vessel', 63, 1, 0, 1, 0, 10, 0, 0, 0, 'npc_soul_vessel_coa'
      UNION ALL SELECT 9780029, 'Trut-K''hahn', 63, 3, 20.45, 1, 0, 1, 1, -294, 1, 'boss_trut_khahn_coa'
      UNION ALL SELECT 9780030, 'Trut-K''hahn''s Flock', 62, 1, 4, 1, 0, 1, 1, 0, 0, 'npc_custom_add_coa'
      UNION ALL SELECT 9780031, 'Feather Storm', 63, 0, 1, 1, 33554432 | 2, 10, 0, 0, 0, 'npc_feather_storm_coa') n
WHERE t.entry = 6109;

-- No model for any of them in the data here. Stand-ins: Jammal'an the Prophet
-- (Atal'ai priest), Atal'alarion (Sunken Temple), a skeletal warrior, a restless
-- soul, the Phylactery, the Wild Turkey (huge for Trut) and a cyclone.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (67532, 67533, 67534, 67535, 67536, 9780029, 9780030, 9780031);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(67532, 0, 6708, 2.5, 1, 12340),
(67533, 0, 7873, 1.5, 1, 12340),
(67534, 0, 200, 1.3, 1, 12340),
(67535, 0, 1825, 1, 1, 12340),
(67536, 0, 24889, 2, 1, 12340),
(9780029, 0, 21774, 6, 1, 12340),
(9780030, 0, 21774, 1.5, 1, 12340),
(9780031, 0, 5494, 1, 1, 12340);

DELETE FROM `instance_template` WHERE `map` = 890;
INSERT INTO `instance_template` (`map`, `parent`, `script`, `allowMount`) VALUES (890, 0, '', 0);

-- Map 890 is terrain, so heights come from it: Atal'zul 40 yards west of the
-- graveyard (WorldSafeLocs 6090) on flat ground, Zul'rogg beside him, the four
-- vessels on a 22-yard half ring south of him.
DELETE FROM `creature` WHERE `id` IN (67532, 67533, 67536);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`) VALUES
(9780104, 67532, 890, 0, 0, 15, 1, 0, 3313.0, -4844.6, 167.7, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780105, 67533, 890, 0, 0, 15, 1, 0, 3305.0, -4848.6, 168.2, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780106, 67536, 890, 0, 0, 15, 1, 0, 3335.0, -4844.6, 166.7, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780107, 67536, 890, 0, 0, 15, 1, 0, 3291.0, -4844.6, 169.5, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780108, 67536, 890, 0, 0, 15, 1, 0, 3297.4, -4860.2, 169.7, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0),
(9780109, 67536, 890, 0, 0, 15, 1, 0, 3328.6, -4860.2, 166.3, 0, 604800, 0, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `game_tele` WHERE `name` = 'AtalzulBossMap';
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT MAX(`id`) + 1, 3353.0, -4844.6, 167.4, 0, 890, 'AtalzulBossMap' FROM `game_tele`;
