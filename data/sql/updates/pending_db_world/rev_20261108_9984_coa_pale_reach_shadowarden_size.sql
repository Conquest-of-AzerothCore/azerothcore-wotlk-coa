-- Shadowardens (164358) in Scadeald Barrows drew far too small. They use the Shadowed model (142372), and on the
-- realm they are about as tall as a player while crouched (JG98sWrvX4U 0:01:40-0:02:00), like the Rockrend Shadowed
-- (164328), whose 1.6 was settled in game (rev_20261108_9938).
UPDATE `creature_template_model` SET `DisplayScale` = 1.6 WHERE `CreatureID` = 164358 AND `CreatureDisplayID` = 142372;
