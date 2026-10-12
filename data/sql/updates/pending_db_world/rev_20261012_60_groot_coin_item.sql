-- Groot Coin (910001): a soulbound reward item staff mail for useful bug reports and Tiraxis exchanges for Bazaar
-- Tokens. No loot, vendor, quest or welcome-chest source. Display 30015 is the existing Bazaar Token icon until the
-- custom texture ships. A replay rewrites only this definition: for an unrelated row already holding 910001 the
-- name assignment evaluates a two-row subquery, which fails the whole statement and leaves that row untouched.
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`,
    `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `BagFamily`, `duration`, `ItemLimitCategory`, `ScriptName`)
VALUES
(910001, 15, 0, -1, 'Groot Coin', 30015, 4, 0, 0, 1, 0, 0, 0, -1, -1, 1, 0, 0, 1000, 1,
    'Awarded for helping improve Conquest of Azeroth. Exchange with Tiraxis for Bazaar Tokens.', 4, 0, 0, 0, 0, 0, 0,
    '')
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`),
    `SoundOverrideSubclass` = VALUES(`SoundOverrideSubclass`), `displayid` = VALUES(`displayid`),
    `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`), `FlagsExtra` = VALUES(`FlagsExtra`),
    `BuyCount` = VALUES(`BuyCount`), `BuyPrice` = VALUES(`BuyPrice`), `SellPrice` = VALUES(`SellPrice`),
    `InventoryType` = VALUES(`InventoryType`), `AllowableClass` = VALUES(`AllowableClass`),
    `AllowableRace` = VALUES(`AllowableRace`), `ItemLevel` = VALUES(`ItemLevel`),
    `RequiredLevel` = VALUES(`RequiredLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`),
    `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `Material` = VALUES(`Material`),
    `sheath` = VALUES(`sheath`), `RandomProperty` = VALUES(`RandomProperty`),
    `RandomSuffix` = VALUES(`RandomSuffix`), `BagFamily` = VALUES(`BagFamily`), `duration` = VALUES(`duration`),
    `ItemLimitCategory` = VALUES(`ItemLimitCategory`), `ScriptName` = VALUES(`ScriptName`),
    `name` = IF(`name` = 'Groot Coin', VALUES(`name`), (SELECT 1 UNION SELECT 2));

DELETE FROM `item_dbc` WHERE `ID` = 910001 AND `ClassID` = 15 AND `SubclassID` = 0;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES
(910001, 15, 0, -1, 4, 30015, 0, 0);
