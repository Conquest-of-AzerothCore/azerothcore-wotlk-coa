-- Zalashji (#10902) credits A Serpentine Strange 255028 on Gossip Hello, but carried only the quest giver flag and
-- has no quest to offer until 255028 is rewarded, so the client never let players speak to him. Add the gossip flag.
UPDATE `creature_template` SET `npcflag` = `npcflag` | 1 WHERE `entry` = 8617;
