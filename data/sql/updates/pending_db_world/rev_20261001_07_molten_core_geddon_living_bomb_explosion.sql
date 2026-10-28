-- Baron Geddon's Living Bomb carrier aura (2105702 N / 2105703 H / 2105704 M / 2105705 A) explodes
-- on natural expiry via spell_geddon_living_bomb_explosion_coa (boss_geddon_coa.cpp): Geddon casts the
-- DBC explosion (2105708-11) on hostile units within 5 yd of the carrier, carrier included, then Knock Up
-- 2105712 on the carrier (docs/coa/molten-core.md).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105702, 2105703, 2105704, 2105705) AND `ScriptName` = 'spell_geddon_living_bomb_explosion_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105702, 'spell_geddon_living_bomb_explosion_coa'),
(2105703, 'spell_geddon_living_bomb_explosion_coa'),
(2105704, 'spell_geddon_living_bomb_explosion_coa'),
(2105705, 'spell_geddon_living_bomb_explosion_coa');
