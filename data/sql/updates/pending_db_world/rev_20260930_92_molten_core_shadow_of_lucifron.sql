-- Shadow of Lucifron (12268 + variants): the player remembers it appearing "a few seconds
-- after the start of the fight" and it is missing entirely from our DB. db.exil.es export
-- creature.csv.gz has 12268/112268/212268/312268 (rank 3, kit {579322, 975011, 2105254,
-- 2105255, 2105256, 2105257}) with no static creature_spawn row anywhere on map 409 -- it must
-- be summoned by Lucifron's own script, and no SUMMON effect exists anywhere in Lucifron's kit
-- (checked the whole 2105200-2105257 Spell.dbc block, live read this session), so the schedule
-- engine gets one small, generic, data-driven hook instead of a bespoke boss script for
-- Lucifron's own body (CoaBossAI.cpp, this revision): a new `coa_boss_summon` table (its
-- own table, not an ALTER TABLE on the module's base `coa_boss`) names a one-shot summon
-- (entry, delay, buff spell cast at the new add). Lucifron's own measured schedule
-- (Impending Doom/Curse of Lucifron/Suppressing Shadows/Shadow Bolt) is untouched.
--
-- 2105223 "Shadow of Lucifron" (the buff, not the creature): APPLY_AURA x2,
-- MOD_DAMAGE_PERCENT_DONE +39% Shadow, effect 0 on TARGET_UNIT_TARGET_ANY (the caster's spell
-- target), effect 1 on TARGET_UNIT_CASTER -- cast by Lucifron at the Shadow, this lands on both
-- of them in one cast, matching "increases his and his master's Shadow damage done".
--
-- Kit: 2105254 Shadow Bolt dummy -> 2105255 Shadow Bolt hit (base points 1 placeholder,
-- already bound to real damage via coa_spell_damage_info 2105250-53 "Flamewaker - Shadow Bolt
-- Damage Info", rev_20260930_83); 2105256 Shadow Cleave (WEAPON_PERCENT_DAMAGE 44%, cone) and
-- 2105257 Dark Sundering (WEAPON_PERCENT_DAMAGE 44% + MOD_RESISTANCE_PCT -11% Physical) are
-- direct real effects, no wrapper needed. 579322 "Fetid Mark" and 975011 "Fierce Blow" stay
-- unused -- same unmatched-kit-entry case as Ragnaros/Magmadar's body (no log or DBC evidence
-- either is cast here).
--
-- Health/level/faction: export health_min/max (1), faction_template_id (0) and min/max_level
-- (1) are the same placeholder shape already documented for Magmadar's heads
-- (rev_20260930_91) -- not usable. Designed instead: level 63 and faction 54 copied from
-- Lucifron; health [designed] 25% of Lucifron's own per-player coa_boss_flex figures (nearest
-- real ratio on record for a Lucifron-room reinforcement add: Flamewaker Protector's
-- HealthModifier against Lucifron's, 57.7568/219.026 = 26.4%, rounded to a clean 25%).
-- model_id 13031 in the export *is* measured, not a placeholder: it is Lucifron's own display
-- id (mc-ascdb-report.md), so the Shadow is literally a shadow copy of him.

-- `coa_boss` is base SQL (owned by the module's own schema, ALTER TABLE there is not
-- idempotent and not authorized); the one-shot summon hook gets its own dedicated table
-- instead, same engine/charset style as the module's other tables
-- (modules/mod-coa-raid-difficulty/data/sql/db-world/base/03_boss_schedule.sql).
-- summon_entry: the difficulty variant resolves via difficulty_entry_1..3, as usual.
-- summon_buff_spell: cast by this boss at the summoned add right after the summon, 0 none.
--
-- This table is owned only by this unpublished branch (created here, widened in place by
-- rev_20260930_96 for Sulfuron's disciples, narrowed back in place by this correction once the
-- disciples turned out to apply on every difficulty): rev_96's own ALTER TABLE on a CREATE TABLE
-- IF NOT EXISTS was not idempotent (a changed-hash re-run of either file re-applies both, and
-- ALTER ADD COLUMN/DROP PRIMARY KEY fails the second time). This revision instead owns the
-- table's final shape directly -- `idx` supports several summon rows per boss (PK `entry`,
-- `idx`), `replace_entry`/`replace_radius` let a summon take the place of a nearby live creature
-- instead of adding on top. There is no `min_difficulty` column: rev_96 added one for
-- Sulfuron's disciples on the (corrected) assumption that they were Mythic/Ascended only: once
-- that assumption was wrong (this correction), every row left in the table wanted every
-- difficulty, so the column and its CoaBossAI.cpp gate were dead code and were dropped with it
-- rather than kept for a hypothetical future row. Lucifron's own row below is unaffected: it
-- keeps idx 0, replace_entry 0 (no replacement).
DROP TABLE IF EXISTS `coa_boss_summon`;
CREATE TABLE `coa_boss_summon` (
  `entry`             INT UNSIGNED NOT NULL COMMENT 'boss entry, coa_boss.entry',
  `idx`               INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'position within this boss, multiple summons',
  `summon_entry`      INT UNSIGNED NOT NULL DEFAULT 0,
  `summon_delay_ms`   INT UNSIGNED NOT NULL DEFAULT 0,
  `summon_buff_spell` INT UNSIGNED NOT NULL DEFAULT 0,
  `replace_entry`     INT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'despawn the nearest live creature of this entry near the boss and summon at its spot, 0 none',
  `replace_radius`    FLOAT NOT NULL DEFAULT 0 COMMENT 'search radius in yards for replace_entry',
  `comment`           VARCHAR(128) NOT NULL DEFAULT '',
  PRIMARY KEY (`entry`, `idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_boss_summon` WHERE `entry` = 12118;
INSERT INTO `coa_boss_summon` (`entry`, `idx`, `summon_entry`, `summon_delay_ms`, `summon_buff_spell`, `comment`) VALUES
(12118, 0, 12268, 5000, 2105223, 'Lucifron summons Shadow of Lucifron');

-- Full column list, difficulty variants matching every other MC add (Firesworn:
-- 12099/112099/212099/312099; Magmadar's heads: rev_20260930_91).
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
(12268, 112268, 212268, 312268, 12268, 12268, 'Shadow of Lucifron', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.14286, 1,
 1, 20, 3, 0, 13, 2000, 2000, 1, 1, 2, 0, 0, 0, 0, 10, 72, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_shadow_of_lucifron_coa'),
(112268, 0, 0, 0, 12268, 12268, 'Shadow of Lucifron', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.14286, 1, 1, 20, 3, 0,
 13, 2000, 2000, 1, 1, 2, 0, 0, 0, 0, 10, 72, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_shadow_of_lucifron_coa'),
(212268, 0, 0, 0, 12268, 12268, 'Shadow of Lucifron', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.14286, 1, 1, 20, 3, 0,
 13, 2000, 2000, 1, 1, 2, 0, 0, 0, 0, 10, 72, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_shadow_of_lucifron_coa'),
(312268, 0, 0, 0, 12268, 12268, 'Shadow of Lucifron', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.14286, 1, 1, 20, 3, 0,
 13, 2000, 2000, 1, 1, 2, 0, 0, 0, 0, 10, 72, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_shadow_of_lucifron_coa')
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

-- Model: export display_ids {13031} -- Lucifron's own display id (measured, not placeholder).
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (12268, 112268, 212268, 312268);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(12268, 0, 13031, 1, 1),
(112268, 0, 13031, 1, 1),
(212268, 0, 13031, 1, 1),
(312268, 0, 13031, 1, 1);

-- Health: [designed] 25% of Lucifron's own per-player coa_boss_flex figures (rev_20260930_81);
-- this is an addition to the fight, not a split of Lucifron's own total, so his row is untouched.
DELETE FROM `coa_boss_flex` WHERE `entry` = 12268;
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(12268, 107953, 143937, 216638, 315873, '[designed] 25% of Lucifron''s own flex figures');

-- Spell script: dummy-then-effect chain for Shadow Bolt, same idiom as the other MC adds'
-- damage-info chains (spell_magmadar_head_scorching_breath_tick, rev_20260930_91).
DELETE FROM `spell_script_names` WHERE `spell_id` = 2105254 AND `ScriptName` = 'spell_shadow_of_lucifron_shadow_bolt';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105254, 'spell_shadow_of_lucifron_shadow_bolt');
