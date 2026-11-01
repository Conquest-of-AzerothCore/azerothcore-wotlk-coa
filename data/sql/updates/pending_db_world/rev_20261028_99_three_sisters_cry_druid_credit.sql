-- Three Sisters Cry (175062): the second Ealdir Dark Druid template (164033), spawned among the
-- quest's druids (164081), now gives the same kill credit
UPDATE `creature_template` SET `KillCredit1` = 164081 WHERE `entry` = 164033;
