-- #10710 Custom-class single-target Intellect buffs stack with Arcane Intellect and with each other.
-- Maintainer decision (2026-11-15): they follow the vanilla "Single Intellect Buffs" group 1083
-- (SPELL_GROUP_STACK_RULE_EXCLUSIVE_HIGHEST), so only the strongest Intellect buff stays on a target.
-- Each class family joins 1083 as its own subgroup, like Arcane Intellect (-1072) and Scroll of Intellect (-1068):
-- SpellMgr::CheckSpellGroupStackRules skips a common group when both spells share one of its subgroups, so the
-- existing per-caster rules within a family (1135, 1150, 1171, 2110008) still decide those pairs.
-- 2110710 Celestial Mind (Starcaller), 2110711 Nozdormu's Wisdom (Chronomancer),
-- 2110712 Call of the Storm (Stormbringer), 2110713 Seal of Alysrazor (Pyromancer); first ranks plus the
-- unranked Greater raid forms.
START TRANSACTION;

DELETE FROM `spell_group` WHERE `id` IN (2110710, 2110711, 2110712, 2110713);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110710, 300255),
(2110710, 680301),
(2110711, 572391),
(2110711, 572396),
(2110712, 578311),
(2110712, 578316),
(2110713, 800196),
(2110713, 570170);

DELETE FROM `spell_group` WHERE `id` = 1083 AND `spell_id` IN (-2110710, -2110711, -2110712, -2110713);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1083, -2110710),
(1083, -2110711),
(1083, -2110712),
(1083, -2110713);

COMMIT;
