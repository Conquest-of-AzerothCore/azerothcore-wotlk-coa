-- Parasitic Serpents stay until killed so Corpse Explosion finds their corpses (tester round 7, 2026-11-14): the stock
-- Parasitic Serpent proc (23867 -> 23865) made each serpent evade and despawn on its first hit.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 14884 AND `source_type` = 0 AND `id` IN (0, 1, 2, 3);
