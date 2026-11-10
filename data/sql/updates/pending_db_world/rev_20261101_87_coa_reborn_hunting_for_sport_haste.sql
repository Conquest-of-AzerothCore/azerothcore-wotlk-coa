-- Reborn Hunting for Sport (1119183, 1119186, 1119187): the tooltip's melee haste for party and raid members within
-- 50 yd is each rank's own aura (1119189-1119191, 7/14/20%), held while the talent is.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (1119183, 1119186, 1119187) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(1119183, 1119189, 2, 'Hunting for Sport rank 1 - party melee haste'),
(1119186, 1119190, 2, 'Hunting for Sport rank 2 - party melee haste'),
(1119187, 1119191, 2, 'Hunting for Sport rank 3 - party melee haste');
