-- Mythic+ rewards (mod-coa-mythic-plus): Mythical Caches (Mythic 1-12)
-- open through the module's item script.
UPDATE `item_template` SET `ScriptName` = 'item_coa_mythic_cache' WHERE `entry` IN (2093952, 2093963, 2093964, 2093965,
    2093966, 2093967, 2093968, 2093995, 2093996, 2093997, 2093998, 2093999);
