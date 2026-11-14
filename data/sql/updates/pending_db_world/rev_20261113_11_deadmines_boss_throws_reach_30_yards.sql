DELETE FROM `coa_dungeon_spell_reach` WHERE `spell_id` IN (2102589, 2102569);
INSERT INTO `coa_dungeon_spell_reach` (`spell_id`, `range_index`, `line_of_sight`, `comment`) VALUES
(2102589, 4, 1, 'Cookie: Throw Food 30 yd, line of sight'),
(2102569, 4, 1, 'Sneed''s Shredder: Throw Buzzing Saw Blade 30 yd, line of sight');
