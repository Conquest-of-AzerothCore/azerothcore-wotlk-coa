DELETE FROM `spell_group` WHERE `id` IN (2106090, 2106091, 2106092, 2106093, 2106094, 2106095, 2106096);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2106090, 572173),
(2106090, 572177),
(2106091, 561244),
(2106091, 561245),
(2106091, 561246),
(2106091, 561247),
(2106091, 561257),
(2106091, 561258),
(2106092, 561248),
(2106092, 561249),
(2106092, 561250),
(2106092, 561251),
(2106093, 582533),
(2106093, 582536),
(2106094, 561252),
(2106094, 561253),
(2106094, 561254),
(2106094, 561255),
(2106095, 561256),
(2106095, 561259),
(2106096, 581314),
(2106096, 582261);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (2106090, 2106091, 2106092, 2106093, 2106094, 2106095, 2106096);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2106090, 4, 'Chill of the Tomb and Greater Chill of the Tomb: strongest stays'),
(2106091, 4, 'Runemaster Frost Inscriptions: strongest stays'),
(2106092, 4, 'Runemaster Fire Inscriptions: strongest stays'),
(2106093, 4, 'Fire Protection and Greater Fire Protection: strongest stays'),
(2106094, 4, 'Runemaster Arcane Inscriptions: strongest stays'),
(2106095, 4, 'Runemaster Nature Inscriptions: strongest stays'),
(2106096, 4, 'Essence of Nature and Greater Essence of Nature: strongest stays');
