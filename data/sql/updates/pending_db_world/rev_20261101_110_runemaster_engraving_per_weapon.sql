-- Air Engraving 653225 and Earth Engraving 653221 follow the engraved weapon that carries them (#10466, #10467)
DELETE FROM `spell_linked_spell` WHERE `type` = 2 AND ((`spell_trigger` = 653223 AND `spell_effect` = 653225)
    OR (`spell_trigger` = 653219 AND `spell_effect` = 653221));

DELETE FROM `spell_script_names` WHERE `spell_id` IN (653219, 653223)
    AND `ScriptName` = 'aura_ascension_runemaster_engraving_per_weapon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(653219, 'aura_ascension_runemaster_engraving_per_weapon'),
(653223, 'aura_ascension_runemaster_engraving_per_weapon');
