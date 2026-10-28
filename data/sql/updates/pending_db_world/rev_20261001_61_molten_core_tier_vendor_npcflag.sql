-- Major Mattingly (14394) and Overlord Runthak (14392) carry npcflag=3 (GOSSIP 0x1 +
-- QUESTGIVER 0x2 -- UnitDefines.h) and no UNIT_NPC_FLAG_VENDOR (0x80): diag-P-token-exchange.md's
-- "already has the gossip+vendor npcflag" was checked directly against the flag values and was
-- wrong -- the vendor bit was never set, so the vendor window could not open regardless of
-- npc_vendor content. Adds 0x80, keeping the existing gossip/questgiver bits (3 | 128 = 131).
-- Both NPCs get `npc_coa_tier_token_vendor` (src/server/coa/AscensionTierTokenVendor.cpp): per
-- the player's own recollection of live CoA, talking to either NPC shows 8 gossip options
-- ("Tokens T1 Normal/Heroic/Mythic/Ascended", same four for T2), each opening a vendor list
-- scoped to that tier only via the 91000001-91000008 virtual vendor entries wired in
-- rev_20261001_60_molten_core_tier_token_vendors.sql, not the creature's own direct npc_vendor.
UPDATE `creature_template` SET `npcflag` = 131, `ScriptName` = 'npc_coa_tier_token_vendor'
WHERE `entry` IN (14392, 14394);
