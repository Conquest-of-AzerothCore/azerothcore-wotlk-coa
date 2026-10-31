-- Mageroyal 12018230 and Briarthorn 12018231 (#9927, pool 20020589) floated 11.3 yd up in a stone tree in the
-- Barrens; the terrain under (646.04, -1582.78) is 91.68.
UPDATE `gameobject` SET `position_z` = 91.68 WHERE `guid` IN (12018230, 12018231) AND `id` IN (1620, 1621);
