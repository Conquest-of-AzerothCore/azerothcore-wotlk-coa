-- #4086 The CoA client splits each starting valley into its own top-level zone (AreaTable 10138-10144, 10146). The
-- graveyard links sit on the stock parent zones, so a death in a valley found no link and fell back to the default
-- Barrens (Horde) or Westfall (Alliance) graveyard. Link each valley to its own start graveyard for both factions,
-- since any race can start in any valley.
DELETE FROM `graveyard_zone` WHERE `GhostZone` IN (10138, 10139, 10140, 10141, 10142, 10143, 10144, 10146);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(105, 10138, 0, 'Northshire Valley - Elwynn Forest, Northshire'),
(100, 10139, 0, 'Coldridge Valley - Dun Morogh, Anvilmar'),
(94, 10140, 0, 'Deathknell - Tirisfal Glades, Deathknell'),
(912, 10141, 0, 'Sunstrider Isle - Eversong Woods, Sunstrider Isle'),
(918, 10142, 0, 'Ammen Vale - Azuremyst Isle, Ammen Vale'),
(93, 10143, 0, 'Shadowglen - Teldrassil, Aldrassil'),
(709, 10144, 0, 'Valley of Trials - Durotar, Valley of Trials'),
(34, 10146, 0, 'Red Cloud Mesa - Mulgore, Red Cloud Mesa');
