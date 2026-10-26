-- Equip-spell PvE Power and PvP Power markers ("PvE Power (+N)" 101600 + N, "PvP Power (+N)" 101700 + N)
-- brought in line with the client's ItemAddon.dbc: Bloodforged items lose their PvE Power marker, and items
-- that lacked a marker get the client's value. Every statement is guarded by the slot's current spell, so a
-- reapply changes nothing.

-- Insignia of the Burning Legion: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 409 AND `spellid_4` = 0;
-- Insignia of the Burning Legion: add PvE Power (+6)
UPDATE `item_template` SET `spellid_2` = 101606, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 409 AND `spellid_2` = 0;

-- Contraband Crossbow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 473 AND `spellid_4` = 0;

-- Blackmarket Powdershot: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 474 AND `spellid_4` = 0;

-- Kenny's Star: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 475 AND `spellid_4` = 0;

-- Bronze Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 586 AND `spellid_4` = 0;

-- Iron Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 587 AND `spellid_4` = 0;

-- Steel Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 588 AND `spellid_4` = 0;

-- Black Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 589 AND `spellid_4` = 0;

-- Mithril Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 590 AND `spellid_4` = 0;

-- Adamant Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 591 AND `spellid_4` = 0;

-- Rune Amulet: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 592 AND `spellid_4` = 0;

-- Notched Shortsword: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 727 AND `spellid_4` = 0;

-- Draconic Blood Spike: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 10472 AND `spellid_4` = 0;

-- Dragon Eye Pendant: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 10675 AND `spellid_4` = 0;

-- Shattered Hand Gauntlets: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 25017 AND `spellid_4` = 0;

-- Battlemaster's Hostility: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42128 AND `spellid_4` = 0;
-- Battlemaster's Hostility: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42128 AND `spellid_1` = 0;

-- Battlemaster's Accuracy: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42129 AND `spellid_4` = 0;
-- Battlemaster's Accuracy: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42129 AND `spellid_1` = 0;

-- Battlemaster's Avidity: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42130 AND `spellid_4` = 0;
-- Battlemaster's Avidity: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42130 AND `spellid_1` = 0;

-- Battlemaster's Conviction: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42131 AND `spellid_4` = 0;
-- Battlemaster's Conviction: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42131 AND `spellid_1` = 0;

-- Battlemaster's Bravery: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42132 AND `spellid_4` = 0;
-- Battlemaster's Bravery: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42132 AND `spellid_1` = 0;

-- Battlemaster's Fury: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42133 AND `spellid_4` = 0;
-- Battlemaster's Fury: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42133 AND `spellid_1` = 0;

-- Battlemaster's Precision: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42134 AND `spellid_4` = 0;
-- Battlemaster's Precision: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42134 AND `spellid_1` = 0;

-- Battlemaster's Vivacity: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42135 AND `spellid_4` = 0;
-- Battlemaster's Vivacity: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42135 AND `spellid_1` = 0;

-- Battlemaster's Rage: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42136 AND `spellid_4` = 0;
-- Battlemaster's Rage: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42136 AND `spellid_1` = 0;

-- Battlemaster's Ruination: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 42137 AND `spellid_4` = 0;
-- Battlemaster's Ruination: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 42137 AND `spellid_1` = 0;

-- Gladiator's Kodohide Spaulders: add PvP Power (+36)
UPDATE `item_template` SET `spellid_4` = 101736, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 88205 AND `spellid_4` = 0;
-- Gladiator's Kodohide Spaulders: add PvE Power (+25)
UPDATE `item_template` SET `spellid_1` = 101625, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 88205 AND `spellid_1` = 0;

-- Greater Insignia of the Burning Legion: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 101428 AND `spellid_4` = 0;
-- Greater Insignia of the Burning Legion: add PvE Power (+6)
UPDATE `item_template` SET `spellid_2` = 101606, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 101428 AND `spellid_2` = 0;

-- Temporal Greater Insignia of the Burning Legion: add PvP Power (+54)
UPDATE `item_template` SET `spellid_4` = 101754, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 101429 AND `spellid_4` = 0;
-- Temporal Greater Insignia of the Burning Legion: add PvE Power (+18)
UPDATE `item_template` SET `spellid_2` = 101618, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 101429 AND `spellid_2` = 0;

-- Shattered Hand Gauntlets: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 123811 AND `spellid_4` = 0;

-- Bloodforged Shattered Hand Gauntlets: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 123812 AND `spellid_4` = 0;

-- Water Loggers: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 199510 AND `spellid_4` = 0;

-- Hex Defender's Shield: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 199514 AND `spellid_4` = 0;

-- Stolen Composite Bow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 215096 AND `spellid_4` = 0;

-- Mysterious Stolen Rifle: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 215196 AND `spellid_4` = 0;

-- Tattered Tunic: add PvE Power (+38)
UPDATE `item_template` SET `spellid_1` = 101638, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 217846 AND `spellid_1` = 0;

-- Shroud of Infernal Shadows: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 217847 AND `spellid_1` = 0;

-- Felthread Warbelt: add PvE Power (+25)
UPDATE `item_template` SET `spellid_1` = 101625, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 217848 AND `spellid_1` = 0;

-- Kris of Corrupted Flame: add PvE Power (+48)
UPDATE `item_template` SET `spellid_1` = 101648, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 217849 AND `spellid_1` = 0;

-- Fel Infused Rifle: add PvE Power (+45)
UPDATE `item_template` SET `spellid_1` = 101645, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 217850 AND `spellid_1` = 0;

-- Phil Grim's Backbone: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 218096 AND `spellid_4` = 0;

-- Bieko's Stolen Wand: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 219096 AND `spellid_4` = 0;

-- Crystal of Serenity: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 291929 AND `spellid_4` = 0;

-- Southshore Sniper: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 304100 AND `spellid_4` = 0;

-- Sorrow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 304101 AND `spellid_4` = 0;

-- Battlemaster's Hostility: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354532 AND `spellid_4` = 0;
-- Battlemaster's Hostility: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354532 AND `spellid_1` = 0;

-- Battlemaster's Accuracy: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354544 AND `spellid_4` = 0;
-- Battlemaster's Accuracy: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354544 AND `spellid_1` = 0;

-- Battlemaster's Avidity: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354556 AND `spellid_4` = 0;
-- Battlemaster's Avidity: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354556 AND `spellid_1` = 0;

-- Battlemaster's Conviction: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354568 AND `spellid_4` = 0;
-- Battlemaster's Conviction: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354568 AND `spellid_1` = 0;

-- Battlemaster's Bravery: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354580 AND `spellid_4` = 0;
-- Battlemaster's Bravery: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354580 AND `spellid_1` = 0;

-- Battlemaster's Fury: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354592 AND `spellid_4` = 0;
-- Battlemaster's Fury: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354592 AND `spellid_1` = 0;

-- Battlemaster's Precision: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354604 AND `spellid_4` = 0;
-- Battlemaster's Precision: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354604 AND `spellid_1` = 0;

-- Battlemaster's Vivacity: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354616 AND `spellid_4` = 0;
-- Battlemaster's Vivacity: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354616 AND `spellid_1` = 0;

-- Battlemaster's Rage: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354628 AND `spellid_4` = 0;
-- Battlemaster's Rage: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354628 AND `spellid_1` = 0;

-- Battlemaster's Ruination: add PvP Power (+18)
UPDATE `item_template` SET `spellid_4` = 101718, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 354640 AND `spellid_4` = 0;
-- Battlemaster's Ruination: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 354640 AND `spellid_1` = 0;

-- Skullhood of the Ravager: add PvP Power (+42)
UPDATE `item_template` SET `spellid_1` = 101742, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 355029 AND `spellid_1` = 0;

-- Cylla's Endless Potion: add PvE Power (+48)
UPDATE `item_template` SET `spellid_2` = 101648, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 355131 AND `spellid_2` = 0;

-- Dragon Eye Medallion: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 403355 AND `spellid_4` = 0;

-- Dragon Eye Collar: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 403356 AND `spellid_4` = 0;

-- Dragon Eye Chain: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 403357 AND `spellid_4` = 0;

-- Dragon Eye Choker: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 403358 AND `spellid_4` = 0;

-- Dragon Eye Locket: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 403359 AND `spellid_4` = 0;

-- Shattered Hand Gauntlets: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 425017 AND `spellid_4` = 0;

-- Magtheridon's Felforged Spaulders: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492186 AND `spellid_4` = 0;
-- Magtheridon's Felforged Spaulders: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492186 AND `spellid_2` = 0;

-- Magtheridon's Felforged Bracers: add PvP Power (+24)
UPDATE `item_template` SET `spellid_4` = 101724, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492189 AND `spellid_4` = 0;
-- Magtheridon's Felforged Bracers: add PvE Power (+8)
UPDATE `item_template` SET `spellid_2` = 101608, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492189 AND `spellid_2` = 0;

-- Magtheridon's Felforged Gauntlets: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492190 AND `spellid_4` = 0;
-- Magtheridon's Felforged Gauntlets: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492190 AND `spellid_2` = 0;

-- Magtheridon's Felforged Waistguard: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492191 AND `spellid_4` = 0;
-- Magtheridon's Felforged Waistguard: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492191 AND `spellid_2` = 0;

-- Magtheridon's Felforged Sabatons: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492192 AND `spellid_4` = 0;
-- Magtheridon's Felforged Sabatons: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492192 AND `spellid_2` = 0;

-- Magtheridon's Felforged Cloak: add PvP Power (+24)
UPDATE `item_template` SET `spellid_4` = 101724, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492193 AND `spellid_4` = 0;
-- Magtheridon's Felforged Cloak: add PvE Power (+8)
UPDATE `item_template` SET `spellid_2` = 101608, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492193 AND `spellid_2` = 0;

-- Magtheridon's Felforged Carapace: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492194 AND `spellid_4` = 0;
-- Magtheridon's Felforged Carapace: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492194 AND `spellid_2` = 0;

-- Magtheridon's Felforged Legguards: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492195 AND `spellid_4` = 0;
-- Magtheridon's Felforged Legguards: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492195 AND `spellid_2` = 0;

-- Archimonde's Felforged Pauldron: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492286 AND `spellid_4` = 0;
-- Archimonde's Felforged Pauldron: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492286 AND `spellid_2` = 0;

-- Archimonde's Felforged Bracer: add PvP Power (+24)
UPDATE `item_template` SET `spellid_4` = 101724, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492289 AND `spellid_4` = 0;
-- Archimonde's Felforged Bracer: add PvE Power (+8)
UPDATE `item_template` SET `spellid_2` = 101608, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492289 AND `spellid_2` = 0;

-- Archimonde's Felforged Gauntlet: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492290 AND `spellid_4` = 0;
-- Archimonde's Felforged Gauntlet: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492290 AND `spellid_2` = 0;

-- Archimonde's Felforged Waistband: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492291 AND `spellid_4` = 0;
-- Archimonde's Felforged Waistband: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492291 AND `spellid_2` = 0;

-- Archimonde's Felforged Boots: add PvP Power (+30)
UPDATE `item_template` SET `spellid_4` = 101730, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492292 AND `spellid_4` = 0;
-- Archimonde's Felforged Boots: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492292 AND `spellid_2` = 0;

-- Archimonde's Felforged Drape: add PvP Power (+72)
UPDATE `item_template` SET `spellid_4` = 101772, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492293 AND `spellid_4` = 0;
-- Archimonde's Felforged Drape: add PvE Power (+20)
UPDATE `item_template` SET `spellid_2` = 101620, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492293 AND `spellid_2` = 0;

-- Archimonde's Felforged Carapace: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492294 AND `spellid_4` = 0;
-- Archimonde's Felforged Carapace: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492294 AND `spellid_2` = 0;

-- Archimonde's Felforged Leggings: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492295 AND `spellid_4` = 0;
-- Archimonde's Felforged Leggings: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492295 AND `spellid_2` = 0;

-- Magtheridon's Felforged Crown: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 492672 AND `spellid_4` = 0;
-- Magtheridon's Felforged Crown: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 492672 AND `spellid_2` = 0;

-- Archimonde's Felforged Crown: add PvP Power (+15)
UPDATE `item_template` SET `spellid_4` = 101715, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 494213 AND `spellid_4` = 0;
-- Archimonde's Felforged Crown: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 494213 AND `spellid_2` = 0;

-- Ring of Embered Thought: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 500820 AND `spellid_1` = 0;

-- Charstone Warband: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 500821 AND `spellid_1` = 0;

-- Ashen Dreambinder: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 500822 AND `spellid_1` = 0;

-- Static Cowl: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 501973 AND `spellid_4` = 0;

-- Ashwood Hunting Spear: add PvP Power (+24)
UPDATE `item_template` SET `spellid_1` = 101724, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 515543 AND `spellid_1` = 0;
-- Ashwood Hunting Spear: add PvE Power (+96)
UPDATE `item_template` SET `spellid_2` = 101696, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 515543 AND `spellid_2` = 0;

-- Well-Used Skinning Knife: add PvE Power (+48)
UPDATE `item_template` SET `spellid_1` = 101648, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 515544 AND `spellid_1` = 0;

-- Hillstalker?s Bow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 515545 AND `spellid_4` = 0;

-- Initiate's Boots: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 529344 AND `spellid_4` = 0;

-- axe_1h_pvpcataclysms3_c_01: add PvP Power (+36)
UPDATE `item_template` SET `spellid_4` = 101736, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 558835 AND `spellid_4` = 0;

-- axe_1h_pvpcataclysms3_c_01green: add PvP Power (+36)
UPDATE `item_template` SET `spellid_4` = 101736, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 558836 AND `spellid_4` = 0;

-- axe_1h_pvpcataclysms3_c_01orange: add PvP Power (+36)
UPDATE `item_template` SET `spellid_4` = 101736, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 558837 AND `spellid_4` = 0;

-- axe_1h_pvpcataclysms3_c_01malakk: add PvP Power (+36)
UPDATE `item_template` SET `spellid_4` = 101736, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 558838 AND `spellid_4` = 0;

-- Right Hand of Thaurgrim: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 560525 AND `spellid_4` = 0;

-- Left Hand of Thaurgrim: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 560527 AND `spellid_4` = 0;

-- Coral Scepter: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 632301 AND `spellid_4` = 0;

-- Insignia of the Sundered Scourge: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856016 AND `spellid_4` = 0;

-- Razorfang Battle Harness: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856017 AND `spellid_4` = 0;

-- Greatfather's Rending Claw: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856018 AND `spellid_4` = 0;

-- Darkbargainer's Arc-Cannon: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856020 AND `spellid_4` = 0;

-- Blackscale Warder's Cinch: add PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 101625, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856021 AND `spellid_4` = 0;

-- Timbermaw Rootcleaver: add PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 101696, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856022 AND `spellid_4` = 0;

-- Cloak of Unbroken Dawn: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856025 AND `spellid_4` = 0;

-- Dark Iron War-Censer: add PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 101696, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856027 AND `spellid_4` = 0;

-- Sandwarder's Bracers: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856028 AND `spellid_4` = 0;

-- Talisman of the Furbolg Warder: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856029 AND `spellid_4` = 0;

-- Qiraji Carapace Fragment: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856031 AND `spellid_4` = 0;

-- Legguards of the Shifting Sands: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856032 AND `spellid_4` = 0;

-- Longbow of Shifting Stars: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 856033 AND `spellid_4` = 0;

-- Last Whisper: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1303700 AND `spellid_4` = 0;

-- Dark Cross: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1303701 AND `spellid_4` = 0;

-- Thunderfall Wand: add PvP Power (+12)
UPDATE `item_template` SET `spellid_2` = 101712, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 1388543 AND `spellid_2` = 0;

-- Fine Crossbow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1403701 AND `spellid_4` = 0;

-- Eyegouging Crossbow: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1403702 AND `spellid_4` = 0;

-- Bunga Club: add PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 101696, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1512751 AND `spellid_4` = 0;

-- Rethreaded Left Bear Claw: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1518202 AND `spellid_4` = 0;

-- Rethreaded Right Bear Claw: add PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 101648, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 1518203 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +1: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001204 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +1: add PvE Power (+10)
UPDATE `item_template` SET `spellid_2` = 101610, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001204 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +2: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001205 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +2: add PvE Power (+15)
UPDATE `item_template` SET `spellid_2` = 101615, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001205 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +3: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001206 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +3: add PvE Power (+20)
UPDATE `item_template` SET `spellid_2` = 101620, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001206 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +4: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001207 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +4: add PvE Power (+25)
UPDATE `item_template` SET `spellid_2` = 101625, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001207 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +5: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001208 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +5: add PvE Power (+30)
UPDATE `item_template` SET `spellid_2` = 101630, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001208 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +6: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001209 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +6: add PvE Power (+35)
UPDATE `item_template` SET `spellid_2` = 101635, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001209 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +7: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001210 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +7: add PvE Power (+40)
UPDATE `item_template` SET `spellid_2` = 101640, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001210 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +8: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001211 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +8: add PvE Power (+45)
UPDATE `item_template` SET `spellid_2` = 101645, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001211 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +9: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001212 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +9: add PvE Power (+50)
UPDATE `item_template` SET `spellid_2` = 101650, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001212 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +10: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001213 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +10: add PvE Power (+55)
UPDATE `item_template` SET `spellid_2` = 101655, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001213 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +11: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001214 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +11: add PvE Power (+60)
UPDATE `item_template` SET `spellid_2` = 101660, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001214 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +12: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001215 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +12: add PvE Power (+65)
UPDATE `item_template` SET `spellid_2` = 101665, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001215 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +13: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001216 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +13: add PvE Power (+70)
UPDATE `item_template` SET `spellid_2` = 101670, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001216 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +14: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001217 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +14: add PvE Power (+75)
UPDATE `item_template` SET `spellid_2` = 101675, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001217 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +15: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001218 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +15: add PvE Power (+80)
UPDATE `item_template` SET `spellid_2` = 101680, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001218 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +16: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001219 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +16: add PvE Power (+85)
UPDATE `item_template` SET `spellid_2` = 101685, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001219 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +17: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001220 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +17: add PvE Power (+90)
UPDATE `item_template` SET `spellid_2` = 101690, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001220 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +18: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001221 AND `spellid_4` = 0;
-- Empowered Insignia of the Burning Legion +18: add PvE Power (+95)
UPDATE `item_template` SET `spellid_2` = 101695, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001221 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +19: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001222 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +20: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001223 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +21: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001224 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +22: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001225 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +23: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001226 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +24: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001227 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +25: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001228 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +26: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001229 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +27: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001230 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +28: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001231 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +29: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001232 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +30: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001233 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +31: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001234 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +32: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001235 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +33: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001236 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +34: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001237 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +35: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001238 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +36: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001239 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +37: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001240 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +38: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001241 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +39: add PvP Power (+6)
UPDATE `item_template` SET `spellid_4` = 101706, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2001242 AND `spellid_4` = 0;

-- Empowered Insignia of the Burning Legion +40: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001243 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +41: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001244 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +42: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001245 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +43: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001246 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +44: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001247 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +45: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001248 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +46: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001249 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +47: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001250 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +48: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001251 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +49: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001252 AND `spellid_2` = 0;

-- Empowered Insignia of the Burning Legion +50: add PvP Power (+6)
UPDATE `item_template` SET `spellid_2` = 101706, `spelltrigger_2` = 1, `spellcharges_2` = 0, `spellcooldown_2` = -1, `spellcategory_2` = 0, `spellcategorycooldown_2` = -1 WHERE `entry` = 2001253 AND `spellid_2` = 0;

-- Reusable Oversized Bobber: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 2919291 AND `spellid_4` = 0;

-- Dwarven Rifle: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 3641001 AND `spellid_4` = 0;

-- Barbaric Rifle: add PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 101645, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 3641002 AND `spellid_4` = 0;

-- Pawned Darkshire Monocle: add PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 101638, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 5744001 AND `spellid_4` = 0;

-- Ring of the Three-Headed Beast: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015829 AND `spellid_1` = 0;

-- Old Gods' Blessing: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015832 AND `spellid_1` = 0;

-- Barrier of the Earth Princess: add PvE Power (+48)
UPDATE `item_template` SET `spellid_1` = 101648, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015833 AND `spellid_1` = 0;

-- Sulfuron's Favor: add PvE Power (+20)
UPDATE `item_template` SET `spellid_1` = 101620, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015837 AND `spellid_1` = 0;

-- Salamander Skin: add PvE Power (+38)
UPDATE `item_template` SET `spellid_1` = 101638, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015841 AND `spellid_1` = 0;

-- Sandfury Sandals: add PvE Power (+25)
UPDATE `item_template` SET `spellid_1` = 101625, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6015897 AND `spellid_1` = 0;

-- Obsidian Heartseeker: add PvE Power (+48)
UPDATE `item_template` SET `spellid_1` = 101648, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6018906 AND `spellid_1` = 0;

-- Bloodforged Brawler Gloves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299426 AND `spellid_4` = 101625;

-- Bloodforged Gnarled Ash Staff: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299584 AND `spellid_4` = 101696;

-- Bloodforged Rockslicer: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299670 AND `spellid_4` = 101696;

-- Bloodforged Naga Battle Gloves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299713 AND `spellid_4` = 101625;

-- Bloodforged Rod of the Sleepwalker: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299906 AND `spellid_4` = 101696;

-- Bloodforged Lavishly Jeweled Ring: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6299949 AND `spellid_4` = 101620;

-- Bloodforged Butcher's Cleaver: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6303605 AND `spellid_4` = 101648;

-- Bloodforged Axe of the Enforcer: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6304889 AND `spellid_4` = 101648;

-- Bloodforged Grimclaw: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6304932 AND `spellid_4` = 101648;

-- Bloodforged Talisman of Binding Shard: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6317782 AND `spellid_4` = 101620;

-- Obsidian Heartseeker: add PvE Power (+48)
UPDATE `item_template` SET `spellid_1` = 101648, `spelltrigger_1` = 1, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1 WHERE `entry` = 6318906 AND `spellid_1` = 0;

-- Bloodforged Thunderfury, Blessed Blade of the Windseeker: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6319019 AND `spellid_4` = 101648;

-- Bloodforged Tree Bark Jacket: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6329213 AND `spellid_4` = 101638;

-- Bloodforged Avenger's Armor: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6331104 AND `spellid_4` = 101638;

-- Bloodforged Thori'dal, the Stars' Fury: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6334334 AND `spellid_4` = 101645;

-- Bloodforged Ring of Precision: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6345550 AND `spellid_4` = 101620;

-- Bloodforged Double Link Tunic: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6346211 AND `spellid_4` = 101638;

-- Bloodforged Sword of Decay: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6346590 AND `spellid_4` = 101648;

-- Bloodforged Buzz Saw: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6346706 AND `spellid_4` = 101648;

-- Bloodforged Slaghammer: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6346824 AND `spellid_4` = 101696;

-- Bloodforged Twisted Sabre: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6347612 AND `spellid_4` = 101648;

-- Bloodforged Double-barreled Shotgun: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6348400 AND `spellid_4` = 101645;

-- Bloodforged Buzzer Blade: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6349491 AND `spellid_4` = 101648;

-- Bloodforged Mantle of Thieves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6349536 AND `spellid_4` = 101625;

-- Bloodforged Staff of the Blessed Seer: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6349593 AND `spellid_4` = 101696;

-- Bloodforged Forest Tracker Epaulets: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6350993 AND `spellid_4` = 101625;

-- Bloodforged Kam's Walking Stick: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6351603 AND `spellid_4` = 101696;

-- Bloodforged Burning War Axe: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6352130 AND `spellid_4` = 101696;

-- Bloodforged Holy Shroud: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6352223 AND `spellid_4` = 101638;

-- Bloodforged Black Velvet Robes: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6352735 AND `spellid_4` = 101638;

-- Bloodforged Death Speaker Scepter: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353040 AND `spellid_4` = 101648;

-- Bloodforged Combatant Claymore: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353157 AND `spellid_4` = 101696;

-- Bloodforged Bearded Boneaxe: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353431 AND `spellid_4` = 101648;

-- Bloodforged Claw of the Shadowmancer: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353572 AND `spellid_4` = 101648;

-- Bloodforged Prison Shank: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353785 AND `spellid_4` = 101648;

-- Bloodforged Iron Knuckles: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6353874 AND `spellid_4` = 101648;

-- Bloodforged Enduring Cap: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6362561 AND `spellid_4` = 101638;

-- Bloodforged Naga Heartpiercer: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393285 AND `spellid_4` = 101645;

-- Bloodforged Arced War Axe: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393328 AND `spellid_4` = 101696;

-- Bloodforged Dense Triangle Mace: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393635 AND `spellid_4` = 101696;

-- Bloodforged Jimmied Handcuffs: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393678 AND `spellid_4` = 101620;

-- Bloodforged Black Wolf Bracers: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393721 AND `spellid_4` = 101620;

-- Bloodforged Doomspike: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6393764 AND `spellid_4` = 101648;

-- Bloodforged Crested Scepter: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6397195 AND `spellid_4` = 101648;

-- Bloodforged Staff of the Friar: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6397319 AND `spellid_4` = 101696;

-- Bloodforged Martyr's Chain: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6397378 AND `spellid_4` = 101638;

-- Bloodforged Onyx Claymore: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6397464 AND `spellid_4` = 101696;

-- Bloodforged Feline Mantle: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6397507 AND `spellid_4` = 101625;

-- Bloodforged Pugilist Bracers: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398293 AND `spellid_4` = 101620;

-- Bloodforged Rhahk'Zor's Hammer: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398336 AND `spellid_4` = 101696;

-- Bloodforged Cruel Barb: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398379 AND `spellid_4` = 101648;

-- Bloodforged Thief's Blade: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398422 AND `spellid_4` = 101648;

-- Bloodforged Cape of the Brotherhood: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398651 AND `spellid_4` = 101620;

-- Bloodforged Taskmaster Axe: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398738 AND `spellid_4` = 101696;

-- Bloodforged Gold-flecked Gloves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398781 AND `spellid_4` = 101625;

-- Bloodforged Smite's Reaver: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398824 AND `spellid_4` = 101648;

-- Bloodforged Cookie's Tenderizer: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398867 AND `spellid_4` = 101648;

-- Bloodforged Cookie's Stirring Rod: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398910 AND `spellid_4` = 101645;

-- Bloodforged Smelting Pants: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6398953 AND `spellid_4` = 101638;

-- Bloodforged Impaling Harpoon: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399003 AND `spellid_4` = 101696;

-- Bloodforged Emberstone Staff: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399046 AND `spellid_4` = 101696;

-- Bloodforged Corsair's Overshirt: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399089 AND `spellid_4` = 101638;

-- Bloodforged Firebelcher: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399132 AND `spellid_4` = 101645;

-- Bloodforged Rugged Spaulders: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399431 AND `spellid_4` = 101625;

-- Bloodforged Serpent's Shoulders: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399474 AND `spellid_4` = 101625;

-- Bloodforged Gold-plated Buckler: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399517 AND `spellid_4` = 101648;

-- Bloodforged Miner's Cape: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399560 AND `spellid_4` = 101620;

-- Bloodforged Serpent Gloves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399646 AND `spellid_4` = 101625;

-- Bloodforged Meteor Shard: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399689 AND `spellid_4` = 101648;

-- Bloodforged Bloody Apron: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399732 AND `spellid_4` = 101638;

-- Bloodforged Wolfmaster Cape: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399775 AND `spellid_4` = 101620;

-- Bloodforged Odo's Ley Staff: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399818 AND `spellid_4` = 101696;

-- Bloodforged Girdle of the Blindwatcher: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399861 AND `spellid_4` = 101625;

-- Bloodforged Commander's Crest: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399904 AND `spellid_4` = 101648;

-- Bloodforged Silverlaine's Family Seal: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6399952 AND `spellid_4` = 101620;

-- Bloodforged Baron's Scepter: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6400081 AND `spellid_4` = 101648;

-- Bloodforged Robes of Arugal: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6400165 AND `spellid_4` = 101638;

-- Bloodforged Fenrus' Hide: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6400208 AND `spellid_4` = 101620;

-- Bloodforged Belt of Arugal: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6405755 AND `spellid_4` = 101625;

-- Bloodforged Worn Turtle Shell Shield: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6405798 AND `spellid_4` = 101648;

-- Bloodforged Tail Spike: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6405841 AND `spellid_4` = 101648;

-- Bloodforged Glowing Lizardscale Cloak: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6405884 AND `spellid_4` = 101620;

-- Bloodforged Savage Trodders: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6405927 AND `spellid_4` = 101625;

-- Bloodforged Cobrahn's Grasp: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406051 AND `spellid_4` = 101625;

-- Bloodforged Slime-encrusted Pads: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406094 AND `spellid_4` = 101625;

-- Bloodforged Deep Fathom Ring: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406137 AND `spellid_4` = 101620;

-- Bloodforged Robe of the Moccasin: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406227 AND `spellid_4` = 101638;

-- Bloodforged Venomstrike: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406270 AND `spellid_4` = 101645;

-- Bloodforged Stinging Viper: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406570 AND `spellid_4` = 101648;

-- Bloodforged Armor of the Fang: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406613 AND `spellid_4` = 101638;

-- Bloodforged Mutant Scale Breastplate: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406656 AND `spellid_4` = 101638;

-- Bloodforged Sporid Cape: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406699 AND `spellid_4` = 101620;

-- Bloodforged Seedcloud Buckler: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406742 AND `spellid_4` = 101648;

-- Bloodforged Living Root: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406785 AND `spellid_4` = 101696;

-- Bloodforged Feyscale Cloak: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406828 AND `spellid_4` = 101620;

-- Bloodforged Butcher's Slicer: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406871 AND `spellid_4` = 101648;

-- Bloodforged Haunting Blade: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406914 AND `spellid_4` = 101696;

-- Bloodforged Phantom Armor: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6406957 AND `spellid_4` = 101638;

-- Bloodforged Thornspike: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407000 AND `spellid_4` = 101648;

-- Bloodforged Death Speaker Robes: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407043 AND `spellid_4` = 101638;

-- Bloodforged Death Speaker Mantle: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407086 AND `spellid_4` = 101625;

-- Bloodforged Tusken Helm: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407129 AND `spellid_4` = 101638;

-- Bloodforged Corpsemaker: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407172 AND `spellid_4` = 101696;

-- Bloodforged Whisperwind Headdress: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407215 AND `spellid_4` = 101638;

-- Bloodforged Wind Spirit Staff: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407258 AND `spellid_4` = 101696;

-- Bloodforged Ferine Leggings: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407301 AND `spellid_4` = 101638;

-- Bloodforged Agamaggan's Clutch: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407430 AND `spellid_4` = 101620;

-- Bloodforged Heart of Agamaggan: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407473 AND `spellid_4` = 101648;

-- Bloodforged Stygian Bone Amulet: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407516 AND `spellid_4` = 101620;

-- Bloodforged Nightstalker Bow: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407559 AND `spellid_4` = 101645;

-- Bloodforged Batwing Mantle: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407602 AND `spellid_4` = 101625;

-- Bloodforged Glowing Thresher Cape: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407645 AND `spellid_4` = 101620;

-- Bloodforged Bands of Serra'kis: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407688 AND `spellid_4` = 101620;

-- Bloodforged Gaze Dreamer Pants: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407731 AND `spellid_4` = 101638;

-- Bloodforged Bite of Serra'kis: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407774 AND `spellid_4` = 101648;

-- Bloodforged Reef Axe: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407861 AND `spellid_4` = 101696;

-- Bloodforged Algae Fists: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407904 AND `spellid_4` = 101625;

-- Bloodforged Tortoise Armor: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407947 AND `spellid_4` = 101638;

-- Bloodforged Ghamoo-ra's Bind: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6407990 AND `spellid_4` = 101625;

-- Bloodforged Strike of the Hydra: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408033 AND `spellid_4` = 101696;

-- Bloodforged Leech Pants: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408093 AND `spellid_4` = 101638;

-- Bloodforged Moss Cinch: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408136 AND `spellid_4` = 101625;

-- Bloodforged Smite's Mighty Hammer: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408179 AND `spellid_4` = 101696;

-- Bloodforged Torturing Poker: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408222 AND `spellid_4` = 101648;

-- Bloodforged Bloody Brass Knuckles: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6408265 AND `spellid_4` = 101648;

-- Bloodforged Dog Training Gloves: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6409383 AND `spellid_4` = 101625;

-- Bloodforged Girdle of Golem Strength: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6410502 AND `spellid_4` = 101625;

-- Bloodforged Grubbis Paws: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411405 AND `spellid_4` = 101625;

-- Bloodforged Electrocutioner Leg: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411448 AND `spellid_4` = 101648;

-- Bloodforged Electrocutioner Lagnut: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411491 AND `spellid_4` = 101620;

-- Bloodforged Spidertank Oilrag: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411534 AND `spellid_4` = 101620;

-- Bloodforged Manual Crowd Pummeler: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411577 AND `spellid_4` = 101696;

-- Bloodforged Gnomebot Operating Boots: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411620 AND `spellid_4` = 101625;

-- Bloodforged Hydrocane: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411663 AND `spellid_4` = 101696;

-- Bloodforged Toxic Revenger: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411706 AND `spellid_4` = 101648;

-- Bloodforged Acidic Walkers: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411749 AND `spellid_4` = 101625;

-- Bloodforged Emissary Cuffs: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411792 AND `spellid_4` = 101620;

-- Bloodforged Thermaplugg's Central Core: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6411921 AND `spellid_4` = 101648;

-- Bloodforged Thermaplugg's Left Arm: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412006 AND `spellid_4` = 101696;

-- Bloodforged Charged Gear: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412049 AND `spellid_4` = 101620;

-- Bloodforged Supercharger Battle Axe: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412694 AND `spellid_4` = 101696;

-- Bloodforged Hi-tech Supergun: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412737 AND `spellid_4` = 101645;

-- Bloodforged Oscillating Power Hammer: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412785 AND `spellid_4` = 101648;

-- Bloodforged Electromagnetic Gigaflux Reactivator: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6412828 AND `spellid_4` = 101638;

-- Bloodforged Blackened Defias Armor: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6413116 AND `spellid_4` = 101638;

-- Bloodforged Blackened Defias Belt: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6413159 AND `spellid_4` = 101625;

-- Bloodforged Darkwater Talwar: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415205 AND `spellid_4` = 101648;

-- Bloodforged The Black Knight: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415506 AND `spellid_4` = 101648;

-- Bloodforged Amy's Blanket: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415549 AND `spellid_4` = 101620;

-- Bloodforged Dreamsinger Legguards: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415592 AND `spellid_4` = 101638;

-- Bloodforged Silver-lined Belt: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415635 AND `spellid_4` = 101625;

-- Bloodforged Yorgen Bracers: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415678 AND `spellid_4` = 101620;

-- Bloodforged Killmaim: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415721 AND `spellid_4` = 101696;

-- Bloodforged Harpyclaw Short Bow: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415807 AND `spellid_4` = 101645;

-- Bloodforged Beazel's Basher: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6415893 AND `spellid_4` = 101648;

-- Bloodforged Orb of Mistmantle: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416015 AND `spellid_4` = 101648;

-- Bloodforged Sword of Corruption: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416058 AND `spellid_4` = 101648;

-- Bloodforged Crystalpine Stinger: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416144 AND `spellid_4` = 101645;

-- Bloodforged Guardian Blade: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416230 AND `spellid_4` = 101696;

-- Bloodforged Looming Gavel: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416316 AND `spellid_4` = 101648;

-- Bloodforged Deanship Claymore: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416359 AND `spellid_4` = 101696;

-- Bloodforged Bloodpike: remove PvE Power (+96)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416488 AND `spellid_4` = 101696;

-- Bloodforged Thunderwood: remove PvE Power (+45)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6416863 AND `spellid_4` = 101645;

-- Bloodforged Shield of Thorsen: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417035 AND `spellid_4` = 101648;

-- Bloodforged River Pride Choker: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417121 AND `spellid_4` = 101620;

-- Bloodforged The Queen's Jewel: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417207 AND `spellid_4` = 101620;

-- Bloodforged Thunderbrow Ring: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417293 AND `spellid_4` = 101620;

-- Bloodforged Moccasins of the White Hare: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417336 AND `spellid_4` = 101625;

-- Bloodforged Glowing Magical Bracelets: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417465 AND `spellid_4` = 101620;

-- Bloodforged Troll's Bane Leggings: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417594 AND `spellid_4` = 101638;

-- Bloodforged Frostreaver Crown: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417680 AND `spellid_4` = 101638;

-- Bloodforged Sparkleshell Mantle: remove PvE Power (+25)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6417766 AND `spellid_4` = 101625;

-- Bloodforged Cursed Felblade: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418012 AND `spellid_4` = 101648;

-- Bloodforged Cavedweller Bracers: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418055 AND `spellid_4` = 101620;

-- Bloodforged Crystalline Cuffs: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418098 AND `spellid_4` = 101620;

-- Bloodforged Subterranean Cape: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418141 AND `spellid_4` = 101620;

-- Bloodforged Robe of Evocation: remove PvE Power (+38)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418184 AND `spellid_4` = 101638;

-- Bloodforged Chanting Blade: remove PvE Power (+48)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6418227 AND `spellid_4` = 101648;

-- Bloodforged Deadman's Hand: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6419941 AND `spellid_4` = 101620;

-- Bloodforged Mutated Heart Cloak: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6594229 AND `spellid_4` = 101620;

-- Bloodforged Cloak of the Other Side: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6594811 AND `spellid_4` = 101620;

-- Bloodforged Cape of the Last Feast: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6594919 AND `spellid_4` = 101620;

-- Bloodforged Cloak of the Last Confessor: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6595370 AND `spellid_4` = 101620;

-- Bloodforged Ancient Sigh Cloak: remove PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 0, `spelltrigger_4` = 0, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 6597649 AND `spellid_4` = 101620;

-- BWL SP REP NECK: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 9200819 AND `spellid_4` = 0;

-- BWL rep tank trinket: add PvE Power (+20)
UPDATE `item_template` SET `spellid_4` = 101620, `spelltrigger_4` = 1, `spellcharges_4` = 0, `spellcooldown_4` = -1, `spellcategory_4` = 0, `spellcategorycooldown_4` = -1 WHERE `entry` = 9200836 AND `spellid_4` = 0;
