-- #5153, #4258: Ancestral Keg 804748 is SPELL_EFFECT_TRANS_DOOR with EffectMiscValue 9000118. Spell::EffectTransmitted
-- (SpellEffects.cpp) looks the id up with sObjectMgr->GetGameObjectTemplate and silently returns, logging
-- "Gameobject (Entry: {}) not exist", when the row is missing; no gameobject_template row for 9000118 exists
-- anywhere under data/sql (base, archive, updates, pending), matching the reports exactly ("did the animation,
-- but nothing showed up" / "Places nothing").
--
-- Source: hertigservices/ascension-data, release exiles-db-export-2026-09-13 (asset
-- coa-public-2026-09-13-tables.tar), table `gameobject`, row id 9000118: name "Ancestral Keg", type 22
-- (GAMEOBJECT_TYPE_SPELLCASTER), display_id 1011172. GameObjectDisplayInfo.dbc id 1011172 exists in the local
-- client set (/home/fab/CoaServer/dbc_clientset), corroborating the display id.
--
-- The export's `misc_info` column (where Data0.. would be recorded) is empty for this row and for every other
-- GAMEOBJECT_TYPE_SPELLCASTER row in the same snapshot, so the object's on-use spell (Data0) and charges
-- (Data1) are not established by this source and are left at schema default (0); Spell::EffectTransmitted does
-- not read type-specific Data fields to spawn the object (only GAMEOBJECT_TYPE_FISHINGNODE/SUMMONING_RITUAL/
-- DUEL_ARBITER get special handling, GAMEOBJECT_TYPE_SPELLCASTER falls to `default`), so this is sufficient to
-- fix the reported "nothing spawns" defect. Whether using the spawned Keg then grants a drink buff is a
-- separate, unreported question this migration does not answer.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`,
`name`, `size`) VALUES
(9000118, 22, 1011172, 'Ancestral Keg', 1)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`),
`name` = VALUES(`name`), `size` = VALUES(`size`);
