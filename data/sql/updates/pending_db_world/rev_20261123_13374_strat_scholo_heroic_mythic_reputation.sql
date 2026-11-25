-- Heroic and Mythic Stratholme and Scholomance creatures give no Argent Dawn reputation: kill reputation is read for
-- the active difficulty template (difficulty_entry_1 Heroic, difficulty_entry_2 Mythic), and none of them had a row.
-- Each copies its Normal entry's row (faction, value and standing cap), as Zul'Gurub's difficulty templates do.
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` IN (
    SELECT `difficulty_entry` FROM (
        SELECT `entry`, `difficulty_entry_1` AS `difficulty_entry` FROM `creature_template` WHERE `difficulty_entry_1` > 0
        UNION ALL
        SELECT `entry`, `difficulty_entry_2` FROM `creature_template` WHERE `difficulty_entry_2` > 0
    ) AS `d`
    WHERE `d`.`entry` IN (1853, 10381, 10382, 10383, 10384, 10385, 10387, 10390, 10391, 10393, 10398, 10399, 10400,
    10405, 10406, 10407, 10408, 10409, 10411, 10412, 10413, 10414, 10416, 10417, 10432, 10433, 10435, 10436, 10437,
    10438, 10439, 10440, 10463, 10464, 10469, 10470, 10471, 10476, 10477, 10478, 10480, 10481, 10482, 10485, 10486,
    10487, 10488, 10489, 10491, 10495, 10498, 10499, 10500, 10502, 10503, 10504, 10505, 10506, 10507, 10508, 10516,
    10558, 10808, 10809, 10901, 11058, 11082, 11197, 11257, 11261, 11263, 11551, 11582, 11622, 14516, 14861, 16101,
    16102));
INSERT INTO `creature_onkill_reputation` (`creature_id`, `RewOnKillRepFaction1`, `RewOnKillRepFaction2`,
    `MaxStanding1`, `IsTeamAward1`, `RewOnKillRepValue1`, `MaxStanding2`, `IsTeamAward2`, `RewOnKillRepValue2`,
    `TeamDependent`)
SELECT `d`.`difficulty_entry`, `r`.`RewOnKillRepFaction1`, `r`.`RewOnKillRepFaction2`, `r`.`MaxStanding1`,
    `r`.`IsTeamAward1`, `r`.`RewOnKillRepValue1`, `r`.`MaxStanding2`, `r`.`IsTeamAward2`, `r`.`RewOnKillRepValue2`,
    `r`.`TeamDependent`
FROM (
    SELECT `entry`, `difficulty_entry_1` AS `difficulty_entry` FROM `creature_template` WHERE `difficulty_entry_1` > 0
    UNION ALL
    SELECT `entry`, `difficulty_entry_2` FROM `creature_template` WHERE `difficulty_entry_2` > 0
) AS `d`
JOIN `creature_onkill_reputation` AS `r` ON `r`.`creature_id` = `d`.`entry`
WHERE `d`.`entry` IN (1853, 10381, 10382, 10383, 10384, 10385, 10387, 10390, 10391, 10393, 10398, 10399, 10400,
    10405, 10406, 10407, 10408, 10409, 10411, 10412, 10413, 10414, 10416, 10417, 10432, 10433, 10435, 10436, 10437,
    10438, 10439, 10440, 10463, 10464, 10469, 10470, 10471, 10476, 10477, 10478, 10480, 10481, 10482, 10485, 10486,
    10487, 10488, 10489, 10491, 10495, 10498, 10499, 10500, 10502, 10503, 10504, 10505, 10506, 10507, 10508, 10516,
    10558, 10808, 10809, 10901, 11058, 11082, 11197, 11257, 11261, 11263, 11551, 11582, 11622, 14516, 14861, 16101,
    16102);
