-- rev_20260925_35 gave the pillar creatures (10186/10187/10188) flags_extra
-- |= CREATURE_FLAG_EXTRA_TRIGGER (0x80) on the assumption it would make them
-- "read as scenery, not an NPC". Wrong: ObjectMgr::ChooseDisplayId() skips the
-- real model entirely for CREATURE_FLAG_EXTRA_TRIGGER creatures and falls
-- back to the invisible model (only visible with GM mode on) -- confirmed
-- live 2026-09-26, the pillars were invisible to a normal player and only
-- showed up (with name/nameplate, still targetable) once GM mode was on,
-- because GM view bypasses the normal client-side selectability checks too.
--
-- Fix: drop CREATURE_FLAG_EXTRA_TRIGGER. unit_flags already carries
-- UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE (0x02000002, set in
-- rev_20260925_35 and untouched here) -- that alone is what actually
-- prevents targeting/damage for a normal player; TRIGGER was never needed
-- for that and was actively breaking visibility.

UPDATE `creature_template` SET `flags_extra` = `flags_extra` & ~0x00000080
WHERE `entry` IN (10186, 10187, 10188);
