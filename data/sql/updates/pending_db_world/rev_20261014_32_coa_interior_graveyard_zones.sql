-- #7648 More CoA interior zones with no parent and no graveyard_zone row, so a ghost released inside fell back to the
-- default Westfall (Alliance) or Barrens (Horde) graveyard: the Deadmines entrance (10135), the Amani Catacombs (10127),
-- Tides Hollow (3569), Twilight Run (3446) and Depthbreaker Hollow (10239). Link each to the graveyards of the zone that
-- holds it: Westfall (40), Ghostlands (3433), Azuremyst Isle (3524), Silithus (1377) and Feralas (357).
DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (10135, 10127, 3569, 3446, 10239);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
SELECT `gz`.`ID`, `m`.`interior`, `gz`.`Faction`, `m`.`name`
FROM `graveyard_zone` `gz`
JOIN (SELECT 10135 AS `interior`, 40 AS `parent`, 'The Deadmines entrance - Westfall graveyards' AS `name`
      UNION ALL SELECT 10127, 3433, 'Amani Catacombs - Ghostlands graveyards'
      UNION ALL SELECT 3569, 3524, 'Tides Hollow - Azuremyst Isle graveyards'
      UNION ALL SELECT 3446, 1377, 'Twilight Run - Silithus graveyards'
      UNION ALL SELECT 10239, 357, 'Depthbreaker Hollow - Feralas graveyards') `m` ON `m`.`parent` = `gz`.`GhostZone`;
