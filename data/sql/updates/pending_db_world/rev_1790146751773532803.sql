-- Forgefiend's Bulwark's Enrage buff (801019) claims a native SPELL_AURA_MOD_CRIT_PCT effect at
-- EFFECT_1 for Fiend of Forges (300386, AscensionXorothContracts.cpp) whose amount is computed by
-- aura_ascension_xoroth_lifecycle::Calculate (AscensionXorothAuras.cpp), but the spell had no
-- spell_script_names row binding it to that script, so the override never ran - the same missing-
-- registration bug already fixed once for Suffuse (801063, rev_1790135733036043769.sql, #1223).
DELETE FROM `spell_script_names` WHERE `spell_id` = 801019 AND `ScriptName` = 'aura_ascension_xoroth_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (801019, 'aura_ascension_xoroth_lifecycle');
