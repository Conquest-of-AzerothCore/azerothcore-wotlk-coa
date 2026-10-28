-- On "Darkmoon - Season 10 Wildcard" the first character of an account found a Specialization Cache (2977359) in
-- its bags. It belongs to the item family of the CoA Elite Warchest (2977351: quality 6, item level 15, dummy spell
-- 93461); name, display, binding and text follow the client item cache (harvest 2026-08-31).
CREATE TEMPORARY TABLE `wildcard_specialization_cache` ENGINE=InnoDB AS
    SELECT * FROM `item_template` WHERE `entry` = 2977351;
UPDATE `wildcard_specialization_cache` SET
    `entry` = 2977359,
    `name` = 'Specialization Cache (Soulbound)',
    `displayid` = 14575,
    `bonding` = 1,
    `description` = CONCAT('Contains: \n  \n - 6x Mystic Enchanting: Specialization \n',
        ' - Tome of Specialization II \n - Tome of Specialization III \n - Tome of Specialization IV \n',
        ' - Tome of Specialization V \n - Tome of Specialization VI \n  \n',
        ' |cFFFF5500IMPORTANT:|r Make sure you open this on the character you want to receive the rewards, as the',
        ' |cFFFF5500contents cannot be transferred or reclaimed.|r'),
    `ScriptName` = 'item_wildcard_specialization_cache';
INSERT INTO `item_template` SELECT * FROM `wildcard_specialization_cache`
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `bonding` = VALUES(`bonding`),
    `description` = VALUES(`description`), `ScriptName` = VALUES(`ScriptName`);
DROP TEMPORARY TABLE `wildcard_specialization_cache`;
