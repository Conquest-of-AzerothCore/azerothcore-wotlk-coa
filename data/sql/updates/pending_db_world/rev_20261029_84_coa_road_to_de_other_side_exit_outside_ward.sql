-- Road to De Other Side (map 937): the start room's exit (AreaTrigger 8005) set players down at the Sinister Lair mouth
-- inside the troll ward (GO 2300564), which stays solid for anyone without the amulet who has not finished The Way is
-- Shut, so they had to dig themselves out with the Old Digging Shovel. They now land outside the ward, where the shovel
-- sends them.
UPDATE `areatrigger_teleport` SET `target_position_x` = -243, `target_position_y` = -4185, `target_position_z` = 56.029,
    `target_orientation` = 3.14 WHERE `ID` = 8005;
