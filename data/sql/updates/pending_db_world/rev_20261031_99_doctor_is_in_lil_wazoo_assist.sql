-- The Doctor Is In! (200027): Lil Wa'zoo lacked CREATURE_TYPE_FLAG_CAN_ASSIST, so Loa's Brew could not target him
-- and the client cast it on the player instead; Hi'bi Ja'min, the quest's other patient, already has the flag
UPDATE `creature_template` SET `type_flags` = `type_flags` | 4096 WHERE `entry` = 85031;
