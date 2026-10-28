-- CoA: 1660074 'Termites in Teldrassil' had no objective markers - only its turn-in pin.
--
-- The quest is finished by killing 10 Barkshredder Termites 162876 and the single Barkshredder Queen
-- 162877 (RequiredNpcOrGo1 and 2) in the termite den CoA cut under Dolanaar, but its only quest_poi row
-- was the turn-in pin rev_20260924_60_coa_quest_markers.sql wrote (id 0, ObjectiveIndex -1, at Kaladir
-- 162879, 9804 939), so a player carrying the open quest saw nothing on the world map for either
-- objective. That is what issue #6914 reports ("Objective is not tracking on the map").
--
-- quest_poi / quest_poi_points are the whole world-map marker system: ObjectMgr::LoadQuestPOI
-- (src/server/game/Globals/ObjectMgr.cpp:8549) loads them, WorldSession::HandleQuestPOIQuery
-- (src/server/game/Handlers/QueryHandler.cpp:411) answers the CMSG_QUEST_POI_QUERY a client sends for the
-- quests in its log, and QuestPOI.Enabled is 1. With no objective rows the quest draws its one pin and
-- no search area for the targets, while the 3D arrow and the minimap pin keep working off the client's
-- own QuestSuperTrack.dbc.
--
-- WHERE EACH VALUE COMES FROM
--   the two objectives  SOURCED-CLIENT: the client's QuestSuperTrack table carries this quest's route -
--     its row f1 = 1660074 holds turn-in 8785, objective node 8786 and objective node 8787. Those are
--     world points in the client's own SuperTrack coordinates: 8786 (9715.14, 1027.43, 1277.77) is the
--     crater floor at the den mouth the barricade sentinels hold (rev_20260924_11 places them 23-45 yd
--     away at 9678-9692 1028-1045), and 8787 (9792.3, 956.3, 1232.30) is the bottom chamber, where that
--     same file puts the Queen's spawn (guid 9007402, the one point on this map the quest needs).
--   the termite area  SOURCED-CORE: the den's 31 Barkshredder Termite spawns (creature 162876, guids
--     9007403-9007433) run from the mouth at 9734 1019 down the ramp, along the shelf to 9834 1000 and
--     into the bottom chamber at 9790-9824 958-978. The polygon is that spawn cluster's outline grown
--     5 yd, the way 1660018 outlines its 15 Uneasy Citizens and 1660029 its three spawn areas, so the
--     client fills the den the quest text describes ("the earth yawns open") and not the whole village.
--     Both client nodes above fall inside it, so the map area and the client's own arrow agree.
--   the queen's pin  SOURCED-CLIENT: node 8787, rounded to whole yards (9792 956). She is one unique
--     creature, so she takes a single point, the style rev_20261006_01 uses for the three Balnir spawns.
--
-- CONVENTIONS (the layout rev_20260924_60_coa_quest_markers.sql documents from stock data)
--   ObjectiveIndex -1 is the turn-in pin; 0-3 are the RequiredNpcOrGo slots 1-4 (a creature or object
--     objective). The termites are slot 1, so 0; the queen slot 2, so 1. Stock Teldrassil quests 456
--     and 457 carry exactly this pair (ObjectiveIndex 0 and 1) beside their -1 pin.
--   MapID 1 and WorldMapAreaId 41 are Teldrassil - the values this quest's own turn-in pin and every
--     stock Teldrassil quest row use (456, 457, 458, 459, 916 and the rest), so the markers land on the
--     map the client already draws for the zone. Floor 0 and Priority 0 are the stock values, Flags 1 is
--     the ordinary marker flag, VerifiedBuild is left to its default as every sibling marker file does.
--   `id` is only the row's own key within the quest: the turn-in holds 0, so the objectives take 1 and 2.
--
-- Idempotent: delete of the exact keys followed by the insert.

DELETE FROM `quest_poi` WHERE (`QuestID`, `id`) IN (
    (1660074, 1), (1660074, 2));
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`)
VALUES
(1660074, 1, 0, 1, 41, 0, 0, 1),
(1660074, 2, 1, 1, 41, 0, 0, 1);

DELETE FROM `quest_poi_points` WHERE (`QuestID`, `Idx1`) IN (
    (1660074, 1), (1660074, 2));
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`)
VALUES
(1660074, 1, 0, 9701, 1033),
(1660074, 1, 1, 9791, 951),
(1660074, 1, 2, 9817, 955),
(1660074, 1, 3, 9837, 988),
(1660074, 1, 4, 9839, 1000),
(1660074, 1, 5, 9832, 1022),
(1660074, 1, 6, 9807, 1027),
(1660074, 2, 0, 9792, 956);
