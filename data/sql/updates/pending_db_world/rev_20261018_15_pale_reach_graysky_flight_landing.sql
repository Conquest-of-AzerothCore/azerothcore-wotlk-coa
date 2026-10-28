-- Flights into Graysky (TaxiNodes 420) from Stormwind (path 1985) ended at -7049.98, 1136.11, 332.24: past the edge of the
-- gryphon tower's platform and 3.6 yards above it, so players were dismounted in the air and fell (issue #8070). End that
-- flight on the platform at the point where path 1988 already lands safely.
DELETE FROM `taxipathnode_dbc` WHERE `ID` = 39762;
INSERT INTO `taxipathnode_dbc` (`ID`, `PathID`, `NodeIndex`, `ContinentID`, `LocX`, `LocY`, `LocZ`, `Flags`, `Delay`, `ArrivalEventID`, `DepartureEventID`) VALUES
(39762, 1985, 19, 0, -7050.46, 1130.1, 328.65, 0, 0, 0, 0);
