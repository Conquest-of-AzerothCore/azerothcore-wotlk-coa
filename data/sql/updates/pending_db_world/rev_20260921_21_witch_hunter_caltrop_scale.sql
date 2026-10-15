-- The caltrop prop (entry 506010) renders display 401941, whose model is the Outland
-- passive doodad `World\Outland\PassiveDoodads\Caltrop01.mdx`. That mesh is authored at
-- doodad size (the same display is used for the hidden cauldron), so spawning it at scale
-- 1.0 made the caltrops enormous, far larger than the intended trip-marker. Both client-side
-- scale factors for the display are 1.0, so the server value is the only lever: a hundredth
-- of the mesh reads as a small field prop, and the trigger radius the field code uses
-- (3.0 yards) is unchanged, so only the visual size is affected.
UPDATE `creature_template_model`
SET `DisplayScale` = 0.01
WHERE `CreatureID` = 506010 AND `CreatureDisplayID` = 401941;
