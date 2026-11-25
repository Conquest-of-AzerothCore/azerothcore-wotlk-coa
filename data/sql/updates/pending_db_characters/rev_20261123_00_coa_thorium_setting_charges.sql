-- Thorium Settings created before their socketing use stored five zero charges.
UPDATE `item_instance`
SET `charges` = '-1 0 0 0 0 '
WHERE `itemEntry` = 21752 AND `charges` IN ('0 0 0 0 0', '0 0 0 0 0 ');
