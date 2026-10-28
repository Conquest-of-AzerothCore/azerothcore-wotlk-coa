-- #140: Flames of Xoroth (801059 and ranks) carries SpellVisual 194027, whose only kit is a target state kit.
-- Its cast and impact visuals (SpellVisual 989851: cinderflame cast, lava-burst cast hands, fire chest impact)
-- belong to the hidden helper 801003, which the Knight of Xoroth script now casts with every Flames of Xoroth.
-- The helper uses the same implicit target 24 cone, so give it the same 90 degree arc as 801059
-- (rev_20260916_13_flames_of_xoroth_cone.sql); the default 24 degrees would leave the impact visual off enemies
-- the damage reaches.
DELETE FROM `spell_cone` WHERE `ID` = 801003;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES
(801003, 90);
