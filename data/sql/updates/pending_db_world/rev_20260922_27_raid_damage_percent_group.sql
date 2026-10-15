-- Conductor In Charge (#3910) and the eight other CoA raid damage auras promise "Does not stack with similar
-- effects", but no spell_group held them, so two of them multiplied. Every member carries the same raid effect:
-- SPELL_EFFECT_APPLY_AREA_AURA_RAID with SPELL_AURA_MOD_DAMAGE_PERCENT_DONE, MiscValue 127, 2 + 1 = 3%.
-- Group 2000184 is handled next to the other CoA raid groups in SpellMgr::LoadSpellGroupStackRules, so only the
-- area-aura effect joins the group and each spell's separate personal effect keeps multiplying on its own.
START TRANSACTION;
DELETE FROM `spell_group` WHERE `id` = 2000184;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2000184, 300929),
(2000184, 300944),
(2000184, 300961),
(2000184, 300963),
(2000184, 503738),
(2000184, 520371),
(2000184, 560528),
(2000184, 560534),
(2000184, 560545);
DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 2000184;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2000184, 3, 'Local CoA: only the strongest raid damage percent aura applies');
COMMIT;
