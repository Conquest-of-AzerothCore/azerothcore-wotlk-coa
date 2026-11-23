CREATE TABLE IF NOT EXISTS `coa_dungeon_spell_reach` (
  `spell_id` int unsigned NOT NULL,
  `range_index` int unsigned NOT NULL DEFAULT 0,
  `line_of_sight` tinyint unsigned NOT NULL DEFAULT 0,
  `comment` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_dungeon_spell_reach` WHERE `spell_id` IN (2102658, 2102527, 2102544, 2102632, 2102502, 2102504, 2102710, 2102698, 2102542, 2102726, 2102604, 2102779, 92578, 2102653, 2102647, 2101002, 2102722, 2102724, 22709);
INSERT INTO `coa_dungeon_spell_reach` (`spell_id`, `range_index`, `line_of_sight`, `comment`) VALUES
(2102658, 4, 0, 'Baron Silverlaine: Veil of Shadow 30 yd'),
(2102527, 4, 0, 'Bazzalan, Cookie: Throw Poison Vial 30 yd'),
(2102544, 4, 0, 'Thalnos, Jargba, Plugger Spazzring, Ragglesnout, Zum''rah: Shadow Bolt 30 yd'),
(2102632, 4, 0, 'Brightwing: Fae Magic 30 yd'),
(2102502, 4, 0, 'Charlga Razorflank: Chain Lightning 30 yd'),
(2102504, 4, 0, 'Electrocutioner 6000, Oggleflint, Skum: Chain Lightning 30 yd'),
(2102710, 4, 0, 'Halmgar, Argelmach, Grimlok, Lorgus Jett, Revelosh: Lightning Bolt 30 yd'),
(2102698, 4, 0, 'Gelihast: Throw Net 30 yd'),
(2102542, 4, 0, 'Hydromancer Velratha: Shadow Bolt 30 yd'),
(2102726, 4, 0, 'Interrogator Vishas, Ragglesnout: Shadow Word: Pain 30 yd'),
(2102604, 4, 0, 'Anacondra, Cobrahn, Serpentis: Lightning Bolt 30 yd'),
(2102779, 4, 0, 'Death Speaker Jargba: Dominate Mind 30 yd'),
(92578, 4, 0, 'Ramstein the Gorger: Flesh Hook 30 yd'),
(2102653, 4, 0, 'Razorclaw the Butcher: Throw Cleaver 30 yd'),
(2102647, 4, 0, 'Rethilgore: Siphon Life 30 yd'),
(2101002, 4, 0, 'Seeth''rel: Frostbolt 30 yd'),
(2102722, 4, 0, 'Twilight Lord Kelris: Mind Blast 30 yd'),
(2102724, 4, 0, 'Twilight Lord Kelris: Shadow Word: Pain 30 yd'),
(22709, 4, 0, 'Lethtendris: Void Bolt 30 yd');
