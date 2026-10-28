-- Ranger Campsite 807955 places three objects (SPELL_EFFECT_TRANS_DOOR): Bright Campfire 31511 and the two
-- Ranger's Campsite bedrolls 1005767 and 1005768. The bedrolls had no gameobject_template row, so
-- Spell::EffectTransmitted skipped them and only the campfire appeared.
--
-- Source: captured client gameobject cache (hertigservices/ascension-data cachedata, conquest-of-azeroth,
-- captured 2026-09-10): type 22 (GAMEOBJECT_TYPE_SPELLCASTER), size 1, Data0 583404 'Resting' (the spell cast on
-- the user), Data1 0 charges (unlimited), Data2 1 party only, Data3 1 usable mounted. Display 1011606
-- (bedroll_01) for 1005767 and 1011282 (sherpa_bedroll_02) for 1005768; older captures (coa-beta, free-pick)
-- carry the stand-in 7727, which Exiles DB records as replaced on 2026-08-01. Both displays exist in the server
-- and client GameObjectDisplayInfo.dbc.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `Data2`, `Data3`)
VALUES
(1005767, 22, 1011606, 'Ranger''s Campsite', 1, 583404, 0, 1, 1),
(1005768, 22, 1011282, 'Ranger''s Campsite', 1, 583404, 0, 1, 1)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
    `Data3` = VALUES(`Data3`);
