-- Basalthane (10189-10192) shipped with flags_extra=536870914, which is
-- CREATURE_FLAG_EXTRA_CIVILIAN (0x2) | CREATURE_FLAG_EXTRA_IGNORE_PATHFINDING
-- (0x20000000) -- confirmed via code review that CIVILIAN makes
-- Creature::CanStartAttack() return false, so a raid boss with this flag
-- never aggros on proximity. The value is exactly 2 off from the ooze's own
-- flags_extra (536870912, IGNORE_PATHFINDING only) -- almost certainly a typo
-- from copy-pasting the ooze's value and accidentally OR-ing in CIVILIAN,
-- not an intentional design choice.
--
-- IGNORE_PATHFINDING was needed on both the boss and the ooze (310189) while
-- this room's vmap/mmap data was broken (see [[coa_codebase_gotchas]]-style
-- notes in the project docs) -- now that fresh vmaps/mmaps fixed the terrain
-- and native SmartAI movement works correctly on both, neither needs this
-- flag anymore either.
--
-- Clears flags_extra to 0 for both.

UPDATE `creature_template` SET `flags_extra` = 0 WHERE `entry` IN (10189, 10190, 10191, 10192);
UPDATE `creature_template` SET `flags_extra` = 0 WHERE `entry` = 310189;
