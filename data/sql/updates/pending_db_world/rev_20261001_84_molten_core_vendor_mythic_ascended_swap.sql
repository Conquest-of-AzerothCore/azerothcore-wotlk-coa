-- Fixes the Mythic/Ascended tier-token vendor exchange at Major Mattingly (14394) and Overlord
-- Runthak (14392): `rev_20261001_60_molten_core_tier_token_vendors.sql` picked `npc_vendor`
-- `ExtendedCost` ids for virtual lists 91000003/91000004 (T1 Mythic/Ascended) and
-- 91000007/91000008 (T2 Mythic/Ascended) under the same backwards "27=Mythic/37=Ascended"
-- assumption already corrected for loot by `rev_20261001_73_molten_core_mythic_ascended_token_swap.sql`
-- (docs/coa/molten-core.md SS7.1: ground truth is `25xxxxx` Normal, `26xxxxx` Heroic, `37xxxxx`
-- Mythic, `27xxxxx` Ascended, per each item's own "@Heroic/@Mythic/@Ascended Raid@" tooltip tag).
--
-- Decoded `ItemExtendedCost.dbc` directly (WDBC, reqitem[0] at field index 4): the 403xx-family
-- ids used by the Mythic lists (91000003/91000007) require a `2722xxx` token -- actually
-- Ascended, not Mythic. The 302xx/305xx-family ids used by the Ascended lists
-- (91000004/91000008) require a `3722xxx` token -- actually Mythic, not Ascended. Every pair
-- shares the same per-slot suffix (e.g. 40303 <-> 30203 both resolve to the Legguards slot), so
-- the fix swaps `ExtendedCost` between the two lists per matching suffix, leaving every other
-- column (item, slot, maxcount, incrtime) untouched. Normal (91000001/91000005) and Heroic
-- (91000002/91000006) lists already use the correct 401xx/402xx (T1) and 404xx/405xx (T2)
-- families and are not touched.
--
-- T1: list 91000003 (Mythic, item offset +1300000) moves off 403xx onto 302xx (the id that
-- actually requires the 37xxxxx Mythic token); list 91000004 (Ascended, item offset +200000)
-- moves off 302xx onto 403xx (the id that actually requires the 27xxxxx Ascended token).
UPDATE `npc_vendor` SET `ExtendedCost` = 30200 WHERE `entry` = 91000003 AND `ExtendedCost` = 40300;
UPDATE `npc_vendor` SET `ExtendedCost` = 30203 WHERE `entry` = 91000003 AND `ExtendedCost` = 40303;
UPDATE `npc_vendor` SET `ExtendedCost` = 30204 WHERE `entry` = 91000003 AND `ExtendedCost` = 40304;
UPDATE `npc_vendor` SET `ExtendedCost` = 30205 WHERE `entry` = 91000003 AND `ExtendedCost` = 40305;
UPDATE `npc_vendor` SET `ExtendedCost` = 30206 WHERE `entry` = 91000003 AND `ExtendedCost` = 40306;
UPDATE `npc_vendor` SET `ExtendedCost` = 30207 WHERE `entry` = 91000003 AND `ExtendedCost` = 40307;
UPDATE `npc_vendor` SET `ExtendedCost` = 30208 WHERE `entry` = 91000003 AND `ExtendedCost` = 40308;
UPDATE `npc_vendor` SET `ExtendedCost` = 30209 WHERE `entry` = 91000003 AND `ExtendedCost` = 40309;

UPDATE `npc_vendor` SET `ExtendedCost` = 40300 WHERE `entry` = 91000004 AND `ExtendedCost` = 30200;
UPDATE `npc_vendor` SET `ExtendedCost` = 40303 WHERE `entry` = 91000004 AND `ExtendedCost` = 30203;
UPDATE `npc_vendor` SET `ExtendedCost` = 40304 WHERE `entry` = 91000004 AND `ExtendedCost` = 30204;
UPDATE `npc_vendor` SET `ExtendedCost` = 40305 WHERE `entry` = 91000004 AND `ExtendedCost` = 30205;
UPDATE `npc_vendor` SET `ExtendedCost` = 40306 WHERE `entry` = 91000004 AND `ExtendedCost` = 30206;
UPDATE `npc_vendor` SET `ExtendedCost` = 40307 WHERE `entry` = 91000004 AND `ExtendedCost` = 30207;
UPDATE `npc_vendor` SET `ExtendedCost` = 40308 WHERE `entry` = 91000004 AND `ExtendedCost` = 30208;
UPDATE `npc_vendor` SET `ExtendedCost` = 40309 WHERE `entry` = 91000004 AND `ExtendedCost` = 30209;

-- T2: list 91000007 (Mythic) moves off 406xx onto 305xx; list 91000008 (Ascended) moves off
-- 305xx onto 406xx. Same suffix-matched swap as T1 above.
UPDATE `npc_vendor` SET `ExtendedCost` = 30500 WHERE `entry` = 91000007 AND `ExtendedCost` = 40600;
UPDATE `npc_vendor` SET `ExtendedCost` = 30503 WHERE `entry` = 91000007 AND `ExtendedCost` = 40603;
UPDATE `npc_vendor` SET `ExtendedCost` = 30504 WHERE `entry` = 91000007 AND `ExtendedCost` = 40604;
UPDATE `npc_vendor` SET `ExtendedCost` = 30505 WHERE `entry` = 91000007 AND `ExtendedCost` = 40605;
UPDATE `npc_vendor` SET `ExtendedCost` = 30506 WHERE `entry` = 91000007 AND `ExtendedCost` = 40606;
UPDATE `npc_vendor` SET `ExtendedCost` = 30507 WHERE `entry` = 91000007 AND `ExtendedCost` = 40607;
UPDATE `npc_vendor` SET `ExtendedCost` = 30508 WHERE `entry` = 91000007 AND `ExtendedCost` = 40608;
UPDATE `npc_vendor` SET `ExtendedCost` = 30509 WHERE `entry` = 91000007 AND `ExtendedCost` = 40609;

UPDATE `npc_vendor` SET `ExtendedCost` = 40600 WHERE `entry` = 91000008 AND `ExtendedCost` = 30500;
UPDATE `npc_vendor` SET `ExtendedCost` = 40603 WHERE `entry` = 91000008 AND `ExtendedCost` = 30503;
UPDATE `npc_vendor` SET `ExtendedCost` = 40604 WHERE `entry` = 91000008 AND `ExtendedCost` = 30504;
UPDATE `npc_vendor` SET `ExtendedCost` = 40605 WHERE `entry` = 91000008 AND `ExtendedCost` = 30505;
UPDATE `npc_vendor` SET `ExtendedCost` = 40606 WHERE `entry` = 91000008 AND `ExtendedCost` = 30506;
UPDATE `npc_vendor` SET `ExtendedCost` = 40607 WHERE `entry` = 91000008 AND `ExtendedCost` = 30507;
UPDATE `npc_vendor` SET `ExtendedCost` = 40608 WHERE `entry` = 91000008 AND `ExtendedCost` = 30508;
UPDATE `npc_vendor` SET `ExtendedCost` = 40609 WHERE `entry` = 91000008 AND `ExtendedCost` = 30509;
