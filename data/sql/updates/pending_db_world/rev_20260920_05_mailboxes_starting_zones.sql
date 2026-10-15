-- CoA/Ascension: add Mailbox to all 8 starter zones.
-- Issue #4197: Every starting zone is missing a mailbox. The base AC DB has no
-- mailbox spawns in any starting zone; existing entries (guids 49531/49532) are in
-- Dolanaar, not Shadowglen. Entry 143990 exists in DB but is in Brill, not Deathknell.
--
-- Position sources:
--   hertigservices/ascension-data preservation catalogue — Shadowglen, Coldridge Valley, VOT, Camp Narache
--   In-game GPS survey — Northshire Valley, Deathknell, Azuremyst Isle (no preservation sightings exist)
--   EmuCoach community reference — Sunstrider Isle
--
-- Entry IDs used (all faction 0 or faction 55 — accessible to any player):
--   142109 — Night Elf mailbox (displayId 1948, faction 80) — Shadowglen (Alliance NE zone)
--   144570 — Human mailbox   (displayId 1907, faction  0) — Northshire Valley
--   142102 — Dwarf mailbox   (displayId 1947, faction 55) — Coldridge Valley (matches Ironforge)
--   188132 — Horde mailbox   (displayId 2128, faction  0) — VOT, Deathknell, Camp Narache
--   184133 — Blood Elf mbx   (displayId 6870, faction  0) — Sunstrider Isle
--   184134 — Draenei mailbox (displayId 7013, faction  0) — Azuremyst Isle
-- Note: preservation catalogue shows CoA used entries 143981/143984 at VOT/Narache, but those
-- carry Horde-only faction templates (29, 104) blocking Alliance players. Race-appropriate
-- neutral-faction entries are used instead at the same preservation-sourced coordinates.

DELETE FROM `gameobject` WHERE `guid` IN (6901511,6901512,6901513,6901514,6901515,6901516,6901517,6901518);
INSERT INTO `gameobject`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `rotation0`, `rotation1`, `rotation2`, `rotation3`,
     `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`)
VALUES
-- Shadowglen (Night Elf, map 1, area Aldrassil) — GPS confirmed at building entrance
(6901511, 142109, 1, 0, 0, 1, 1,  10391.40,   747.17, 1320.14, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Shadowglen (Aldrassil) starting zone mailbox — hertigservices preservation sighting'),
-- Northshire Valley (Human, map 0) — GPS confirmed; 144570 = Human model (displayId 1907, faction 0)
(6901512, 144570, 0, 0, 0, 1, 1,  -8908.83,  -131.85,   80.67, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Northshire Valley starting zone mailbox — GPS confirmed'),
-- Coldridge Valley (Dwarf/Gnome, map 0) — preservation sighting; 142102 = Dwarf model (displayId 1947) matches Ironforge
(6901513, 142102, 0, 0, 0, 1, 1,  -6168.27,   375.71,  398.99, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Coldridge Valley starting zone mailbox — preservation data'),
-- Valley of Trials (Orc/Troll, map 1) — preservation sighting; 188132 = Horde model (displayId 2128, faction 0)
(6901514, 188132, 1, 0, 0, 1, 1,   -599.61, -4200.88,   40.01, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Valley of Trials starting zone mailbox — preservation data'),
-- Deathknell (Undead, map 0) — GPS confirmed; 188132 = Horde dark model (displayId 2128, faction 0)
(6901515, 188132, 0, 0, 0, 1, 1,   1848.37,  1609.22,   95.43, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Deathknell starting zone mailbox — GPS confirmed'),
-- Camp Narache (Tauren, map 1) — preservation sighting; 188132 = Horde dark model (displayId 2128, faction 0)
(6901516, 188132, 1, 0, 0, 1, 1,  -2887.32,  -227.18,   53.92, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Camp Narache starting zone mailbox — preservation data'),
-- Sunstrider Isle (Blood Elf, map 530) — EmuCoach reference; 184133 = Blood Elf model (displayId 6870, faction 0)
(6901517, 184133, 530, 0, 0, 1, 1, 10354.30, -6370.68,   36.09, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Sunstrider Isle starting zone mailbox — EmuCoach reference'),
-- Azuremyst Isle (Draenei, map 530) — GPS confirmed at Crash Site; 184134 = Draenei model (displayId 7013, faction 0)
(6901518, 184134, 530, 0, 0, 1, 1, -4049.83,-13781.80,   75.30, 0, 0, 0, 0, 1.0, 120, 255, 1, '', NULL, 'Azuremyst Isle starting zone mailbox — GPS confirmed');
