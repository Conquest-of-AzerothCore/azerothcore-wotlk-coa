-- rev_20260930_99_ASC_northshire_revamp.sql (section 4, a Northshire Valley field-level
-- reconciliation unrelated to Molten Core) flattens every map-409 spawnMask back to 1
-- (`UPDATE creature/gameobject SET spawnMask = 1 WHERE map IN (309, 531, 509, 469, 409)
-- AND spawnMask = 15`), undoing modules/mod-coa-raid-difficulty's
-- 02_mc_difficulty_spawns.sql, which puts every MC creature/gameobject on all four
-- difficulty bits (15) so the core spawns them for Heroic/Mythic/Ascended too. That file
-- sorts before the ASC revamp by filename, so without this restore MC is empty on
-- Ascended/Mythic/Heroic. Re-assert spawnMask = 15 for every map-409 row, including the
-- Majordomo portal gameobject added at spawnMask 1 in
-- rev_20261001_08_molten_core_majordomo_portal.sql, since its visibility is already gated
-- by the instance script's encounter state rather than by the spawn mask.
--
-- The same ASC revamp statement also narrows spawnMask on maps 309, 531, 509, 469 (to 1)
-- and 249 (to 3). Those are other raids, out of this fix's scope; left as a known related
-- finding (see docs/coa/molten-core.md).

UPDATE `creature` SET `spawnMask` = 15 WHERE `map` = 409;
UPDATE `gameobject` SET `spawnMask` = 15 WHERE `map` = 409;
