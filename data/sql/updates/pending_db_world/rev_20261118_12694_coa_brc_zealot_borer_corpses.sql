-- Blackrock Caverns decorative corpses that #11373 left attackable (#12694): the Twilight Obsidian Borer in Beauty's
-- lair (6450168) and the Twilight Zealots 6450097-6450101 carry Permanent Feign Death 29266, so attacking one left the
-- player in combat and unable to leave the dungeon.
-- Per spawn only: entries 39990 and 40019 are also the live trash elsewhere in the dungeon. NON_ATTACKABLE (2), as
-- the Element Warden corpses 6450150-6450153 received in #11373.
UPDATE `creature` SET `unit_flags` = `unit_flags` | 2
WHERE `guid` IN (6450097, 6450098, 6450099, 6450100, 6450101) AND `id` = 39990 AND `map` = 645 AND `unit_flags` = 0;
UPDATE `creature` SET `unit_flags` = `unit_flags` | 2
WHERE `guid` = 6450168 AND `id` = 40019 AND `map` = 645 AND `unit_flags` = 0;
