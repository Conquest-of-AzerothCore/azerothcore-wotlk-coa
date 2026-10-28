-- #5726: Conjure Thunderkeg (spell 807849, Stormbringer) is SPELL_EFFECT_TRANS_DOOR (Effect[0]=50) with
-- EffectMiscValue[0]=195002 (Spell.dbc, confirmed via coa-dbc-viewer). Spell::EffectTransmitted
-- (SpellEffects.cpp) looks the id up with sObjectMgr->GetGameObjectTemplate and silently returns, logging
-- "Gameobject (Entry: {}) not exist", when the row is missing; no gameobject_template row for 195002 exists
-- anywhere under data/sql (base, archive, updates, pending) -- same defect class PR #5651 fixed for the
-- Ancestral Keg (9000118), just not yet fixed for this one.
--
-- Source: hertigservices/ascension-data, release exiles-db-export-2026-09-13 (asset
-- coa-public-2026-09-13-tables.tar), table `gameobject`, row id 195002: name "Thunderkeg", type 22
-- (GAMEOBJECT_TYPE_SPELLCASTER), display_id 1013445, misc_info empty (same as the Ancestral Keg row in that
-- export). GameObjectDisplayInfo.dbc id 1013445 exists in the local client set
-- (/home/fab/CoaServer/dbc_clientset), corroborating the display id.
--
-- The export's misc_info being empty means the object's on-use spell (Data0) and charges (Data1) are not
-- established by this source and are left at schema default (0); Spell::EffectTransmitted does not read
-- type-specific Data fields to spawn the object (only GAMEOBJECT_TYPE_FISHINGNODE/SUMMONING_RITUAL/
-- DUEL_ARBITER get special handling, GAMEOBJECT_TYPE_SPELLCASTER falls to `default`), so this is sufficient
-- to fix the reported "not spawning" defect. Whatever the Thunderkeg is meant to do once used is a separate,
-- unreported question this migration does not answer.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`,
`name`, `size`) VALUES
(195002, 22, 1013445, 'Thunderkeg', 1)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`),
`name` = VALUES(`name`), `size` = VALUES(`size`);
