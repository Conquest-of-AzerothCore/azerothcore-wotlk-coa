-- White-Glove Mischief (175022): opening Little Mickey's Flask releases a faint ghostly skull that flies around the
-- Petitioner's Chamber council table (Redthedeer VOD 2026-07-13, wJ2j4NOgjRI 01:24:59 and 01:25:02). Ghostly Skull
-- model 28089 with the realm's Cosmetic - Ghost Visual Blue Fog Transparent 365039; the flight is scripted.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
    `BaseAttackTime`, `RangeAttackTime`, `unit_flags`, `speed_run`, `speed_flight`) VALUES
(9935000, '[TG] Little Mickey''s Flask Skull', 1, 1, 35, 1, 12, 2000, 2000, 33554434, 1.14286, 1.14286)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
    `unit_flags` = VALUES(`unit_flags`), `speed_run` = VALUES(`speed_run`), `speed_flight` = VALUES(`speed_flight`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9935000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9935000, 0, 28089, 1, 1);

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 9935000;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`,
    `InteractionPauseTimer`) VALUES
(9935000, 0, 0, 1, 0, 0, 0, 0);
