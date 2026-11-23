-- Fifteen non-boss rifts each summon one guardian. These summons need explicit forces credit.
DELETE FROM `coa_mythic_forces` WHERE `entry` IN (17839, 21104, 21140, 21148);
INSERT INTO `coa_mythic_forces` (`entry`, `forces`, `comment`)
VALUES
(17839, 9, 'Black Morass - Rift Lord'),
(21104, 9, 'Black Morass - Rift Keeper Warlock'),
(21140, 9, 'Black Morass - Rift Lord'),
(21148, 9, 'Black Morass - Rift Keeper Mage');
