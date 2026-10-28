-- Elune's Cradle (#7531): the area 807992 heals allies inside it, but its
-- only effect targets the enemy (TargetA TARGET_UNIT_TARGET_ENEMY), so the
-- positivity heuristic classifies the heal as negative and allies see it
-- among their debuffs. Mark effect 0 positive (SPELL_ATTR0_CU_POSITIVE_EFF0)
-- so the healing aura is displayed as a buff.

DELETE FROM `spell_custom_attr` WHERE `spell_id` = 807992;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(807992, 33554432);
