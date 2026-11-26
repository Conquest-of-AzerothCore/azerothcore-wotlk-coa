-- #13058: Abandoned Trader Crate (guid 6941628, id 515798, Tanaris) sat at z 9.276, 1.10 yd below stock terrain (10.3717).
-- Raise it to terrain level (10.372) so the bottom-pivoted AO_OrcCrate01.mdx rests on the ground.
UPDATE `gameobject`
SET `position_z` = 10.372
WHERE `guid` = 6941628 AND `id` = 515798 AND `map` = 1;
