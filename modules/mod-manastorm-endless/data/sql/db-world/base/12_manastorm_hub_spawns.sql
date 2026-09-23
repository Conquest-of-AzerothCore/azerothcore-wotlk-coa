-- Manastorm capital hub placements.
--
-- These coordinates are project-authored placements created in-game for the
-- Conquest of AzerothCore reconstruction. They are NOT claimed to be recovered
-- original Ascension Stormwind/Orgrimmar coordinates.
--
-- Required templates are installed by:
--   11_manastorm_hub_vendors.sql
--
--   179538 = Millhouse Manastorm <Manastorm Rewards>
--   179539 = Cogsworth <Manastorm Gadget Vendor>
--    20832 = Teleport Pad (display 1055964)
--
-- GUID SAFETY
-- -----------
-- The requested persistent GUIDs are declared once below so an operator can
-- replace only these values if another world database already uses them.
--
-- The preflight result sets report:
--
--   FREE
--       Nothing currently uses the requested GUID.
--
--   ALREADY PRESENT
--       The expected Manastorm spawn is already installed at this placement.
--       This is safe when re-running the file.
--
--   OCCUPIED - CHOOSE NEW GUID
--       The GUID belongs to another spawn, or the existing row does not match
--       the expected Manastorm placement. Change the corresponding variable
--       below to an unused GUID and run the file again.
--
-- Inserts are deliberately collision-safe. Existing GUIDs are NEVER updated,
-- deleted, or overwritten by this migration.

SET @MS_ORG_COGSWORTH_GUID := 5300689;
SET @MS_ORG_MILLHOUSE_GUID := 5300688;
SET @MS_SW_COGSWORTH_GUID  := 5300685;
SET @MS_SW_MILLHOUSE_GUID  := 5300684;

SET @MS_ORG_PORTAL_GUID := 6901536;
SET @MS_SW_PORTAL_GUID  := 6901535;

-- ---------------------------------------------------------------------------
-- Death/wipe return routing
-- ---------------------------------------------------------------------------
--
-- Native-style failed-run ejection is anchored to the actual capital Teleport
-- Pad spawn, not a duplicated game_tele/XYZ. The Manastorm datastore joins this
-- GUID back to `gameobject` when it loads.
--
-- team_id uses AzerothCore TeamId:
--   0 = Alliance
--   1 = Horde
--
-- z_offset is added to the pad's database Z so resurrected players appear
-- above the platform rather than inside its model. Tune this one value if a
-- client model later proves to need a slightly different standing height.
--
CREATE TABLE IF NOT EXISTS `manastorm_hub_return`
(
    `team_id` TINYINT UNSIGNED NOT NULL,
    `gameobject_guid` BIGINT UNSIGNED NOT NULL,
    `z_offset` FLOAT NOT NULL DEFAULT 1.0,
    PRIMARY KEY (`team_id`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COMMENT='Faction Teleport Pad anchors used only for Manastorm death/wipe ejection';

-- ---------------------------------------------------------------------------
-- Preflight: creature GUID availability
-- ---------------------------------------------------------------------------

SELECT
    desired.`location`,
    desired.`guid` AS `requested_guid`,
    desired.`entry` AS `expected_entry`,
    desired.`map` AS `expected_map`,
    existing.`id` AS `existing_entry`,
    existing.`map` AS `existing_map`,
    CASE
        WHEN existing.`guid` IS NULL THEN
            'FREE'
        WHEN existing.`id` = desired.`entry`
          AND existing.`map` = desired.`map`
          AND ABS(existing.`position_x` - desired.`position_x`) < 0.01
          AND ABS(existing.`position_y` - desired.`position_y`) < 0.01
          AND ABS(existing.`position_z` - desired.`position_z`) < 0.01
          AND ABS(existing.`orientation` - desired.`orientation`) < 0.01
        THEN
            'ALREADY PRESENT'
        ELSE
            'OCCUPIED - CHOOSE NEW GUID'
    END AS `guid_status`
FROM
(
    SELECT
        'Orgrimmar - Cogsworth' AS `location`,
        @MS_ORG_COGSWORTH_GUID AS `guid`,
        179539 AS `entry`,
        1 AS `map`,
        1643.89 AS `position_x`,
        -4431.14 AS `position_y`,
        16.7329 AS `position_z`,
        1.72271 AS `orientation`
    UNION ALL
    SELECT
        'Orgrimmar - Millhouse',
        @MS_ORG_MILLHOUSE_GUID,
        179538,
        1,
        1641.28,
        -4431.54,
        16.604,
        1.72271
    UNION ALL
    SELECT
        'Stormwind - Cogsworth',
        @MS_SW_COGSWORTH_GUID,
        179539,
        0,
        -8891.85,
        588.252,
        93.5254,
        5.70449
    UNION ALL
    SELECT
        'Stormwind - Millhouse',
        @MS_SW_MILLHOUSE_GUID,
        179538,
        0,
        -8893.37,
        585.932,
        93.3443,
        5.70449
) AS desired
LEFT JOIN `creature` AS existing
    ON existing.`guid` = desired.`guid`
ORDER BY desired.`location`;

-- ---------------------------------------------------------------------------
-- Preflight: gameobject GUID availability
-- ---------------------------------------------------------------------------

SELECT
    desired.`location`,
    desired.`guid` AS `requested_guid`,
    desired.`entry` AS `expected_entry`,
    desired.`map` AS `expected_map`,
    existing.`id` AS `existing_entry`,
    existing.`map` AS `existing_map`,
    CASE
        WHEN existing.`guid` IS NULL THEN
            'FREE'
        WHEN existing.`id` = desired.`entry`
          AND existing.`map` = desired.`map`
          AND ABS(existing.`position_x` - desired.`position_x`) < 0.01
          AND ABS(existing.`position_y` - desired.`position_y`) < 0.01
          AND ABS(existing.`position_z` - desired.`position_z`) < 0.01
          AND ABS(existing.`orientation` - desired.`orientation`) < 0.01
        THEN
            'ALREADY PRESENT'
        ELSE
            'OCCUPIED - CHOOSE NEW GUID'
    END AS `guid_status`
FROM
(
    SELECT
        'Orgrimmar - Teleport Pad' AS `location`,
        @MS_ORG_PORTAL_GUID AS `guid`,
        20832 AS `entry`,
        1 AS `map`,
        1648.1 AS `position_x`,
        -4431.11 AS `position_y`,
        16.9532 AS `position_z`,
        2.18527 AS `orientation`
    UNION ALL
    SELECT
        'Stormwind - Teleport Pad',
        @MS_SW_PORTAL_GUID,
        20832,
        0,
        -8888.36,
        590.391,
        93.5542,
        2.21732
) AS desired
LEFT JOIN `gameobject` AS existing
    ON existing.`guid` = desired.`guid`
ORDER BY desired.`location`;

-- ---------------------------------------------------------------------------
-- Capital hub vendor spawns
--
-- INSERT ... SELECT ... WHERE NOT EXISTS is intentional:
-- an occupied GUID is skipped instead of replacing unrelated world content.
-- ---------------------------------------------------------------------------

INSERT INTO `creature`
(
    `guid`,
    `id`,
    `map`,
    `zoneId`,
    `areaId`,
    `spawnMask`,
    `phaseMask`,
    `equipment_id`,
    `position_x`,
    `position_y`,
    `position_z`,
    `orientation`,
    `spawntimesecs`,
    `wander_distance`,
    `currentwaypoint`,
    `curhealth`,
    `curmana`,
    `MovementType`,
    `npcflag`,
    `unit_flags`,
    `dynamicflags`,
    `ScriptName`,
    `VerifiedBuild`,
    `CreateObject`,
    `Comment`
)
SELECT
    @MS_ORG_COGSWORTH_GUID,
    179539,
    1,
    0,
    0,
    1,
    1,
    0,
    1643.89,
    -4431.14,
    16.7329,
    1.72271,
    300,
    0,
    0,
    39375,
    0,
    0,
    0,
    0,
    0,
    '',
    NULL,
    0,
    NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `creature`
    WHERE `guid` = @MS_ORG_COGSWORTH_GUID
);

INSERT INTO `creature`
(
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
    `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`,
    `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`,
    `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`
)
SELECT
    @MS_ORG_MILLHOUSE_GUID, 179538, 1, 0, 0, 1, 1, 0,
    1641.28, -4431.54, 16.604, 1.72271,
    300, 0, 0, 39375, 0, 0, 0, 0, 0, '', NULL, 0, NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `creature`
    WHERE `guid` = @MS_ORG_MILLHOUSE_GUID
);

INSERT INTO `creature`
(
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
    `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`,
    `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`,
    `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`
)
SELECT
    @MS_SW_COGSWORTH_GUID, 179539, 0, 0, 0, 1, 1, 0,
    -8891.85, 588.252, 93.5254, 5.70449,
    300, 0, 0, 39375, 0, 0, 0, 0, 0, '', NULL, 0, NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `creature`
    WHERE `guid` = @MS_SW_COGSWORTH_GUID
);

INSERT INTO `creature`
(
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
    `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`,
    `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`,
    `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`
)
SELECT
    @MS_SW_MILLHOUSE_GUID, 179538, 0, 0, 0, 1, 1, 0,
    -8893.37, 585.932, 93.3443, 5.70449,
    300, 0, 0, 39375, 0, 0, 0, 0, 0, '', NULL, 0, NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `creature`
    WHERE `guid` = @MS_SW_MILLHOUSE_GUID
);

-- ---------------------------------------------------------------------------
-- Capital hub Teleport Pad spawns
-- ---------------------------------------------------------------------------

INSERT INTO `gameobject`
(
    `guid`,
    `id`,
    `map`,
    `zoneId`,
    `areaId`,
    `spawnMask`,
    `phaseMask`,
    `position_x`,
    `position_y`,
    `position_z`,
    `orientation`,
    `rotation0`,
    `rotation1`,
    `rotation2`,
    `rotation3`,
    `spawntimesecs`,
    `animprogress`,
    `state`,
    `ScriptName`,
    `VerifiedBuild`,
    `Comment`
)
SELECT
    @MS_ORG_PORTAL_GUID,
    20832,
    1,
    0,
    0,
    1,
    1,
    1648.1,
    -4431.11,
    16.9532,
    2.18527,
    0,
    0,
    0.887843,
    0.460146,
    300,
    0,
    1,
    '',
    NULL,
    NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `gameobject`
    WHERE `guid` = @MS_ORG_PORTAL_GUID
);

INSERT INTO `gameobject`
(
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `rotation0`, `rotation1`, `rotation2`, `rotation3`,
    `spawntimesecs`, `animprogress`, `state`, `ScriptName`,
    `VerifiedBuild`, `Comment`
)
SELECT
    @MS_SW_PORTAL_GUID, 20832, 0, 0, 0, 1, 1,
    -8888.36, 590.391, 93.5542, 2.21732,
    0, 0, 0.895101, 0.445863,
    300, 0, 1, '', NULL, NULL
WHERE NOT EXISTS
(
    SELECT 1
    FROM `gameobject`
    WHERE `guid` = @MS_SW_PORTAL_GUID
);


-- ---------------------------------------------------------------------------
-- Bind death/wipe returns to the actual Teleport Pad spawn GUIDs
-- ---------------------------------------------------------------------------
--
-- The SELECT guards matter: a GUID collision must never make Manastorm point
-- at unrelated world content. The mapping is created/updated only if the GUID
-- currently resolves to the exact expected Teleport Pad placement.
--
INSERT INTO `manastorm_hub_return`
(
    `team_id`,
    `gameobject_guid`,
    `z_offset`
)
SELECT
    0,
    @MS_SW_PORTAL_GUID,
    1.0
FROM `gameobject`
WHERE `guid` = @MS_SW_PORTAL_GUID
  AND `id` = 20832
  AND `map` = 0
  AND ABS(`position_x` - (-8888.36)) < 0.01
  AND ABS(`position_y` - 590.391) < 0.01
  AND ABS(`position_z` - 93.5542) < 0.01
  AND ABS(`orientation` - 2.21732) < 0.01
ON DUPLICATE KEY UPDATE
    `gameobject_guid` = VALUES(`gameobject_guid`),
    `z_offset` = VALUES(`z_offset`);

INSERT INTO `manastorm_hub_return`
(
    `team_id`,
    `gameobject_guid`,
    `z_offset`
)
SELECT
    1,
    @MS_ORG_PORTAL_GUID,
    1.0
FROM `gameobject`
WHERE `guid` = @MS_ORG_PORTAL_GUID
  AND `id` = 20832
  AND `map` = 1
  AND ABS(`position_x` - 1648.1) < 0.01
  AND ABS(`position_y` - (-4431.11)) < 0.01
  AND ABS(`position_z` - 16.9532) < 0.01
  AND ABS(`orientation` - 2.18527) < 0.01
ON DUPLICATE KEY UPDATE
    `gameobject_guid` = VALUES(`gameobject_guid`),
    `z_offset` = VALUES(`z_offset`);

-- ---------------------------------------------------------------------------
-- Post-run verification
--
-- A clean first installation should now report ALREADY PRESENT for all six
-- requested placements. Any OCCUPIED result still requires choosing a new GUID.
-- ---------------------------------------------------------------------------

SELECT
    desired.`location`,
    desired.`guid`,
    CASE
        WHEN existing.`guid` IS NULL THEN
            'MISSING'
        WHEN existing.`id` = desired.`entry`
          AND existing.`map` = desired.`map`
          AND ABS(existing.`position_x` - desired.`position_x`) < 0.01
          AND ABS(existing.`position_y` - desired.`position_y`) < 0.01
          AND ABS(existing.`position_z` - desired.`position_z`) < 0.01
          AND ABS(existing.`orientation` - desired.`orientation`) < 0.01
        THEN
            'ALREADY PRESENT'
        ELSE
            'OCCUPIED - CHOOSE NEW GUID'
    END AS `final_status`
FROM
(
    SELECT 'Orgrimmar - Cogsworth' AS `location`, @MS_ORG_COGSWORTH_GUID AS `guid`, 179539 AS `entry`, 1 AS `map`, 1643.89 AS `position_x`, -4431.14 AS `position_y`, 16.7329 AS `position_z`, 1.72271 AS `orientation`
    UNION ALL
    SELECT 'Orgrimmar - Millhouse', @MS_ORG_MILLHOUSE_GUID, 179538, 1, 1641.28, -4431.54, 16.604, 1.72271
    UNION ALL
    SELECT 'Stormwind - Cogsworth', @MS_SW_COGSWORTH_GUID, 179539, 0, -8891.85, 588.252, 93.5254, 5.70449
    UNION ALL
    SELECT 'Stormwind - Millhouse', @MS_SW_MILLHOUSE_GUID, 179538, 0, -8893.37, 585.932, 93.3443, 5.70449
) AS desired
LEFT JOIN `creature` AS existing
    ON existing.`guid` = desired.`guid`

UNION ALL

SELECT
    desired.`location`,
    desired.`guid`,
    CASE
        WHEN existing.`guid` IS NULL THEN
            'MISSING'
        WHEN existing.`id` = desired.`entry`
          AND existing.`map` = desired.`map`
          AND ABS(existing.`position_x` - desired.`position_x`) < 0.01
          AND ABS(existing.`position_y` - desired.`position_y`) < 0.01
          AND ABS(existing.`position_z` - desired.`position_z`) < 0.01
          AND ABS(existing.`orientation` - desired.`orientation`) < 0.01
        THEN
            'ALREADY PRESENT'
        ELSE
            'OCCUPIED - CHOOSE NEW GUID'
    END AS `final_status`
FROM
(
    SELECT 'Orgrimmar - Teleport Pad' AS `location`, @MS_ORG_PORTAL_GUID AS `guid`, 20832 AS `entry`, 1 AS `map`, 1648.1 AS `position_x`, -4431.11 AS `position_y`, 16.9532 AS `position_z`, 2.18527 AS `orientation`
    UNION ALL
    SELECT 'Stormwind - Teleport Pad', @MS_SW_PORTAL_GUID, 20832, 0, -8888.36, 590.391, 93.5542, 2.21732
) AS desired
LEFT JOIN `gameobject` AS existing
    ON existing.`guid` = desired.`guid`
ORDER BY `location`;


-- Verify the runtime death/wipe anchors after the spawn checks above.
SELECT
    CASE `r`.`team_id`
        WHEN 0 THEN 'Alliance'
        WHEN 1 THEN 'Horde'
        ELSE CONCAT('Unknown team ', `r`.`team_id`)
    END AS `team`,
    `r`.`gameobject_guid`,
    `g`.`id` AS `gameobject_entry`,
    `g`.`map`,
    `g`.`position_x`,
    `g`.`position_y`,
    `g`.`position_z`,
    `r`.`z_offset`,
    `g`.`position_z` + `r`.`z_offset` AS `player_return_z`
FROM `manastorm_hub_return` AS `r`
LEFT JOIN `gameobject` AS `g`
    ON `g`.`guid` = `r`.`gameobject_guid`
ORDER BY `r`.`team_id`;
