-- Basalthane (10189-10192, renamed from 10185-10188 in rev_20260925_34) and
-- Molten Blood ooze (310189) never got creature_template_model rows in any
-- migration -- they were only ever applied by hand via the mysql CLI on the
-- live dev DB. On a clean world DB, both fail to load entirely
-- ("has no model defined in table creature_template_model, can't load").
--
-- rev_20260925_34's own UPDATE ... CreatureID CASE WHEN 10185 THEN 10189 ...
-- affects zero rows for exactly this reason (there was nothing to rename).

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (10189,10190,10191,10192,310189);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
    (10189, 0, 142102, 1, 1),
    (10190, 0, 142102, 1, 1),
    (10191, 0, 142102, 1, 1),
    (10192, 0, 142102, 1, 1),
    (310189, 0, 60375, 1, 1);

-- Same story for creature_template_movement's Swim flag on the ooze (needs
-- Swim=1 to move across this room's lava per docs/coa's known room quirks) --
-- present in the live DB, never in a migration.
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 310189;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`) VALUES
    (310189, 1, 1, 0, 0, 0, 0);

-- Even with the creature_template_model row above, Basalthane's stock display
-- (142102) and the ooze's stock display (60375) ALSO need a creature_model_info
-- row each -- ObjectMgr::GetCreatureModelInfo() does a SQL lookup by DisplayID
-- and returns nullptr with no row, which aborts the whole creature load with
-- the exact same "has no model ... defined in table creature_template_model,
-- can't load" message even though creature_template_model itself is correct.
-- Confirmed missing on a second, independently-set-up world DB (never touched
-- by any of this project's ad-hoc mysql CLI sessions) - same "only ever
-- applied by hand on the original dev DB" story as everything else here.
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (142102, 60375);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
    (142102, 2, 6, 2, 0),
    (60375, 0.5, 1.5, 2, 0);
