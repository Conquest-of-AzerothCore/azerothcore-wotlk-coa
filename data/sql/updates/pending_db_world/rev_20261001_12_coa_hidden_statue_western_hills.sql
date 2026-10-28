-- A Quiet Life 200081 (Templar, CoA questcache: "Visit the hidden statue in the western mountains of Deathknell")
-- names no point; no QuestSuperTrack row, atlas sighting or cached statue object exists, so the statue and its
-- credit marker are placed by hand (INFERRED). rev_20260923_09 put them on the road up to the Cain Family Estate.
-- They move to a saddle in the western mountains above the village that the author picked in game, as the quest
-- text describes ("hidden away in a gap in the mountain"): on flat open ground (surface.check: slope 4, no walls
-- or models) with its back to the slope, facing down the climb players come up. The credit marker floats just above
-- the 2 yd statue, so it marks the statue and its 8 yd sight check starts clear of the statue's collision.
UPDATE `gameobject` SET `position_x` = 1722.6, `position_y` = 1811, `position_z` = 170.82, `orientation` = 0.1,
    `rotation2` = 0.049979, `rotation3` = 0.99875 WHERE `guid` = 7912409 AND `id` = 9301257;
UPDATE `creature` SET `position_x` = 1722.6, `position_y` = 1811, `position_z` = 173.32
    WHERE `guid` = 9003728 AND `id` = 685037;
