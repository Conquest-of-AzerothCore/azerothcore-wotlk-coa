-- The three Bloodpaw Gnolls (164030) behind Alto Bilberg in Ironbough Mine are friendly on live (9elvxh9Fct0 at 59:28),
-- as the original import had them; rev_20261017_10 had made them hostile.
UPDATE `creature_template` SET `faction` = 35 WHERE `entry` = 164030;
