-- Road to De Other Side (map 937) opens again: DestinyWeaver scales its Normal tier (finder entry 402, band 15-59).
-- Vaults of the Inquisition (map 936) too: live realms closed it by hand to players and the Dungeon Finder while its
-- per-difficulty rules and melee were wrong; it scales 15-59 on Normal (finder entry 401).
DELETE FROM `disables` WHERE `sourceType` IN (2, 8) AND `entry` IN (936, 937);
