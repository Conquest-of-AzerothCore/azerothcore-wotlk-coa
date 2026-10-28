-- Worldforged Old Insignia (#9185): a later LootCollector-alignment pass overwrote the Scarlet
-- Insignia pickup's (guid 6941016) 2026-09-26 in-game audited spot on the Crusader Outpost floor
-- with a terrain-level position about 4.4 yd below it, where Captain Perrine and the Scarlet
-- Neophyte stand. Restore the audited spot, guarded on the current LootCollector-alignment
-- coordinates so a newer correction is never overwritten.
UPDATE `gameobject` SET `position_x` = 1803.41, `position_y` = 727.664, `position_z` = 49.4158
WHERE `guid` = 6941016 AND `id` = 515377 AND `map` = 0
  AND `position_x` BETWEEN 1789.8 AND 1790.8 AND `position_y` BETWEEN 724.2 AND 725.2;
