-- Pol Amberstill's display 22455 needs CreatureDisplayInfoExtra 15349, which the client lacks.
-- Veron Amberstill's dwarf display 2790 stands in.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 2790 WHERE `CreatureID` = 24468 AND `Idx` = 0;
