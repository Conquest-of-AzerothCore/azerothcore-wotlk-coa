-- Pillar display ID switched from the custom Mantid Spike model (9500100, requires a
-- raw DBC binary edit outside git/SQL - see this project's known DBC-gap note) to a
-- stock display ID (200003) already present in the repo's own DBC/creature_model_info,
-- so a fresh install no longer hits "has no model defined" for the pillars.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 200003
WHERE `CreatureID` IN (10186, 10187, 10188) AND `CreatureDisplayID` = 9500100;
