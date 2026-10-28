-- ----------------------------------------------------------------------------
-- Worldforged pickups: Un'Goro pickups the open-world height review left out (#4984)
-- ----------------------------------------------------------------------------
-- Follow-up to 2026_10_06_65. Its review skipped rows whose map height looked invalid, but the
-- Un'Goro crater floor sits at -240..-274, so these seven map heights are valid stock terrain and
-- the pins float 2-4 yd above it. The same exclusion audit checked the 198 rows that sit below the
-- terrain and found no open-world float among them (caves, mines, buildings and hand-placed rows).
-- Audit: wf_height_review/EXCLUSION_AUDIT.md. Each Z is the stock map height at the object's own XY. XY, orientation and entry are unchanged.
START TRANSACTION;

UPDATE `gameobject` SET `position_z` = -270.0654 WHERE `guid` = 6942061;
UPDATE `gameobject` SET `position_z` = -270.0905 WHERE `guid` = 6942168;
UPDATE `gameobject` SET `position_z` = -240.5719 WHERE `guid` = 6941952;
UPDATE `gameobject` SET `position_z` = -270.6999 WHERE `guid` = 6941679;
UPDATE `gameobject` SET `position_z` = -269.7315 WHERE `guid` = 6941887;
UPDATE `gameobject` SET `position_z` = -271.6200 WHERE `guid` = 6942049;
UPDATE `gameobject` SET `position_z` = -274.2327 WHERE `guid` = 6941750;

COMMIT;
