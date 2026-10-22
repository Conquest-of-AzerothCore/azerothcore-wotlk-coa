-- #8416 The Gaping Chasm's hive interior is a CoA top-level zone (AreaTable 10132, parent 0) with no
-- `graveyard_zone` row, so a ghost released inside fell back to the default Crossroads (Horde) or Westfall
-- (Alliance) graveyard. Link it to the graveyards of Tanaris (440), as the other CoA interior zones do.
DELETE FROM `graveyard_zone` WHERE `GhostZone` = 10132;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
SELECT `gz`.`ID`, 10132, `gz`.`Faction`, 'The Gaping Chasm - Tanaris graveyards'
FROM `graveyard_zone` `gz` WHERE `gz`.`GhostZone` = 440;
