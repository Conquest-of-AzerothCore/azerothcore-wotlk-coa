-- Golemagg's Massive Stomp (2105817) is a DBC-pure stun with no damage effect, so the raid
-- takes nothing from it today. CoA's own Spell.dbc already ships the real mechanic unused:
-- "Massive Stomp" 2105823 (SCHOOL_DAMAGE placeholder, base points 1) backed by "Massive Stomp -
-- Hidden Damage - No School" 2105819/2105820/2105821/2105822 (SpellDifficulty group 2124, 100 yd
-- radius, real D0-D3 base points 3199/4265/5330/6399), the same dummy -> Damage Info pattern
-- rev_20260930_83 already reads for the other twelve bound spells. boss_golemagg_coa.cpp casts
-- 2105823 at every player near Golemagg when Massive Stomp lands; this binds its damage.
DELETE FROM `coa_spell_damage_info` WHERE `spell_id` IN (2105823);
INSERT INTO `coa_spell_damage_info` (`spell_id`, `info_d0`, `info_d1`, `info_d2`, `info_d3`, `comment`) VALUES
(2105823, 2105819, 2105820, 2105821, 2105822, 'Golemagg Massive Stomp');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105817, 2105823)
  AND `ScriptName` IN ('spell_golemagg_massive_stomp_coa', 'spell_coa_damage_info_hit');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105817, 'spell_golemagg_massive_stomp_coa'),
(2105823, 'spell_coa_damage_info_hit');
