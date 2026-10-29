-- Zul'Farrak pyramid event: talking to Sergeant Bly, Weegli Blastfuse or the other freed prisoners paused their scripted
-- walk for Creature.MovingStopTimeForPlayer (3 minutes), so they stood still and the troll waves never started.
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (7604, 7605, 7606, 7607, 7608);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES
(7604, NULL, NULL, NULL, NULL, NULL, NULL, 0),
(7605, NULL, NULL, NULL, NULL, NULL, NULL, 0),
(7606, NULL, NULL, NULL, NULL, NULL, NULL, 0),
(7607, NULL, NULL, NULL, NULL, NULL, NULL, 0),
(7608, NULL, NULL, NULL, NULL, NULL, NULL, 0);
