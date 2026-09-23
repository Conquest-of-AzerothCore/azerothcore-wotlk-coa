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
