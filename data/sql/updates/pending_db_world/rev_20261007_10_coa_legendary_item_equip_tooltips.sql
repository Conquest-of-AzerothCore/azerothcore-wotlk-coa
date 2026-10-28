DROP TEMPORARY TABLE IF EXISTS `coa_legendary_item_tooltips`;
CREATE TEMPORARY TABLE `coa_legendary_item_tooltips` ENGINE=InnoDB AS
SELECT `i`.`entry` + 20000 AS `ID`, `i`.`name` AS `Name`,
  COALESCE(NULLIF(`i`.`description`, ''), `s`.`Description_Lang_enUS`) AS `Description`
FROM `item_template` AS `i`
INNER JOIN `item_dbc` AS `d` ON `d`.`ID` = `i`.`entry`
LEFT JOIN `spell_dbc` AS `s` ON `s`.`ID` = `i`.`entry` + 20000
WHERE `i`.`entry` >= 9700000 AND `i`.`entry` < 9706400 AND (`i`.`entry` - 9700000) % 100 BETWEEN 1 AND 60;
ALTER TABLE `coa_legendary_item_tooltips` ADD PRIMARY KEY (`ID`);

DELETE FROM `spell_dbc` WHERE `ID` IN (SELECT `ID` FROM `coa_legendary_item_tooltips`);
INSERT INTO `spell_dbc` (`ID`, `Attributes`, `AttributesEx3`, `CastingTimeIndex`, `RangeIndex`,
  `EquippedItemClass`, `SchoolMask`, `Name_Lang_enUS`, `Description_Lang_enUS`)
SELECT `ID`, 64, 65536, 1, 1, -1, 1, `Name`, `Description` FROM `coa_legendary_item_tooltips`;

UPDATE `item_template` AS `i` INNER JOIN `coa_legendary_item_tooltips` AS `t` ON `t`.`ID` = `i`.`entry` + 20000
SET `i`.`description` = '', `i`.`spellid_1` = `t`.`ID`, `i`.`spelltrigger_1` = 1, `i`.`spellcharges_1` = 0,
  `i`.`spellcooldown_1` = -1, `i`.`spellcategory_1` = 0, `i`.`spellcategorycooldown_1` = -1;

DROP TEMPORARY TABLE `coa_legendary_item_tooltips`;
