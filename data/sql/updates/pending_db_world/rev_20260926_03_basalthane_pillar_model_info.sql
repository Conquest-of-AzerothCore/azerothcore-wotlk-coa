-- rev_20260926_02 added DisplayID 9500100 to CreatureModelData.dbc and
-- CreatureDisplayInfo.dbc, but the pillar creatures (10186-10188) still
-- failed to load: "Creature (Entry: 10186) has no model 9500100 defined in
-- table `creature_template_model`, can't load." (confirmed live 2026-09-26).
--
-- Root cause: `creature_model_info` is a SQL table, not DBC-backed, despite
-- the name looking like it should mirror CreatureModelData.dbc.
-- ObjectMgr::GetCreatureModelRandomGender() -> GetCreatureModelInfo() reads
-- it directly (BoundingRadius, CombatReach, Gender, DisplayID_Other_Gender)
-- and returns nullptr if the DisplayID has no row here, which aborts the
-- whole creature load regardless of the DBC side being correct.

DELETE FROM `creature_model_info` WHERE `DisplayID` = 9500100;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES (9500100, 1.5, 1.5, 2, 0);
