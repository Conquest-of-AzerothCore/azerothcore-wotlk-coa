-- CoA #7771: freed Restless Souls (11122) render friendly (green, faction 35) to
-- Alliance-template players, so the 15 souls for 5282 'The Restless Souls' cannot be
-- attacked and freeing never advances the quest. The Spectral/Ghostly Citizens that
-- release them are neutral (faction 7) and attackable; mirror that on the souls so
-- every freed soul stays a valid kill target. Temp summons keep template faction
-- (summon properties 64 sets none), so the template change covers summoned souls too.
UPDATE `creature_template` SET `faction` = 7 WHERE `entry` = 11122;
