-- ============================================================================
-- Conquest of AzerothCore / mod-manastorm-endless
-- Transfer legacy Manastorm cache opening ownership from mod-ascension-compat
-- to mod-manastorm-endless.
--
-- These are the only recovered item_template rows still bound to
-- item_ascension_manastorm_cache. Newer TBC caches are ordinary HAS_LOOT
-- containers and intentionally have no per-item ScriptName.
-- ============================================================================

UPDATE `item_template`
SET `ScriptName` = 'item_manastorm_cache'
WHERE `entry` IN
(
    97877,
    97878,
    97879,
    97880,
    97881,
    97882,
    97883,
    1278050,
    1278051
)
AND `ScriptName` = 'item_ascension_manastorm_cache';

SELECT
    `entry`,
    `name`,
    `ScriptName`
FROM `item_template`
WHERE `entry` IN
(
    97877,
    97878,
    97879,
    97880,
    97881,
    97882,
    97883,
    1278050,
    1278051
)
ORDER BY `entry`;
