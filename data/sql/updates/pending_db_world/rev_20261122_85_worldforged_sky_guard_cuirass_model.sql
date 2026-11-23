-- #12099: show a breastplate instead of the boots model (display of plate chest pickup 1345152)
UPDATE `gameobject_template` SET `displayId` = 4074
WHERE `entry` = 1345133 AND `displayId` = 1012699;
