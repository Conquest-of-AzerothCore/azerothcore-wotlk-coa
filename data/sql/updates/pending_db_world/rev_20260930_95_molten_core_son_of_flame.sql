-- Ragnaros's Son of Flame merge chain: Lesser Son of Flame (12143, already live on this fork)
-- merges in pairs into Son of Flame (92026), which merges into Greater Son of Flame (92027),
-- which merges into Unstable Son of Flame (92028). Confirmed by
-- `.agents/plans/mc-restoration/logs/mc-dataset.json` (54 CoA/Ascension logs): all four tiers
-- appear together on both Normal and Ascended pulls (Lesser 40 Normal + 72 Ascended, Son 16 + 28,
-- Greater 5 + 9, Unstable 1 pull only) -- a difficulty-independent merge chain, not a
-- Mythic/Ascended-only mechanic. db.exil.es export (refs/mc-refs.md A.2) gives all three new
-- entries the same display id (5488, Lesser's own model) and an escalating Fire-damage kit:
-- Fire Strike/Fierce Fire Strike (2108704/2108705) at every tier, Magma Strike (2108657-2108660)
-- from Son on, Cone of Fire (2108735, 2108737-2108740) from Greater on, and Unstable's own
-- closing "Unstable Flames" (2108749) -- NOT wired here (see below). The proximity-merge AI
-- itself lives in `modules/mod-coa-raid-difficulty/src/npc_son_of_flame_coa.cpp`
-- (`npc_son_of_flame_coa`), also given to Lesser Son of Flame here so the very first merge in
-- the chain is driven by the same script.
--
-- Level/faction/speed/type/movementId/CreatureImmunitiesId are copied unchanged from Lesser Son
-- of Flame's own base row (data/sql/base/db_world/creature_template.sql) -- [designed]: the
-- export's own rows for 92026-92028 are level-1/health-1 placeholder stubs (same situation
-- flagged for Sacrificial Chains/Sulfuron's disciples in hp/hp-pools.md), so there is no
-- measured level to use instead; treating the merge chain as the same creature at every tier
-- (only the model/kit/health escalate) is the simplest reading consistent with them sharing one
-- display id. flags_extra gets the same 0x40000000 knockback/pull immunity the rest of this
-- instance's trash already carries (rev_20260930_93).
--
-- HealthModifier is left at the schema default (1): FlexHealth.cpp overrides it at spawn/pull
-- for any creature whose base entry has a `coa_boss_flex` row (rev_20260930_94's own note),
-- which is the actual health source below.
--
-- Health (`coa_boss_flex`, per-player hp_d0..d3, Normal:Heroic:Mythic:Ascended = 1:1.44:1.88:2.32,
-- the same client-cache trash ratio used for the rest of this instance's non-video-anchored
-- creatures, rev_20260930_81/_94):
--   * Son of Flame (92026): real CoA-video reading, hp/hp-pools.md ("2.5M/17 players" ==
--     147,059/player, Ascended/d3). d0-d2 derived from that d3 via the ratio above.
--   * Greater Son of Flame (92027): real CoA-video reading, hp-pools.md ("3.9M/17 players" ==
--     229,412/player, Ascended/d3). d0-d2 derived the same way.
--   * Unstable Son of Flame (92028): NO video reading and NO BB reading exist (a single,
--     unkilled pull in the whole corpus). Per this task's explicit fallback, the log corpus's own
--     best figure -- mc-dataset.json's damage-taken LOWER BOUND at 15 players, 2,200,559 (not a
--     kill, so the add's true max health is >= this number, not equal to it) -- is scaled x1.365
--     (the CoA-video/pre-video-log ratio documented in hp-pools.md's Method 3) to 3,003,763 and
--     used as the d3 anchor, with d0-d2 derived via the same 1:1.44:1.88:2.32 ratio. This is the
--     lowest-confidence figure in this migration: one pull, unresolved difficulty tag, and a
--     lower bound standing in for a pool value. Flagged, not resolved; revisit if a kill or a
--     video reading of Unstable Son of Flame ever turns up.
--
-- NOT done here (explicitly out of scope for this pass, per the task's instruction not to invent
-- unmeasured mechanics):
--   * Unstable Son of Flame's closing "Unstable Flames" (2108749): refs.md lists it in the
--     export's kit, but the corpus's single Unstable pull never shows it casting anything beyond
--     the shared Fire Strike/Magma Strike/Cone of Fire kit. No trigger condition (health%, timer,
--     on-merge) is in evidence. Left unwired; do not add a finisher timer without more data.
--   * The merge trigger's proximity range/duration (see npc_son_of_flame_coa.cpp) are [designed]:
--     the dataset has no coordinates, only near-instant (0-0.3s) timing between a pair's
--     near-simultaneous "death" and the next tier's first appearance in the log.

-- Give Lesser Son of Flame (and its difficulty variants) the merge-chain/kit script; it had no
-- AIName/ScriptName at all before this (base row, `data/sql/base/db_world/creature_template.sql`).
UPDATE `creature_template` SET `ScriptName` = 'npc_son_of_flame_coa'
  WHERE `entry` IN (12143, 112143, 212143, 312143);

-- Full column list, same shape as the other from-scratch CoA adds in this instance
-- (rev_20260930_92's Shadow of Lucifron); difficulty variants follow the same +100000/+200000/
-- +300000 numbering already used for every other Molten Core CoA entry.
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
(92026, 192026, 292026, 392026, 92026, 92026, 'Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20,
 1, 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(192026, 0, 0, 0, 92026, 92026, 'Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2, 12,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21, 1073741824,
 'npc_son_of_flame_coa'),
(292026, 0, 0, 0, 92026, 92026, 'Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2, 12,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21, 1073741824,
 'npc_son_of_flame_coa'),
(392026, 0, 0, 0, 92026, 92026, 'Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2, 12,
 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21, 1073741824,
 'npc_son_of_flame_coa'),
(92027, 192027, 292027, 392027, 92027, 92027, 'Greater Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429,
 1, 1, 20, 1, 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1,
 -21, 1073741824, 'npc_son_of_flame_coa'),
(192027, 0, 0, 0, 92027, 92027, 'Greater Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2,
 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(292027, 0, 0, 0, 92027, 92027, 'Greater Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2,
 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(392027, 0, 0, 0, 92027, 92027, 'Greater Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1, 2,
 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(92028, 192028, 292028, 392028, 92028, 92028, 'Unstable Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429,
 1, 1, 20, 1, 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1,
 -21, 1073741824, 'npc_son_of_flame_coa'),
(192028, 0, 0, 0, 92028, 92028, 'Unstable Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1,
 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(292028, 0, 0, 0, 92028, 92028, 'Unstable Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1,
 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa'),
(392028, 0, 0, 0, 92028, 92028, 'Unstable Son of Flame', NULL, NULL, 0, 60, 60, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1,
 2, 12, 2000, 2000, 1, 1, 1, 0, 2048, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 164, 1, -21,
 1073741824, 'npc_son_of_flame_coa')
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

-- Model: export display id 5488 for all three tiers -- Lesser Son of Flame's own display
-- (`data/sql/base/db_world/creature_template_model.sql`), matching refs.md's A.2 export row.
DELETE FROM `creature_template_model` WHERE `CreatureID` IN
  (92026, 192026, 292026, 392026, 92027, 192027, 292027, 392027, 92028, 192028, 292028, 392028);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(92026, 0, 5488, 1, 1), (192026, 0, 5488, 1, 1), (292026, 0, 5488, 1, 1), (392026, 0, 5488, 1, 1),
(92027, 0, 5488, 1, 1), (192027, 0, 5488, 1, 1), (292027, 0, 5488, 1, 1), (392027, 0, 5488, 1, 1),
(92028, 0, 5488, 1, 1), (192028, 0, 5488, 1, 1), (292028, 0, 5488, 1, 1), (392028, 0, 5488, 1, 1);

-- Health: CoA-video Ascended (d3) for Son/Greater, log-derived x1.365 [low confidence, see
-- header] for Unstable; d0-d2 derived from d3 via the 1:1.44:1.88:2.32 trash ratio.
DELETE FROM `coa_boss_flex` WHERE `entry` IN (92026, 92027, 92028);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(92026, 63388, 91278, 119168, 147059, 'Son of Flame: CoA video Ascended (2.5M/17p); trash ratio for d0-d2'),
(92027, 98884, 142394, 185903, 229412, 'Greater Son of Flame: CoA video Ascended (3.9M/17p); trash ratio for d0-d2'),
(92028, 1294725, 1864405, 2434084, 3003763, '[low confidence] no reading; log bound 2200559@15p x1.365');
