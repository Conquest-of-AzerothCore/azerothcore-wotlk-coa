-- #4290: the rank 3 Animated Blood amalgam (display 93307) rendered about 12 yards tall.
-- The client's CreatureDisplayInfo already scales bloodelemental.mdx (3.1 yards) by 4, so the creature's own
-- DisplayScale must cancel it out. 4 * 0.25 = 1 puts the amalgam at the model's native size, in line with
-- other summoned minions such as the Death Knight ghoul and the Mage water elemental (about 3 yards).
UPDATE `creature_template_model` SET `DisplayScale` = 0.25 WHERE `CreatureID` = 315301 AND `Idx` = 0;
