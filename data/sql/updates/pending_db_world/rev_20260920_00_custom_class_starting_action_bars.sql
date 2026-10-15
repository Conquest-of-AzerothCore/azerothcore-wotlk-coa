-- #3977 seeded only the old ascension_custom_class_race whitelist, missing 86 supported race/class pairs.
-- Use playercreateinfo for actual availability; retain the original active starter spell IDs and button order.
-- Include Attack for the expanded races, which also lack button 0. Existing character bars are unaffected.
DELETE FROM `playercreateinfo_action` WHERE `class` BETWEEN 12 AND 32 AND `button` BETWEEN 0 AND 4;
INSERT INTO `playercreateinfo_action`
    (`race`, `class`, `button`, `action`, `type`)
SELECT `race`, `class`, 0, 6603, 0
FROM `playercreateinfo`
WHERE `class` BETWEEN 12 AND 32
UNION ALL
SELECT `races`.`race`, `starts`.`class`, `starts`.`button`, `starts`.`action`, 0
FROM `playercreateinfo` AS `races`
INNER JOIN (
    SELECT 12 AS `class`, 1 AS `button`, 801576 AS `action`
    UNION ALL SELECT 12 AS `class`, 2 AS `button`, 804136 AS `action`
    UNION ALL SELECT 13 AS `class`, 1 AS `button`, 801670 AS `action`
    UNION ALL SELECT 13 AS `class`, 2 AS `button`, 807037 AS `action`
    UNION ALL SELECT 14 AS `class`, 1 AS `button`, 801901 AS `action`
    UNION ALL SELECT 14 AS `class`, 2 AS `button`, 802060 AS `action`
    UNION ALL SELECT 15 AS `class`, 1 AS `button`, 802024 AS `action`
    UNION ALL SELECT 15 AS `class`, 2 AS `button`, 804179 AS `action`
    UNION ALL SELECT 16 AS `class`, 1 AS `button`, 500040 AS `action`
    UNION ALL SELECT 16 AS `class`, 2 AS `button`, 804020 AS `action`
    UNION ALL SELECT 17 AS `class`, 1 AS `button`, 500904 AS `action`
    UNION ALL SELECT 17 AS `class`, 2 AS `button`, 800168 AS `action`
    UNION ALL SELECT 17 AS `class`, 3 AS `button`, 801016 AS `action`
    UNION ALL SELECT 18 AS `class`, 1 AS `button`, 800311 AS `action`
    UNION ALL SELECT 18 AS `class`, 2 AS `button`, 802197 AS `action`
    UNION ALL SELECT 18 AS `class`, 3 AS `button`, 803417 AS `action`
    UNION ALL SELECT 19 AS `class`, 1 AS `button`, 801443 AS `action`
    UNION ALL SELECT 19 AS `class`, 2 AS `button`, 803157 AS `action`
    UNION ALL SELECT 20 AS `class`, 1 AS `button`, 500125 AS `action`
    UNION ALL SELECT 20 AS `class`, 2 AS `button`, 802310 AS `action`
    UNION ALL SELECT 21 AS `class`, 1 AS `button`, 500074 AS `action`
    UNION ALL SELECT 21 AS `class`, 2 AS `button`, 800083 AS `action`
    UNION ALL SELECT 21 AS `class`, 3 AS `button`, 802036 AS `action`
    UNION ALL SELECT 22 AS `class`, 1 AS `button`, 801303 AS `action`
    UNION ALL SELECT 22 AS `class`, 2 AS `button`, 804418 AS `action`
    UNION ALL SELECT 23 AS `class`, 1 AS `button`, 500970 AS `action`
    UNION ALL SELECT 23 AS `class`, 2 AS `button`, 500985 AS `action`
    UNION ALL SELECT 23 AS `class`, 3 AS `button`, 504868 AS `action`
    UNION ALL SELECT 23 AS `class`, 4 AS `button`, 801722 AS `action`
    UNION ALL SELECT 24 AS `class`, 1 AS `button`, 800790 AS `action`
    UNION ALL SELECT 24 AS `class`, 2 AS `button`, 800792 AS `action`
    UNION ALL SELECT 25 AS `class`, 1 AS `button`, 500720 AS `action`
    UNION ALL SELECT 25 AS `class`, 2 AS `button`, 800413 AS `action`
    UNION ALL SELECT 26 AS `class`, 1 AS `button`, 800496 AS `action`
    UNION ALL SELECT 26 AS `class`, 2 AS `button`, 801127 AS `action`
    UNION ALL SELECT 26 AS `class`, 3 AS `button`, 801132 AS `action`
    UNION ALL SELECT 27 AS `class`, 1 AS `button`, 500143 AS `action`
    UNION ALL SELECT 27 AS `class`, 2 AS `button`, 800231 AS `action`
    UNION ALL SELECT 28 AS `class`, 1 AS `button`, 500239 AS `action`
    UNION ALL SELECT 28 AS `class`, 2 AS `button`, 500549 AS `action`
    UNION ALL SELECT 28 AS `class`, 3 AS `button`, 805351 AS `action`
    UNION ALL SELECT 29 AS `class`, 1 AS `button`, 800869 AS `action`
    UNION ALL SELECT 29 AS `class`, 2 AS `button`, 805776 AS `action`
    UNION ALL SELECT 30 AS `class`, 1 AS `button`, 500357 AS `action`
    UNION ALL SELECT 30 AS `class`, 2 AS `button`, 500376 AS `action`
    UNION ALL SELECT 30 AS `class`, 3 AS `button`, 573316 AS `action`
    UNION ALL SELECT 31 AS `class`, 1 AS `button`, 500402 AS `action`
    UNION ALL SELECT 31 AS `class`, 2 AS `button`, 800140 AS `action`
    UNION ALL SELECT 32 AS `class`, 1 AS `button`, 653022 AS `action`
    UNION ALL SELECT 32 AS `class`, 2 AS `button`, 707141 AS `action`
) AS `starts`
    ON `starts`.`class` = `races`.`class`;
