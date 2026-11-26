-- #13424: the GatherMate revert re-inserted two Tyr's Hand ore pools at their stock heights.
-- Truesilver Deposit 200771 floated 9.05 yd above the spot its pool partner 200729 has used since
-- rev_20261020_63 (z 80.14); pool 13556 (200731, 200773) lay 2.37 yd under the ground, raised to the
-- ground height of the server maps (120.29).
UPDATE `gameobject` SET `position_z` = 80.14
WHERE `guid` = 200771 AND `id` = 2047 AND `map` = 0 AND `position_z` BETWEEN 89.18 AND 89.20;
UPDATE `gameobject` SET `position_z` = 120.29
WHERE `guid` IN (200731, 200773) AND `id` IN (175404, 2047) AND `map` = 0 AND `position_z` BETWEEN 117.90 AND 117.93;
