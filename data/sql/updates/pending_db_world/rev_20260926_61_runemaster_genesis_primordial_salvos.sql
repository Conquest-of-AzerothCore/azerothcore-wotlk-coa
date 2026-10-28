-- Runemaster Genesis (500501): accumulates 50% of the caster's damage to the branded enemy and releases it as
-- Genesis (500502) Elemental damage on expiry, which then triggers the caster's active Weapon Engraving.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (500501, 500502) AND `ScriptName` IN
    ('aura_ascension_runemaster_genesis', 'spell_ascension_runemaster_genesis_damage');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500501, 'aura_ascension_runemaster_genesis'),
(500502, 'spell_ascension_runemaster_genesis_damage');

-- Runemaster Primordial Salvos (800752): ${$800730m1+$SP*0.06} per unleashed Glyph, in the Glyph's school.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (800729, 800730, 800731);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(800729, 0.06, 0, 0, 0, 'Ascension Runemaster Primordial Salvos - Flame Salvo'),
(800730, 0.06, 0, 0, 0, 'Ascension Runemaster Primordial Salvos - Frost Salvo'),
(800731, 0.06, 0, 0, 0, 'Ascension Runemaster Primordial Salvos - Arcane Salvo');
