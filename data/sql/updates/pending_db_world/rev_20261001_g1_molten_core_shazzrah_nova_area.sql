-- rev_20261001_02 fixed the Arcane Force Nova's damage AMOUNT (coa_spell_damage_info bound
-- 2105617 to the real per-difficulty "Arcane Force Nova - Hidden Area Damage" base points
-- 6999/9333/11667/11999) but left `coa_boss_schedule`'s dummy (2105612) completing into 2105617
-- itself. Live reproduction (Ghost harness, grouped 5-bot raid, real Shazzrah spawn) confirms the
-- defect that fix did not touch: 2105617's own EffectImplicitTargetA is TARGET_UNIT_TARGET_ANY
-- (Spell.dbc), a single-unit hit on whichever target CoaBossAI::Cast() passed in (the tank) -- not
-- an area. One Nova landed exactly one real hit (7413 on bot01, the tank) and zero on the other
-- four raid members: the real damage number reached one player, never "the raid".
--
-- The actual area spells are 2105613-16 themselves (EffectImplicitTargetA
-- TARGET_UNIT_DEST_AREA_ENEMY, EffectRadiusIndex 12 ~10yd, SPELL_ATTR0_DO_NOT_DISPLAY +
-- SPELL_ATTR0_DO_NOT_LOG -- a Blizzard "hidden effect" meant to be triggered by a visible dummy,
-- never cast directly). No Spell.dbc row (2105612/2105617 included) carries SpellDifficultyId
-- 2114, the SpellDifficulty.dbc group whose four SpellID columns happen to equal 2105613-16: that
-- group is orphaned data, not a resolution path this engine can reach by casting any one id, so
-- CoaBossAI's `effect` column -- a single id meant to be shared across all four difficulties --
-- cannot name this family by itself, unlike every other dummy/effect pair in this table.
--
-- Fix at the root: let `effect` differ per difficulty, the same shape `spell_d0..d3` already uses
-- for the few casts whose id genuinely differs by tier. CoaBossAI.cpp (this revision) now resolves
-- the pending post-dummy cast the same way it resolves the dummy itself. Existing rows keep their
-- single `effect` value copied into all four new columns (no behaviour change for Lucifron,
-- Gehennas, Garr, Baron Geddon, Sulfuron and Golemagg's own dummy/effect pairs). Shazzrah's Nova
-- row alone gets the real per-difficulty hidden spells, and no longer needs the coa_spell_damage_info
-- read-the-amount-back retrofit: 2105613-16 already carry their own correct EffectBasePoints and
-- area targeting, so that row and its spell_script_names binding (both 2105617, now never cast) are
-- dropped as dead data.

SELECT IF(
    NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_boss_schedule' AND `COLUMN_NAME` = 'effect_d0'),
    "ALTER TABLE `coa_boss_schedule` "
        "CHANGE COLUMN `effect` `effect_d0` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cast when the dummy completes, 0 none', "
        "ADD COLUMN `effect_d1` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cast when the dummy completes, 0 none' AFTER `effect_d0`, "
        "ADD COLUMN `effect_d2` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cast when the dummy completes, 0 none' AFTER `effect_d1`, "
        "ADD COLUMN `effect_d3` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cast when the dummy completes, 0 none' AFTER `effect_d2`",
    'DO 0') INTO @coa_boss_schedule_effect_split;
PREPARE `coa_boss_schedule_effect_split` FROM @coa_boss_schedule_effect_split;
EXECUTE `coa_boss_schedule_effect_split`;
DEALLOCATE PREPARE `coa_boss_schedule_effect_split`;

UPDATE `coa_boss_schedule` SET `effect_d1` = `effect_d0`, `effect_d2` = `effect_d0`, `effect_d3` = `effect_d0`
    WHERE `effect_d0` != 0 AND `effect_d1` = 0 AND `effect_d2` = 0 AND `effect_d3` = 0;

UPDATE `coa_boss_schedule` SET `effect_d0` = 2105613, `effect_d1` = 2105614, `effect_d2` = 2105615, `effect_d3` = 2105616
    WHERE `entry` = 12264 AND `idx` = 6;

DELETE FROM `coa_spell_damage_info` WHERE `spell_id` = 2105617;
DELETE FROM `spell_script_names` WHERE `spell_id` = 2105617 AND `ScriptName` = 'spell_coa_damage_info_hit';
