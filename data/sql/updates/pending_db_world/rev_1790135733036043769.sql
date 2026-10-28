-- Suffuse (801063) claims a native SPELL_AURA_MOD_INCREASE_SPEED effect at EFFECT_2 for Speed Demon
-- (707232, AscensionXorothContracts.cpp) whose amount is computed by aura_ascension_xoroth_lifecycle::
-- Calculate (AscensionXorothAuras.cpp), but the spell had no spell_script_names row binding it to that
-- script, so the override (and the OnCalcMaxDuration duration fix alongside it) never ran.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801063 AND `ScriptName` = 'aura_ascension_xoroth_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (801063, 'aura_ascension_xoroth_lifecycle');
