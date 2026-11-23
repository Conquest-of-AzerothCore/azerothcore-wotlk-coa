UPDATE `ethereal_bazaar_set_cache`
SET `member_item` = CASE `member_item` WHEN 297892 THEN 499683 WHEN 297893 THEN 499680 WHEN 297894 THEN 499681 END
WHERE `cache_item` IN (673299, 918854) AND `member_item` IN (297892, 297893, 297894);
