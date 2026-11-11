-- Bonus Manastorm Cache 1478051: no endgame profession materials
UPDATE `manastorm_material_cache_pool` SET `enabled` = 0 WHERE `item_entry` IN (
    11382, 17010, 17011, 13468, 12360, 13926, 20725,
    11370, 11371, 12361, 12364, 12799, 12800, 11754, 14256, 14342, 15417, 17012,
    16202, 16203, 14343, 14344, 7076, 7078, 7080, 7082, 12803
);
