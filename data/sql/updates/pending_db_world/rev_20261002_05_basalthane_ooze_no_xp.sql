-- Molten Blood oozes (310189) should not give XP on kill - they're a pillar-triggered
-- hazard/add, not a real kill target worth experience.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40 WHERE `entry` = 310189;
