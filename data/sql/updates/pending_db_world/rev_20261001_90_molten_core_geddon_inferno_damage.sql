-- Baron Geddon's Inferno wave damage (2105741 Normal / 2105742 Heroic / 2105743 Mythic /
-- 2105744 Ascended, SpellDifficulty.dbc row 2119, triggered every second by the channel 2105740)
-- is real DBC damage, not a placeholder. The user reported it too light on Ascended (almost no
-- raid frame drops, no deaths to it) and asked for +20% on every difficulty. The multiplier lives
-- in one constant, INFERNO_DAMAGE_MULTIPLIER (boss_geddon_coa.cpp), applied by
-- spell_geddon_inferno_damage_coa.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105741, 2105742, 2105743, 2105744) AND `ScriptName` = 'spell_geddon_inferno_damage_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105741, 'spell_geddon_inferno_damage_coa'),
(2105742, 'spell_geddon_inferno_damage_coa'),
(2105743, 'spell_geddon_inferno_damage_coa'),
(2105744, 'spell_geddon_inferno_damage_coa');
