-- Gehennas (12259): Conjure Flame Orb (2105417, coa_boss_schedule idx 5, "ran" per
-- docs/coa/molten-core.md) casts but produces nothing. Spell.dbc (live server-data, parsed
-- this session): EFFECT_0 is a plain dummy, EFFECT_1 is TRIGGER_SPELL -> 2180023, which is
-- "Cosmetic - Camera Shake Big" (a client-only visual, no SUMMON effect) -- the orb itself has
-- to be summoned by script, same idiom as the other MC dummy-effect chains
-- (spell_magmadar_lava_bomb, boss_magmadar.cpp).
--
-- Orb creature: db.exil.es export (~/Projects/refs/exiles/exiles.sqlite, table creature)
-- entry 80644 "Flame Orb" carries spells {2105421,2105422} -- Gehennas' own Flame Orb damage
-- family (SpellDifficulty.dbc row 2106: 2105419->20->21->22) -- confirming this is the matching
-- export row, not the unrelated level-1 entry 10195 (spells {2108268-70}) or the generic WotLK
-- retail entry 30702 (same visual, spells {57750,58937}, level 80). Export health/level/faction
-- are the same unusable placeholder shape already documented for other MC adds
-- (rev_20260930_91, rev_20260930_92): level 1, health 1, no faction. Designed instead: level 63
-- and faction 54, copied from Gehennas and every other MC boss/add in this module
-- (coa_boss_ai.cpp, Shadow of Lucifron rev_20260930_92); unit_flags 33554432
-- (UNIT_FLAG_NOT_SELECTABLE) and flags_extra 192 (CREATURE_FLAG_EXTRA_TRIGGER |
-- CREATURE_FLAG_EXTRA_NO_XP) copied from the stock WotLK entry 30702, the same non-interactive
-- fire-orb visual Blizzard ships elsewhere; display_ids {24722} is the export's own model for
-- 80644, distinct from 30702's 26767. Nobody is seen attacking the orb in any recorded fight
-- (coa-log-history raw 307/1617/1741), so it additionally gets UNIT_FLAG_NON_ATTACKABLE (2) on
-- top of NOT_SELECTABLE -- [designed] safeguard so it survives its full lifetime regardless of
-- incidental AoE (a player's Consecration is seen landing on it in fight 307's raw log).
--
-- Lifetime 11000ms is measured, not designed: coa-log-history raw dumps of fights 307
-- (5/28), 1617 (8/16) and 1741 (8/23) give 12 orb instances; first-to-last SPELL_DAMAGE/MISSED
-- span is 10.098-10.956s, i.e. 37-40 ticks of the 275ms amplitude on 2105418 (Spell.dbc) --
-- 40 ticks = 11000ms, the smallest round number consistent with every instance (the true start
-- and the moment the aura is removed are a few ms outside the first/last observed tick).
-- 2105418's own SpellDuration.dbc row (21) is infinite, so the orb's lifetime is enforced by
-- the summon's own despawn timer, not the aura.
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
(80644, 0, 0, 0, 0, 0, 'Flame Orb', NULL, NULL, 0, 63, 63, 0, 54, 0, 2, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1,
 1, 33554434, 2048, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 192,
 'npc_coa_gehennas_flame_orb')
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

DELETE FROM `creature_template_model` WHERE `CreatureID` = 80644;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(80644, 0, 24722, 1, 1);

-- Script: dummy-then-summon chain (spell_gehennas_conjure_flame_orb, boss_gehennas.cpp), same
-- idiom as spell_shadow_of_lucifron_shadow_bolt (rev_20260930_92) but summoning the orb instead
-- of chaining to another spell, since the orb has to exist to pulse its own damage.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2105417 AND `ScriptName` = 'spell_gehennas_conjure_flame_orb';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105417, 'spell_gehennas_conjure_flame_orb');
