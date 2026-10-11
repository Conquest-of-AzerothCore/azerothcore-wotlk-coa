-- Sorcerer Ashcrombe (Shadowfang Keep) stays hostile to the Horde but cannot be attacked by players or creatures,
-- like Deathstalker Adamant: in cross-faction groups Horde members killed the Alliance door opener.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 0x2 | 0x100 | 0x200 WHERE `entry` IN (3850, 103850, 203850);
