-- Runaway's Tunic belongs beside Hermit Ortell inside the cave (#3238).
-- Use the reporting character's cave-floor position; the inferred surface height
-- put this pickup above the cave and outside Opening's interaction range.
UPDATE `gameobject`
SET `position_x` = -7574.46, `position_y` = 196.347, `position_z` = 11.1919
WHERE `guid` = 6942106 AND `id` = 1345118 AND `map` = 1;
