--
-- Keep area sources active and let native flat armor apply only the strongest grouped effect.
-- Protector's Hand (#3900) and equivalent raid armor auras: keep only the strongest armor effect.
DELETE FROM `spell_group` WHERE `id` = 2000200;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2000200, 465),
(2000200, 8072),
(2000200, 300730),
(2000200, 685028),
(2000200, 705094),
(2000200, 705095),
(2000200, 706222),
(2000200, 707540),
(2000200, 707541),
(2000200, 707547),
(2000200, 707550),
(2000200, 712432),
(2000200, 807460);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2000200;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`) VALUES (2000200, 3);
