DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 573071 AND `spell_effect` = 573076 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(573071, 573076, 2, 'CoA Withering Touch - magic vulnerability follows the armor debuff');
