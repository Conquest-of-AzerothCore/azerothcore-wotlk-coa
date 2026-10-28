-- CoA Northshire class chain: the Lost Pendant and Uther's Statue as they stand in the valley now.
--
-- rev_20261007_20_coa_northshire_class_chain_spawns.sql republished both objects after the valley
-- restore deleted them. How they look and where they stand was then finished by hand in game
-- (2026-10-07) and is captured here, so a fresh world database reproduces what the live one holds:
--
--   * 9301103 Lost Pendant: size 1 -> 0.3. At size 1 the necklace model (display 1010146) stood as
--     tall as the player looking at it, which is what "the pendants are huge" describes.
--   * one pendant, not two. The row the republish put back on the trail toward the river, guid
--     7912106, is deleted: it had never left its authored spot. The pendant that was moved onto the
--     crate at the Defias camp is the one kept (guid 7912105, -8956.38 -435.027 65.3559, rotated to
--     sit on the crate). Lost Pendant 200058 wants one pickup, and the camp is where the quest text
--     says the chaplain dropped it ("they ran me off. In my haste, I dropped my pendant.").
--   * 9301105 Uther's Statue: type 10 (goober) -> 5 (generic), with the questId (Data1) cleared, so
--     it no longer activates and sparkles for every player on A Quiet Life. That is the same cause
--     rev_20261001_23_coa_noble_heritage_stop_sparkling.sql documents for the Noble Heritage chests
--     (ActivateToQuest sets GO_DYNFLAG_LO_SPARKLE for anyone the quest is incomplete for). The
--     quest credit itself is unaffected: A Quiet Life 200077 is credited by the walk-in creature
--     685037 at the foot of the falls, not by clicking the statue.
--   * the statue is size 1.5 and stands in front of the Northshire falls at -8739.86 -413.297
--     82.6027, a yard from the walk-in marker at the foot of the falls, instead of the cliff ledge
--     behind the falling water the republish gave it.
--
-- Idempotent: the delete names the exact guid, every update names the exact row.
--
-- Rollback: rev_20261007_20_coa_northshire_class_chain_spawns.sql holds the two original spawns and
-- rev_20260923_06_coa_class_trainers_northshire.sql the original templates.

DELETE FROM `gameobject` WHERE `guid` = 7912106 AND `id` = 9301103;

UPDATE `gameobject_template` SET `size` = 0.3 WHERE `entry` = 9301103;
UPDATE `gameobject_template` SET `type` = 5, `size` = 1.5, `Data1` = 0 WHERE `entry` = 9301105;

UPDATE `gameobject` SET `position_x` = -8956.38, `position_y` = -435.027, `position_z` = 65.3559,
    `orientation` = 0.00392888, `rotation0` = -0.0725746, `rotation1` = -0.031781,
    `rotation2` = -0.000347103, `rotation3` = 0.996856,
    `Comment` = 'CoA Northshire class chain: on the crate at the Defias camp, where the chaplain fled and dropped it; the valley''s single Lost Pendant for 200058'
    WHERE `guid` = 7912105 AND `id` = 9301103;

UPDATE `gameobject` SET `position_x` = -8739.86, `position_y` = -413.297, `position_z` = 82.6027,
    `orientation` = 2.97193, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.996404, `rotation3` = 0.0847297,
    `Comment` = 'CoA Northshire class chain: the bank in front of the Northshire falls, where a player on A Quiet Life sees the statue without the falling water across it'
    WHERE `guid` = 7912102 AND `id` = 9301105;
