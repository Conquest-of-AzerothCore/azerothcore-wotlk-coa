-- The Bazaar Token (975001) vendor items that could still be traded are Realm Bound: bonding 1 plus
-- ITEM_FLAG_IS_BOUND_TO_ACCOUNT (0x08000000), which the Ascension client shows as "Realm Bound". Tokens from the Elite
-- Warchest and the Daily Login Reward cannot leave the account, so what they buy cannot either. Copies that already
-- exist are bound by rev_20261120_01_bind_token_vendor_item_copies. A reapply leaves the result unchanged.
UPDATE `item_template`
SET `bonding` = 1, `Flags` = `Flags` | 0x08000000
WHERE `entry` IN (
  97388,    -- Keeper's Scroll: Zoomer
  246194,   -- Keeper's Scroll: Sargeras
  246199,   -- Keeper's Scroll: Aman'thul
  969029,   -- Ethereal Cache of Wares
  102130,   -- Ornate Bank Voucher
  102131,   -- Guild Vault Voucher
  110002,   -- Personal Bank Tab Voucher
  1180485,  -- Realm Bank Tab Voucher
  1203466,  -- Stone of Retreat: Zul'Gurub
  1203467,  -- Stone of Retreat: Blackrock Mountain
  1203468,  -- Stone of Retreat: Gates of Ahn'Qiraj
  1203469,  -- Stone of Retreat: Onyxia's Lair
  1880045,  -- Stone of Retreat: Goldshire
  1880046,  -- Stone of Retreat: Razor Hill
  8950001,  -- Lost Weapon Cache
  8950002,  -- Lost Armor Cache
  8950003,  -- Lost Mount Cache
  8950004,  -- Lost Spell Cache
  8950005,  -- Lost Pet Cache
  8950006,  -- Lost Beast Cache
  8950008   -- Lost Curio Cache
);
