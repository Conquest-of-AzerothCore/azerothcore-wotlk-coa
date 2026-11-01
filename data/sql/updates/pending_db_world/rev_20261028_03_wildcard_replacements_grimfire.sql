-- Arcane Thunder and Grimfire use their own lifecycle controllers, replacing only their generic proc bindings.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (276693, 278016)
AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 276693 AND `ScriptName` = 'aura_wildcard_arcane_thunder';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (276693, 'aura_wildcard_arcane_thunder');
DELETE FROM `spell_script_names` WHERE `spell_id` = 760000 AND `ScriptName` = 'aura_wildcard_flame_ascendance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (760000, 'aura_wildcard_flame_ascendance');
DELETE FROM `spell_script_names` WHERE `spell_id` = 278016 AND `ScriptName` = 'aura_wildcard_grimfire';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (278016, 'aura_wildcard_grimfire');
DELETE FROM `spell_script_names` WHERE `spell_id` = 278015 AND `ScriptName` = 'spell_wildcard_grimfire_projectile';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (278015, 'spell_wildcard_grimfire_projectile');
DELETE FROM `spell_ranks` WHERE `first_spell_id` IN (276711, 760123);
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(276711, 276711, 1),
(276711, 276712, 2),
(276711, 276713, 3),
(276711, 276714, 4),
(276711, 276715, 5),
(276711, 276716, 6),
(276711, 276717, 7),
(276711, 276718, 8),
(276711, 276719, 9),
(276711, 276720, 10),
(276711, 276721, 11),
(276711, 276722, 12),
(276711, 276723, 13),
(276711, 276724, 14),
(760123, 760123, 1),
(760123, 760242, 2),
(760123, 760124, 3),
(760123, 760125, 4),
(760123, 760126, 5),
(760123, 760127, 6),
(760123, 760128, 7),
(760123, 760129, 8),
(760123, 760130, 9);
DELETE FROM `spell_bonus_data` WHERE `entry` IN (278015, 760123, 760242, 760124, 760125, 760126, 760127, 760128, 760129, 760130);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(278015, 0.367, 0, 0.238, 0, 'Wildcard Grimfire secondary projectile'),
(760123, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 1'),
(760242, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 2'),
(760124, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 3'),
(760125, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 4'),
(760126, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 5'),
(760127, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 6'),
(760128, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 7'),
(760129, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 8'),
(760130, 0.3792, 0, 0.2465, 0, 'Wildcard Lava Beam rank 9');
