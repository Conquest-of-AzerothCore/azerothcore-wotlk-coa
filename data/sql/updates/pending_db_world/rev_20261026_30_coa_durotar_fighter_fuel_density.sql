-- CoA Durotar: drop the 35 boars, raptors and scorpids added to the Fighter Fuel circle east of the Warborn
-- Grounds. Together with the nine stock rows moved there they stacked 51 mobs on the slope; the stock rows stay.
DELETE FROM `creature` WHERE `guid` BETWEEN 9012630 AND 9012664 AND `id` IN (3099, 3122, 3123, 3126, 3127);
