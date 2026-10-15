-- Fel Cone (#365): live CoA splits each Fel Cone into an invisible lootable chest and a separate decorative cone,
-- so the quest sparkle of Seek Redemption! (489) sits on a size 1 object instead of the 2.5-scaled cone.
-- Values: AscensionDB client gameobject caches (coa-alpha, coa-beta, conquest-of-azeroth, free-pick, season-10,
-- warcraft-reborn; captured 2026-09-04..09, ascension-data d6494ceb 2026-09-12) and the SUB gameobject dump
-- (db.exil.es, 2026-10-04): 1673 type 3, display 980926, size 1, Data0 43, Data1 1701, Data3 1; 661673 type 5,
-- display 425, size 2.5, Data0 43. The ascension-data catalogue (d6494ceb) records one Bronzebeard 661673 spawn at
-- 1673 guid 49746's position; Descension wf-real-displays/mapping.tsv (78dcaeeb, 2026-10-07) records the companion
-- 0.00 yd from its chest. The other 61 coincident 661673 spawns are inferred from that pairing.
UPDATE `gameobject_template` SET `displayId` = 980926, `size` = 1 WHERE `entry` = 1673;

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`)
VALUES (661673, 5, 425, 'Fel Cone', 2.5, 43)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 6616730 AND 6616791 AND `id` = 661673;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
    `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
    `animprogress`, `state`)
SELECT 6616730 + `guid` - 49739, 661673, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
    `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
    `animprogress`, `state`
FROM `gameobject` WHERE `id` = 1673 AND `guid` BETWEEN 49739 AND 49800;
