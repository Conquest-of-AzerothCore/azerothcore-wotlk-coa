-- Prestige Challenge (9930831), #9877: the aura carries the 300% experience bonus the player chose, but its spell
-- attributes make the server count it as negative, so the client lists it among the debuffs instead of the buffs.
-- Mark every effect positive (SPELL_ATTR0_CU_POSITIVE_EFF0 | EFF1 | EFF2).
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 9930831;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (9930831, 234881024);
