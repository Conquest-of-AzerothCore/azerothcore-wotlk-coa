-- Hero Execution Sentence (#9804): every rank's dummy effect had no handler, so the cast spent mana and started the
-- cooldown without effect. The dummy now applies the rank's Execution Sentence damage over time to an enemy or Stay
-- of Execution healing over time to an ally; when either expires or is dispelled, the rank's final burst follows.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_hero_paladin_execution_sentence',
    'aura_hero_paladin_execution_sentence_burst');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(954817, 'spell_hero_paladin_execution_sentence'),
(954972, 'spell_hero_paladin_execution_sentence'),
(954973, 'spell_hero_paladin_execution_sentence'),
(954974, 'spell_hero_paladin_execution_sentence'),
(954975, 'spell_hero_paladin_execution_sentence'),
(954976, 'spell_hero_paladin_execution_sentence'),
(954977, 'spell_hero_paladin_execution_sentence'),
(954818, 'aura_hero_paladin_execution_sentence_burst'),
(954979, 'aura_hero_paladin_execution_sentence_burst'),
(954980, 'aura_hero_paladin_execution_sentence_burst'),
(954981, 'aura_hero_paladin_execution_sentence_burst'),
(954982, 'aura_hero_paladin_execution_sentence_burst'),
(954983, 'aura_hero_paladin_execution_sentence_burst'),
(954984, 'aura_hero_paladin_execution_sentence_burst'),
(954819, 'aura_hero_paladin_execution_sentence_burst'),
(954985, 'aura_hero_paladin_execution_sentence_burst'),
(954986, 'aura_hero_paladin_execution_sentence_burst'),
(954987, 'aura_hero_paladin_execution_sentence_burst'),
(954988, 'aura_hero_paladin_execution_sentence_burst'),
(954989, 'aura_hero_paladin_execution_sentence_burst'),
(954991, 'aura_hero_paladin_execution_sentence_burst');
