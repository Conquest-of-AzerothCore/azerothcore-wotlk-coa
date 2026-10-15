-- Corrections to Ascension spell values that are plainly wrong in its DBC.
--
-- A tier row that steps up steadily and then breaks is read as a typo, and the
-- broken value is set to what the row's own step predicts. Applied to the
-- loaded spell data at startup (SpellFix.cpp); Spell.dbc itself stays as it is,
-- so the client tooltip still shows the old number.
--
-- `value` is the number as the DBC shows it: base points + 1.

CREATE TABLE IF NOT EXISTS `coa_spell_fix` (
  `spell_id`     INT UNSIGNED NOT NULL,
  `effect_index` TINYINT UNSIGNED NOT NULL,
  `value`        INT NOT NULL,
  `comment`      VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`, `effect_index`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

-- Only our own rows: other modules may add corrections to the same table.
DELETE FROM `coa_spell_fix` WHERE `spell_id` IN (2110405, 2110410, 2110816, 2110823);

-- Razorgore. Both rows step Normal -> Heroic x1.259, Heroic -> Mythic x1.177;
-- Ascended takes the same x1.176 again, the last step of the 20:27:34:40 family.
INSERT INTO `coa_spell_fix` VALUES
(2110405, 0, 3051, 'Fireball Storm, Ascended hit: DBC 2275, below Mythic 2594'),
(2110405, 1, 407,  'Fireball Storm, Ascended burn: DBC 260, below Mythic 346'),
(2110410, 0, 814,  'War Stomp, Ascended: DBC 3500, five times Mythic 692');

-- The Blackwing drakes.
-- Scorched steps 217 / 293 / 369, then 381 on Ascended: x1.03 where the row
-- elsewhere steps x1.26 and x1.26. Ascended takes x1.176 like its neighbours.
-- Flame Buffet steps 341 / 618 / 929 / 1365: Normal is 0.55 of Heroic where the
-- family is 0.74. Normal is set from Heroic by that step. (Its missing debuff
-- on Normal is handled in the script, which applies it on every difficulty.)
INSERT INTO `coa_spell_fix` VALUES
(2110816, 0, 434, 'Scorched (drakes), Ascended: DBC 381, barely above Mythic 369'),
(2110823, 0, 455, 'Flame Buffet, Normal: DBC 341, far below the step to Heroic 618');
