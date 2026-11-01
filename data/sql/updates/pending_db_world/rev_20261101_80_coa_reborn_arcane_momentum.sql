-- Reborn Arcane Momentum (1144397-1144399) is a dummy talent: an Arcane Blast stack (1136032, or 1136033 in Mindshift)
-- puts the rank's Arcane Mending helper on (1144405-1144407, scoped to Arcane Mending by SpellAffect.dbc), each Arcane
-- Mending consumes a stack, and the helper goes with the last stack.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_ascension_reborn_arcane_blast_stack',
'spell_ascension_reborn_arcane_mending');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1136032, 'spell_ascension_reborn_arcane_blast_stack'),
(1136033, 'spell_ascension_reborn_arcane_blast_stack'),
(1122361, 'spell_ascension_reborn_arcane_mending'),
(1122362, 'spell_ascension_reborn_arcane_mending'),
(1122363, 'spell_ascension_reborn_arcane_mending'),
(1122364, 'spell_ascension_reborn_arcane_mending'),
(1122365, 'spell_ascension_reborn_arcane_mending'),
(1122366, 'spell_ascension_reborn_arcane_mending'),
(1122367, 'spell_ascension_reborn_arcane_mending'),
(1122368, 'spell_ascension_reborn_arcane_mending'),
(1122369, 'spell_ascension_reborn_arcane_mending'),
(1122370, 'spell_ascension_reborn_arcane_mending'),
(1122371, 'spell_ascension_reborn_arcane_mending');
