-- The Soulstone Lure was still a ziggurat crystal planted in the floor.
--
-- Two separate things. The Ash'ari Crystal model is several yards tall, so a third of it is still
-- taller than the player: 0.12 puts it at the width of the green ring the ability draws on the
-- ground, which is what it is meant to sit inside. And the model's origin is at its middle rather
-- than its base, so at any scale it comes out half buried.
--
-- Ground movement Hover is what CanHover() reads, and it is the flag that puts MOVEMENTFLAG_HOVER
-- on the creature; HoverHeight is how far off the ground it then sits. Together the crystal floats
-- inside its ring instead of being sunk into it.
UPDATE `creature_template_model` SET `DisplayScale` = 0.12 WHERE `CreatureID` = 557911;

UPDATE `creature_template` SET `HoverHeight` = 1.2 WHERE `entry` = 557911;

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 557911;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(557911, 2, 0, 0, 1);
