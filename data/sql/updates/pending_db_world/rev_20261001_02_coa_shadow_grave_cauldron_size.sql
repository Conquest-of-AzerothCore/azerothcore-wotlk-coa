-- Shadow Grave, beside Undertaker Mordo: the Cauldron Prop drew about twice as large as on CoA. CoA footage of
-- the room shows the cauldron beside the Plague Cistern Prop (0.327267) as wide as the cistern and lower; with
-- the two models' mesh sizes (SC_Cauldron_Green 10.77 x 5.33, FK_PlagueCistern 21.24 x 17.81) that is a scale
-- of 0.67 by width and 0.70 by height, against the cache's 1.42242 (INFERRED from the footage). At 0.7 it stands
-- beside the cistern against the back wall at its atlas point instead of spilling across the platform. It is
-- the only spawn of this entry.
UPDATE `gameobject_template` SET `size` = 0.7 WHERE `entry` = 600636;
