-- Kobold Desecrators 161751 (Cain Family Estate and crypt) respawn after 180 s instead of 300 s, like the CoA
-- Necrotic Bears and Ghouls around them and most of Deathknell's stock mobs. No source records CoA's timer.
UPDATE `creature` SET `spawntimesecs` = 180 WHERE `id` = 161751;
