-- Tiraxis' heirloom list (900011): new Bazaar Token prices. Amounts are ItemExtendedCost.dbc rows
-- (item 975001 x count); the DBC has no 1750 row, so the
-- Experience Heirloom Caches use 1800.

-- Heirloom Caches: 1500 tokens
UPDATE `npc_vendor` SET `ExtendedCost` = 10344 WHERE `entry` = 900011 AND `item` IN (
  1339058, 1339059, 1339060, 1339061, 1339062, 1339063, 1339064);

-- Experience Heirloom Caches: 1800 tokens
UPDATE `npc_vendor` SET `ExtendedCost` = 10347 WHERE `entry` = 900011 AND `item` IN (
  1339051, 1339052, 1339053, 1339054, 1339055, 1339056, 1339057);

-- One-handed weapons, the shield, the off-hand and the trinkets: 900 tokens (half a two-hander)
UPDATE `npc_vendor` SET `ExtendedCost` = 10338 WHERE `entry` = 900011 AND `item` IN (
  1642944,  -- Balanced Heartseeker
  1644096,  -- Battleworn Thrash Blade
  1642948,  -- Devout Aurastone Hammer
  1518202,  -- Rethreaded Left Bear Claw
  1518203,  -- Rethreaded Right Bear Claw
  1644091,  -- Sharpened Scarlet Kris
  1644094,  -- The Blessed Hammer of Grace
  1642945,  -- Venerable Dal'Rend's Sacred Charge
  1648716,  -- Venerable Mass of McGowan
  3148335,  -- Polished Observer's Shield
  1642992,  -- Discerning Eye of the Beast
  1644098,  -- Inherited Insignia of the Alliance
  1644097,  -- Inherited Insignia of the Horde
  1642991,  -- Swift Hand of Justice
  3140350   -- Urn of Aspiring Light
);

-- Two-handed weapons: 1800 tokens
UPDATE `npc_vendor` SET `ExtendedCost` = 10347 WHERE `entry` = 900011 AND `item` IN (
  1642943,  -- Bloodied Arcanite Reaper
  1642947,  -- Dignified Headmaster's Charge
  1644095,  -- Grand Staff of Jordan
  1644092,  -- Reforged Truesilver Champion
  1648718,  -- Repurposed Lava Dredger
  3142943   -- Sturdied Arcanite Spear
);

-- Ranged weapons and relics: 1000 tokens
UPDATE `npc_vendor` SET `ExtendedCost` = 10339 WHERE `entry` = 900011 AND `item` IN (
  1642999,  -- Ancient Crossbow
  1642946,  -- Charmed Ancient Bone Bow
  1642902,  -- Thrown Axe of the Executioner
  1644093,  -- Upgraded Dwarven Hand Cannon
  1642846,  -- Wand of the Forgotten Lich
  1642896,  -- Druid Idol of Agility
  1642897,  -- Druid Idol of Spells
  1642901,  -- Paladin Libram of Healing
  1642900,  -- Paladin Libram of Strength
  1642898,  -- Shaman Totem of Agility
  1642899   -- Shaman Totem of Spells
);
