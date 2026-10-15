-- Sulfuron Harbinger's three named disciples (92031-92033), every difficulty.
--
-- The 55-pull Mythic/Ascended log corpus for Sulfuron always shows the same four adds next to
-- him: one Corvus the Nimble (11662, the stock Flamewaker Priest, renamed on CoA by
-- rev_20260930_84) plus Cull the Destroyer (92031), Proxima the Opressor (92032) and Ebon the
-- Cruel (92033), one of each -- never a second Corvus alongside the three named ones, and never
-- more than four total. The base game spawns four Flamewaker Priests around Sulfuron; three of
-- those four spots are the disciples instead, not three extra adds on top of all four Corvus.
-- Corrected (this correction, the user's own report): the fight does not differ by difficulty --
-- the same four named adds appear on Normal/Heroic too, not only Mythic/Ascended. No
-- Normal/Heroic Sulfuron pull exists in the log corpus to independently confirm this, so the
-- Normal/Heroic composition rests on the user's report rather than a log; the Mythic/Ascended
-- composition remains log-confirmed. This migration no longer gates the disciples' summon rows
-- to a minimum difficulty (this correction dropped `coa_boss_summon.min_difficulty` and its
-- CoaBossAI.cpp gate entirely, see rev_20260930_92's updated header).
--
-- Second correction: the `coa_boss_summon`-driven replace-on-pull (below) made the disciples
-- look like a mid-fight swap -- four identical Flamewaker Priests before the pull, with three
-- of them despawning and being replaced by the named disciples a few hundred ms into combat.
-- This is presentation/timing, not a missing add: the corpus's own pre-pull spawns are static,
-- not summons. A follow-up pending migration converts three of Sulfuron's four static 11662
-- spawns directly to 92031/92032/92033 (`creature.id`) and drops the `coa_boss_summon` rows for
-- entry 12098 below, so the four named adds are present and distinct from the moment the room
-- loads, not only after engage.
--
-- Each disciple's sub_name names the MC boss it apes (exiles-db export, 2026-09-13):
-- Cull the Destroyer -> "Disciple to Gehennas", Proxima the Opressor -> "Disciple to Shazzrah",
-- Ebon the Cruel -> "Disciple to Lucifron". Display id 12030 is the plain Flamewaker model (the
-- same one creature 11661 "Flamewaker" uses) -- the export contradicts the "Flamewaker Elite"
-- skin recollection; reported, not silently substituted.
--
-- Health: video reading is 6.5M at 23 players Ascended for all three, identical to Corvus's own
-- reading (hp/hp-pools.md) -- so this migration mirrors Corvus's own already-flexed coa_boss_flex
-- shape (rev_20260930_94) verbatim for all three, all four difficulty columns now live (the
-- disciples spawn on Normal/Heroic too, this correction). d0/d1 (Normal/Heroic) still have no
-- own reading; carrying Corvus's own numbers there is the least invented choice, not a claim
-- that a Normal/Heroic reading exists.
--
-- Template columns otherwise copy Corvus/Flamewaker Priest's own row (creature_template.sql,
-- entry 11662) -- same archetype, same room -- except name/subname/spells/AIName/ScriptName.
-- HealthModifier is left at the neutral 1 used by every other flexed MC add (Shadow of
-- Lucifron, rev_20260930_92): actual health comes from coa_boss_flex, not this column.
-- rank stays 1 (Corvus's own), not 3: nothing here justifies a boss-tier CC-immunity change
-- for what is, mechanically, another Flamewaker Priest reskin.
--
-- flags_extra 0x40000000 (knockback/pull immunity) and CreatureImmunitiesId 9920254 are added by
-- a follow-up pending migration once CC-immunity parity with Corvus is decided; left at their
-- prior values (0) here to keep this file's own history intact.

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
(92031, 0, 0, 0, 0, 0, 'Cull the Destroyer', 'Disciple to Gehennas', NULL, 0, 62, 62, 0, 54, 0, 1, 1.71429, 1, 1, 20,
 1, 0, 13, 2000, 2000, 1, 1, 8, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_cull_the_destroyer_coa'),
(92032, 0, 0, 0, 0, 0, 'Proxima the Opressor', 'Disciple to Shazzrah', NULL, 0, 62, 62, 0, 54, 0, 1, 1.71429, 1, 1,
 20, 1, 0, 13, 2000, 2000, 1, 1, 8, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_proxima_the_opressor_coa'),
(92033, 0, 0, 0, 0, 0, 'Ebon the Cruel', 'Disciple to Lucifron', NULL, 0, 62, 62, 0, 54, 0, 1, 1.71429, 1, 1, 20, 1,
 0, 13, 2000, 2000, 1, 1, 8, 64, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0,
 'npc_ebon_the_cruel_coa')
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

-- Model: export display_id 12030, plain Flamewaker (not Flamewaker Elite's 12002).
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (92031, 92032, 92033);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(92031, 0, 12030, 1, 1),
(92032, 0, 12030, 1, 1),
(92033, 0, 12030, 1, 1);

-- Health: [measured] video reading identical to Corvus's own (6.5M/23 players, Ascended) --
-- mirrors Corvus's own coa_boss_flex row (rev_20260930_94) verbatim; see the header comment.
DELETE FROM `coa_boss_flex` WHERE `entry` IN (92031, 92032, 92033);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(92031, 121814, 175412, 229010, 282609, 'Cull the Destroyer: CoA video Ascended (6.5M/23), same reading as Corvus; every difficulty'),
(92032, 121814, 175412, 229010, 282609, 'Proxima the Opressor: CoA video Ascended (6.5M/23), same reading as Corvus; every difficulty'),
(92033, 121814, 175412, 229010, 282609, 'Ebon the Cruel: CoA video Ascended (6.5M/23), same reading as Corvus; every difficulty');

-- Superseded by the second correction above: Sulfuron's disciples are no longer a post-pull
-- replace-in-combat (`coa_boss_summon`) -- they are static spawns (a follow-up pending migration
-- converts three of the four 11662 `creature` rows around Sulfuron to 92031/92032/92033 directly).
-- This DELETE only clears any `coa_boss_summon` rows a prior deploy of this file may have written
-- for entry 12098; rev_20260930_92's table and every other boss's rows are untouched.
DELETE FROM `coa_boss_summon` WHERE `entry` = 12098;
