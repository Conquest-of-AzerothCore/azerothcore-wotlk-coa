-- Spindlebind (800887, ranks 502890-502895, Tunneler 504706) webs enemies behind the caster (issue 7280).
-- The client's SpellCustomAttr.dbc sets 2 = SPELL_ATTR0_CU_CONE_BACK for each of these ids.
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (800887, 502890, 502891, 502892, 502893, 502894, 502895, 504706);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(800887, 2),
(502890, 2),
(502891, 2),
(502892, 2),
(502893, 2),
(502894, 2),
(502895, 2),
(504706, 2);
