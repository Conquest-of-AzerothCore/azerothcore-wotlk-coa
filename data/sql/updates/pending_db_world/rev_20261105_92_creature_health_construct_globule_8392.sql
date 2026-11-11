-- #8392: Shadowy Construct and Ichor Globule had HealthModifier 1000 instead of AzerothCore's 5.95 and 0.181802.
UPDATE `creature_template` SET `HealthModifier` = 5.95
WHERE `entry` = 23111 AND `HealthModifier` BETWEEN 999.999 AND 1000.001;
UPDATE `creature_template` SET `HealthModifier` = 0.181802
WHERE `entry` = 29321 AND `HealthModifier` BETWEEN 999.999 AND 1000.001;
