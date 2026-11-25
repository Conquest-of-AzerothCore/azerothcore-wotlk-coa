-- #13418: Dustwallow Tree 8001126 (rev_20260928_82) stood in Mulgore at The Venture Co. Mine. Remove it, as
-- rev_20260930_92 removed Dustwallow Tree 8001129.
DELETE FROM `gameobject`
WHERE `guid` = 8001126 AND `id` = 1244625 AND `map` = 1 AND `position_x` BETWEEN -2085.2 AND -2085.1;
DELETE FROM `gameobject_addon` WHERE `guid` = 8001126;
