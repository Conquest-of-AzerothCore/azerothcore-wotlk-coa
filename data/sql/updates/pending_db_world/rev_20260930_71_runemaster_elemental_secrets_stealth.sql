-- Runemaster Speed Rune path (572136) stealths allies with Elemental Secrets (706736) only for a caster with the
-- Elemental Secrets talent (707149).
DELETE FROM `spell_script_names` WHERE `spell_id` = 572136 AND
    `ScriptName` = 'aura_ascension_runemaster_speed_rune_stealth';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(572136, 'aura_ascension_runemaster_speed_rune_stealth');
