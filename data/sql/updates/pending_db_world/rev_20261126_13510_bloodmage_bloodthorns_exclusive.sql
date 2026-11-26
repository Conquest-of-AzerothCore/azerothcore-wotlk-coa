-- Bloodmage: Bloodthorns (802313 chain, ranks 802313 and 501662-501670) and Greater Bloodthorns (572116)
-- are the single-target and raid-wide forms of the same Shadow damage-shield buff (SpellFamilyName 26,
-- aura 15 SPELL_AURA_DAMAGE_SHIELD). They lacked a spell_group entry, so both auras stacked (#13510).
-- SpellMgr resolves spell_group membership via each chain's first rank (802313 in SpellRank.dbc).
DELETE FROM `spell_group` WHERE `id` = 2100008;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2100008, 802313),
(2100008, 572116);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2100008;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2100008, 4, 'Bloodmage: Bloodthorns and Greater Bloodthorns - exclusive, highest wins');
