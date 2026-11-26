-- #13625: Lift the underground Hillsbrad Attacker (guid 9950759, entry 41756) in Azurelode Mine
-- from z 4.02 (2.00 yd below the Md_Goldmine_Variantb.wmo floor) onto the measured floor at z 6.020.
UPDATE `creature`
SET `position_z` = 6.020
WHERE `guid` = 9950759 AND `id` = 41756;
