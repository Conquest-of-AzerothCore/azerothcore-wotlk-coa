-- Valerius Thorne (501266) stands beside Troes the Remover in Northshire Valley. The Northshire baseline
-- restore (rev_20260930_98) reset his template to npcflag 179 (gossip, trainer, class trainer, vendor) although
-- he has no vendor items, no trainer and no gossip menu, so the client shows the merchant bag over a trainer that
-- sells nothing (#6118). Restore the gossip-only flag the Northshire port (rev_20260929_92) gave him.
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` = 501266;
