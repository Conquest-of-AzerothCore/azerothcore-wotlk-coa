START TRANSACTION;

UPDATE `spellvisual_dbc`
SET `ChannelKit` = 0
WHERE `ID` = 99028;

UPDATE `smart_scripts`
SET `event_phase_mask` = 0
WHERE `entryorguid` = 9916212 AND `id` IN (20, 40);

COMMIT;
