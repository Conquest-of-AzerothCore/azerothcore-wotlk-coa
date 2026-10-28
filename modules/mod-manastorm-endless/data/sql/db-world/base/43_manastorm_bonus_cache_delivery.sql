-- Apply to acore_world after SQL 42.
-- Shared automatic bag delivery/mail overflow for both Bonus Cache variants.
-- Loot profiles, material weights and gold quantities are unchanged.
UPDATE `item_template` SET `ScriptName` = 'item_manastorm_bonus_cache' WHERE `entry` IN (1478051, 1478052);
