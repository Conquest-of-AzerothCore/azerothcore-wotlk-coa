-- Lady Serenya Coldmere (164005): wait for each voiced line of Posthumous Confession (175123) to end before the
-- next one, as rev_20261119_12822 does for Anzuldin: each timer is the clip rounded up plus one second.
UPDATE `smart_scripts` SET `action_param2` = 10000,
    `comment` = 'Lady Serenya Coldmere - On Link - Say Line 3 (senerya1.wav 8.4 s)'
WHERE `entryorguid` = 164005 AND `source_type` = 0 AND `id` = 6 AND `action_type` = 1
    AND `action_param1` = 3 AND `action_param2` = 7000;
UPDATE `smart_scripts` SET `action_param2` = 15000,
    `comment` = 'Lady Serenya Coldmere - On Text 3 Over - Say Line 4 (senerya2.wav 13.4 s)'
WHERE `entryorguid` = 164005 AND `source_type` = 0 AND `id` = 3 AND `action_type` = 1
    AND `action_param1` = 4 AND `action_param2` = 7000;
UPDATE `smart_scripts` SET `action_param2` = 10000,
    `comment` = 'Lady Serenya Coldmere - On Text 4 Over - Say Line 5 (senerya5.wav 8.2 s)'
WHERE `entryorguid` = 164005 AND `source_type` = 0 AND `id` = 4 AND `action_type` = 1
    AND `action_param1` = 5 AND `action_param2` = 7000;
UPDATE `smart_scripts` SET `action_param2` = 14000,
    `comment` = 'Lady Serenya Coldmere - On Text 5 Over - Say Line 6 (senerya6.wav 12.7 s)'
WHERE `entryorguid` = 164005 AND `source_type` = 0 AND `id` = 7 AND `action_type` = 1
    AND `action_param1` = 6 AND `action_param2` = 7000;
