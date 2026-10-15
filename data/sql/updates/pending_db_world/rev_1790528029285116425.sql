-- Witch Hunter Edicts and Runemaster Etchings: an Edict or Etching and its Greater version are one buff, whoever
-- casts them (#5385); a caster gives each recipient one Etching, as group 1139 already does for Edicts (#4039).
-- The pair groups sort below 1139 and 1140 so their exclusive rule is the one SpellMgr reads first.
DELETE FROM `spell_group` WHERE `id` IN (1039, 1040, 1041, 1042, 1043, 1044, 1140);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1039, 523485),
(1039, 523510),
(1040, 706741),
(1040, 680303),
(1041, 707684),
(1041, 681442),
(1042, 561237),
(1042, 561241),
(1043, 561236),
(1043, 561242),
(1044, 560295),
(1044, 561243),
(1140, 561237),
(1140, 561241),
(1140, 561236),
(1140, 561242),
(1140, 560295),
(1140, 561243);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (1039, 1040, 1041, 1042, 1043, 1044, 1140);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1039, 1, 'Local CoA: Knight\'s Edict and Greater Knight\'s Edict'),
(1040, 1, 'Local CoA: Inquisitor\'s Edict and Greater Inquisitor\'s Edict'),
(1041, 1, 'Local CoA: Witching Edict and Greater Witching Edict'),
(1042, 1, 'Local CoA: Etching of the Dextrous and its Greater version'),
(1043, 1, 'Local CoA: Etching of the Leylines and its Greater version'),
(1044, 1, 'Local CoA: Etching of the Magi and its Greater version'),
(1140, 2, 'Local CoA: one Runemaster Etching per caster on each recipient');
