-- Bloodmail Legguards 227465 (epic, item level 61, RequiredDisenchantSkill 225) had no DisenchantID, so Disenchant failed (#10066). Bloodmail Hauberk 227453 and Bloodmail Coif 99706, epic at the same item level, use bracket 64 (one Nexus Crystal).
UPDATE `item_template` SET `DisenchantID` = 64 WHERE `entry` = 227465 AND `DisenchantID` = 0;
