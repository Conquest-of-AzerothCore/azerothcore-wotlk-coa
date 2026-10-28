--
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 802581 OR `spell_id` BETWEEN 802581 AND 802586;
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(802581, 802581, 1),
(802581, 802582, 2),
(802581, 802583, 3),
(802581, 802584, 4),
(802581, 802585, 5),
(802581, 802586, 6);
