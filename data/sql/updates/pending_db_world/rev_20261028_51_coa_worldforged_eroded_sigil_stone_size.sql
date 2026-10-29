-- Worldforged Eroded Sigil Stone (#9041): display 1025463 (be_runestone01.m2) is 20.29 yd tall at
-- scale 1.0. #6146 brought the size down from 1.0 to 0.4 (still 8.1 yd, about 6.6x the median
-- apparent height of comparable worldforged pickups). 0.06 brings it to about 1.22 yd.
UPDATE `gameobject_template` SET `size` = 0.06
WHERE `entry` = 254162
  AND ABS(`size` - 0.4) < 0.001;
