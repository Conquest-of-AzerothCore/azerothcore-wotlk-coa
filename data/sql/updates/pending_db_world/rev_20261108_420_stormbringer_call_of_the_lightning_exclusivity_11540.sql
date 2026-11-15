-- #11540 Call of the Lightning and Greater Call of the Lightning both stay on the buff bar
--
-- Greater Call of the Lightning (575846) is the raid-wide form of Call of the Lightning (ranks 575843-575845):
-- the same SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE aura (MiscValue 126) of 20 resistance for the same duration, with
-- TARGET_UNIT_CASTER_AREA_RAID in place of TARGET_UNIT_TARGET_ALLY. The ranks are one spell_ranks chain, but 575846
-- is unranked and in no spell_group, so nothing removes the other form and both auras stay on the recipient. Same
-- shape as the Greater Calls of the Storm and of the Wind (group 1171, #10238): a Greater buff is the same family as
-- its normal form. The Call of the Lightning family gets its own group so it does not become exclusive with the
-- Calls of the Storm and of the Wind.
START TRANSACTION;

DELETE FROM `spell_group` WHERE `id` = 1172;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1172, 575843),
(1172, 575844),
(1172, 575845),
(1172, 575846);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` = 1172;
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(1172, 2, 'Local CoA: one Call of the Lightning (including the Greater raid form) per caster on each recipient');

COMMIT;
