-- #13423: Phin Odelic (2711) stood 0.44 yd sunk into the Southshore ground. Raise spawn 15325 onto the
-- ground height measured from the server maps (10.587), where the reporter stood.
UPDATE `creature` SET `position_z` = 10.587
WHERE `guid` = 15325 AND `id` = 2711 AND `map` = 0 AND `position_z` BETWEEN 10.094 AND 10.194;
