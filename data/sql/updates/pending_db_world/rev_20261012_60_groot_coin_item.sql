-- Groot Coin (910001): a soulbound reward item staff mail for useful bug reports and Tiraxis exchanges for Bazaar
-- Tokens. No loot, vendor, quest or welcome-chest source. Display 990001 is the custom INV_GrootCoin icon: the client
-- patch (Interface\Icons\INV_GrootCoin.blp, ItemDisplayInfo row 990001) must ship before or with this, see
-- modules/mod-ethereal-bazaar/client-art/README.md (revert SQL there). A replay rewrites only this definition: for an unrelated row already holding 910001 the
-- name assignment evaluates a two-row subquery, which fails the whole statement and leaves that row untouched.
-- Refuse to run unless all three allocated ids are ours or absent: item_template 910001 named 'Groot Coin',
-- item_dbc 910001 as written below (any of the two coin displays), itemdisplayinfo_dbc 990001 with our icon.
-- A foreign row makes the SELECT evaluate a two-row subquery, which fails this file before anything changes.
SELECT IF(EXISTS (SELECT 1 FROM `item_template` WHERE `entry` = 910001 AND `name` <> 'Groot Coin')
    OR EXISTS (SELECT 1 FROM `item_dbc` WHERE `ID` = 910001 AND NOT (`ClassID` = 15 AND `SubclassID` = 0
        AND `Sound_Override_Subclassid` = -1 AND `Material` = 4 AND `DisplayInfoID` IN (30015, 990001)
        AND `InventoryType` = 0 AND `SheatheType` = 0))
    OR EXISTS (SELECT 1 FROM `itemdisplayinfo_dbc` WHERE `ID` = 990001 AND `InventoryIcon_1` <> 'INV_GrootCoin'),
    (SELECT 1 UNION SELECT 2), 1) INTO @groot_coin_ids_free;

INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`,
    `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `BagFamily`, `duration`, `ItemLimitCategory`, `ScriptName`)
VALUES
(910001, 15, 0, -1, 'Groot Coin', 990001, 4, 0, 0, 1, 0, 0, 0, -1, -1, 1, 0, 0, 1000, 1,
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

DELETE FROM `item_dbc` WHERE `ID` = 910001;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES
(910001, 15, 0, -1, 4, 990001, 0, 0);

-- Display 990001: only the inventory icon; everything else empty, like the client DBC row.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 990001;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES
(990001, '', '', '', '', 'INV_GrootCoin', '', 0, 0, 0, 0, 0, 24, 0, 0, '', '', '', '', '', '', '', '', 0, 0);
