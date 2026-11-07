-- CONFIRMED SQL-ONLY REPAIRS for CoA exact user DBC + World DB dump, 2026-10-29.
-- Culling of Stratholme (normal and heroic): absent criterion for Mal'Ganis 26533.
-- Same-ACHIEVEMENT sibling kill criteria all carry map difficulty filter 12.
-- This copies that filter rather than inventing a broad NONE condition.
-- Safe to re-run: INSERT SELECT checks absence of ANY data row for target criterion.

INSERT IGNORE INTO `achievement_criteria_data` (`criteria_id`,`type`,`value1`,`value2`,`ScriptName`)
SELECT 202, `s`.`type`,`s`.`value1`,`s`.`value2`,`s`.`ScriptName`
FROM `achievement_criteria_data` AS `s`
WHERE `s`.`criteria_id`=211 AND `s`.`type`=12 AND `s`.`value1`=0 AND `s`.`value2`=0
    AND NOT EXISTS (SELECT 1 FROM `achievement_criteria_data` AS `d` WHERE `d`.`criteria_id`=202);

INSERT IGNORE INTO `achievement_criteria_data` (`criteria_id`,`type`,`value1`,`value2`,`ScriptName`)
SELECT 6801, `s`.`type`,`s`.`value1`,`s`.`value2`,`s`.`ScriptName`
FROM `achievement_criteria_data` AS `s`
WHERE `s`.`criteria_id`=6805 AND `s`.`type`=12 AND `s`.`value1`=1 AND `s`.`value2`=0
    AND NOT EXISTS (SELECT 1 FROM `achievement_criteria_data` AS `d` WHERE `d`.`criteria_id`=6801);
