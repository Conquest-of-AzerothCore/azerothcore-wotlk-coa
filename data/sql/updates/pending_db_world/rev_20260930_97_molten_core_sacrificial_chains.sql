-- Sacrificial Chains (92030), Majordomo Executus's periodic hostage add. mc-dataset.json
-- (54-log corpus, Aug-Sep 2026) shows it in 48 of the corpus's 49 Majordomo Executus fights
-- (Heroic 6, Mythic 8, Ascended 34 pulls), with a consistent Sacrifice aura and real per-pull
-- health -- it fights on live CoA even though this fork never had a creature_template row for
-- it: rev_20260930_94's own note called it a "level-1/health-1 placeholder stub" and left it
-- unwired, matching this session's read of the same db.exil.es export row (min/max_level 1,
-- faction_id empty, health_min/max 1 -- not usable). display_id 20367, name and spell list
-- (2100213 Berserk, 2108020/2108023 Sacrifice) are real DBC data on that same row, not
-- placeholders (refs.md A.3), and are used as-is.
--
-- Summoner: re-querying the dataset by pull id (this session) finds no other boss's kit ever
-- co-occurring with 92030 in the same fight -- only Majordomo Executus (48/49; the one
-- exception is a fight the dataset itself labelled "Flamewaker Elite" instead, same encounter
-- room). The C++ hook lives in boss_majordomo_executus.cpp (this revision).
--
-- No Normal pull of 92030 exists in the corpus, but neither does any Normal Majordomo pull at
-- all (0/0 -- Majordomo's own sample is Heroic/Mythic/Ascended-only here) -- this is not the
-- "seen only on Mythic/Ascended, with Normal/Heroic pulls available" shape the restoration
-- treats as a genuine difficulty-gated mechanic, so it is wired for every difficulty rather than
-- skipped on Normal, same as the rest of the room.
--
-- Health: real per-pull readings, not the generic trash ladder (mc-summary.md kill health /
-- player count, all values are exact and repeat identically across every kill at a given
-- player count, confirming per-player linear scaling): Heroic 149,507/13p = 11,501/player;
-- Mythic 332,402/17p = 19,553/player; Ascended 378,200/12p = 31,517/player and 491,659/15p =
-- 32,777/player, averaged to 32,147/player. Normal [designed] = Heroic x 0.750, the same "set"
-- ratio already used for every other coa_boss_flex row with no measured Normal figure
-- (rev_20260930_94).
--
-- level/faction 63/54 [designed], copied from Majordomo himself (his own summoner, same as
-- Shadow of Lucifron copying Lucifron, rev_20260930_92); type 10 and type_flags 0 preserved
-- from the export (real DBC data per refs.md, unlike level/health/faction on the same row).
-- rank 1 (Elite), matching other named MC adds with real health/mechanics (Flamewaker Elite).
-- No difficulty_entry_1..3 variants: unlike Shadow of Lucifron's own template, Sacrificial
-- Chains behaves identically on every difficulty and only needs the health scaling
-- coa_boss_flex already gives any single entry via FlexHealth.cpp's GetSpawnMode() lookup.
--
-- ScriptName npc_sacrificial_chains_coa: self-casts Sacrifice (2108020) on spawn, then a
-- [designed] 20s heal-to-full-and-re-sacrifice loop (2108023) if still alive -- the corpus's own
-- measured kill times (10-24s, median ~15s, every difficulty) show raids routinely beating this
-- loop once and rarely needing a second try, matching Berserk (2100213) appearing only once in
-- the whole 35-pull Ascended sample; loop count 2 opens Berserk. See the C++ file for the full
-- evidence trail.

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
(92030, 0, 0, 0, 92030, 92030, 'Sacrificial Chains', NULL, NULL, 0, 63, 63, 0, 54, 0, 1, 1.14286, 1, 1, 20, 1, 0, 1,
 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_sacrificial_chains_coa')
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

DELETE FROM `creature_template_model` WHERE `CreatureID` = 92030;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(92030, 0, 20367, 1, 1);

DELETE FROM `coa_boss_flex` WHERE `entry` = 92030;
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(92030, 8625, 11501, 19553, 32147, 'Sacrificial Chains: Normal = Heroic x 0.750 (set), Heroic/Mythic/Ascended measured (mc-dataset.json kill health / player count)');
