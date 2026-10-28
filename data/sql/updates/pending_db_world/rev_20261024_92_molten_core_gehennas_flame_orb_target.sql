-- Gehennas (12259): Conjure Flame Orb's tooltip sends the orb "towards a distant enemy", not
-- the tank, but coa_boss_schedule idx 5's `target` column was 0 (TANK) -- noted but left alone
-- in rev_20261024_91 as outside the reported "orb does nothing" defect. Now addressed directly:
-- CoaBossAI.cpp gets a new TargetMode, TARGET_DISTANT (4) -- a random player beyond 10 yards
-- (within 100), or the farthest player when none qualifies, reusing boss_magmadar.cpp's own
-- MELEE_TARGET_LOOKUP_DIST/100.0f pair (same module, same "beyond melee range" idea; Spell.dbc
-- has no usable RangeIndex on 2105417 to derive a threshold from).
UPDATE `coa_boss_schedule` SET `target` = 4 WHERE `entry` = 12259 AND `idx` = 5;
