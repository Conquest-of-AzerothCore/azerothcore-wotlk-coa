CREATE TABLE IF NOT EXISTS `coa_dungeon_spell_reach` (
  `spell_id` int unsigned NOT NULL,
  `range_index` int unsigned NOT NULL DEFAULT 0,
  `line_of_sight` tinyint unsigned NOT NULL DEFAULT 0,
  `comment` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_dungeon_spell_reach` WHERE `spell_id` IN (2102536, 2102540, 2102677, 2102679);
INSERT INTO `coa_dungeon_spell_reach` (`spell_id`, `range_index`, `line_of_sight`, `comment`) VALUES
(2102536, 4, 0, 'Jergosh the Invoker, Plugger Spazzring: Immolate 30 yd'),
(2102540, 4, 0, 'Jergosh the Invoker: Incinerate 30 yd'),
(2102677, 4, 1, 'Archmage Arugal: Wrath of Arugal 30 yd, line of sight'),
(2102679, 4, 1, 'Archmage Arugal: Curse of Arugal 30 yd, line of sight');
