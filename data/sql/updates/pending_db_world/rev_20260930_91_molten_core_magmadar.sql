-- Magmadar (11982) as Ascension ran him: the two head creatures that do all of his casting
-- (issue #5120: the body itself never casts in the 42-log corpus), their kit's ground-fire
-- "puddle" (Lava Bomb) and Fire hit (Lava Burst, coa_spell_damage_info-bound Damage Info
-- already exists), and a designed periodic Core Hound reinforcement.
--
-- Sources: db.exil.es export creature.csv.gz (80642 "Magmadar's Right Head", 80643 "Magmadar's
-- Left Head" -- exist as their own rows, no static creature_spawn row for either, no vehicle_id;
-- health_min/max = 1, faction_template_id = 0 on both -- placeholder/prop values, not usable for
-- a combat add, so health and faction are designed below instead of copied); live server-data
-- Spell.dbc (parsed directly this session): Enrage 2105307 (self, +9% melee/ranged haste and
-- +9% spell haste, no per-difficulty variant); Lava Burst dummy 2105355 -> school-damage effect
-- 2105357 (base points placeholder 1, real damage from coa_spell_damage_info 2105351-54, already
-- bound by rev_20260930_83); Scorching Breath 2105360 (periodic-trigger-with-value aura on the
-- current target, 500ms ticks) -> hidden hit dummy 2105361 -> real per-difficulty hit 2105362-65
-- (SpellDifficulty.dbc row 2099, confirmed); Lava Bomb dummy 2105366 (target: any unit) -> ground
-- persistent-area Fire aura 2105367-70 (SpellDifficulty.dbc row 2100, confirmed; effect
-- SPELL_EFFECT_PERSISTENT_AREA_AURA at TARGET_UNIT_DEST_AREA_ENEMY -- the ground-fire patch the
-- body's own vanilla Lava Bomb only approximates with a 30-60s GO trap).
--
-- No log or export data places the heads on a timer, sizes their share of the fight's health, or
-- describes Core Hound reinforcements at all -- every cadence and health split below is
-- [designed], not measured; flagged for a maintainer to confirm or replace with real data if it
-- ever surfaces. Core Hound entry 11671 is the same trash entry already used outside the boss
-- room (rev_20260930_81), reused here rather than inventing a new one.

-- Body: dedicated script (boss_magmadar_coa) instead of the generic coa_boss_ai, the same reason
-- Garr and Golemagg keep their own scripts -- Magmadar now manages the head and hound adds.
UPDATE `creature_template` SET `ScriptName` = 'boss_magmadar_coa'
 WHERE `entry` IN (11982, 111982, 211982, 311982);

-- Heads: summoned by boss_magmadar_coa on engage, not statically spawned (matches the export).
-- Full column list, difficulty variants matching every other MC add (Firesworn: 12099/112099/
-- 212099/312099). Faction 14 and rank 3 copied from Magmadar's own row (export's own faction 0
-- and rank 3 kept for rank only -- 0 is not a valid hostile faction). No melee (dmg 0 in the
-- export): BaseAttackTime left at the schema default, DamageModifier 0 so the default swing timer
-- with a 0/0 damage range does not tick anything visible.
INSERT INTO `creature_template`
  (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`,
     `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`,
     `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`,
     `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`,
     `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`,
     `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`,
     `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`,
     `flags_extra`, `ScriptName`)
VALUES
(80642, 180642, 280642, 380642, 0, 0, 'Magmadar''s Right Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1,
 20, 3, 0, 0, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(180642, 0, 0, 0, 0, 0, 'Magmadar''s Right Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(280642, 0, 0, 0, 0, 0, 'Magmadar''s Right Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(380642, 0, 0, 0, 0, 0, 'Magmadar''s Right Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(80643, 180643, 280643, 380643, 0, 0, 'Magmadar''s Left Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1,
 20, 3, 0, 0, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(180643, 0, 0, 0, 0, 0, 'Magmadar''s Left Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(280643, 0, 0, 0, 0, 0, 'Magmadar''s Left Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa'),
(380643, 0, 0, 0, 0, 0, 'Magmadar''s Left Head', NULL, NULL, 0, 63, 63, 0, 14, 0, 1, 1.14286, 1, 1, 20, 3, 0, 0,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_magmadar_head_coa')
ON DUPLICATE KEY UPDATE
  `difficulty_entry_1` = VALUES(`difficulty_entry_1`), `difficulty_entry_2` = VALUES(`difficulty_entry_2`),
  `difficulty_entry_3` = VALUES(`difficulty_entry_3`), `KillCredit1` = VALUES(`KillCredit1`),
  `KillCredit2` = VALUES(`KillCredit2`), `name` = VALUES(`name`), `subname` = VALUES(`subname`),
  `IconName` = VALUES(`IconName`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`),
  `maxlevel` = VALUES(`maxlevel`), `exp` = VALUES(`exp`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`),
  `speed_swim` = VALUES(`speed_swim`), `speed_flight` = VALUES(`speed_flight`),
  `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`), `dmgschool` = VALUES(`dmgschool`),
  `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
  `RangeAttackTime` = VALUES(`RangeAttackTime`), `BaseVariance` = VALUES(`BaseVariance`),
  `RangeVariance` = VALUES(`RangeVariance`), `unit_class` = VALUES(`unit_class`),
  `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`),
  `dynamicflags` = VALUES(`dynamicflags`), `family` = VALUES(`family`), `type` = VALUES(`type`),
  `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`), `pickpocketloot` = VALUES(`pickpocketloot`),
  `skinloot` = VALUES(`skinloot`), `PetSpellDataId` = VALUES(`PetSpellDataId`), `VehicleId` = VALUES(`VehicleId`),
  `mingold` = VALUES(`mingold`), `maxgold` = VALUES(`maxgold`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `HoverHeight` = VALUES(`HoverHeight`),
  `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`),
  `ArmorModifier` = VALUES(`ArmorModifier`), `ExperienceModifier` = VALUES(`ExperienceModifier`),
  `RacialLeader` = VALUES(`RacialLeader`), `movementId` = VALUES(`movementId`),
  `RegenHealth` = VALUES(`RegenHealth`), `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
  `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
-- Model: export display_ids {600003} for both heads.
DELETE FROM `creature_template_model`
 WHERE `CreatureID` IN (80642, 180642, 280642, 380642, 80643, 180643, 280643, 380643);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(80642, 0, 600003, 1, 1),
(180642, 0, 600003, 1, 1),
(280642, 0, 600003, 1, 1),
(380642, 0, 600003, 1, 1),
(80643, 0, 600003, 1, 1),
(180643, 0, 600003, 1, 1),
(280643, 0, 600003, 1, 1),
(380643, 0, 600003, 1, 1);

-- Health: [designed] split of Magmadar's already-committed flex total (rev_20260930_81; that
-- total itself stays the evidenced Golemagg-ratio figure) -- 70% body, 15% per head, so the
-- fight's total health does not change, only how it is distributed between the three targets.
DELETE FROM `coa_boss_flex` WHERE `entry` IN (11982, 80642, 80643);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(11982, 566752, 755669, 1137347, 1658331, 'Magmadar body: [designed] 70% of the existing flex total'),
(80642, 121447, 161929, 243717, 355357, 'Magmadar''s Right Head: [designed] 15% of the existing flex total'),
(80643, 121447, 161929, 243717, 355357, 'Magmadar''s Left Head: [designed] 15% of the existing flex total');

-- Spell scripts: dummy-then-effect chains, same idiom as the body's own stock Lava Bomb
-- (spell_magmadar_lava_bomb) and Garr's Land Slide.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105361, 2105366)
 AND `ScriptName` IN ('spell_magmadar_head_scorching_breath_tick', 'spell_magmadar_head_lava_bomb');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105361, 'spell_magmadar_head_scorching_breath_tick'),
(2105366, 'spell_magmadar_head_lava_bomb');
