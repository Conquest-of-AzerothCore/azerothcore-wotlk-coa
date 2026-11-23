-- North gate, Dwarven District: Gareth Lindgren steps off the spot Paulo Granger took in #9885, Brother Caesar turns
-- toward the crowd, and Guard Thair Spada stands on the street instead of 0.1 yd inside it.
UPDATE `creature` SET `position_x` = -8348.71, `position_y` = 642.971, `position_z` = 95.4189, `orientation` = 0.7107
    WHERE `guid` = 9920208 AND `id` = 164983;
UPDATE `creature` SET `orientation` = 0.4138 WHERE `guid` = 9920207 AND `id` = 164985;
UPDATE `creature` SET `position_z` = 95.5 WHERE `guid` = 9920212 AND `id` = 164980;
