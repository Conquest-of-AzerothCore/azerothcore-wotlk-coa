-- Possessed Crow perches in NIs_cJRD9YE at 00:57; the raven model supports the sitting stand state.
-- Raven aura 365403 attaches the client's SCD_raven_aura blue/cyan effect to both eyes.
UPDATE `creature_template_model` SET `DisplayScale` = 1
WHERE `CreatureID` = 164944 AND `CreatureDisplayID` = 32546;

DELETE FROM `creature_template_addon` WHERE `entry` = 164944;
INSERT INTO `creature_template_addon` (`entry`, `bytes1`, `bytes2`, `emote`, `auras`)
VALUES (164944, 1, 1, 0, '365403');

UPDATE `creature_addon` AS `addon`
INNER JOIN `creature` AS `spawn` ON `spawn`.`guid` = `addon`.`guid`
SET `addon`.`bytes1` = (`addon`.`bytes1` & 0xFFFFFF00) | 1,
    `addon`.`emote` = 0,
    `addon`.`auras` = IF(
        FIND_IN_SET('365403', REPLACE(TRIM(COALESCE(`addon`.`auras`, '')), ' ', ',')) > 0,
        `addon`.`auras`,
        TRIM(CONCAT(COALESCE(`addon`.`auras`, ''), ' 365403'))
    )
WHERE `spawn`.`id` = 164944;
