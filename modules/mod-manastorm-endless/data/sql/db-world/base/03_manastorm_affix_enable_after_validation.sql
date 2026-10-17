
-- Enable only after the direct-unlock C++ path and forced-affix runtime tests pass.
UPDATE `manastorm_unlock`
SET `enabled`=1
WHERE `unlock_id` IN
(900011,900013,900016,900019,900021,900023,900026,
 900028,900031,900033,900039,900041,900061,900101);

UPDATE `manastorm_unlock_grant`
SET `enabled`=1
WHERE `unlock_id` IN
(900011,900013,900016,900019,900021,900023,900026,
 900028,900031,900033,900039,900041,900061,900101)
AND `grant_type`=4;
