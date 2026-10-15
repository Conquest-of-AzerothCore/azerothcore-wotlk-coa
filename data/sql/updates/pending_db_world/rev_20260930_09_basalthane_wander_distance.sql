-- Basalthane's random walk (MovementType=1) is intentional -- he wandered on
-- real Ascension too. User confirmed this, and that in-combat movement is
-- already correctly handled by the engine's own combat AI (random walk only
-- ever applies while idle/out of combat; EnterEvadeMode's MoveTargetedHome()
-- already resets him to his spawn point on wipe/evade -- no custom code
-- needed for either).
--
-- wander_distance was 35 (original value) on one server and 8 (a later,
-- tighter tuning) on another -- settled on 8 as the correct value.

UPDATE `creature` SET `wander_distance` = 8 WHERE `guid` = 9650000;
