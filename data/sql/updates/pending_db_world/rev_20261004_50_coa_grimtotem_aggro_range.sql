-- Starting-zone hostiles detect players at 10 yd (Bristleback Quilboar, Battleboar, Kobold Vermin, Rockjaw Trogg);
-- the Three Totems Grimtotems kept the 20 yd default and pulled from twice as far.
UPDATE `creature_template` SET `detection_range` = 10
    WHERE `entry` IN (161809, 161810, 161814, 161815, 161837);
