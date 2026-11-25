-- Split each T1 inventory into complete-set pages while retaining the canonical offers.
START TRANSACTION;

INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`)
VALUES
(91000101, 'T1 Normal - Part 1', 60, 60, 35, 128, 1, 7),
(91000102, 'T1 Normal - Part 2', 60, 60, 35, 128, 1, 7),
(91000103, 'T1 Heroic - Part 1', 60, 60, 35, 128, 1, 7),
(91000104, 'T1 Heroic - Part 2', 60, 60, 35, 128, 1, 7),
(91000105, 'T1 Mythic - Part 1', 60, 60, 35, 128, 1, 7),
(91000106, 'T1 Mythic - Part 2', 60, 60, 35, 128, 1, 7),
(91000107, 'T1 Ascended - Part 1', 60, 60, 35, 128, 1, 7),
(91000108, 'T1 Ascended - Part 2', 60, 60, 35, 128, 1, 7)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `npcflag` = VALUES(`npcflag`);

DELETE FROM `npc_vendor` WHERE `entry` BETWEEN 91000101 AND 91000108;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 91000101 + (`v`.`entry` - 91000001) * 2 + CASE WHEN `i`.`ItemSet` <= 211 THEN 0 ELSE 1 END,
    `v`.`slot`, `v`.`item`, `v`.`maxcount`, `v`.`incrtime`, `v`.`ExtendedCost`, `v`.`VerifiedBuild`
FROM `npc_vendor` `v` JOIN `item_template` `i` ON `i`.`entry` = `v`.`item`
WHERE `v`.`entry` BETWEEN 91000001 AND 91000004;

COMMIT;
