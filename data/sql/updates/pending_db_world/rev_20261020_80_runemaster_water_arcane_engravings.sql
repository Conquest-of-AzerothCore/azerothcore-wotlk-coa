-- Runemaster Water Engraving payload 653261: drain up to 2% of the caster's maximum mana and deal it as Frost damage.
-- Arcane Engraving mark 653263: store effective healing taken and detonate 30% of it as Arcane damage on expiry.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (653261, 653263) AND `ScriptName` IN
    ('spell_ascension_runemaster_water_engraving', 'aura_ascension_runemaster_arcane_engraving_mark');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(653261, 'spell_ascension_runemaster_water_engraving'),
(653263, 'aura_ascension_runemaster_arcane_engraving_mark');
