-- Worldforged Loop of the Sly Rogue (#8603): rev_20261014_95_worldforged_lootcollector_alignment
-- overwrote the hand-authored spot of the Fargodeep Mine ring pickup (gameobject guid 6940714)
-- with the open-ground height next to the Mirror Lake house's rising stairs, 1.15 yd under the
-- vmap floor there (confirmed with the gameplay harness's own ground probe). Restore the authored
-- position, which sits on the house floor.

UPDATE `gameobject`
SET `position_x` = -9435.332031, `position_y` = 464.496094, `position_z` = 53.225555
WHERE `guid` = 6940714 AND `id` = 90238
    AND `position_x` BETWEEN -9443.7 AND -9442.7 AND `position_y` BETWEEN 461.6 AND 462.6;
