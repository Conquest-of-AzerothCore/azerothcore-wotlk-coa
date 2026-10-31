-- #5833 moved Brother Neals (952, guid 79968) to the front of the Northshire bell tower room for an easier
-- turn-in. rev_20260930_99_ASC_northshire_revamp.sql (#5764), a broad Northshire restore added later and applied
-- after #5833's fix in filename order, silently reset his position back to the stock back-of-room spot,
-- reintroducing #7798. Re-apply the front-of-room position; do not edit either earlier migration.
UPDATE `creature` SET `position_x` = -8892.94, `position_y` = -172.944, `position_z` = 113.158, `orientation` = 0.87
    WHERE `guid` = 79968 AND `id` = 952;
