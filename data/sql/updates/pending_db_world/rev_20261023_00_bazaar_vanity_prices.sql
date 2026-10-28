-- Ethereal Bazaar price tuning (Rexxar realm).
--
-- Vanity Store (coa_client_vanity_collection): the table ships empty and each realm fills it, so on a realm
-- without rows this file changes nothing there.
--   * Heirlooms and a few convenience items are no longer sold in the Vanity Store (rows removed, the same
--     way an item without a row is not offered).
--   * Bazaar Token prices x10, except the 75-token toys, banners and costumes, which become 250.
--     Written as fixed old->new values so a reapply does not multiply again.
-- Tiraxis' Convenience Items (900008) and Chromie's Experience Items (990782):
--   * Aura of Experience 818059: 250 -> 350 tokens (ExtendedCost 2990 -> 3015).
--   * Potion of Experience 818046: 35 -> 100 tokens (ExtendedCost 41021 -> 2983).
--   Amounts read from ItemExtendedCost.dbc (item 975001 x count).

-- Heirlooms (Quality 7)
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  339075,  -- Stick on a Carrot
  339076,  -- Pendant of Adventure
  339100,  -- Pendant of Discovery
  818046,  -- Potion of Experience
  1339076,  -- Pendant of the Warrior
  1339077,  -- Pendant of the Sorcerer
  1339078,  -- Pendant of the Bulwark
  1339079,  -- Ring of the Vanguard
  1339080,  -- Ring of the Sorcerer
  1339081,  -- Ring of the Bulwark
  1339082,  -- Ring of the Lionhearted
  1339083,  -- Ring of the Seer
  1339084,  -- Champion's Deathdealer Cloak
  1339085,  -- Polished Cloak of Valor
  1339086,  -- Tattered Dreadmist Cloak
  1339087,  -- Strengthened Cloak of Might
  1339088,  -- Stained Shadowcraft Cloak
  1339089,  -- Preened Ironfeather Cloak
  1339090,  -- Mystical Cloak of Elements
  1339092,  -- Tattered Dreadmist Belt
  1339093,  -- Stained Shadowcraft Belt
  1339094,  -- Preened Ironfeather Belt
  1339095,  -- Mystical Belt of Elements
  1339096,  -- Champion Herod's Belt
  1339097,  -- Polished Belt of Valor
  1339098,  -- Burnished Belt of Might
  1339099,  -- Tattered Dreadmist Boots
  1339100,  -- Stained Shadowcraft Boots
  1339101,  -- Preened Ironfeather Boots
  1339102,  -- Mystical Boots of Elements
  1339103,  -- Champion Herod's Boots
  1339104,  -- Polished Boots of Valor
  1339105,  -- Burnished Boots of Might
  1339106,  -- Tattered Dreadmist Bracers
  1339107,  -- Stained Shadowcraft Bracers
  1339108,  -- Preened Ironfeather Bracers
  1339109,  -- Mystical Bracers of Elements
  1339110,  -- Champion Herod's Bracers
  1339111,  -- Polished Bracers of Valor
  1339112,  -- Burnished Bracers of Might
  1339113,  -- Tattered Dreadmist Leggings
  1339114,  -- Stained Shadowcraft Pants
  1339115,  -- Preened Ironfeather Legguards
  1339116,  -- Mystical Kilt of Elements
  1339117,  -- Champion Herod's Legguards
  1339118,  -- Polished Platelegs of Valor
  1339119,  -- Burnished Platelegs of Might
  1339120,  -- Tattered Dreadmist Hood
  1339121,  -- Stained Shadowcraft Hood
  1339122,  -- Preened Ironfeather Headguard
  1339123,  -- Mystical Helm of Elements
  1339124,  -- Champion Herod's Helmet
  1339125,  -- Polished Helmet of Valor
  1339126,  -- Burnished Helmet of Might
  1339127,  -- Tattered Dreadmist Gloves
  1339128,  -- Stained Shadowcraft Gloves
  1339129,  -- Preened Ironfeather Gloves
  1339130,  -- Mystical Gloves of Elements
  1339131,  -- Champion Herod's Gloves
  1339132,  -- Polished Gauntlets of Valor
  1339133,  -- Burnished Gauntlets of Might
  1518202,  -- Rethreaded Left Bear Claw
  1518203,  -- Rethreaded Right Bear Claw
  1642846,  -- Wand of the Forgotten Lich
  1642896,  -- Druid Idol of Agility
  1642897,  -- Druid Idol of Spells
  1642898,  -- Shaman Totem of Agility
  1642899,  -- Shaman Totem of Spells
  1642900,  -- Paladin Libram of Strength
  1642901,  -- Paladin Libram of Healing
  1642902,  -- Thrown Axe of the Executioner
  1642943,  -- Bloodied Arcanite Reaper
  1642944,  -- Balanced Heartseeker
  1642945,  -- Venerable Dal'Rend's Sacred Charge
  1642946,  -- Charmed Ancient Bone Bow
  1642947,  -- Dignified Headmaster's Charge
  1642948,  -- Devout Aurastone Hammer
  1642949,  -- Polished Spaulders of Valor
  1642950,  -- Champion Herod's Shoulder
  1642951,  -- Mystical Pauldrons of Elements
  1642952,  -- Stained Shadowcraft Spaulders
  1642984,  -- Preened Ironfeather Shoulders
  1642985,  -- Tattered Dreadmist Mantle
  1642991,  -- Swift Hand of Justice
  1642992,  -- Discerning Eye of the Beast
  1642999,  -- Ancient Crossbow
  1644091,  -- Sharpened Scarlet Kris
  1644092,  -- Reforged Truesilver Champion
  1644093,  -- Upgraded Dwarven Hand Cannon
  1644094,  -- The Blessed Hammer of Grace
  1644095,  -- Grand Staff of Jordan
  1644096,  -- Battleworn Thrash Blade
  1644097,  -- Inherited Insignia of the Horde
  1644098,  -- Inherited Insignia of the Alliance
  1644099,  -- Strengthened Stockade Pauldrons
  1644100,  -- Pristine Lightforge Spaulders
  1644101,  -- Prized Beastmaster's Mantle
  1644102,  -- Aged Pauldrons of The Five Thunders
  1644103,  -- Exceptional Stormshroud Shoulders
  1644105,  -- Lasting Feralheart Spaulders
  1644107,  -- Exquisite Sunderseer Mantle
  1648677,  -- Champion's Deathdealer Breastplate
  1648683,  -- Mystical Vest of Elements
  1648685,  -- Polished Breastplate of Valor
  1648687,  -- Preened Ironfeather Breastplate
  1648689,  -- Stained Shadowcraft Tunic
  1648691,  -- Tattered Dreadmist Robe
  1648716,  -- Venerable Mass of McGowan
  1648718,  -- Repurposed Lava Dredger
  3140350,  -- Urn of Aspiring Light
  3142943,  -- Sturdied Arcanite Spear
  3142949,  -- Burnished Spaulders of Might
  3148335,  -- Polished Observer's Shield
  3148685  -- Burnished Breastplate of Might
);

-- Convenience items
DELETE FROM `coa_client_vanity_collection` WHERE `ItemID` IN (
  1180097,  -- Realm Bank
  818059,  -- Aura of Experience
  3001005,  -- Riding Tome: Journeyman Riding
  3001006,  -- Riding Tome: Apprentice Riding
  2200033,  -- Soulbound Riding Tome: Journeyman Riding
  2200034,  -- Soulbound Riding Tome: Apprentice Riding
  106955,  -- Tome of Specialization II
  106956,  -- Tome of Specialization III
  106957,  -- Tome of Specialization IV
  106958,  -- Tome of Specialization V
  134980,  -- Tome of Specialization III
  134981,  -- Tome of Specialization IV
  134982,  -- Tome of Specialization V
  777998,  -- Tradesman's Scroll
  461566,  -- Aura of Souls
  461563,  -- Aura of Fel Power
  818061  -- Aura of Reputation
);

-- Prices x10 (75 -> 250)
UPDATE `coa_client_vanity_collection` SET `BazaarTokenCost` = CASE `BazaarTokenCost`
    WHEN 75 THEN 250
    WHEN 150 THEN 1500
    WHEN 200 THEN 2000
    WHEN 300 THEN 3000
    WHEN 350 THEN 3500
    WHEN 500 THEN 5000
  END
WHERE `BazaarTokenCost` IN (75, 150, 200, 300, 350, 500);

-- Aura of Experience 350 tokens, Potion of Experience 100 tokens
UPDATE `npc_vendor` SET `ExtendedCost` = 3015 WHERE `entry` IN (900008, 990782) AND `item` = 818059;
UPDATE `npc_vendor` SET `ExtendedCost` = 2983 WHERE `entry` IN (900008, 990782) AND `item` = 818046;
