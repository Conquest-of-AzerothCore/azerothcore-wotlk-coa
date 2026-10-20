-- So That He May Hear Again (#8276): the Elder Guardian Spirit stood in the circle of power
-- with the bound elementals, in the open, instead of in the Sinister Lair it guards.
--
-- Quest 1660021 sends the player from the cave exit along the winding path to the circle of
-- power; the spirit's Questie-derived position (-223.8 -4128.9 72.938) put it directly among
-- the elementals (161859-161862) and above the cave mouth. Move the spawn into the first
-- stretch of the cave tunnel, on the floor the Sinister Snake spawns already follow
-- (-137.3 -4202.8 41.3 and -135.5 -4212.3 37.1), facing back toward the entrance.

UPDATE `creature` SET
    `position_x` = -136.4,
    `position_y` = -4207.5,
    `position_z` = 39.2,
    `orientation` = 2.4
WHERE `guid` = 9012005 AND `id` = 161792 AND `map` = 1;
