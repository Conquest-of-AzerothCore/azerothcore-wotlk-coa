-- Treasures of Azeroth (1615011) and its source chest 978059 rolled one pool of every world boss item,
-- 31 unused Emerald Dragon placeholders (UNUSED...) included, whatever the release stage. The pool now
-- follows the stage: 978060 holds the Zul'Gurub stage bosses (Setis, Azuregos) and 978064 adds the Molten Core
-- stage ones (Lord Kazzak, The Will of Soggoth, Kaldros, Snowgrave, Atal'zul). The worldserver publishes the
-- released stage in world state 20121, which the conditions below read.
DELETE FROM `reference_loot_template` WHERE `Entry` = 978064;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`)
SELECT 978064, r.`Item`, 0, 0, 0, 1, 1, 1, 1, 'Treasures of Azeroth - Molten Core stage world boss item'
FROM `reference_loot_template` r JOIN `item_template` i ON i.`entry` = r.`Item`
WHERE r.`Entry` = 978060 AND i.`name` NOT LIKE 'UNUSED%';
DELETE r FROM `reference_loot_template` r JOIN `item_template` i ON i.`entry` = r.`Item`
WHERE r.`Entry` = 978060 AND (i.`name` LIKE 'UNUSED%'
  OR r.`Item` NOT IN (17365, 17366, 17367, 17334, 17243, 17244, 17356, 17357, 17358,
  18202, 18208, 19132, 18542, 18545, 19131, 17070, 19130, 18541, 18547));
DELETE FROM `item_loot_template` WHERE `Entry` IN (978059, 1615011) AND `Reference` = 978064;
INSERT INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
  `MinCount`, `MaxCount`, `Comment`) VALUES
(978059, 978064, 978064, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item (Molten Core stage)'),
(1615011, 978064, 978064, 5, 0, 1, 0, 1, 1, 'Treasures of Azeroth - 5% a world boss item (Molten Core stage)');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 5 AND `SourceGroup` IN (978059, 1615011)
  AND `SourceEntry` IN (978060, 978064);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(5, 978059, 978060, 0, 0, 11, 0, 20121, 3, 0, 0, 0, 0, '', 'Zul''Gurub stage world boss items'),
(5, 978059, 978064, 0, 0, 11, 0, 20121, 4, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 978059, 978064, 0, 1, 11, 0, 20121, 5, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 978059, 978064, 0, 2, 11, 0, 20121, 6, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 978059, 978064, 0, 3, 11, 0, 20121, 7, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 978059, 978064, 0, 4, 11, 0, 20121, 8, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 1615011, 978060, 0, 0, 11, 0, 20121, 3, 0, 0, 0, 0, '', 'Zul''Gurub stage world boss items'),
(5, 1615011, 978064, 0, 0, 11, 0, 20121, 4, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 1615011, 978064, 0, 1, 11, 0, 20121, 5, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 1615011, 978064, 0, 2, 11, 0, 20121, 6, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 1615011, 978064, 0, 3, 11, 0, 20121, 7, 0, 0, 0, 0, '', 'Molten Core stage world boss items'),
(5, 1615011, 978064, 0, 4, 11, 0, 20121, 8, 0, 0, 0, 0, '', 'Molten Core stage world boss items');
