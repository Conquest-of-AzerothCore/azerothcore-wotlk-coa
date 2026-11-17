-- Eleven Ealdfrost Goats removed and Kharold Frostpeak moved and standing, as set in game by the user.
DELETE FROM `creature_addon` WHERE `guid` IN (9965089, 9965090, 9965092, 9985025, 9985026, 9985027, 9985029, 9985030,
    9985031, 9985032, 9985033);
DELETE FROM `creature` WHERE `guid` IN (9965089, 9965090, 9965092, 9985025, 9985026, 9985027, 9985029, 9985030,
    9985031, 9985032, 9985033) AND `id` = 164424;

UPDATE `creature` SET `position_x` = -6719.211, `position_y` = 20.953, `position_z` = 496.567, `orientation` = 1.548
    WHERE `guid` = 9962212 AND `id` = 164566;
DELETE FROM `creature_addon` WHERE `guid` = 9962212;
