-- Worldforged Defias Shanker (#8545): two pickups of the Murloc Tool catalog entry 95688 stand 3.1
-- yd apart in Elwynn Forest. rev_20261026_01_coa_worldforged_stacked_twins (#9253) moved only the
-- third copy (guid 6940344) back to its Alterac Mountains realm-map marker and left this Elwynn
-- pair alone (its own rule: same-entry pairs that already stood together are untouched; neither
-- 6901119 nor 6940343 appears in that migration). Keep the hand-authored copy (guid 6940343,
-- placed in game by 2026_09_24_20_worldforged_authored_in_game_final) and remove the older catalog
-- row (guid 6901119) so one pickup remains.

DELETE FROM `gameobject`
WHERE `guid` = 6901119 AND `id` = 95688 AND `map` = 0
    AND `position_x` BETWEEN -9687.9 AND -9686.9 AND `position_y` BETWEEN -76.1 AND -75.1;
