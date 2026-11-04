-- The GatherMate import (#9555) placed the Gold Vein and Mithril Deposit spot in the Circle of Inner Binding 7.5 yd
-- above the terrain, on top of the stone-circle model where nobody can reach it (#10789). Set both rows on the
-- terrain height read from the server .map files at their position.
UPDATE `gameobject` SET `position_z` = 16.58
WHERE `guid` IN (12008835, 12008836) AND `id` IN (1734, 2040) AND `map` = 0 AND `position_z` BETWEEN 24.08 AND 24.10;
