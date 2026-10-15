-- Ionic Aura (#3147) promises maximum mana, Rage, Energy, Focus and Runic Power, but Spell.dbc 707652 encodes
-- only MiscValue 0 (mana) and MiscValue 1 (Rage) with SPELL_AURA_MOD_INCREASE_ENERGY_PERCENT, and its third
-- effect is an unscripted dummy, so Energy, Focus and Runic Power received nothing. The script applies the same
-- percentage to those three pools on every unit the raid aura reaches.
START TRANSACTION;
SET @ScriptName = 'aura_ascension_ionic_aura';
DELETE FROM `spell_script_names` WHERE `spell_id` = 707652 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707652, @ScriptName);
COMMIT;
