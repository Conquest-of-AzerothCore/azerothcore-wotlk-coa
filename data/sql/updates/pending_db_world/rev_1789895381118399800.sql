--
-- Golem Form (#642): native linked auras supply haste and the authored moving-cast spell mask.
-- Type 2 also removes both helpers when the form is cancelled, expires or is removed by death.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 805335 AND `spell_effect` IN (801615, 504635) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(805335, 801615, 2, 'Primalist Golem Form - 20 percent melee and spell haste'),
(805335, 504635, 2, 'Primalist Golem Form - damaging spells while moving');
