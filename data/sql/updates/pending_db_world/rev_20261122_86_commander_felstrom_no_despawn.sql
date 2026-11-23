-- #8951: Felstrom Resurrection (3488) only heals the caster on CoA, so the stock despawn left no corpse
DELETE FROM `smart_scripts` WHERE `entryorguid` = 771 AND `source_type` = 0 AND `id` IN (1, 2);
UPDATE `smart_scripts` SET `link` = 0 WHERE `entryorguid` = 771 AND `source_type` = 0 AND `id` = 0 AND `link` <> 0;
