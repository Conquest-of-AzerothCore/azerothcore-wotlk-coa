-- Grimtotem Marauder 161809: the "Victim 8-25 yd - Cast Charge" range event had its range in the timer
-- parameters (8, 25, 15000, 20000, 0, 0), so the range check was 0-0 yd and Charge 22120 never fired.
UPDATE `smart_scripts`
SET `event_param1` = 0, `event_param2` = 0, `event_param3` = 15000, `event_param4` = 20000,
    `event_param5` = 8, `event_param6` = 25
WHERE `entryorguid` = 161809 AND `source_type` = 0 AND `id` = 2 AND `event_type` = 9 AND `action_type` = 11
  AND `action_param1` = 22120;
