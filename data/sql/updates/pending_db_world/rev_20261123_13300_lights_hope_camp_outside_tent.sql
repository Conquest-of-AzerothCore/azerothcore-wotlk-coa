-- Light's Hope Chapel: the CoA client patch moved the tent over Betina Bigglezink, Carlin Redpath and their campfire.
-- The campfire moves between the two camp chairs the patch placed east of the tent, the two NPCs stand beside it
-- facing it, and Duke Nicholas Zverenhoff rises to the ground his feet clipped into.
UPDATE `creature` SET `position_x` = 2265.85, `position_y` = -5334.19, `position_z` = 86.986, `orientation` = 4.4506
    WHERE `guid` = 69680 AND `id` = 11035;
UPDATE `creature` SET `position_x` = 2264.71, `position_y` = -5338.45, `position_z` = 86.898, `orientation` = 1.309
    WHERE `guid` = 53737 AND `id` = 11063;
UPDATE `creature` SET `position_z` = 86.42 WHERE `guid` = 54754 AND `id` = 11039;
UPDATE `gameobject` SET `position_x` = 2265.28, `position_y` = -5336.32, `position_z` = 87.142
    WHERE `guid` = 45565 AND `id` = 176276;
