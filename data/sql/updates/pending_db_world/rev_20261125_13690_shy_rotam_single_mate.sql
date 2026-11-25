-- #13690, #13606: Shy-Rotam (10737) called another Sian-Rotam (10741) each time she re-engaged, because an evade
-- re-arms her "(No Repeat)" summon. SMART_EVENT_FLAG_DONT_RESET (256) keeps it at one call per Shy-Rotam.
UPDATE `smart_scripts` SET `event_flags` = `event_flags` | 256
WHERE `entryorguid` = 10737 AND `source_type` = 0 AND `id` = 3 AND `event_type` = 0 AND `action_type` = 12
  AND `action_param1` = 10741 AND `event_flags` = 1;
