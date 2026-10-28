-- Dulcinea, Aldia Crayon and Lady Agria Spada: the re-run of rev_20260930_99 (edited by #7230) put them back on
-- the revamp's undressed displays 652354, 652414 and 652415. Restore the displays of rev_20261009_50 (Dulcinea,
-- matching her 25599 preset) and rev_20261002_00 (Aldia Crayon, Lady Agria Spada).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 25599 WHERE `CreatureID` = 162800 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 8632 WHERE `CreatureID` = 162802 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1544 WHERE `CreatureID` = 162803 AND `Idx` = 0;
