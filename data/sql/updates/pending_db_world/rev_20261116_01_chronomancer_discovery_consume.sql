-- Discovery (500116): its second proc effect fired the bonus hit 806201 on every Artificer's Wand and Wand of
-- Time hit. The tooltip grants it only "at 3 stacks" of Discovery 704197, which that hit then consumes
-- through Discovery Trigger 524963 (SPELL_EFFECT_REMOVE_AURA 704197).
DELETE FROM `spell_script_names` WHERE `spell_id` = 500116 AND `ScriptName` = 'spell_ascension_discovery';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500116, 'spell_ascension_discovery');
