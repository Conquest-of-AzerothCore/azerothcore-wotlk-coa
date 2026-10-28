-- [Tinker] Rocket Boots (#8084): keep a moving caster's movement on the leap.
--
-- Root cause: Tinker Rocket Boots (500241) triggers 760384 (SPELL_EFFECT_LEAP_BACK).
-- EffectLeapBack sends SMSG_MOVE_KNOCK_BACK, a server-forced displacement that hands
-- the client's movement over to the server. That clears auto-run and stops a W-held
-- run, same as Flame Step (#6527) before its dash fix. Both W and auto-run arrive as
-- MOVEMENTFLAG_FORWARD, so the leap cannot distinguish them and must not take over.
--
-- Fix: spell_ascension_tinker_rocket_boots (AscensionTinkerAbilities.cpp) prevents the
-- knockback only when the caster is already moving (FORWARD/BACKWARD/STRAFE) and carries
-- the boost with a run-speed surge at the leap's own horizontal speed (MiscValue/10,
-- 15 yd/s for 760384) for 1s, matching the root/snare immunity window on 500241.
-- A standing caster keeps the original knockback lunge. The immunity auras on 500241
-- are untouched.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 760384 AND `ScriptName` = 'spell_ascension_tinker_rocket_boots';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(760384, 'spell_ascension_tinker_rocket_boots');
COMMIT;
