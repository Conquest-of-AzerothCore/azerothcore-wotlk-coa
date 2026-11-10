-- rev_1792975384724126100.sql (#9226) lands the Stormwind and Dun Kazad flights inside the Graysky tower and the
-- Graysky flight on Moer Stonefist's roost, but the updater applies pending files in filename order, so on a database
-- built from scratch rev_20261018_15 and rev_20261018_80 run after it and restore the old landing points that dismount
-- players in the air (#9615). Re-state the #9226 landing nodes after both.
DELETE FROM `taxipathnode_dbc` WHERE `ID` IN (39762, 39825, 39807);
INSERT INTO `taxipathnode_dbc` (`ID`, `PathID`, `NodeIndex`, `ContinentID`, `LocX`, `LocY`, `LocZ`, `Flags`, `Delay`, `ArrivalEventID`, `DepartureEventID`) VALUES
(39762, 1985, 19, 0, -7042.01, 1127.80, 328.9, 0, 0, 0, 0),
(39825, 1988, 13, 0, -7042.01, 1127.80, 328.9, 0, 0, 0, 0),
(39807, 1987, 13, 0, -6724.74, -14.41, 581.7, 0, 0, 0, 0);
