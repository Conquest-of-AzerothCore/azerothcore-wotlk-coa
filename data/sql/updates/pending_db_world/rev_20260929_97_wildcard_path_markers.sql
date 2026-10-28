-- A Wildcard stat path marks its Hero with a "Primary Stat" aura, which the client reads for the character window
-- (UnitPrimaryStat: 954687 Strength, 954688 Agility, 954689 Intellect, 954690 Healing, 954699 Duality). Intellect,
-- Healing and Duality link theirs in Spell.dbc; Strength and Agility only link their attack power buff.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (84864, 84865) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(84864, 954687, 2, 'Path of Strength - Primary Stat: Strength'),
(84865, 954688, 2, 'Path of Agility - Primary Stat: Agility');
