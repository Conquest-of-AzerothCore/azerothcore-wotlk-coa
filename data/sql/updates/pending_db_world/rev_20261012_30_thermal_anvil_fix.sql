-- Thermal Anvil (1777028) did nothing: it was bound to item_ethereal_set_cache, whose only row pointed at a missing item
-- (425924), and its summon spell 9931265 uses two gameobjects that had no template. Values from the client's own cache (#7447).
UPDATE `item_template` SET `ScriptName` = '' WHERE `entry` = 1777028 AND `ScriptName` = 'item_ethereal_set_cache';
DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 1777028;

DELETE FROM `gameobject_template` WHERE `entry` IN (2201000, 2202000);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`) VALUES
-- Forge (spell focus 3) and Anvil (spell focus 1), 20 yards
(2201000, 8, 137975, 'Thermal Anvil', '', '', 1.0, 3, 20, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(2202000, 8, 1287, 'Thermal Anvil', '', '', 0.2, 1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
