-- Renumber Basalthane's 4 difficulty templates off entries 10185-10188.
--
-- User discovered (2026-09-25, from an Ascension client cache lookup) that
-- 10186/10187/10188 are the REAL entries for this encounter's pillar
-- creatures -- "Volatile Pillar" / "Crumbling Pillar" / "Searing Pillar",
-- all modelid1 200003 -- and Basalthane's own difficulty_entry_1/2/3
-- (assigned back on 2026-09-24, before this was known) happened to land
-- squarely on top of them.
--
-- Basalthane moves to 10189-10192 (right after the real pillar IDs, as
-- requested), freeing 10186-10188 for the real pillar creatures. The C++
-- side (ENTRY_BASALTHANE_* constants in spell_basalthane.cpp) was updated
-- to match in the same commit as this file -- requires a worldserver
-- rebuild before this migration and the binary agree with each other.
--
-- Mapping: 10185->10189 (Normal), 10186->10190 (Heroic),
--          10187->10191 (Mythic), 10188->10192 (Ascended)
--
-- CORRECTED 2026-10-03 (confirmed from Errors.log: "Could not update the World
-- database"): AzerothCore's updater reapplies a pending_db_world file in full every
-- time its content hash changes - not just once ever - and this file's rename WAS NOT
-- idempotent: replayed against an already-migrated DB (10189-10192 already exist), the
-- CASE-based rename tries to move 10185 -> 10189 again and hits a primary-key
-- collision, which aborts the ENTIRE world database update (every later pending file,
-- however correct, never gets a chance to run) and can stop worldserver from starting
-- at all. Every rename below is now guarded to skip entirely once 10189 already exists
-- (meaning the rename already happened), and a stale leftover 10185 row (which predates
-- the real pillars at 10186-10188 and is never legitimate once renamed) is cleaned up
-- after the fact instead of being renamed again.

UPDATE `creature_template` SET
    `entry` = CASE `entry` WHEN 10185 THEN 10189 WHEN 10186 THEN 10190 WHEN 10187 THEN 10191 WHEN 10188 THEN 10192 END,
    `difficulty_entry_1` = CASE `difficulty_entry_1` WHEN 10186 THEN 10190 ELSE `difficulty_entry_1` END,
    `difficulty_entry_2` = CASE `difficulty_entry_2` WHEN 10187 THEN 10191 ELSE `difficulty_entry_2` END,
    `difficulty_entry_3` = CASE `difficulty_entry_3` WHEN 10188 THEN 10192 ELSE `difficulty_entry_3` END
WHERE `entry` IN (10185,10186,10187,10188)
  AND NOT EXISTS (SELECT 1 FROM (SELECT `entry` FROM `creature_template`) AS already WHERE already.`entry` = 10189);

DELETE FROM `creature_template` WHERE `entry` = 10185
  AND EXISTS (SELECT 1 FROM (SELECT `entry` FROM `creature_template`) AS already WHERE already.`entry` = 10189);

UPDATE `creature_template_model` SET
    `CreatureID` = CASE `CreatureID` WHEN 10185 THEN 10189 WHEN 10186 THEN 10190 WHEN 10187 THEN 10191 WHEN 10188 THEN 10192 END
WHERE `CreatureID` IN (10185,10186,10187,10188)
  AND NOT EXISTS (SELECT 1 FROM (SELECT `CreatureID` FROM `creature_template_model`) AS already WHERE already.`CreatureID` = 10189);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 10185
  AND EXISTS (SELECT 1 FROM (SELECT `CreatureID` FROM `creature_template_model`) AS already WHERE already.`CreatureID` = 10189);

UPDATE `creature_template_movement` SET
    `CreatureId` = CASE `CreatureId` WHEN 10185 THEN 10189 WHEN 10186 THEN 10190 WHEN 10187 THEN 10191 WHEN 10188 THEN 10192 END
WHERE `CreatureId` IN (10185,10186,10187,10188)
  AND NOT EXISTS (SELECT 1 FROM (SELECT `CreatureId` FROM `creature_template_movement`) AS already WHERE already.`CreatureId` = 10189);

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 10185
  AND EXISTS (SELECT 1 FROM (SELECT `CreatureId` FROM `creature_template_movement`) AS already WHERE already.`CreatureId` = 10189);

-- smart_scripts for entryorguid 10185-10188/10189-10192 is established fresh by
-- rev_20261002_04_basalthane_smartai_full_block_consolidation.sql as a full
-- DELETE+INSERT (per .agents/docs/sql-guidelines.md, smart_scripts edits never use a
-- partial UPDATE) - no rename needed here, that file owns the complete final state
-- regardless of what entry numbers existed before it runs.

UPDATE `coa_boss_flex` SET
    `entry` = CASE `entry` WHEN 10185 THEN 10189 WHEN 10186 THEN 10190 WHEN 10187 THEN 10191 WHEN 10188 THEN 10192 END
WHERE `entry` IN (10185,10186,10187,10188)
  AND NOT EXISTS (SELECT 1 FROM (SELECT `entry` FROM `coa_boss_flex`) AS already WHERE already.`entry` = 10189);

DELETE FROM `coa_boss_flex` WHERE `entry` = 10185
  AND EXISTS (SELECT 1 FROM (SELECT `entry` FROM `coa_boss_flex`) AS already WHERE already.`entry` = 10189);

-- Already idempotent: once `id` becomes 10189 this WHERE no longer matches, so a
-- replay is a safe no-op without needing a guard.
UPDATE `creature` SET `id` = 10189 WHERE `guid` = 9650000 AND `id` = 10185;

-- The real pillar creatures (from Ascension client data, 2026-09-25).
-- Templates only for now -- not spawned, and the boss's pillar-shatter
-- mechanic (currently gameobject-based, entry 9500100) is NOT wired to
-- these yet. Follow-up work, not part of this rename.
--
-- No DELETE here (creature_template entries are never deleted, per codestyle) - by this
-- point in the chain, 10186-10188 were already vacated by the rename UPDATE above, so
-- INSERT IGNORE is both correct for a fresh install and safe to replay.
INSERT IGNORE INTO `creature_template`
    (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`,
     `rank`, `unit_class`, `type`, `HealthModifier`, `ManaModifier`,
     `ArmorModifier`, `ExperienceModifier`, `RegenHealth`, `AIName`, `ScriptName`)
VALUES
    (10186, 'Volatile Pillar',  63, 63, 14, 1, 1.14286, 0, 1, 4, 1, 1, 1, 1, 1, '', ''),
    (10187, 'Crumbling Pillar', 63, 63, 14, 1, 1.14286, 0, 1, 4, 1, 1, 1, 1, 1, '', ''),
    (10188, 'Searing Pillar',   63, 63, 14, 1, 1.14286, 0, 1, 4, 1, 1, 1, 1, 1, '', '');

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (10186,10187,10188);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (10186, 0, 200003, 1, 1), (10187, 0, 200003, 1, 1), (10188, 0, 200003, 1, 1);
