-- Stellar Drift 800501 (#10998): the caster's own 3 s aura (effect 0) ticks once at expiry to cast the knockback
-- 800500. That trigger made it count as harmful, so Way of the Goddess 801976 (-25% to harmful magic effects on you)
-- cut it to 2250 ms and it expired before the knockback. SPELL_ATTR0_CU_POSITIVE_EFF0 keeps it beneficial.
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 800501;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (800501, 33554432);
