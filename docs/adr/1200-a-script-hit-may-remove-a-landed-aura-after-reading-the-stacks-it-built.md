# 1200. A script hit may remove a landed aura after reading the stacks it built

- Status: accepted (provisional number, to be renumbered to the next free shared number before merge)
- Date: 2026-11-22

## Context

Sun Cleric Suncharged 804628: "At the end of the duration, or when Judgement Day ends, the enemy takes ... Holy
damage, increased for each stack on the target." Judgement Day 570125 puts Suncharge 807080 on the target every 500 ms
(570125 slot 2 tick, AscensionSunClericAuras.cpp:239-243, Amplitude 500 set in AscensionSunClericContracts.cpp:277-278),
up to 10 stacks, and any removal of 570125 from a caster who has 804628 releases 807064 with the stacks read from
807080 (AscensionSunClericAuras.cpp:187-189, ReleaseSuncharge AscensionSunCleric.cpp:326-334). The `release` entry reads
the 10-stack case at the natural end (32 s). The "per stack" part and the "when Judgement Day ends" branch need a hit
read at fewer stacks, so the harness has to end Judgement Day itself once 807080 holds a chosen count.

`script_hit` had no way to act between the casts and the read. Three fields were added (D-167) and a first design of
the 1-stack arm failed (D-174): trial 2 read 10 stacks at 9000 ms where trial 1 had read 1 at about 115 ms.

Cause of that failure, shown by the diagnostic run `.cache/verify-all/20261122-164250` (non-failing reads):
- The options were applied in every trial. The defect was a missing clean start.
- 806121 does not apply 570125 itself: its Effect[0] is 183 (SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED) with
  TriggerSpell 570125 and BasePoints 149 (/srv/coa/server-data/dbc, Spell 806121). `Spell::EffectAscensionTriggerSpellDelayed`
  queues the cast with `Milliseconds delay(std::max<int32>(1, damage))` and `m_Events.AddEventAtOffset`
  (SpellEffects.cpp:1092-1094), so 570125 lands about 150 ms after the cast.
- A removal issued straight after the cast therefore removes nothing: the read was 570125 absent at 0 and 100 ms,
  present from 200 ms to 6600 ms. The control arm, which removes right after each cast, left Judgement Day
  (SpellDuration 9 = 30000 ms) on the dummy.
- `learn 804628` then let that leftover tick (807080 = 1 at 700 ms, 2 at 1200 ms, 4 at 2200 ms), so trial 1 read 1 from
  the control's Judgement Day. Its own removal, about 115 ms after the cast, again came before the landing, so
  trial 1's Judgement Day ticked through the 4000 ms settle and trial 2 started with 8 or more stacks.

## Options

- Wait a fixed delay after each cast before removing: states a duration, not a state, and cannot tell a leftover from
  the trial's own aura.
- A fresh dummy for every trial: the scenario has one dummy and the plan fixes the trial count per scenario.
- Gates built from existing reads: remove the leftover once, require a clean receiver at every trial start, require
  the aura to be present before it is removed, and void the arm otherwise.

## Decision

Python builder only (behaviours.py, `script_hit`); no new kind, metric or harness action. Entries without the fields
generate unchanged (Necromancer, Templar and the other finished classes are byte-identical, checked by regenerating
classes 15, 19, 19 `--stack` and 23 before and after).

- `receiver_aura_removals`: `[spell, delay_ms]` pairs removed from the dummy (`set_aura stacks 0`) after the last cast
  of every trial of both arms; needs casts and the dummy receiver.
- `no_wait_after_casts`: the removal follows the last cast without the cast's trailing wait.
- `stacks_read_before_removal`: `[spell, stacks]`; in the treatment arm an `aura_stacks` assert (`SETUP stacks N`,
  `equals`, `within_ms` 9000) precedes the removal. With it the builder also:
  - removes the `receiver_aura_removals` auras once after the control drain and before the tooltip spell is learned;
  - before the casts of every treatment trial asserts, on the dummy, `aura` of each removed spell `equals 0` and
    `aura_stacks` of the read spell `equals 0` (`SETUP clean N`);
  - before each removal asserts `aura` of the removed spell `equals 1` (`SETUP <spell> present N`).
  A failed assert fails the scenario, which voids the arm; it never produces a measurement.

## Consequences

- A removal always follows the landing of the aura it removes, and the stack count at the removal is read, not
  assumed. An arm that starts dirty or reads another count is void; the compare verdict then reads `alert` with no hit
  measurement, a false alert and never a false pass.
- In a clean trial 807080 holds exactly 1 stack for one 570125 period (Amplitude 500) before the second tick; the
  `within_ms` poll reads once per world tick, which the counted pair must confirm.
- Seeded tests in test_behaviours.py (`ScriptHitReceiverAuraRemovalTests`): removal position, stack read before the
  removal in the treatment arm only, clean gate per treatment trial, control leftover removed before the learn,
  presence read before each treatment removal, no gates without a stack read, entries without removals unchanged,
  refusals.
- Provisional number: the next free shared number after 1029 on the branches known at writing.
