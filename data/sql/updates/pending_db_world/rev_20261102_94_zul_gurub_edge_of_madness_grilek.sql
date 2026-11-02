-- Edge of Madness as on live CoA: the Brazier of Madness (180327) always summons Gri'lek (15082) and needs no
-- Gurubashi Mojo Madness. Live client captures (AscensionDB gameobjectcache, 2026-09-04) send the brazier with
-- lock 0, and the live log of 2026-08-02 summons Gri'lek during what the stock rotation makes Wushoolay's window;
-- Hazza'rah, Renataki and Wushoolay appear in no player capture. Event 27 stays active for good, the other three
-- end, and the Edge of Madness encounter credits Gri'lek.

UPDATE `game_event` SET `occurence` = 525600, `length` = 525600 WHERE `eventEntry` = 27;
UPDATE `game_event` SET `end_time` = `start_time` WHERE `eventEntry` IN (28, 29, 30);

UPDATE `gameobject_template` SET `Data1` = 0 WHERE `entry` = 180327;

UPDATE `instance_encounters` SET `creditEntry` = 15082
 WHERE `entry` IN (788, 4397, 4401, 4405, 4409) AND `creditType` = 0 AND `creditEntry` = 15083;
