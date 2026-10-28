-- CoA: 1660018 'Those Who Fell' - the Uneasy Citizens (161791) stand plainly instead of
-- cowering with the grey swirl. Spell 256478 'Fear' is the permanent (duration -1) visual aura
-- the SmartAI row re-applies on distillation, and the citizens never received it (or the cower
-- emote) ambiently. Give them EMOTE_STATE_COWER (431) and the aura via the template addon.
DELETE FROM `creature_template_addon` WHERE `entry` = 161791;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES (161791, 0, 0, 0, 0, 431, 0, '256478');
