-- Blackrock Caverns decorative Twilight Element Warden corpses (spawns 6450150-6450153, Permanent Feign Death 29266)
-- were attackable (#11373).
-- Per spawn only: entry 40017 is also the live warden at 6450154-6450167. NON_ATTACKABLE (2) is what Galaen's Corpse
-- 17508 carries.
UPDATE `creature` SET `unit_flags` = `unit_flags` | 2
WHERE `guid` IN (6450150, 6450151, 6450152, 6450153) AND `id` = 40017 AND `map` = 645 AND `unit_flags` = 0;
