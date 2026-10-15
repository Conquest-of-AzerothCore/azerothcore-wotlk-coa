-- Unholy Sin, the reward of "Cardinal Sin", was a placeholder: its stats from the user's screenshot of the live tooltip
-- (one-hand, item level 25, 32-52 damage at 16.8 per second, +4 Strength, +2 Stamina, +4 Intellect, +6 Spirit, +2 Shadow
-- Resistance, binds when picked up, sells for 40s 96c). Its two Equip: lines are cut off in the screenshot and left out.
UPDATE `item_template` SET `name` = 'Unholy Sin', `Quality` = 3, `ItemLevel` = 25, `bonding` = 1, `dmg_min1` = 32, `dmg_max1` = 52,
  `dmg_type1` = 0, `delay` = 2500, `stat_type1` = 4, `stat_value1` = 4, `stat_type2` = 7, `stat_value2` = 2,
  `stat_type3` = 5, `stat_value3` = 4, `stat_type4` = 6, `stat_value4` = 6, `shadow_res` = 2, `SellPrice` = 4096,
  `BuyPrice` = 20480 WHERE `entry` = 560146;
