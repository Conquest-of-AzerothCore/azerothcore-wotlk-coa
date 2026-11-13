CREATE TABLE IF NOT EXISTS `coa_dungeon_spell_reach` (
  `spell_id` int unsigned NOT NULL,
  `range_index` int unsigned NOT NULL DEFAULT 0,
  `line_of_sight` tinyint unsigned NOT NULL DEFAULT 0,
  `comment` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_dungeon_spell_reach` WHERE `spell_id` IN (2102781, 2100732, 2100709, 2102215, 2100189, 22994);
INSERT INTO `coa_dungeon_spell_reach` (`spell_id`, `range_index`, `line_of_sight`, `comment`) VALUES
(2102781, 0, 1, 'Death Speaker Jargba: Shadow Bolt Volley needs line of sight'),
(2100732, 0, 1, 'Landslide: Hurl Boulder needs line of sight'),
(2100709, 0, 1, 'Amnennar the Coldbringer: Steal Warmth needs line of sight'),
(2102215, 0, 1, 'Mother Smolderweb: Mother''s Milk needs line of sight'),
(2100189, 0, 1, 'Stomper Kreeg: Booze Spit needs line of sight'),
(22994, 0, 1, 'Tendris Warpwood: Entangle needs line of sight');
