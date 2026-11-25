-- Preserve the in-game placement clear of the Stormwind Callboard pillars.
UPDATE `creature`
SET `position_x` = -8829.06, `position_y` = 635.029, `position_z` = 94.5892, `orientation` = 0.768465
WHERE `guid` = 9990501 AND `id` = 9990501 AND `map` = 0;
