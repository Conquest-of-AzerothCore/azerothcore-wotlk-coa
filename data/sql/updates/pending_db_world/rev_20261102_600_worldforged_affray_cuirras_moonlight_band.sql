-- Worldforged pickups reported out of reach or twice (#10804, #10829).

-- #10829 Affray Cuirras, Fray Island main building: 1.9 yd under the floor; raised onto the vmap floor the gameplay
-- harness measures there
UPDATE `gameobject` SET `position_z` = 6.752 WHERE `guid` = 6941387 AND `id` = 1345000;

-- #10804 Moonlight Infused Band (Accumulated Moonlight): a second copy 24 yd from the one at the Ascension pin
DELETE FROM `gameobject` WHERE `guid` = 6941381 AND `id` = 518135;
