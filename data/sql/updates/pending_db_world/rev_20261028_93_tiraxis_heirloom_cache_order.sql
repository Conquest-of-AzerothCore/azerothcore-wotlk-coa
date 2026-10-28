-- Tiraxis' heirloom list (900011): the heirloom set caches first, each set's two caches side by side - the
-- Experience Heirloom Cache, then the Heirloom Cache without the experience bonus - then the weapons, off-hands and
-- relics, then the pendants, rings and Stick on a Carrot.
-- Fixed slots per item, so a reapply leaves the order unchanged. Like rev_20261024_01 it only acts on a realm that
-- fills the Vanity Store price table.
UPDATE `npc_vendor` SET `slot` = CASE `item`
  WHEN 1339051 THEN 0     -- Tattered Dreadmist Raiment - Experience Heirloom Cache
  WHEN 1339058 THEN 1     -- Tattered Dreadmist Raiment - Heirloom Cache
  WHEN 1339052 THEN 2     -- Preened Ironfeather Armor - Experience Heirloom Cache
  WHEN 1339059 THEN 3     -- Preened Ironfeather Armor - Heirloom Cache
  WHEN 1339053 THEN 4     -- Stained Shadowcraft Armor - Experience Heirloom Cache
  WHEN 1339060 THEN 5     -- Stained Shadowcraft Armor - Heirloom Cache
  WHEN 1339054 THEN 6     -- Champion's Battlegear - Experience Heirloom Cache
  WHEN 1339061 THEN 7     -- Champion's Battlegear - Heirloom Cache
  WHEN 1339055 THEN 8     -- Polished Battlegear of Valor - Experience Heirloom Cache
  WHEN 1339062 THEN 9     -- Polished Battlegear of Valor - Heirloom Cache
  WHEN 1339056 THEN 10    -- Armor of Might - Experience Heirloom Cache
  WHEN 1339063 THEN 11    -- Armor of Might - Heirloom Cache
  WHEN 1339057 THEN 12    -- The Mystical Elements - Experience Heirloom Cache
  WHEN 1339064 THEN 13    -- The Mystical Elements - Heirloom Cache
  WHEN 1642999 THEN 14    -- Ancient Crossbow
  WHEN 1642944 THEN 15    -- Balanced Heartseeker
  WHEN 1644096 THEN 16    -- Battleworn Thrash Blade
  WHEN 1642943 THEN 17    -- Bloodied Arcanite Reaper
  WHEN 1642946 THEN 18    -- Charmed Ancient Bone Bow
  WHEN 1642948 THEN 19    -- Devout Aurastone Hammer
  WHEN 1642947 THEN 20    -- Dignified Headmaster's Charge
  WHEN 1644095 THEN 21    -- Grand Staff of Jordan
  WHEN 1644092 THEN 22    -- Reforged Truesilver Champion
  WHEN 1648718 THEN 23    -- Repurposed Lava Dredger
  WHEN 1518202 THEN 24    -- Rethreaded Left Bear Claw
  WHEN 1518203 THEN 25    -- Rethreaded Right Bear Claw
  WHEN 1644091 THEN 26    -- Sharpened Scarlet Kris
  WHEN 3142943 THEN 27    -- Sturdied Arcanite Spear
  WHEN 1644094 THEN 28    -- The Blessed Hammer of Grace
  WHEN 1642902 THEN 29    -- Thrown Axe of the Executioner
  WHEN 1644093 THEN 30    -- Upgraded Dwarven Hand Cannon
  WHEN 1642945 THEN 31    -- Venerable Dal'Rend's Sacred Charge
  WHEN 1648716 THEN 32    -- Venerable Mass of McGowan
  WHEN 1642846 THEN 33    -- Wand of the Forgotten Lich
  WHEN 1642896 THEN 34    -- Druid Idol of Agility
  WHEN 1642897 THEN 35    -- Druid Idol of Spells
  WHEN 1642901 THEN 36    -- Paladin Libram of Healing
  WHEN 1642900 THEN 37    -- Paladin Libram of Strength
  WHEN 3148335 THEN 38    -- Polished Observer's Shield
  WHEN 1642898 THEN 39    -- Shaman Totem of Agility
  WHEN 1642899 THEN 40    -- Shaman Totem of Spells
  WHEN 3140350 THEN 41    -- Urn of Aspiring Light
  WHEN 1339078 THEN 48    -- Pendant of the Bulwark
  WHEN 1339077 THEN 49    -- Pendant of the Sorcerer
  WHEN 1339076 THEN 50    -- Pendant of the Warrior
  WHEN 1339081 THEN 51    -- Ring of the Bulwark
  WHEN 1339082 THEN 52    -- Ring of the Lionhearted
  WHEN 1339083 THEN 53    -- Ring of the Seer
  WHEN 1339080 THEN 54    -- Ring of the Sorcerer
  WHEN 1339079 THEN 55    -- Ring of the Vanguard
  WHEN 339075 THEN 56     -- Stick on a Carrot
  ELSE `slot`
END
WHERE `entry` = 900011
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
  AND `item` IN (
  1339051, 1339052, 1339053, 1339054, 1339055, 1339056, 1339057, 1339058, 1339059, 1339060,
  1339061, 1339062, 1339063, 1339064, 1642999, 1642944, 1644096, 1642943, 1642946, 1642948,
  1642947, 1644095, 1644092, 1648718, 1518202, 1518203, 1644091, 3142943, 1644094, 1642902,
  1644093, 1642945, 1648716, 1642846, 1642896, 1642897, 1642901, 1642900, 3148335, 1642898,
  1642899, 3140350, 1339078, 1339077, 1339076, 1339081, 1339082, 1339083, 1339080, 1339079,
  339075
);
