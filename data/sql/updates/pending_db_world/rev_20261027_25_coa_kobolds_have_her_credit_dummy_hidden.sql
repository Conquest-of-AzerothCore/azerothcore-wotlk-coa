-- The Kobolds Have Her (175071): the five clue talkers [TG] The Kobols Have Her (164520), invisible stalkers spawned on
-- the Shadewell Cave clues, lacked the trigger flag the Shadewell Falls clue talkers (164519) carry, so the client drew
-- their shadow as a yellow ring under each clue.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 128 WHERE `entry` = 164520;
