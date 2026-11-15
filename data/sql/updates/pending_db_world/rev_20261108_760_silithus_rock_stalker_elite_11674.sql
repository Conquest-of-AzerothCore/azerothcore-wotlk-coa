-- Rock Stalker (11739) is elite on Ascension. CoA's own creature cache (conquest-of-azeroth) reports rank 1
-- with the health modifier of 3.87 this world already carries, while the template was still rank 0.
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 11739 AND `rank` = 0;
