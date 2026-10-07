-- Label Classic cache brackets with the verified item names.
-- Apply to the world database after SQL 47. Reward behaviour is unchanged.

START TRANSACTION;

UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Normal Dungeons' WHERE `bracket_id` = 1000 AND `cache_item_entry` = 1278050;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Dungeons' WHERE `bracket_id` = 1001 AND `cache_item_entry` = 1278051;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Zul''Gurub' WHERE `bracket_id` = 1002 AND `cache_item_entry` = 1278052;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Zul''Gurub' WHERE `bracket_id` = 1003 AND `cache_item_entry` = 1278053;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Zul''Gurub' WHERE `bracket_id` = 1004 AND `cache_item_entry` = 1278055;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Molten Core' WHERE `bracket_id` = 1005 AND `cache_item_entry` = 1278056;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Molten Core' WHERE `bracket_id` = 1006 AND `cache_item_entry` = 1278058;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Molten Core' WHERE `bracket_id` = 1007 AND `cache_item_entry` = 1278060;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Blackwing Lair' WHERE `bracket_id` = 1008 AND `cache_item_entry` = 1278066;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Blackwing Lair' WHERE `bracket_id` = 1009 AND `cache_item_entry` = 1278068;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Blackwing Lair' WHERE `bracket_id` = 1010 AND `cache_item_entry` = 1278069;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Ruins of Ahn''Qiraj' WHERE `bracket_id` = 1011 AND `cache_item_entry` = 1278070;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Ruins of Ahn''Qiraj' WHERE `bracket_id` = 1012 AND `cache_item_entry` = 1278072;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Ruins of Ahn''Qiraj' WHERE `bracket_id` = 1013 AND `cache_item_entry` = 1278074;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Temple of Ahn''Qiraj' WHERE `bracket_id` = 1014 AND `cache_item_entry` = 1278075;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Temple of Ahn''Qiraj' WHERE `bracket_id` = 1015 AND `cache_item_entry` = 1278077;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Temple of Ahn''Qiraj' WHERE `bracket_id` = 1016 AND `cache_item_entry` = 1278078;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Naxxramas' WHERE `bracket_id` = 1017 AND `cache_item_entry` = 1278079;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Heroic Naxxramas' WHERE `bracket_id` = 1018 AND `cache_item_entry` = 1278081;
UPDATE `manastorm_cache_bracket` SET `comment` = 'Manastorm Cache: Mythic Naxxramas' WHERE `bracket_id` = 1019 AND `cache_item_entry` = 1278083;

COMMIT;
