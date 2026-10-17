-- The witch doctor's Voodoo Cauldron (spell 804684) summons its healing helper
-- "Cauldron Hidden Periodic" entry 506011, which exists only to run the periodic
-- heal and must not be seen. AscensionWitchDoctorSummons calls SetVisible(false)
-- on it, but that is a server-side visibility flag: the client still spawns the
-- creature's model. The helper shares display 401941 with the witch hunter's
-- Caltrop prop, and that display resolves to the Outland passive doodad
-- `World\Outland\PassiveDoodads\Caltrop01.mdx`, a mesh authored at doodad size.
-- rev_20260921_21 scaled the caltrop's own copy (entry 506010) down to 0.01 for
-- its trip marker; the helper kept scale 1, so casting Voodoo Cauldron placed
-- that whole prop on top of the player (#7675).
--
-- A hidden helper needs a mesh that draws nothing, not a scaled-down prop, so
-- entry 506011 takes display 11686 (`Creature\InvisibleStalker\InvisibleStalker.mdx`),
-- the invisible display 1137 other trigger creatures here already use. Entry
-- 506010 and display 401941 are left alone: the caltrop is meant to be visible.

UPDATE `creature_template_model`
SET `CreatureDisplayID` = 11686, `DisplayScale` = 1
WHERE `CreatureID` = 506011 AND `CreatureDisplayID` = 401941;
