-- Shazzrah's Arcane Force Nova schedule effect (2105612 dummy -> 2105617) is a DBC placeholder
-- (EffectBasePoints 1, ~1 damage) on every difficulty; the real per-difficulty amounts live in the
-- "Arcane Force Nova - Hidden Area Damage" family (2105613-16, base points 6999/9333/11667/11999).
-- Wired through the same coa_spell_damage_info/spell_coa_damage_info_hit mechanism as rev_20260930_83's
-- 12 pairs.
DELETE FROM `coa_spell_damage_info` WHERE `spell_id` = 2105617;
INSERT INTO `coa_spell_damage_info` (`spell_id`, `info_d0`, `info_d1`, `info_d2`, `info_d3`, `comment`) VALUES
(2105617, 2105613, 2105614, 2105615, 2105616, 'Shazzrah Arcane Force Nova');

DELETE FROM `spell_script_names` WHERE `spell_id` = 2105617 AND `ScriptName` = 'spell_coa_damage_info_hit';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105617, 'spell_coa_damage_info_hit');
