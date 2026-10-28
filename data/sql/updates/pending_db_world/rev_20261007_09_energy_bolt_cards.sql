INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`,
    `AllowableClass`, `AllowableRace`, `RequiredLevel`, `stackable`, `spellid_1`, `spelltrigger_1`,
    `spellcharges_1`, `spellcooldown_1`, `spellcategorycooldown_1`, `bonding`, `description`, `Material`
) VALUES
(2205304, 0, 8, 'Skill Card - Energy Bolt', 137694, 3, 134221824, 1, 5000000,
    512, -1, 1, 100, 92657, 0, -1, -1, -1, 1,
    'You get Skill Cards from Silas Darkmoon!\n\nYou can activate skill cards in the Skill Card Collection between levels 1 and 9.', -1),
(2205339, 0, 8, 'Golden Skill Card - Energy Bolt', 137694, 3, 134221824, 1, 5000000,
    512, -1, 1, 100, 92657, 0, -1, -1, -1, 1,
    'You get Skill Cards from Silas Darkmoon!\n\nYou can activate skill cards in the Skill Card Collection between levels 1 and 9.', -1)
ON DUPLICATE KEY UPDATE
    `class` = VALUES(`class`),
    `subclass` = VALUES(`subclass`),
    `name` = VALUES(`name`),
    `displayid` = VALUES(`displayid`),
    `Quality` = VALUES(`Quality`),
    `Flags` = VALUES(`Flags`),
    `BuyCount` = VALUES(`BuyCount`),
    `BuyPrice` = VALUES(`BuyPrice`),
    `AllowableClass` = VALUES(`AllowableClass`),
    `AllowableRace` = VALUES(`AllowableRace`),
    `RequiredLevel` = VALUES(`RequiredLevel`),
    `stackable` = VALUES(`stackable`),
    `spellid_1` = VALUES(`spellid_1`),
    `spelltrigger_1` = VALUES(`spelltrigger_1`),
    `spellcharges_1` = VALUES(`spellcharges_1`),
    `spellcooldown_1` = VALUES(`spellcooldown_1`),
    `spellcategorycooldown_1` = VALUES(`spellcategorycooldown_1`),
    `bonding` = VALUES(`bonding`),
    `description` = VALUES(`description`),
    `Material` = VALUES(`Material`);
