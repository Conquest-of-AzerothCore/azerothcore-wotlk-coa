-- Uther's Statue: the Ascension client crashes building the collision of utherstatue.m2;
-- the tomb already shows the statue, so the quest target needs no model.
UPDATE `gameobject_template` SET `displayId` = 0 WHERE `entry` = 181653;
