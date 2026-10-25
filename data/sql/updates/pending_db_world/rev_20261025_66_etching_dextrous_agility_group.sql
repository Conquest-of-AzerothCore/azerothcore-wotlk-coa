-- COA-6091: Etching of the Dextrous (Runemaster, Agility) stacked with the other classes' Agility buffs such as the
-- Templar's Inquisitor's Edict, because rev_20261009_50 left it out of the shared Agility group 2110001. Add the
-- first rank of its chain (561237 covers 561238-561240) and Greater Etching of the Dextrous 561241.
DELETE FROM `spell_group` WHERE `id` = 2110001 AND `spell_id` IN (561237, 561241);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110001, 561237),
(2110001, 561241);
