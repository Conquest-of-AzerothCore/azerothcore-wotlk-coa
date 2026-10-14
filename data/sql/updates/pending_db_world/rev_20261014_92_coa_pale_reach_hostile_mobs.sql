-- Pale Reach mobs that were level 1 placeholders friendly to everyone: hostile (faction 14) at the level of the quests
-- that send players to kill them, or of the mobs around them where no quest does.
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20, `faction` = 14 WHERE `entry` = 164029; -- Hexed Bloodpaw Gnoll: What the Mine Hides (min 18)
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20, `faction` = 14 WHERE `entry` = 164030; -- Bloodpaw Gnoll: same mine; What the Mine Hides (min 18)
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21, `faction` = 14 WHERE `entry` = 164051; -- Restless Corpse: Noises Below (min 19)
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21, `faction` = 14 WHERE `entry` = 164052; -- Exhumed Risen: Noises Below (min 19)
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21, `faction` = 14 WHERE `entry` = 164053; -- Sir Aldrin Nublar: named, among level 20 mobs
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164154; -- Shadewell Murloc Warrior: A Toll in Murloc Blood (22)
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164155; -- Shadewell Murloc Augur: A Toll in Murloc Blood (22)
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164162; -- Moldmoh: named; the zone's average quest level
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23, `faction` = 14 WHERE `entry` = 164223; -- Petal Prowler: mobs around it are level 23
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164237; -- Shadewell Kobold: A Toll in Kobold Blood (22)
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24, `faction` = 14 WHERE `entry` = 164269; -- Kerebor Spy: Ambush in Shadewell (24)
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24, `faction` = 14 WHERE `entry` = 164270; -- Kerebor Infiltrator: Ambush in Shadewell (24)
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164313; -- Reanimated Devotee: No Holy Dead (min 20)
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28, `faction` = 14 WHERE `entry` = 164328; -- Shadowed: Shadows in the Mine (min 27)
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29, `faction` = 14 WHERE `entry` = 164356; -- Hushed Ealdir: Morgwena's Hushed Ones (29): freed by beating them
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20, `faction` = 14 WHERE `entry` = 164358; -- Shadowarden: mobs around it are level 19
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28, `faction` = 14 WHERE `entry` = 164429; -- Quillscale Murloc: Quillscale Murlocs (28)
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28, `faction` = 14 WHERE `entry` = 164430; -- Whimsical Quillscale Murloc: Quillscale Murlocs (28)
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25, `faction` = 14 WHERE `entry` = 164459; -- Skulltaker Marauder: Funereal Marauders (25)
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25, `faction` = 14 WHERE `entry` = 164461; -- Frost Elemental: Frost Cohort (25)
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164598; -- Cardinal Royce: end of Cardinal Sin (min 19), above No Holy Dead's undead
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24, `faction` = 14 WHERE `entry` = 164599; -- Sickly Slime: A Temple in Ruins (min 23)
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164997; -- Fallen Crusader: No Holy Dead (min 20)
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22, `faction` = 14 WHERE `entry` = 164999; -- Possessed Statue of the Cardinal: beside Cardinal Royce's abbey
