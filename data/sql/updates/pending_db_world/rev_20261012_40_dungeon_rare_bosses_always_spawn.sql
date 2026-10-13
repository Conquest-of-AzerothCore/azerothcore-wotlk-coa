-- AzerothCore spawns these dungeon rares only some of the time: a row on AI init despawns them again with a 50-90 %
-- chance. On Ascension they are fixed encounters (all have an `instance_encounters` row, most an Ascension kit), and
-- players miss them in every run that rolls the despawn (#7348 Earthcaller Halmgar, #7349 Blind Hunter).
--  1720 Bruegal Ironknuckle      3586 Miner Johnson           3872 Captain Midwinter       4425 Blind Hunter
--  4842 Earthcaller Halmgar      5912 Brightwing              6228 Dark Iron Ambassador    7354 Ragglesnout
--  8923 Panzor the Invincible    9217 Wizz'Magg the Magus     9218 Razmorg the Decapitator 9219 Chop'gog the Butcher
--  9596 Bannok Grimaxe          10080 Sandarr Dunereaver     10081 Dustwraith            10082 Zerillis
-- 10376 Crystal Fang            10393 Skul                   10509 Jed Runewatcher       10809 Stonespine
-- 11467 Tsu'zee                 12237 Meshlok the Harvester
DELETE FROM `smart_scripts`
    WHERE `source_type` = 0 AND `id` = 0 AND `event_type` = 37 AND `action_type` = 41
      AND `entryorguid` IN (1720, 3586, 3872, 4425, 4842, 5912, 6228, 7354, 8923, 9217, 9218, 9219, 9596, 10080,
                            10081, 10082, 10376, 10393, 10509, 10809, 11467, 12237);
