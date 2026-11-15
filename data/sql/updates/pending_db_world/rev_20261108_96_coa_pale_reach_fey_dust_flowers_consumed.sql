-- The Dunshire Enchanted Flowers vanish as the Petal Prowler bursts out (9elvxh9Fct0 at 1:02:03) and return on their
-- spawn timer, instead of staying usable 30 seconds later.
UPDATE `gameobject_template` SET `Data3` = 1000, `Data5` = 1 WHERE `entry` IN (2300638, 2300639);
