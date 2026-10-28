-- CoA Elwynn: Agent Serina Vale serves Stormwind, so Horde characters no longer get her dig (#6064).
--
-- rev_20260923_01_coa_elwynn_quests.sql created her two copies (996114 in Goldshire, 996115 on the cliff above the
-- Bandit's Bastion) with faction 35, friendly to everyone, because no source carries her. Every other NPC of her
-- chain is a Stormwind faction 12 NPC (General Marcus Jonathan 466, Theocritus 313, Kitta Firewind 11072), the
-- quests 254038-254108 reward Stormwind reputation (RewardFactionId1 72) and the other Goldshire quest givers of the
-- same pack (Melika Isenstrider 6778, Esyra 900017, Aldia Crayon 162802) use faction 12. A Horde character could
-- therefore take Start Digging 254038 in Goldshire from the only giver of the chain that was not hostile to it.
-- The nearest Defias Bandit 116 stands 38 yd from the cliff copy, outside its 18 yd detection range.

UPDATE `creature_template` SET `faction` = 12 WHERE `entry` IN (996114, 996115);
