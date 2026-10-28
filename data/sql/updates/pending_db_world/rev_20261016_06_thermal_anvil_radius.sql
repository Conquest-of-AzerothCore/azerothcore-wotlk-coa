-- Thermal Anvil forge (2201000) and anvil (2202000) used a 20-yard spell-focus
-- radius, far wider than a placed workstation needs. Reduce to 5 yards.
UPDATE `gameobject_template` SET `Data1` = 5 WHERE `entry` IN (2201000, 2202000);
