-- Level-60 Burning Crusade Heroic dungeons need no heroic key or attunement quest, like their Mythic difficulty.
DELETE FROM `dungeon_access_requirements`
WHERE `dungeon_access_id` IN (18, 34, 36, 38, 41, 43, 45, 49, 51, 53, 55, 57, 59, 61, 63, 77);
