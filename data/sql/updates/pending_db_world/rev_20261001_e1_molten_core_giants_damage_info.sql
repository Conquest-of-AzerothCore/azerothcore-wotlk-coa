-- Molten Giant (11658) Smash and Molten Destroyer (11659) Massive Tremor are real, native AoE
-- abilities (SCHOOL_DAMAGE, TARGET_SRC_CASTER + TARGET_UNIT_SRC_AREA_ENEMY, SpellRadius 13 = 10 yd
-- cleave and SpellRadius 23 = 40 yd room-wide respectively) that SmartAI already casts on every
-- difficulty (rev_20260930_99), but always at their flat base-entry damage (18944/19129's own DBC
-- base points), unscaled. Unlike Golemagg's Massive Stomp, these two already deal real damage on
-- Normal, so no new dummy/trigger indirection is needed -- only reading the right per-difficulty
-- value at cast time via the same spell_coa_damage_info_hit mechanism used elsewhere in this fork
-- (rev_20260930_83).
--
-- Each ability's own per-difficulty DBC family was found via
-- ~/Projects/coa-combatlog-parser scripts/mc_evidence.py, which decodes SpellDifficulty.dbc
-- group->4-spell-id rows directly (authoritative tier order, not inferred from id ordering):
-- Smash is SpellDifficulty group 1818: D0 2018944 (base points 299), D1 2018946 (598), D2 2018947
-- (722), D3 2018948 (901) -- real damage = base points + 1 by this fork's Damage Info convention.
-- Massive Tremor's family is named "Ground Tremor" (SpellDifficulty group 1873): D0 2100278 (299),
-- D1 2100475 (598), D2 2100476 (897), D3 2100477 (1196) -- real damage 300/599/898/1197, a clean
-- x1/x2/x3/x4 ladder matching several other already-wired MC Damage Info families (e.g. Lucifron
-- Shadow Bolt). Both families are confirmed present in each creature's own db.exil.es export kit
-- spell list (11658, 11659) and in mc-dataset.json's spell_difficulty_map (sd:1818, sd:1873).
--
-- The live Ascension combat-log corpus (coa-combatlog-parser local/logs/ascension,
-- mc-summary.md) recorded zero casts of any of these eight ids across every pull and difficulty
-- in the whole corpus -- the same SmartAI difficulty gate bug (rev_20260930_99's own fix target)
-- evidently affected the original live server too, so no live per-hit damage sample exists for
-- these specific ids; the DBC base points are used directly, the same evidence class already
-- accepted for every other Damage Info family in this fork.
--
-- Knock Away (18945) and Stunning Strike (20276) are single-target, not AoE, and are out of this
-- fix's scope; docs/coa/molten-core.md records their own real families (sd:1819 Knock Away incl.
-- 2018949/2018950/2018951, Stunning Strike's 2100135) as a follow-up, not applied here.
CREATE TABLE IF NOT EXISTS `coa_spell_damage_info` (
  `spell_id` INT UNSIGNED NOT NULL,
  `info_d0`  INT UNSIGNED NOT NULL,
  `info_d1`  INT UNSIGNED NOT NULL,
  `info_d2`  INT UNSIGNED NOT NULL,
  `info_d3`  INT UNSIGNED NOT NULL,
  `comment`  VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

DELETE FROM `coa_spell_damage_info` WHERE `spell_id` IN (18944, 19129);
INSERT INTO `coa_spell_damage_info` (`spell_id`, `info_d0`, `info_d1`, `info_d2`, `info_d3`, `comment`) VALUES
(18944, 2018944, 2018946, 2018947, 2018948, 'Molten Giant Smash'),
(19129, 2100278, 2100475, 2100476, 2100477, 'Molten Destroyer Massive Tremor (Ground Tremor family)');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (18944, 19129) AND `ScriptName` = 'spell_coa_damage_info_hit';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(18944, 'spell_coa_damage_info_hit'),
(19129, 'spell_coa_damage_info_hit');
