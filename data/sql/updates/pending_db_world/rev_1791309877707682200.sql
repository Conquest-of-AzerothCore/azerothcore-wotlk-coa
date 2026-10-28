-- Burrow (806152) transforms the Venomancer into display 15435, model 2206 InvisibleMan, whose client row lacks
-- CreatureModelData flag 0x10, so the weapons stay drawn above the burrow. The row is the client's with that flag;
-- the login patch stream sends model rows that differ from the client's copy.
DELETE FROM `creaturemodeldata_dbc` WHERE `ID` = 2206;
INSERT INTO `creaturemodeldata_dbc`
(`ID`, `Flags`, `ModelName`, `SizeClass`, `ModelScale`, `BloodID`, `FootprintTextureID`, `SoundID`, `CollisionWidth`,
`CollisionHeight`, `MountHeight`, `GeoBoxMinX`, `GeoBoxMinY`, `GeoBoxMinZ`, `GeoBoxMaxX`, `GeoBoxMaxY`, `GeoBoxMaxZ`,
`WorldEffectScale`, `AttachedEffectScale`) VALUES
(2206, 19, 'Creature\InvisibleMan\InvisibleMan.mdx', 1, 1, -1, -1, 2101, 0.6111, 2.031, 0, 1, 1, 1, -1, -1, -1, 1, 1);
