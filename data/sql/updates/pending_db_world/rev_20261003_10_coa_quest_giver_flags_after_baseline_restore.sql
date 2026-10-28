-- The Northshire baseline restore (rev_20260930_98) rewrote the valley's creature templates from their
-- pre-revamp rows. Three of them are the only quest giver for their CoA quest chain and the old rows had
-- no quest giver flag, so their quest markers and gossip never appear (Dawn Brightstar for Mixed Reagents,
-- #6289 and #6275; Kitta Firewind for Enchant the Mineral; Tharynn Bouden for Extravagant Order). The
-- Elwynn migration (rev_20260923_01) had already set this flag with `npcflag | 2`; the restore reset the
-- whole column. Re-apply that bit; the rest of each restored row is intentional revamp data.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 2 WHERE `entry` IN (66, 958, 11072);
