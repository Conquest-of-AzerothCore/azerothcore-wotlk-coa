-- The Convenience Items list of Tiraxis (vendor 900008) sells the bank vouchers for Bazaar Tokens (975001).
-- The cost rows already exist in the client's ItemExtendedCost.dbc: 3015 = 350 tokens, 3016 = 500 tokens,
-- 10337 = 800 tokens.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_guild_vault_voucher' WHERE `entry` = 102131;

DELETE FROM `npc_vendor` WHERE `entry` = 900008 AND `item` IN (110002, 1180485, 102130, 102131);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(900008, 60, 110002, 0, 0, 3015, NULL),
(900008, 61, 1180485, 0, 0, 10337, NULL),
(900008, 62, 102130, 0, 0, 10337, NULL),
(900008, 63, 102131, 0, 0, 3016, NULL);
