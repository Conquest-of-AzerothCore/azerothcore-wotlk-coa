-- CoA: 1660041 'A Door Left Ajar' - the 1h axe reward (559187 Cruel-Edged Axe) was
-- item level 24 / required level 19 with matching damage, while its sibling rewards
-- (559177, 559178, 559179) are item level 7 / required level 3 with ~2.8 DPS.
-- Bring the axe into the same level-3 band: item level 7, required level 3, damage
-- scaled to the siblings' DPS (~2.8 at 1.8s swing), and no bonus stats like them.
UPDATE `item_template` SET `ItemLevel` = 7, `RequiredLevel` = 3, `dmg_min1` = 3.8,
`dmg_max1` = 6.3, `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0
WHERE `entry` = 559187;
