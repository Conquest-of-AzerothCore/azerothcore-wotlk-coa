-- Follow-up to rev_20261009_60_companion_scale.sql: companions captured in live sniffs (2026-08-31/09-01,
-- OBJECT_FIELD_SCALE_X of the summoned unit) use the live scale instead of the bounding-box rule.
UPDATE `creature_template_model` SET `DisplayScale` = 0.1 WHERE `CreatureID` = 79055 AND `Idx` = 0;
UPDATE `creature_template_model` SET `DisplayScale` = 0.25 WHERE `CreatureID` IN (519908, 519910) AND `Idx` = 0;
UPDATE `creature_template_model` SET `DisplayScale` = 0.7 WHERE `CreatureID` = 44022 AND `Idx` = 0;
UPDATE `creature_template_model` SET `DisplayScale` = 0.55 WHERE `CreatureID` = 80879 AND `Idx` = 0;

-- Seen at 1 live: the Books of Ascension, Tentacular Manifestation, Seraph's Hilt and Buttercup. The Beginner's
-- Book (75118, same display as 75115) and the Book of Ascension 499992 follow the rest of the family.
UPDATE `creature_template_model` SET `DisplayScale` = 1 WHERE `CreatureID` IN
(75115, 75118, 80054, 98500, 98501, 108586, 108587, 163811, 148911, 499992, 988501, 11000053);
