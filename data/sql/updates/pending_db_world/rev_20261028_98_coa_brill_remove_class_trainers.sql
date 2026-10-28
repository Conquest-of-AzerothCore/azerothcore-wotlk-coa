-- Brill loses its CoA class trainers: the 21 posts of rev_20261021_40 were inferred against the vanilla square,
-- but the CoA client rebuilds Brill (patch-WB1.MPQ, Azeroth_31_27.adt) and several stood inside the ruined
-- fountain, the town hall and a fence. No archive gives a real post (AscensionDB, CoA Tavern, the client addons,
-- the SUB world dump and the 2026-07-03 Brill stream show no CoA trainer in Brill), so the spawns and their
-- event 195 links are removed. The trainer templates keep their Undercity and Orgrimmar spawns. Brill's stock
-- trainers are untouched.
--
-- Destiny Weaver Veylin (rev_20260925_30) stood inside the inn wall; she moves outside the inn door, ray-tested
-- 3.0 yd from the wall with open sky above, on the CoA terrain height, facing the square.
DELETE FROM `game_event_creature` WHERE `eventEntry` = 195 AND `guid` BETWEEN 9005000 AND 9005020;
DELETE FROM `creature` WHERE `guid` BETWEEN 9005000 AND 9005020;
UPDATE `creature` SET `position_x` = 2273.25, `position_y` = 257.75, `position_z` = 34.47, `orientation` = 2.04 WHERE `guid` = 9000022 AND `id` = 449353;
