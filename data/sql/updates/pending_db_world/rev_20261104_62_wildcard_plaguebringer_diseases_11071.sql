-- Wildcard Plaguebringer 288806 ("Infects the target with Frost Fever and Blood Plague") has a single
-- SPELL_EFFECT_DUMMY on the enemy target and no script, so it spent its runes and cooldown and applied nothing.
-- Link both diseases to the hit, as Hungering Cold (51209) already links Frost Fever.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 288806 AND `spell_effect` IN (55095, 55078) AND `type` = 1;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(288806, 55095, 1, 'Wildcard Plaguebringer - Frost Fever'),
(288806, 55078, 1, 'Wildcard Plaguebringer - Blood Plague');
