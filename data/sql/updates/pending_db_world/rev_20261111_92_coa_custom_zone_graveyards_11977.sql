-- #11977 CoA zones with no parent and no graveyard_zone row, so a ghost released inside fell back to the default
-- Westfall (Alliance) or Barrens (Horde) graveyard, like rev_20261014_32: The Slithering Scar (10134), the Maraudon
-- outer caves (10116), Stillpine Hold (10117), Frostmane Hold (10122), The Noxious Lair (10131), the two Caverns of
-- Time areas (10113, 10145) and the two extra Westfall areas (5614, 5615). Link each to the graveyards of the zone
-- that holds it: Un'Goro Crater (490), Desolace (405), Azuremyst Isle (3524), Dun Morogh (1), Tanaris (440) and
-- Westfall (40).
DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (10134, 10116, 10117, 10122, 10131, 10113, 10145, 5614, 5615);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
SELECT `gz`.`ID`, `m`.`interior`, `gz`.`Faction`, `m`.`name`
FROM `graveyard_zone` `gz`
JOIN (SELECT 10134 AS `interior`, 490 AS `parent`, 'The Slithering Scar - Un''Goro Crater graveyards' AS `name`
      UNION ALL SELECT 10116, 405, 'Maraudon - Desolace graveyards'
      UNION ALL SELECT 10117, 3524, 'Stillpine Hold - Azuremyst Isle graveyards'
      UNION ALL SELECT 10122, 1, 'Frostmane Hold - Dun Morogh graveyards'
      UNION ALL SELECT 10131, 440, 'The Noxious Lair - Tanaris graveyards'
      UNION ALL SELECT 10113, 440, 'Caverns of Time - Tanaris graveyards'
      UNION ALL SELECT 10145, 440, 'Caverns of Time - Tanaris graveyards'
      UNION ALL SELECT 5614, 40, 'Westfall - Westfall graveyards'
      UNION ALL SELECT 5615, 40, 'Westfall - Westfall graveyards') `m` ON `m`.`parent` = `gz`.`GhostZone`;
