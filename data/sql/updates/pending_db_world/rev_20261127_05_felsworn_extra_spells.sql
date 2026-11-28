START TRANSACTION;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `ScriptName`) VALUES (9000150, 10, 4398, 'Fel Rift: Stonard', 1, 'go_ascension_felsworn_rift') ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `spell_script_names` WHERE `spell_id` = 704371 AND `ScriptName` = 'aura_ascension_felsworn_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704371, 'aura_ascension_felsworn_lifecycle');
DELETE FROM `spell_group` WHERE `id` = 1078 AND `spell_id` IN (523478, 523495);
DELETE FROM `spell_group` WHERE `id` = 1089 AND `spell_id` IN (523478, 523495);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1089, 523478),
(1089, 523495);
DELETE FROM `spell_group` WHERE `id` = 2110004 AND `spell_id` = 523495;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2110004, 523495);
DELETE FROM `spell_group` WHERE `id` = 1154 AND `spell_id` IN (523478, 523495);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(1154, 523478),
(1154, 523495);
COMMIT;
