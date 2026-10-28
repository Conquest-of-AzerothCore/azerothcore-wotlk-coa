-- Establishes the complete, final smart_scripts state for both Basalthane (10189) and
-- the Molten Blood ooze (310189), source_type 0, as proper full DELETE + INSERT
-- replacements (per .agents/docs/sql-guidelines.md: "smart_scripts edits always rewrite
-- the full block ... never a partial UPDATE, not even for a comment-only fix"). Several
-- earlier migrations in this chain (rev_20260925_34, rev_20260930_03/04/05/13) used to
-- patch individual rows in place instead; since this whole chain is unmerged pending
-- migration data (not live migration history anyone has applied), those partial UPDATEs
-- were removed from the earlier files entirely rather than left in place - this file is
-- now the single source of truth for both blocks' smart_scripts content.

DELETE FROM `smart_scripts` WHERE `entryorguid` = 10189 AND `source_type` = 0;
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    -- Disabled (event_chance=0): Eruption is scheduled from C++ now (see
    -- spell_basalthane.cpp's eruptionNextCast), kept here only as a record of the
    -- original timing data these rows were built from.
    (10189, 0, 2, 0, 0, 0, 0, 14, 39000, 39000, 70000, 80000, 0, 0,
     11, 2108227, 0, 0, 0, 0, 0,
     6, 0, 1, 0, 0, 0, 0, 0, 0,
     'Basalthane - Eruption: first at 39s (WeakAuras data), then every 70-80s (CONFIRMED from real kill logs) - Normal/Heroic/Mythic only, see id=22 for Ascended override - DISABLED, scheduled from C++'),
    (10189, 0, 22, 0, 0, 0, 0, 16, 39000, 39000, 50000, 50000, 0, 0,
     11, 2108227, 0, 0, 0, 0, 0,
     6, 0, 1, 0, 0, 0, 0, 0, 0,
     'Basalthane - Eruption (Ascended/D3 override): first at 39s, then every 50s - user wants faster Eruption cadence on Ascended - DISABLED, scheduled from C++'),
    -- Active rows: Berserk (guess, never confirmed), Fierce Blow (confirmed from logs),
    -- and the two ooze-cleanup-on-evade/death actions. The old id=14 "gain Molten Blood
    -- stack while ooze within 10yd" row is gone - replaced entirely by the merge-based
    -- grant in allcreaturescript_basalthane_ooze_pyroclastic (spell_basalthane.cpp).
    (10189, 0, 12, 0, 0, 0, 100, 0, 1500000, 1500000, 0, 0, 0, 0,
     11, 2100213, 1, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Basalthane - Berserk after 25 min (user-set 2026-10-02, was a 10 min guess)'),
    (10189, 0, 13, 0, 0, 0, 100, 0, 5000, 15000, 5000, 15000, 0, 0,
     11, 975011, 0, 0, 0, 0, 0,
     2, 0, 0, 0, 0, 0, 0, 0, 0,
     'Basalthane - Fierce Blow on tank every 5-15s (CONFIRMED from real kill logs)'),
    (10189, 0, 15, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0, 0,
     41, 0, 0, 0, 0, 0, 0,
     9, 310189, 0, 200, 0, 0, 0, 0, 0,
     'Basalthane - on evade: despawn all Molten Blood oozes'),
    (10189, 0, 16, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0,
     41, 0, 0, 0, 0, 0, 0,
     9, 310189, 0, 200, 0, 0, 0, 0, 0,
     'Basalthane - on death: despawn all Molten Blood oozes (FIXED 2026-09-24, was event_type=8/SPELLHIT by mistake - fired on every single spell hit on the boss and force-despawned every ooze constantly)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 310189 AND `source_type` = 0;
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
     `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (310189, 0, 0, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0,
     8, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Molten Blood - stay passive, never attack players'),
    (310189, 0, 1, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0,
     29, 3, 0, 10189, 0, 0, 0,
     19, 10189, 200, 0, 0, 0, 0, 0, 0,
     'Molten Blood - follow Basalthane at 3yd (native MoveFollow, final decision - see project notes: a custom C++ movement class was tried and reverted, native follow is correct here, just with speed_walk/speed_run reduced ~60% to counter its own catch-up acceleration)');
-- id=2/3 ("reached boss: become aggressive/attackable" / "stop following, act on own",
-- old 4yd proximity) are gone - the ooze is attackable by players from spawn (hostile
-- faction, no NON_ATTACKABLE flag), and the old proximity trigger is replaced entirely
-- by the real-contact merge in allcreaturescript_basalthane_ooze_pyroclastic
-- (spell_basalthane.cpp) - see the SPELL_PYROCLASTIC_* comment there.
