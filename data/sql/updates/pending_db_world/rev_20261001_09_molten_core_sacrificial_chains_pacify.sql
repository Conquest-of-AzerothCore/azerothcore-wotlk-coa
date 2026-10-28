-- Sacrifice (2108020, Sacrificial Chains) gets a server-side root/silence/pacify for its duration
-- (spell_sacrificial_chains_sacrifice_coa, npc_sacrificial_chains_coa.cpp) since neither effect
-- exists in its own Spell.dbc row -- live-Ascension logs show chained players go completely
-- silent for essentially the exact debuff duration (diag-G3.md "Ascension evidence" #2).
DELETE FROM `spell_script_names` WHERE `spell_id` = 2108020 AND `ScriptName` = 'spell_sacrificial_chains_sacrifice_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2108020, 'spell_sacrificial_chains_sacrifice_coa');
