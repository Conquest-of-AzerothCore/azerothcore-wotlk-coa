-- ----------------------------------------------------------------------------
-- Worldforged pickups: off the plane a map does not have.
-- ----------------------------------------------------------------------------
-- A map file can carry one constant height for a whole grid instead of a surface
-- (`MAP_HEIGHT_NO_HEIGHT`): 0 across an interior map such as Scarlet Monastery, the
-- -500 sentinel on a continent grid with no terrain under it. The core uses that
-- constant as a fallback, so a pickup parked on it still loads - it simply stands on a
-- plane the map does not have, which is to say underground and out of sight.
--
-- Each such row takes back the height the pass that created it recorded, and where the
-- plane is all it ever had, the floor of the nearest occupants of that map. The same is
-- done for the rows a pass left at exactly 0 - the number a generator writes when
-- nothing gave it a height, and not a height on any continent - and for any row the
-- sixth pass moved to a height this reading does not support.
-- 61 rows.

UPDATE `gameobject` SET
    `position_z` = CASE `guid`
        WHEN 6903554 THEN 2.5673
        WHEN 6903555 THEN 1.4041
        WHEN 6903579 THEN 1.6555
        WHEN 6903580 THEN 1.1557
        WHEN 6903581 THEN 0.0994
        WHEN 6903675 THEN 3.5738
        WHEN 6903751 THEN 1.6222
        WHEN 6903752 THEN 2.8246
        WHEN 6903776 THEN 3.0677
        WHEN 6903965 THEN 4.4515
        WHEN 6903975 THEN 0.9613
        WHEN 6904299 THEN 1.4059
        WHEN 6904616 THEN 1.5133
        WHEN 6904628 THEN -13.135
        WHEN 6904662 THEN 0.5223
        WHEN 6904859 THEN -0.1025
        WHEN 6905005 THEN 82.195
        WHEN 6905006 THEN 82.195
        WHEN 6905112 THEN 22.627
        WHEN 6905113 THEN 33.153
        WHEN 6905114 THEN 31.549
        WHEN 6905115 THEN 19.076
        WHEN 6905116 THEN 7.49
        WHEN 6905117 THEN 31.549
        WHEN 6905118 THEN 18.023
        WHEN 6905119 THEN 22.609
        WHEN 6905120 THEN 22.609
        WHEN 6905121 THEN 22.609
        WHEN 6905122 THEN 19.307
        WHEN 6905123 THEN 18.149
        WHEN 6905124 THEN 18.023
        WHEN 6905125 THEN 22.627
        WHEN 6905126 THEN 18.157
        WHEN 6905127 THEN 33.046
        WHEN 6905128 THEN 22.627
        WHEN 6905129 THEN 19.076
        WHEN 6905130 THEN 17.561
        WHEN 6905131 THEN 33.177
        WHEN 6905132 THEN 18.023
        WHEN 6905133 THEN 21.437
        WHEN 6905134 THEN 31.549
        WHEN 6905135 THEN 22.609
        WHEN 6905136 THEN 20.424
        WHEN 6905137 THEN 19.712
        WHEN 6905138 THEN 18.023
        WHEN 6910238 THEN 50.508
        WHEN 6910405 THEN 18.023
        WHEN 6910406 THEN 17.561
        WHEN 6910407 THEN 18.023
        WHEN 6910408 THEN 18.149
        WHEN 6910409 THEN 18.023
        WHEN 6910410 THEN 33.177
        WHEN 6910411 THEN 33.153
        WHEN 6910412 THEN 33.153
        WHEN 6910413 THEN 33.046
        WHEN 6910414 THEN 18.023
        WHEN 6910415 THEN 22.627
        WHEN 6910434 THEN 0.629
        WHEN 6920007 THEN 22.627
        WHEN 6920028 THEN 51.928
        WHEN 6904628 THEN -13.135
        ELSE `position_z` END,
    `Comment` = CASE `guid`
        WHEN 6903554 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 2.5673')
        WHEN 6903555 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.4041')
        WHEN 6903579 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.6555')
        WHEN 6903580 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.1557')
        WHEN 6903581 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 0.0994')
        WHEN 6903675 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 3.5738')
        WHEN 6903751 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.6222')
        WHEN 6903752 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 2.8246')
        WHEN 6903776 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 3.0677')
        WHEN 6903965 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 4.4515')
        WHEN 6903975 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 0.9613')
        WHEN 6904299 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.4059')
        WHEN 6904616 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 1.5133')
        WHEN 6904628 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded (it was left at 0), was 0.0, now -13.135')
        WHEN 6904662 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now 0.5223')
        WHEN 6904859 THEN CONCAT(`Comment`, ' | ground: the terrain surface (it was left at 0), was 0.0, now -0.1025')
        WHEN 6905005 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was -2.7778, now 82.195')
        WHEN 6905006 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was -2.7778, now 82.195')
        WHEN 6905112 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.627')
        WHEN 6905113 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.153')
        WHEN 6905114 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 31.549')
        WHEN 6905115 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 19.076')
        WHEN 6905116 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 7.49')
        WHEN 6905117 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 31.549')
        WHEN 6905118 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6905119 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.609')
        WHEN 6905120 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.609')
        WHEN 6905121 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.609')
        WHEN 6905122 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 19.307')
        WHEN 6905123 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.149')
        WHEN 6905124 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6905125 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.627')
        WHEN 6905126 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.157')
        WHEN 6905127 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.046')
        WHEN 6905128 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.627')
        WHEN 6905129 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 19.076')
        WHEN 6905130 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 17.561')
        WHEN 6905131 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.177')
        WHEN 6905132 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6905133 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 21.437')
        WHEN 6905134 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 31.549')
        WHEN 6905135 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.609')
        WHEN 6905136 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 20.424')
        WHEN 6905137 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 19.712')
        WHEN 6905138 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6910238 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded (it was left at 0), was 0.0, now 50.508')
        WHEN 6910405 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6910406 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 17.561')
        WHEN 6910407 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6910408 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.149')
        WHEN 6910409 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6910410 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.177')
        WHEN 6910411 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.153')
        WHEN 6910412 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.153')
        WHEN 6910413 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 33.046')
        WHEN 6910414 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 18.023')
        WHEN 6910415 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.627')
        WHEN 6910434 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0744, now 0.629')
        WHEN 6920007 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 22.627')
        WHEN 6920028 THEN CONCAT(`Comment`, ' | ground: the height its creating pass recorded, was 0.0, now 51.928')
        WHEN 6904628 THEN CONCAT(`Comment`, ' | ground: re-decided, was -12.38, now -13.135')
        ELSE `Comment` END
WHERE `guid` IN (6903554, 6903555, 6903579, 6903580, 6903581, 6903675, 6903751, 6903752, 6903776, 6903965, 6903975, 6904299, 6904616, 6904628, 6904662, 6904859, 6905005, 6905006, 6905112, 6905113, 6905114, 6905115, 6905116, 6905117, 6905118, 6905119, 6905120, 6905121, 6905122, 6905123, 6905124, 6905125, 6905126, 6905127, 6905128, 6905129, 6905130, 6905131, 6905132, 6905133, 6905134, 6905135, 6905136, 6905137, 6905138, 6910238, 6910405, 6910406, 6910407, 6910408, 6910409, 6910410, 6910411, 6910412, 6910413, 6910414, 6910415, 6910434, 6920007, 6920028, 6904628);
