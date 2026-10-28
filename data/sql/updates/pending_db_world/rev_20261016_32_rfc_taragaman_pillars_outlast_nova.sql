-- The Rumbling Earth pillars (663030) despawned 15 s after Taragaman raised them, but cast slows on him stretch the
-- 6 s Massive Fire Nova (started at 7 s) past that, so it hit the whole group (#7764). The pillars now crumble 0.5 s
-- after the nova lands (spell_coa_massive_fire_nova sets data 1 on them) and fall back to 28.5 s if it never does.
UPDATE `smart_scripts` SET `action_param3` = 30000
WHERE `entryorguid` = 11520 AND `source_type` = 0 AND `id` = 9010;
UPDATE `smart_scripts` SET `action_param2` = 24,
    `comment` = 'Earth Pillar - Timed Event - Collision core until it crumbles'
WHERE `entryorguid` = 663030 AND `source_type` = 0 AND `id` = 7;
UPDATE `smart_scripts` SET `action_param2` = 23500, `action_param3` = 23500,
    `comment` = 'Earth Pillar - Timed Event - Crumble if no nova landed'
WHERE `entryorguid` = 663030 AND `source_type` = 0 AND `id` = 8;
UPDATE `smart_scripts` SET `link` = 11 WHERE `entryorguid` = 663030 AND `source_type` = 0 AND `id` = 10;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 663030 AND `source_type` = 0 AND `id` IN (11, 12);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(663030, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Earth Pillar - Timed Event - Despawn after crumbling'),
(663030, 0, 12, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 67, 2, 500, 500, 0, 0, 100, 1, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 'Earth Pillar - Data Set - Crumble after the Massive Fire Nova lands');
