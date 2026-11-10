-- spell_group 2110008 kept one seal per Pyromancer by holding only the Seal of Alysrazor (800196) and Seal
-- of Al'ar (803649) chains (#7705/#7754); Greater Seal of Alysrazor (570170) and Greater Seal of Al'ar (808060)
-- are separate level-58 grants in no spell_group, so they stacked alongside a base-chain seal (#10205).
DELETE FROM `spell_group` WHERE `id` = 2110008;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110008, 800196),
(2110008, 803649),
(2110008, 570170),
(2110008, 808060);
