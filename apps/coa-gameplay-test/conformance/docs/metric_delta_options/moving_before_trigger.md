# Moving before trigger (`metric_delta` `moving_before_trigger`, ADR 0731)

`moving_before_trigger` is `{"flag": "forward" | "backward" | "strafe_left" | "strafe_right"}`. Right before each
cast of the entry's `trigger_spell` by the caster, the scenario sets that native movement flag on the caster (the
harness `set_moving` step), and clears it right after the judged reading (before, after or expired) that follows the
cast. The cast therefore starts and runs while moving. It adds no check: the judged metric is usually `cast_failure`
of the trigger, `SPELL_FAILED_MOVING` (51) without the spell under test and 0 with it; an interrupt during the cast
reads `SPELL_FAILED_INTERRUPTED` (40), so a reading later than the cast time also tells that the cast survived the
movement. A phase without a trigger cast does not move. Absent, the scenario is unchanged.

Witch Hunter: Boltslinger 92091 `moving_cast` (Darkslayer 681203, 2500 ms cast, InterruptFlags 3, read 3000 ms after
the cast).
