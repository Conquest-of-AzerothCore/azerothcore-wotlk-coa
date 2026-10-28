-- Aldia Crayon and Lady Agria Spada (#8926, #8907): the re-run of rev_20260930_99 (edited by #7230)
-- put them back on 652414/652415, the undressed human female; restore the displays of rev_20261002_00.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 8632 WHERE `CreatureID` = 162802 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1544 WHERE `CreatureID` = 162803 AND `Idx` = 0;
