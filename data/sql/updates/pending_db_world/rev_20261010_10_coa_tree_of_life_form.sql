-- Tree of Life's proc casts Remove Tree of Life whenever the druid takes any spell, including the form's own
-- application, so the form never stayed up. Its tooltip restricts what can be cast in the form instead; the script
-- turns the proc off and the cast check enforces that list.
DELETE FROM `spell_script_names` WHERE `spell_id` = 33891 AND `ScriptName` = 'aura_ascension_tree_of_life';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(33891, 'aura_ascension_tree_of_life');
