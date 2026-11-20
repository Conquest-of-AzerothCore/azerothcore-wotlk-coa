DELETE FROM `spell_group` WHERE `id` = 2112508
    AND `spell_id` IN (300856, 301228, 301229, 301230, 301231, 301232, 680280);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2112508, 300856),
(2112508, 301228),
(2112508, 301229),
(2112508, 301230),
(2112508, 301231),
(2112508, 301232),
(2112508, 680280);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2112508;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2112508, 4, 'Guardian Honor and Greater Honor - exclusive, highest wins');
