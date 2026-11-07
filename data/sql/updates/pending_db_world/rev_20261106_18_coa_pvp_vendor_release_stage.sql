-- Season 1 PvP vendors by release phase. The worldserver starts these internal events at startup and on
-- .reload config from Ascension.PvPVendors.ReleaseStage (coa.conf): 197 from stage 1 holds the phase 1 vendors of
-- rev_20261106_17, 198 from stage 2 the phase 2 vendors of rev_20261008_02 and rev_20261008_03.
DELETE FROM `game_event` WHERE `eventEntry` IN (197, 198);
INSERT INTO `game_event` (`eventEntry`, `description`, `world_event`, `announce`) VALUES
(197, 'Conquest of Azeroth - PvP Season 1 Phase 1 Vendors', 5, 0),
(198, 'Conquest of Azeroth - PvP Season 1 Phase 2 Vendors', 5, 0);
DELETE FROM `game_event_creature` WHERE `eventEntry` IN (197, 198) OR `guid` IN (9948051, 9948052, 9966682, 9949050,
9949051, 9966683, 9948053, 9948066, 9949053, 9949066);
INSERT INTO `game_event_creature` (`eventEntry`, `guid`) VALUES
(197, 9948051),
(197, 9948052),
(197, 9966682),
(197, 9949050),
(197, 9949051),
(197, 9966683),
(198, 9948053),
(198, 9948066),
(198, 9949053),
(198, 9949066);
