-- Wilder Thistlenettle and Brohann Caskbelly were moved out of their Dwarven District hall onto the canal-side knoll in
-- rev_20260923_03_coa_stormwind, because the terrain under the hall reads as canal water (ground 92, water 95.46). The hall
-- floor is a building at 99.9-100.6, above that water, and the knoll spot is behind walls: players report Thistlenettle
-- unreachable (#7397, #7448, #7890). Both go back to the CoA world baseline and live server spots in the hall.
UPDATE `creature` SET `position_x` = -8469, `position_y` = 501.28, `position_z` = 99.912, `orientation` = 1.801 WHERE `guid` = 2435 AND `id` = 656;
UPDATE `creature` SET `position_x` = -8464, `position_y` = 516.193, `position_z` = 100.639, `orientation` = 3.264 WHERE `guid` = 35221 AND `id` = 5384;
