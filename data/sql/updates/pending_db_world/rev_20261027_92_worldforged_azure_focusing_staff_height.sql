-- Worldforged Azure Focusing Staff pickup (item 410113, GO 96244, guid 6941421, Mazthoril) was recorded on the
-- realm at z 689.612 (rev_20261006_65 lowered 85 open-world rows to terrain height, including this one, which had
-- no recorded-height row of its own: it ended up at 686.3715, inside the stone box, below click/LoS reach).
UPDATE `gameobject` SET `position_z` = 689.612
 WHERE `guid` = 6941421 AND `id` = 96244 AND `map` = 1
   AND `position_x` BETWEEN 6245.5 AND 6246.5 AND `position_y` BETWEEN -4389.8 AND -4388.8
   AND ABS(`position_z` - 686.3715) < 0.01;
