DELETE FROM `spell_group` WHERE `id` IN (
    2106090, 2106091, 2106092, 2106093, 2106094, 2106095, 2106096, 2106097, 2106098, 2106099, 2106100
);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2106090, 572173),
(2106090, 572177),
(2106091, 561244),
(2106091, 561247),
(2106092, 561248),
(2106092, 561251),
(2106093, 582533),
(2106093, 582536),
(2106094, 561252),
(2106094, 561255),
(2106095, 561256),
(2106095, 561259),
(2106096, 581314),
(2106096, 582261),
(2106097, 680303),
(2106097, 707679),
(2106097, 707680),
(2106097, 707681),
(2106097, 707682),
(2106097, 707683),
(2106098, 681160),
(2106098, 800852),
(2106099, 560289),
(2106099, 560290),
(2106099, 560291),
(2106099, 560292),
(2106099, 560293),
(2106099, 680289),
(2106099, 800194),
(2106100, 561389),
(2106100, 561392);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (
    2106090, 2106091, 2106092, 2106093, 2106094, 2106095, 2106096, 2106097, 2106098, 2106099, 2106100
);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2106090, 4, 'Chill of the Tomb and Greater Chill of the Tomb: strongest stays'),
(2106091, 4, 'Runemaster Frost Inscriptions: strongest stays'),
(2106092, 4, 'Runemaster Fire Inscriptions: strongest stays'),
(2106093, 4, 'Fire Protection and Greater Fire Protection: strongest stays'),
(2106094, 4, 'Runemaster Arcane Inscriptions: strongest stays'),
(2106095, 4, 'Runemaster Nature Inscriptions: strongest stays'),
(2106096, 4, 'Essence of Nature and Greater Essence of Nature: strongest stays'),
(2106097, 4, 'Inquisitor''s Edict and Greater Inquisitor''s Edict: strongest stays'),
(2106098, 4, 'Devotion of Grace and Greater Devotion of Grace: strongest stays'),
(2106099, 4, 'Void Blessing and Greater Void Blessing: strongest stays'),
(2106100, 4, 'Whispers of Y''shaarj and Greater Whispers of Y''shaarj: strongest stays');
