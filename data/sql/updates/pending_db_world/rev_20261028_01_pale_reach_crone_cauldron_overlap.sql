-- Pale Reach, Three Sisters Hollow (#9392): rev_20261017_76 moved Crone (creature guid 9920731, id 164590,
-- quest 175203 'The Three Sisters' Wisdom') to (-7485.93, 663.958, 239.124), 1.06 yd (2D) from the quest
-- cauldron (gameobject id 2300715/2309001, guid 9992006/9999301, at -7485.35, 663.074, 238.599 from
-- rev_20261009_62), putting her inside the pot's model, as reported. Her sisters stand clear of it: Maiden
-- (9920732, untouched) 5.70 yd away, Mother (9920733, untouched) 3.49 yd away. Restore Crone to her original
-- SpawnHelper capture from rev_20261009_62 (-7485.6, 665.8, 238.333, o=4.804), 2.74 yd from the cauldron,
-- clear of it and within the sisters' spacing pattern.
UPDATE `creature` SET `position_x` = -7485.6, `position_y` = 665.8, `position_z` = 238.333, `orientation` = 4.804
  WHERE `guid` = 9920731 AND `id` = 164590;
