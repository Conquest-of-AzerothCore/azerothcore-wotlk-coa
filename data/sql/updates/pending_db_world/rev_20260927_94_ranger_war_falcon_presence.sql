-- War Falcon presence 680278 ('You have a War Falcon active! Generating 1 Focus per second.') is two
-- SPELL_EFFECT_APPLY_AREA_AURA_OWNER effects from TARGET_UNIT_CASTER, radius index 12 (100 yd): a dummy counter and a
-- PERIODIC_ENERGIZE of 1 Focus every 1000 ms, which only a falcon casting it on itself can hand to its Ranger.
-- No spell triggers 680278 and no falcon template carried it, so an active War Falcon never generated Focus.
-- Falcon's Call summons 50264; Falcon Dive, Falcon Diving, Falcon's Aid, Falconstrike and Phoenix Plumes summon 50393.
DELETE FROM `creature_template_addon` WHERE `entry` IN (50264, 50393);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
`visibilityDistanceType`, `auras`) VALUES
(50264, 0, 0, 0, 0, 0, 0, '680278'),
(50393, 0, 0, 0, 0, 0, 0, '680278');
