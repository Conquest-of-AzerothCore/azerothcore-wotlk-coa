-- CoA #8638 Eldritch Tentacle (500464): the live client's Creature.dbc puts this entry on display 30641, the darker
-- "Forsaken" skin of creature\yoggsaron\yoggsarontentacle.m2 at model scale 0.3, instead of 28813 (the light skin at
-- 0.6) that the local template used. Template scale 0.5 keeps the same 0.6 x 0.25 visual size the old pair produced
-- (0.3 x 0.5), so only the skin changes.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 30641, `DisplayScale` = 0.5
WHERE `CreatureID` = 500464 AND `Idx` = 0;
