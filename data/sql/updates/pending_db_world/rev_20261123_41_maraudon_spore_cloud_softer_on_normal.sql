-- Maraudon: Spore Cloud from the Spore Trees deals 25% less damage on Normal; Heroic and Mythic keep their damage.
DELETE FROM `coa_dungeon_normal_spell_damage` WHERE `spell_id` = 21547;
INSERT INTO `coa_dungeon_normal_spell_damage` (`spell_id`, `normal_spell_id`, `high`, `comment`) VALUES
(21547, 0, 0.75, 'Spore Cloud (Maraudon Spore Trees): 25% softer on Normal');
