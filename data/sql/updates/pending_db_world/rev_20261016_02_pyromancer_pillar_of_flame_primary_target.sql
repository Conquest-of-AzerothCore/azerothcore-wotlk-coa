-- Issue #7802: Pillar of Flame (805496 and ranks 807406-807410) deals its splash effect to the
-- primary target on top of the direct hit because the dest-area effect includes everything in radius.
-- Bind the primary-target filter script on every rank so only enemies near the target take the splash.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (805496, 807406, 807407, 807408, 807409, 807410) AND `ScriptName` = 'spell_ascension_pyromancer_pillar_of_flame';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(805496, 'spell_ascension_pyromancer_pillar_of_flame'),
(807406, 'spell_ascension_pyromancer_pillar_of_flame'),
(807407, 'spell_ascension_pyromancer_pillar_of_flame'),
(807408, 'spell_ascension_pyromancer_pillar_of_flame'),
(807409, 'spell_ascension_pyromancer_pillar_of_flame'),
(807410, 'spell_ascension_pyromancer_pillar_of_flame');
