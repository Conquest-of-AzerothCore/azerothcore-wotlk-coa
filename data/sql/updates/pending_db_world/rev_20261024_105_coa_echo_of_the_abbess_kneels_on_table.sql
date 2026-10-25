-- Echo of the Abbess (161858) hovered two yards above the trial table she is spawned on; she kneels on it.
UPDATE `creature_template_movement` SET `Ground` = 1, `Flight` = 0 WHERE `CreatureId` = 161858;
UPDATE `creature_template` SET `HoverHeight` = 1 WHERE `entry` = 161858;
