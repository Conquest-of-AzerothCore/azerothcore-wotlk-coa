-- Great Goretusk 90359 spawned in the Sentinel Hill courtyard and wandered through the walls. Move it outside the
-- walls onto open ground, clear of buildings for its 5 yd wander radius.

UPDATE `creature` SET `position_x` = -10746.47, `position_y` = 934.235, `position_z` = 39.501, `orientation` = 5.1206
  WHERE `guid` = 90359 AND `id` = 547;
