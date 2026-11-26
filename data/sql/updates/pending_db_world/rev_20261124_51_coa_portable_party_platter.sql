-- Portable Party Platter (retail item 207092): a realm-bound Vanity Collection toy the team hands to players who
-- helped the server. Using it places the platter (creature 11000400) for 3 minutes; its gossip offers six treats.
-- It is never sold: its VanityCollection row's prices are 0 and its Vanity Store price row is 0/0/0.
-- Requires VanityCollection.dbc row 11125798 (ItemID 9707200) in the server's DataDir/dbc: the server reads the
-- Vanity collection from that file, and the price row below makes the login stream send that row to clients.
-- Without it the item is not collected and the server logs "coa_client_vanity_collection 9707200 has no
-- VanityCollection.dbc row". Spells, the item's client row and the spell visuals are in rev_20261124_50.
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`,
    `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`,
    `RequiredLevel`, `maxcount`, `stackable`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellcooldown_1`,
    `spellcategory_1`, `spellcategorycooldown_1`, `bonding`, `description`, `Material`, `RequiredDisenchantSkill`)
VALUES
(9707200, 15, 4, -1, 'Portable Party Platter', 135194, 6, 134217728, 1, 0, 0, 0, -1, -1, 1, 1, 1, 1, 9978100, 0,
    0, 7200000, 0, -1, 1, '', 4, -1)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`),
    `SoundOverrideSubclass` = VALUES(`SoundOverrideSubclass`), `name` = VALUES(`name`),
    `displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`),
    `BuyCount` = VALUES(`BuyCount`), `BuyPrice` = VALUES(`BuyPrice`), `SellPrice` = VALUES(`SellPrice`),
    `InventoryType` = VALUES(`InventoryType`), `AllowableClass` = VALUES(`AllowableClass`),
    `AllowableRace` = VALUES(`AllowableRace`), `ItemLevel` = VALUES(`ItemLevel`),
    `RequiredLevel` = VALUES(`RequiredLevel`), `maxcount` = VALUES(`maxcount`), `stackable` = VALUES(`stackable`),
    `spellid_1` = VALUES(`spellid_1`), `spelltrigger_1` = VALUES(`spelltrigger_1`),
    `spellcharges_1` = VALUES(`spellcharges_1`), `spellcooldown_1` = VALUES(`spellcooldown_1`),
    `spellcategory_1` = VALUES(`spellcategory_1`), `spellcategorycooldown_1` = VALUES(`spellcategorycooldown_1`),
    `bonding` = VALUES(`bonding`), `description` = VALUES(`description`), `Material` = VALUES(`Material`),
    `RequiredDisenchantSkill` = VALUES(`RequiredDisenchantSkill`);

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`,
    `npcflag`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `BaseAttackTime`, `RangeAttackTime`, `ScriptName`)
VALUES
(11000400, 'Portable Party Platter', 'Pastry Propagator', 9997100, 1, 1, 35, 1, 1, 770, 32768, 10, 2000, 2000,
    'npc_coa_portable_party_platter')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`),
    `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`),
    `RangeAttackTime` = VALUES(`RangeAttackTime`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 11000400;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(11000400, 0, 11686, 1, 1);

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 11000400;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(11000400, 1, 0, 0, 1);

DELETE FROM `npc_text` WHERE `ID` = 9990600;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`, `VerifiedBuild`)
VALUES
(9990600, 'A variety of tasty treats are presented in front of you. Please take one, but leave some to share!',
    'A variety of tasty treats are presented in front of you. Please take one, but leave some to share!', 0, 0, 1,
    0);

DELETE FROM `gossip_menu` WHERE `MenuID` = 9997100;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (9997100, 9990600);

DELETE FROM `spell_group` WHERE `id` IN (2112600, 2112601);
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES
(2112600, 9978103),
(2112600, 9978104),
(2112601, 9978107),
(2112601, 9978108),
(2112601, 9978109),
(2112601, 9978110);

DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (2112600, 2112601);
INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES
(2112600, 1, 'Portable Party Platter - Blubbery Muffin and Rocks on the Rocks transforms replace each other'),
(2112601, 1, 'Portable Party Platter - one Snow in a Cone at a time');

DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` = 9707200;
INSERT INTO `coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`)
VALUES (9707200, 0, 0, 0);
