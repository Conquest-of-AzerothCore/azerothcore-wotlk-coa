-- Heroic and Mythic copies of dungeon and raid creatures (entry + 100000, + 200000, + 300000) give the same
-- reputation on kill as the base creature, as Zul'Gurub already does.
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` IN (SELECT `d`.`entry` FROM (
SELECT `t`.`difficulty_entry_1` AS `entry` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_1` = `t`.`entry` + 100000
UNION
SELECT `t`.`difficulty_entry_2` AS `entry` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_2` = `t`.`entry` + 200000
UNION
SELECT `t`.`difficulty_entry_3` AS `entry` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_3` = `t`.`entry` + 300000
) AS `d`);
INSERT INTO `creature_onkill_reputation` (`creature_id`, `RewOnKillRepFaction1`, `RewOnKillRepFaction2`, `MaxStanding1`, `IsTeamAward1`, `RewOnKillRepValue1`, `MaxStanding2`, `IsTeamAward2`, `RewOnKillRepValue2`, `TeamDependent`)
SELECT `t`.`difficulty_entry_1`, `b`.`RewOnKillRepFaction1`, `b`.`RewOnKillRepFaction2`, `b`.`MaxStanding1`, `b`.`IsTeamAward1`, `b`.`RewOnKillRepValue1`, `b`.`MaxStanding2`, `b`.`IsTeamAward2`, `b`.`RewOnKillRepValue2`, `b`.`TeamDependent` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_1` = `t`.`entry` + 100000
UNION ALL
SELECT `t`.`difficulty_entry_2`, `b`.`RewOnKillRepFaction1`, `b`.`RewOnKillRepFaction2`, `b`.`MaxStanding1`, `b`.`IsTeamAward1`, `b`.`RewOnKillRepValue1`, `b`.`MaxStanding2`, `b`.`IsTeamAward2`, `b`.`RewOnKillRepValue2`, `b`.`TeamDependent` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_2` = `t`.`entry` + 200000
UNION ALL
SELECT `t`.`difficulty_entry_3`, `b`.`RewOnKillRepFaction1`, `b`.`RewOnKillRepFaction2`, `b`.`MaxStanding1`, `b`.`IsTeamAward1`, `b`.`RewOnKillRepValue1`, `b`.`MaxStanding2`, `b`.`IsTeamAward2`, `b`.`RewOnKillRepValue2`, `b`.`TeamDependent` FROM `creature_template` `t`
JOIN `creature_onkill_reputation` `b` ON `b`.`creature_id` = `t`.`entry`
WHERE `t`.`difficulty_entry_3` = `t`.`entry` + 300000;
