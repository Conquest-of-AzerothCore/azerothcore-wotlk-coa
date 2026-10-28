-- Basalthane flex health (Onyxia's Lair, base entry 10189 - Normal; Heroic/
-- Mythic/Ascended are 10190-10192, reached via creature_template's own
-- difficulty_entry_N swap, never a separate spawn).
--
-- CORRECTED 2026-10-02 (external review caught a real bug in every earlier
-- version of this file): mod-coa-raid-difficulty's FlexHealth.cpp looks a
-- boss up by `BaseEntry(creature->GetEntry())` - and Creature::GetEntry()
-- always stays at the SPAWN entry (10189) regardless of which difficulty is
-- active; only CreatureTemplate()->Entry changes with difficulty. The actual
-- difficulty is read separately, via the map's own spawn mode, as an index
-- (0-3) into ONE row's four hp_dN columns. Earlier versions of this file (and
-- rev_20260930_12 after it) inserted/updated FOUR separate rows, one per
-- difficulty-entry (10189-10192, each with only its own hp_dN column set) -
-- those rows for 10190-10192 were dead weight, never read by anything; only
-- 10189's hp_d0 column (Normal) ever actually applied. This file now creates
-- the single row FlexHealth.cpp actually reads, with all four final values.
--
-- No CREATE TABLE here - mod-coa-raid-difficulty owns `coa_boss_flex` (see
-- modules/mod-coa-raid-difficulty/data/sql/db-world/base/04_boss_flex.sql)
-- and is a hard dependency of this encounter either way; redefining the
-- table here risked drifting from its canonical definition.
--
-- Per-player values, from four real Basalthane kills:
--   Normal  (24.08, 19 players): 22,343,440 total -> 1,175,972 / player
--   Heroic  (24.08, 20 players): 40,244,223 total -> 2,012,211 / player
--   Heroic  (25.08, 13 players): 24,182,108 total -> 1,860,162 / player
--   Mythic  (26.08, 19 players): 54,699,256 total -> 2,878,908 / player (early estimate)
-- Heroic here is the mean of its two kills (1,936,186).
--
-- RETUNED 2026-10-02 (user's own call): Mythic/Ascended no longer 25-man-locked -
-- all four difficulties now flex dynamically with the instance's actual headcount
-- (clamped 10-25), same as Normal/Heroic. Final per-player values: Mythic 2,478,908,
-- Ascended 3,412,458 (both revised down from the earlier 25-man-locked estimates).
--
-- mod-coa-raid-difficulty's FlexHealth.cpp also supports a negative-value convention
-- (always x25 regardless of headcount) for bosses that DO want a 25-man lock - not
-- used here anymore, but the column type stays signed INT (widened from the module's
-- own INT UNSIGNED) in case another boss on this table wants it; harmless no-op for
-- any boss using positive values, this one included.
ALTER TABLE `coa_boss_flex`
    MODIFY `hp_d0` INT NOT NULL DEFAULT 0 COMMENT 'health per player, Normal; 0 no flex',
    MODIFY `hp_d1` INT NOT NULL DEFAULT 0 COMMENT 'Heroic',
    MODIFY `hp_d2` INT NOT NULL DEFAULT 0 COMMENT 'Mythic; negative = 25-man-locked (always x25)',
    MODIFY `hp_d3` INT NOT NULL DEFAULT 0 COMMENT 'Ascended; negative = 25-man-locked (always x25)';

DELETE FROM `coa_boss_flex` WHERE `entry` IN (10185, 10186, 10187, 10188, 10189, 10190, 10191, 10192);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(10189, 1175972, 1936186, 2478908, 3412458, 'Basalthane: all four difficulties measured/extrapolated and dynamic-flex (10-25 players)');
