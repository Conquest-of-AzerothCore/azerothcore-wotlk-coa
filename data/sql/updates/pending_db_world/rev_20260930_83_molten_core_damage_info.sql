-- Molten Core "Damage Info" spell damage on CoA: a boss casts a dummy followed by an
-- effect spell whose DBC base points are a placeholder (school damage or periodic
-- damage, base points 1, so the effect currently deals ~2 damage on every difficulty).
-- CoA's original server read the real number from a companion aura named
-- "<Boss> - <Spell> Damage Info", one per difficulty (D0..D3), whose own base points
-- (+1) are the intended damage. That script is gone; coa_spell_damage_info restores the
-- mapping and DamageInfo.cpp (modules/mod-coa-raid-difficulty) reads it back in at cast
-- time, picking the row for the caster's map difficulty (raid Normal/Heroic/Mythic/
-- Ascended; any other map uses the D0 row).
CREATE TABLE IF NOT EXISTS `coa_spell_damage_info` (
  `spell_id` INT UNSIGNED NOT NULL,
  `info_d0`  INT UNSIGNED NOT NULL,
  `info_d1`  INT UNSIGNED NOT NULL,
  `info_d2`  INT UNSIGNED NOT NULL,
  `info_d3`  INT UNSIGNED NOT NULL,
  `comment`  VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

DELETE FROM `coa_spell_damage_info` WHERE `spell_id` IN
  (2105213, 2105255, 2105456, 2105563, 2105406, 2105430, 2105436, 2105814, 2105357, 2105906, 2108608, 2108762);
INSERT INTO `coa_spell_damage_info` (`spell_id`, `info_d0`, `info_d1`, `info_d2`, `info_d3`, `comment`) VALUES
(2105213, 2105208, 2105209, 2105210, 2105211, 'Lucifron Shadow Bolt'),
(2105255, 2105250, 2105251, 2105252, 2105253, 'Flamewaker Shadow Bolt'),
(2105456, 2105451, 2105452, 2105453, 2105454, 'Flamewaker Incinerate'),
(2105563, 2105557, 2105558, 2105559, 2105560, 'Firesworn/Garr Ignite'),
(2105406, 2105401, 2105402, 2105403, 2105404, 'Gehennas Incinerate'),
(2105430, 2105425, 2105426, 2105427, 2105428, 'Gehennas Immolate'),
(2105436, 2105431, 2105432, 2105433, 2105434, 'Gehennas Conflagrate'),
(2105814, 2105808, 2105809, 2105810, 2105811, 'Golemagg Lava Burst'),
(2105357, 2105351, 2105352, 2105353, 2105354, 'Magmadar Lava Burst'),
(2105906, 2105901, 2105902, 2105903, 2105904, 'Sulfuron Conflagrate'),
(2108608, 2108603, 2108604, 2108605, 2108606, 'Ragnaros Magma Blast'),
(2108762, 2108755, 2108756, 2108757, 2108758, 'Ragnaros Meteor');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105213, 2105255, 2105456, 2105563, 2105406, 2105814, 2105357, 2108608, 2108762)
  AND `ScriptName` = 'spell_coa_damage_info_hit';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105213, 'spell_coa_damage_info_hit'),
(2105255, 'spell_coa_damage_info_hit'),
(2105456, 'spell_coa_damage_info_hit'),
(2105563, 'spell_coa_damage_info_hit'),
(2105406, 'spell_coa_damage_info_hit'),
(2105814, 'spell_coa_damage_info_hit'),
(2105357, 'spell_coa_damage_info_hit'),
(2108608, 'spell_coa_damage_info_hit'),
(2108762, 'spell_coa_damage_info_hit');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105430, 2105436, 2105906)
  AND `ScriptName` = 'spell_coa_damage_info_periodic';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105430, 'spell_coa_damage_info_periodic'),
(2105436, 'spell_coa_damage_info_periodic'),
(2105906, 'spell_coa_damage_info_periodic');
