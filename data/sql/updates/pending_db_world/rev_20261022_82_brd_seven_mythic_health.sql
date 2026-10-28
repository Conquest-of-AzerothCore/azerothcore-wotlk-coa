-- Blackrock Depths, the Seven (Hate'rel to Dope'rel): 100000 health each on Mythic instead of the 490200 model
-- estimate (no live value exists); Heroic stays derived from Mythic (/1.30)
UPDATE `coa_dungeon_health`
SET `max_health` = 100000, `evidence` = 'assumption',
    `source` = CONCAT('issue 8356 (22.10.2026); ', SUBSTRING_INDEX(`source`, '; ', -1))
WHERE `map_id` = 230 AND `difficulty` = 2 AND `creature_entry` BETWEEN 9034 AND 9040;
UPDATE `coa_dungeon_health`
SET `max_health` = 76923, `evidence` = 'assumption',
    `source` = CONCAT('Heroic from Mythic; issue 8356 (22.10.2026); ', SUBSTRING_INDEX(`source`, '; ', -1))
WHERE `map_id` = 230 AND `difficulty` = 1 AND `creature_entry` BETWEEN 9034 AND 9040;
