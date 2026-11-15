-- #11558 Accelerate (572633-572635) and Decelerate (572632) show as debuffs when a Chronomancer casts them on themself
--
-- Accelerate raises damage and healing taken (aura 14 with a positive value, aura 115) and Decelerate lowers them
-- (aura 87 and aura 118 with negative values). Both are party buffs on TARGET_UNIT_TARGET_RAID, like Amplify Magic
-- 1008 and Dampen Magic 604 whose spell_custom_attr rows carry the same attribute value. SpellMgr marked the
-- damage-taken effect of Accelerate and the healing effect of Decelerate negative, and a self-cast aura with one
-- negative effect is listed as a debuff. Mark both effects of every rank positive
-- (SPELL_ATTR0_CU_POSITIVE_EFF0 | SPELL_ATTR0_CU_POSITIVE_EFF1).
START TRANSACTION;
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (572632, 572633, 572634, 572635);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(572632, 100663296),
(572633, 100663296),
(572634, 100663296),
(572635, 100663296);
COMMIT;
