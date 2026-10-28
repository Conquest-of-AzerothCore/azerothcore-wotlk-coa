-- Lucifron (12118, guid 56605) stands in the open corridor leading into Magmadar Cavern, not in
-- his own alcove: rev_20260930_90 only removed the WAYPOINT path that made him wander into
-- Magmadar's room, it never questioned the static anchor point itself. The player's own in-game
-- memory places him in the alcove south-west of the Magmadar Cavern mouth, north-east of
-- Ragnaros' Lair -- confirmed by fitting an affine pixel->world transform of the Molten Core world
-- map against our own measured boss positions (Lucifron/Magmadar/Gehennas/Garr/Shazzrah/Geddon/
-- Sulfuron/Golemagg, map 409 `creature` rows) and solving for the player-marked spot: world
-- (959, -938). Ground confirmed via GM teleport + `.gps` on slot 3 this session: FloorZ resolves
-- stably to -181.997 (VMap+MMap hit) whenever queried from above it, matching Lucifron's own old
-- Z (-181.516) and Magmadar's (-185.663) closely enough to trust; querying from below (-185.7 and
-- lower) finds no floor at all ("outdoors", FloorZ -100000), confirming this is solid ground, not
-- an open shaft. The export's own static placement (guid 56605 vs. 56606/56607, ~3.66/3.70 yd
-- apart) is unaffected by this move -- the trio was together, just in the wrong room; see below
-- for the Protectors' removal. Orientation 5.729 rad faces back toward Lucifron's old spot
-- (1037.02, -986.342), i.e. the Ragnaros' Lair side a raid group approaches from, away from the
-- Magmadar Cavern dead end.
UPDATE `creature` SET `position_x` = 959, `position_y` = -938, `position_z` = -181.997,
  `orientation` = 5.729
  WHERE `guid` = 56605 AND `id` = 12118;

-- No Lucifron adds (user decision, supersedes §8 item 7's "2 adds are correct" reading of the
-- export): Flamewaker Protector (12119) guids 56606/56607 removed outright, not relocated. No
-- code references these two spawns specifically -- `instance_molten_core.cpp`'s stock
-- `MinionData` entry `{ NPC_FLAMEWALKER_PROTECTOR, DATA_LUCIFRON }` is generic AzerothCore
-- minion-tracking plumbing with no GUID list of its own (unlike Garr's Firesworn or Golemagg's
-- minions, which the instance script does track by GUID); it simply has nothing left to find once
-- the spawns are gone, so it is left untouched. `coa_boss_summon` and Lucifron's own
-- `coa_boss_ai`/`coa_boss_schedule` rows do not mention 12119 either (checked this session).
DELETE FROM `creature` WHERE `guid` IN (56606, 56607) AND `id` = 12119;
DELETE FROM `creature_addon` WHERE `guid` IN (56606, 56607);
DELETE FROM `creature_formations` WHERE `memberGUID` IN (56605, 56606, 56607);
DELETE FROM `linked_respawn` WHERE `guid` IN (56606, 56607) AND `linkedGuid` = 56605;
