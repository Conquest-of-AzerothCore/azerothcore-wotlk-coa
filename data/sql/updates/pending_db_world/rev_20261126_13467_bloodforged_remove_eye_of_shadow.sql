-- Remove Bloodforged The Eye of Shadow (6018665) from coa_bloodforged_catalogue (#13467).
-- Its base item (18665) is the Benediction/Anathema Priest quest trinket with SellPrice 0 and no stats;
-- the Bloodforged copy cannot be sold and has no stats or equip/use effects beyond resilience and PvP power.
DELETE FROM `coa_bloodforged_catalogue` WHERE `entry` = 6018665;
