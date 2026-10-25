-- Two of the seventeen Accursed Judges carried the end-event ghost aura (8326); none of the others do.
UPDATE `creature_template_addon` SET `auras` = '' WHERE `entry` IN (161895, 161897) AND `auras` = '8326';
UPDATE `creature_addon` SET `auras` = '' WHERE `guid` IN (7500336, 7500338) AND `auras` = '8326';
