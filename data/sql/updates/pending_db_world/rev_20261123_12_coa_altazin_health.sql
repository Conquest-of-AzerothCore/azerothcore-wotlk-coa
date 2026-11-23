-- The Beast When I Close My Eyes (175057): Alta'zin the Ascended (164071) had a normal mob's health. Live target frames
-- read about 5,980 at level 25 (VGzezmaiv8A 0:12:24, 5.2K at 86.9%) and 8,939 at level 30 (pEoiXrErJ6w 3:18:24);
-- with the world health scaling of 1.17 + 0.013 * level, a modifier of 5.9 gives 6,165 and 8,790.
UPDATE `creature_template` SET `HealthModifier` = 5.9 WHERE `entry` = 164071;
