-- Level-60 Naxxramas. The four health ratios follow the live AQ40 C'Thun flex curve.
-- Named bosses and Thaddius's platforms use per-effective-player health. Negative flex rows
-- hold fixed trash and add pools. Large trash uses a compressed budget to leave room for Karazhan.
START TRANSACTION;

CREATE TEMPORARY TABLE `_coa_naxx_combat` (
    `entry` INT UNSIGNED PRIMARY KEY, `level` TINYINT UNSIGNED NOT NULL, `expansion` TINYINT UNSIGNED NOT NULL,
    `fixed_normal` INT UNSIGNED NOT NULL, `hp_d0` INT NOT NULL, `hp_d1` INT NOT NULL,
    `hp_d2` INT NOT NULL, `hp_d3` INT NOT NULL
) ENGINE=InnoDB;

DELETE FROM `_coa_naxx_combat`;
INSERT INTO `_coa_naxx_combat` VALUES
(15928, 63, 1, 0, 2250000, 3000001, 4515263, 6583562),
(15929, 63, 1, 0, 240000, 320000, 481628, 702247),
(15930, 63, 1, 0, 240000, 320000, 481628, 702247),
(15931, 63, 1, 0, 1550000, 2066667, 3110514, 4535343),
(15932, 63, 1, 0, 1800000, 2400001, 3612210, 5266850),
(15936, 63, 1, 0, 1400000, 1866667, 2809497, 4096439),
(15952, 63, 1, 0, 2050000, 2733334, 4113906, 5998357),
(15953, 63, 1, 0, 1450000, 1933334, 2909836, 4242740),
(15954, 63, 1, 0, 1150000, 1533334, 2307801, 3364932),
(15956, 63, 1, 0, 1100000, 1466667, 2207462, 3218631),
(15974, 61, 1, 303500, -12140, -16187, -24362, -35522),
(15975, 61, 1, 303500, -12140, -16187, -24362, -35522),
(15976, 61, 1, 396975, -15879, -21172, -31866, -46462),
(15977, 61, 1, 155825, -6233, -8311, -12508, -18238),
(15978, 61, 1, 396975, -15879, -21172, -31866, -46462),
(15979, 61, 1, 396975, -15879, -21172, -31866, -46462),
(15980, 61, 1, 109075, -4363, -5817, -8756, -12766),
(15981, 61, 1, 109075, -4363, -5817, -8756, -12766),
(15989, 63, 1, 0, 2850000, 3800001, 5719333, 8339179),
(15990, 63, 1, 0, 3800000, 5066668, 7625777, 11118906),
(16011, 63, 1, 0, 2250000, 3000001, 4515263, 6583562),
(16017, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16018, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16020, 61, 1, 249275, -9971, -13295, -20010, -29175),
(16021, 62, 1, 403625, -16145, -21527, -32400, -47241),
(16022, 60, 1, 48150, -1926, -2568, -3865, -5636),
(16024, 60, 1, 150400, -6016, -8021, -12073, -17603),
(16025, 62, 1, 597225, -23889, -31852, -47940, -69900),
(16027, 61, 1, 0, 0, 0, 0, 0),
(16028, 63, 1, 0, 1350000, 1800000, 2709158, 3950137),
(16029, 62, 1, 403625, -16145, -21527, -32400, -47241),
(16034, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16036, 60, 1, 150400, -6016, -8021, -12073, -17603),
(16037, 60, 1, 150400, -6016, -8021, -12073, -17603),
(16056, 60, 1, 15050, -602, -803, -1208, -1761),
(16057, 60, 1, 150400, -6016, -8021, -12073, -17603),
(16060, 63, 1, 0, 1350000, 1800000, 2709158, 3950137),
(16061, 63, 1, 0, 1150000, 1533334, 2307801, 3364932),
(16063, 63, 1, 0, 530000, 706667, 1063595, 1550795),
(16064, 63, 1, 0, 530000, 706667, 1063595, 1550795),
(16065, 63, 1, 0, 530000, 706667, 1063595, 1550795),
(16067, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16082, 60, 1, 0, 0, 0, 0, 0),
(16124, 60, 1, 100000, -4000, -5333, -8027, -11704),
(16125, 61, 1, 230000, -9200, -12267, -18462, -26919),
(16126, 61, 1, 360000, -14400, -19200, -28898, -42135),
(16127, 60, 1, 100000, -4000, -5333, -8027, -11704),
(16137, 60, 1, 0, 0, 0, 0, 0),
(16145, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16146, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16148, 61, 1, 230000, -9200, -12267, -18462, -26919),
(16149, 61, 1, 100000, -4000, -5333, -8027, -11704),
(16150, 61, 1, 360000, -14400, -19200, -28898, -42135),
(16154, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16156, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16163, 61, 1, 359575, -14383, -19177, -28864, -42085),
(16164, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16165, 61, 1, 218175, -8727, -11636, -17513, -25535),
(16167, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16168, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16193, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16194, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16215, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16216, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16236, 61, 1, 155825, -6233, -8311, -12508, -18238),
(16243, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16244, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16286, 60, 1, 18000, -720, -960, -1445, -2107),
(16290, 60, 1, 150400, -6016, -8021, -12073, -17603),
(16297, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16360, 60, 1, 300000, -12000, -16000, -24081, -35112),
(16375, 60, 1, 300250, -12010, -16013, -24101, -35142),
(16400, 60, 1, 0, 0, 0, 0, 0),
(16427, 60, 1, 100000, -4000, -5333, -8027, -11704),
(16428, 60, 1, 450000, -18000, -24000, -36122, -52668),
(16429, 60, 1, 195000, -7800, -10400, -15653, -22823),
(16441, 60, 1, 1600000, -64000, -85333, -128434, -187266),
(16447, 61, 1, 303500, -12140, -16187, -24362, -35522),
(16486, 60, 1, 85000, -3400, -4533, -6823, -9948),
(16505, 61, 1, 359575, -14383, -19177, -28864, -42085),
(16506, 61, 1, 174525, -6981, -9308, -14009, -20427),
(16573, 61, 1, 480000, -19200, -25600, -38530, -56180),
(16698, 60, 1, 18000, -720, -960, -1445, -2107),
(16803, 62, 1, 750000, -30000, -40000, -60204, -87781),
(16981, 61, 1, 218175, -8727, -11636, -17513, -25535),
(16983, 61, 1, 396975, -15879, -21172, -31866, -46462),
(16984, 61, 1, 303500, -12140, -16187, -24362, -35522),
(17055, 60, 1, 28000, -1120, -1493, -2248, -3277),
(29912, 60, 1, 0, 0, 0, 0, 0),
(30071, 62, 1, 597225, -23889, -31852, -47940, -69900),
(30083, 60, 1, 150400, -6016, -8021, -12073, -17603),
(30085, 61, 1, 583950, -23358, -31144, -46874, -68346),
(30549, 63, 1, 0, 530000, 706667, 1063595, 1550795);

-- The scoping list contains only Naxxramas enemies and encounter helpers. Update the linked
-- native difficulty templates too so higher modes keep their existing abilities and appearance.
CREATE TEMPORARY TABLE `_coa_naxx_shared_templates` (
    `entry` INT UNSIGNED PRIMARY KEY
) ENGINE=InnoDB;

INSERT IGNORE INTO `_coa_naxx_shared_templates` (`entry`)
SELECT CASE `mode`.`id`
    WHEN 0 THEN `outside`.`entry`
    WHEN 1 THEN `outside`.`difficulty_entry_1`
    WHEN 2 THEN `outside`.`difficulty_entry_2`
    WHEN 3 THEN `outside`.`difficulty_entry_3`
    END AS `entry`
FROM (
    SELECT DISTINCT `template`.`entry`, `template`.`difficulty_entry_1`,
        `template`.`difficulty_entry_2`, `template`.`difficulty_entry_3`
    FROM `creature` AS `spawn`
    JOIN `creature_template` AS `template` ON `template`.`entry` = `spawn`.`id`
    WHERE `spawn`.`map` <> 533
) AS `outside`
CROSS JOIN (SELECT 0 AS `id` UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) AS `mode`
HAVING `entry` <> 0;

CREATE TEMPORARY TABLE `_coa_naxx_combat_templates` AS
SELECT `template`.`entry`, `profile`.`level`, `profile`.`expansion`, `profile`.`fixed_normal`
FROM `_coa_naxx_combat` AS `profile`
JOIN `creature_template` AS `base` ON `base`.`entry` = `profile`.`entry`
JOIN `creature_template` AS `template`
    ON `template`.`entry` IN (`base`.`entry`, `base`.`difficulty_entry_1`,
        `base`.`difficulty_entry_2`, `base`.`difficulty_entry_3`)
LEFT JOIN `_coa_naxx_shared_templates` AS `shared` ON `shared`.`entry` = `template`.`entry`
WHERE `shared`.`entry` IS NULL AND NOT EXISTS (
    SELECT 1 FROM `creature` AS `outside`
    WHERE `outside`.`map` <> 533 AND `outside`.`id` = `base`.`entry`);

DROP TEMPORARY TABLE `_coa_naxx_shared_templates`;

UPDATE `creature_template` AS `template`
JOIN `_coa_naxx_combat_templates` AS `profile` ON `profile`.`entry` = `template`.`entry`
JOIN `creature_classlevelstats` AS `stats`
    ON `stats`.`level` = `profile`.`level` AND `stats`.`class` = `template`.`unit_class`
SET `template`.`minlevel` = `profile`.`level`, `template`.`maxlevel` = `profile`.`level`,
    `template`.`exp` = `profile`.`expansion`,
    `template`.`HealthModifier` = CASE WHEN `profile`.`fixed_normal` > 0 THEN
        `profile`.`fixed_normal` /
            CASE WHEN `profile`.`expansion` = 0 THEN `stats`.`basehp0` ELSE `stats`.`basehp1` END
        ELSE `template`.`HealthModifier` END;

DELETE FROM `coa_boss_flex`
WHERE `entry` IN (SELECT `entry` FROM `_coa_naxx_combat` WHERE `hp_d0` <> 0)
    AND NOT EXISTS (SELECT 1 FROM `creature` AS `outside`
        WHERE `outside`.`map` <> 533 AND `outside`.`id` = `coa_boss_flex`.`entry`);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`)
SELECT `entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`,
    CASE WHEN `hp_d0` < 0 THEN 'Naxxramas fixed trash or encounter add' ELSE 'Naxxramas flex encounter' END
FROM `_coa_naxx_combat`
WHERE `hp_d0` <> 0
    AND NOT EXISTS (SELECT 1 FROM `creature` AS `outside`
        WHERE `outside`.`map` <> 533 AND `outside`.`id` = `_coa_naxx_combat`.`entry`);

DROP TEMPORARY TABLE `_coa_naxx_combat_templates`;
DROP TEMPORARY TABLE `_coa_naxx_combat`;

COMMIT;
