-- Catacombs Torch (#8806): the recorded height pass left the Duskwood crypt pickup (gameobject
-- guid 6940225, entry 90282) floating 2.51 yd above the crypt floor (confirmed with the gameplay
-- harness's own ground probe: spawn_ground_gap +2.511553, floor 16.055). Lower it onto the
-- floor; XY and orientation are unchanged.

UPDATE `gameobject`
SET `position_z` = 16.06
WHERE `guid` = 6940225 AND `id` = 90282 AND `map` = 0 AND `position_z` BETWEEN 18.5 AND 18.6;
