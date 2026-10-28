-- Runemaster Frigid Fusion (803225): accumulates 20% (30% with Frigid Elements 707654) of the caster's damage to the
-- target and releases it as Frigid Fusion (572338) Frost damage on expiry.
DELETE FROM `spell_script_names` WHERE `spell_id` = 803225 AND `ScriptName` = 'aura_ascension_runemaster_frigid_fusion';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(803225, 'aura_ascension_runemaster_frigid_fusion');
