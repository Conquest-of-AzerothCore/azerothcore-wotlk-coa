-- Flights into Graysky (TaxiNodes 420) from Stormwind (path 1985) and Dun Kazad (path 1988) ended at -7050.46, 1130.10,
-- west of the gryphon tower's floor, so players were dismounted in the air and fell to the hillside below (issues #8070,
-- #9210). End both flights inside the tower on the floor beside Grisalda (measured in game at z 328.56).
-- The Graysky to Dun Kazad flight (path 1987) ended at the edge of Moer Stonefist's roost; end it on the roost floor
-- beside him (measured in game at z 581.32).
DELETE FROM `taxipathnode_dbc` WHERE `ID` IN (39762, 39825, 39807);
INSERT INTO `taxipathnode_dbc` (`ID`, `PathID`, `NodeIndex`, `ContinentID`, `LocX`, `LocY`, `LocZ`, `Flags`, `Delay`, `ArrivalEventID`, `DepartureEventID`) VALUES
(39762, 1985, 19, 0, -7042.01, 1127.80, 328.9, 0, 0, 0, 0),
(39825, 1988, 13, 0, -7042.01, 1127.80, 328.9, 0, 0, 0, 0),
(39807, 1987, 13, 0, -6724.74, -14.41, 581.7, 0, 0, 0, 0);
