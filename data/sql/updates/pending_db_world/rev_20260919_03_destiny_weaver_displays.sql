-- Destiny Weaver: the ten creatures move to their original display ids.
--
-- The archive records the ten Weavers' models as 449292 (Tav'vin / Tav'ral, troll), 449293
-- (Thrain Galewin / Thrainnor Galestrom, dwarf), 449296 (Elundra Moonsong / Elundrel Moonsinger,
-- night elf), 449297 (Magistrix Benjamin / Magistrix Belanor, blood elf) and 449299 (Galric Olim /
-- Galrin Olemar, human) - the five ids the ten used on the live realm.
--
-- This client's CreatureDisplayInfo.dbc has no rows there, so the ids are added to the table: the
-- server's copy under COA/Data/dbc, and the copy shipped to clients in patch-B. Each added row
-- carries this client's own character-model art for the matching race, which is what the live
-- build's rows were, so the original ids can be used exactly as they were.
--
-- revision rev_20260919_01 already writes these ids for a fresh install; this one is for realms
-- that ran the earlier version of it, which pointed the ten at the nearest existing displays.
--
--   * creature_model_info: a row per added display, copied from the row of the display whose art
--     the new one carries (the core reads bounding radius and combat reach from here and refuses
--     a display it has no row for);
--   * creature_template_model: the ten move to the original ids.

DELETE FROM `creature_model_info` WHERE `DisplayID` IN (449292, 449293, 449296, 449297, 449299);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
SELECT v.`new_id`, m.`BoundingRadius`, m.`CombatReach`, m.`Gender`, m.`DisplayID_Other_Gender`, m.`VerifiedBuild`
FROM (
    SELECT 449292 AS `new_id`, 466910 AS `art_of` UNION ALL   -- troll male
    SELECT 449293, 466900 UNION ALL                           -- dwarf male
    SELECT 449296, 466903 UNION ALL                           -- night elf female
    SELECT 449297, 16046 UNION ALL                            -- blood elf female
    SELECT 449299, 5076                                       -- human male
) AS v
JOIN `creature_model_info` AS m ON m.`DisplayID` = v.`art_of`;

UPDATE `creature_template_model` SET `CreatureDisplayID` = 449292 WHERE `CreatureID` IN (449340, 449350);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 449293 WHERE `CreatureID` IN (449342, 449352);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 449296 WHERE `CreatureID` IN (449345, 449355);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 449297 WHERE `CreatureID` IN (449341, 449351);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 449299 WHERE `CreatureID` IN (449347, 449357);
