-- Human and Dwarf are the Alliance races holding the Horde head on the affected realm.
UPDATE `item_instance` AS `item`
JOIN `characters` AS `owner` ON `owner`.`guid` = `item`.`owner_guid`
SET `item`.`itemEntry` = 18423
WHERE `item`.`itemEntry` = 18422 AND `owner`.`race` IN (1, 3);
