-- CoA: graveyards for Elwynn Forest / Northshire Valley.
--
-- Two reported deaths resolve to the wrong graveyard, and both trace back to missing
-- graveyard_zone rows rather than to the core's selection logic.
--
-- 1. Northshire Valley (area 9) had no graveyard_zone row at all.
--    Every other starter area is registered: Dun Morogh (1), Tirisfal (85), Teldrassil (141),
--    Mulgore (215), Durotar (14), and Elwynn's own zone 12 all have rows. Area 9 is the single
--    gap. With no area-level row, death inside Northshire falls through to the zone-level list
--    for Elwynn (12), which is shared with Goldshire, Eastvale and the Tower of Azora, and the
--    reported result was a ghost at Sentinel Hill (game_graveyard 4, Westfall).
--    Fix: bind the existing Northshire graveyard (105, already at -8935.33 -188.646) to area 9,
--    matching how 106/854/1468 are bound to zone 12. No new graveyard is created and no
--    coordinates change.
--
--    Faction 469 (Alliance) is deliberate and mirrors 105's own zone-12 binding: Northshire is
--    an Alliance starter area, and a Horde player dying there fails the friendly check and falls
--    back to the zone-level list exactly as before. graveyard_zone's primary key is (ID,
--    GhostZone) - it does NOT include Faction - so area 9 can hold only one row for graveyard
--    105. Adding a second faction row is a duplicate-key error, not a two-team binding.
--
-- 2. 'Elwynn Forest, Shadewell Spring' (game_graveyard 6074) was unreachable.
--    It is bound only to GhostZone 10197 and 10218, which are CoA-invented ids: areatable_dbc
--    is empty on this server, so nothing can ever match them and the graveyard is dead data.
--    Dying at Shadewell therefore fell through to zone 12 and picked the nearest registered
--    graveyard, Northshire (105) - the reported behaviour.
--    Fix: bind 6074 to Elwynn (12) with faction 0, exactly like the Tower of Azora (1468) and
--    Eastvale (854) rows. Selection is nearest-first inside a zone, so this only takes over
--    deaths in the Shadewell part of the forest; Goldshire and Northshire deaths still resolve
--    to their own closer graveyards.
--
-- Idempotent: each row is deleted before it is inserted, and the delete is not narrowed by
-- faction so a re-run also clears any row left behind by an earlier failed apply.

DELETE FROM `graveyard_zone` WHERE `ID` = 105 AND `GhostZone` = 9;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES (105, 9, 469, 'Elwynn Forest, Northshire - area-level binding');

DELETE FROM `graveyard_zone` WHERE `ID` = 6074 AND `GhostZone` = 12;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`)
VALUES (6074, 12, 0, 'Elwynn Forest, Shadewell Spring - bind to the real zone');
