-- Bloodmage worgen form: Blood Curse's transform (563124, linked from 562720) and Eternal Curse (800157) turn the
-- caster into creature 56332, whose only model is a male worgen. Female characters take the female worgen
-- display 142818 instead.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (563124, 800157) AND `ScriptName` = 'aura_ascension_bloodmage_female_worgen';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(563124, 'aura_ascension_bloodmage_female_worgen'),
(800157, 'aura_ascension_bloodmage_female_worgen');
