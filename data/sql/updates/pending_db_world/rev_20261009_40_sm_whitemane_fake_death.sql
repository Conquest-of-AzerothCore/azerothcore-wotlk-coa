-- Scarlet Monastery Cathedral: Whitemane stays invincible at 1 health for the whole fight. The step
-- that lifted it after she raises Mograine goes; instance_scarlet_monastery decides her death at
-- 1 health (fake while Mograine stands, real once he is down), so a wipe after she fell resets both.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 397701 AND `source_type` = 9 AND `id` = 4;
