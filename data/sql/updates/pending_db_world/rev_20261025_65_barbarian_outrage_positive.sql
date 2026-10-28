-- COA-5998: Outrage (801759) raises the Barbarian's haste and critical strike chance, but its damage-taken effect
-- (aura 87, +30%) made the whole aura count as negative, so the client listed it as a debuff. Mark every effect
-- positive (SPELL_ATTR0_CU_POSITIVE_EFF0 | EFF1 | EFF2).
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 801759;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (801759, 234881024);
