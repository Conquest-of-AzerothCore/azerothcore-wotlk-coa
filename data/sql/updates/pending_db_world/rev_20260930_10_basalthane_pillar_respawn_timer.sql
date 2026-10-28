-- Pillars (9650001-9650003) had spawntimesecs=120, so a pillar shattered by
-- ShatterPillar() -> KillSelf() auto-respawns via its own normal respawn
-- timer after 2 minutes -- both mid-fight (any pull longer than 2 minutes)
-- and after a kill, contradicting the encounter's own design (pillars only
-- come back on wipe/evade, via RestorePillar()'s explicit Respawn(true),
-- never on their own timer, never on a kill).
--
-- Set to 86400 (1 day) so the natural timer never fires during normal play --
-- RestorePillar()'s explicit Respawn(true) call still works immediately
-- regardless of this value, it only suppresses the unwanted automatic one.

UPDATE `creature` SET `spawntimesecs` = 86400 WHERE `guid` IN (9650001, 9650002, 9650003);
