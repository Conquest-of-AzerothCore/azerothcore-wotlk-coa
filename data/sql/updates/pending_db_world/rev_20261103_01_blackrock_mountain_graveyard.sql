DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (10114, 10115);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
SELECT `gz`.`ID`, `z`.`zone`, `gz`.`Faction`, 'Blackrock Mountain - stock Blackrock Mountain graveyards'
FROM `graveyard_zone` `gz`
JOIN (SELECT 10114 AS `zone` UNION ALL SELECT 10115) `z`
WHERE `gz`.`GhostZone` = 25;
