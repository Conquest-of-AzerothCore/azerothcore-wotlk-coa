# 0084. `internal_cooldown` behaviour kind for proc-throttle clauses

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's `cast-conditions-cooldowns` workstream still carries Disciplined Blows 680397's "Can only occur
once every 0.5 sec." clause (the actual DBC `Description[enUS]` text reads "Cnly occur once every 0.5 sec.",
a client-data typo distinct from the round10 audit's own corrected quoting of it). No existing kind proves a
throttle: `trigger_count` (`triggers.py`) already proves the pulse fires once per qualifying heal, spacing
repeated casts `cast_interval()` apart specifically to stay clear of any internal cooldown, so it can never
observe the throttle actually blocking anything.

`AscensionTemplarEvents.cpp`'s `aura_ascension_templar_event::Check`, case 680397, returns
`heal && (event.GetTypeMask() & DONE_HIT_PROC_FLAG_MASK) && !State(player).cooldowns.HasTimeUntilEvent(id)`;
its own `Proc`, same case, unconditionally runs `State(player).cooldowns.ScheduleEvent(id, 500ms)` before
casting 680398 — the literal 500 ms window the tooltip names, confirmed by reading the source rather than
inferred from the tooltip text.

Producing two qualifying heal events under 500 ms apart is not trivial: the trigger spell, Benediction
578276, has `StartRecoveryCategory` 133 and `StartRecoveryTime` 1250 (`Spell.dbc`, confirmed by direct field
read) — the standard shared global cooldown. `Spell::TriggerGlobalCooldown`/`HasGlobalCooldown`
(`Spell.cpp:9181-9238`) key every global-cooldown check by `StartRecoveryCategory`
(`GlobalCooldownMgr::HasGlobalCooldown`, `CharmInfo.cpp:397-401`, `m_GlobalCooldowns.find(StartRecoveryCategory)`),
so two 578276 casts through the harness's real `CMSG_CAST_SPELL` path can never land under ~1250 ms apart —
confirmed empirically too: the existing 680397 `trigger_count` scenario already spaces its own repeated
578276 casts 1750 ms apart for exactly this reason.

## Considered options

1. Wait for two Benediction casts spaced under 500 ms via the harness's own `cast` action. Rejected: blocked
   outright by Benediction's own 1250 ms global cooldown, confirmed from both the DBC field and the engine's
   `GlobalCooldownMgr` source; the second cast would simply fail `CheckCast`, proving nothing about the ICD.
2. Align a Benediction cast with a heal-over-time tick from an existing Templar HoT (Testament of Fortitude
   500678, `aura_amplitude_ms` 1000 per round4's own verdict) via precisely timed `wait` steps. Rejected:
   requires landing a cast within tens of milliseconds of a predicted server tick, far tighter than the
   margins every other timed check in this harness relies on (`CAST_MARGIN_MS` 500), and depends on an
   unrelated spell's own timing instead of the clause under test.
3. A multi-target heal landing on several allies in one cast (near-simultaneous `ProcEventInfo` dispatch, no
   global-cooldown concern since it is one cast). Rejected: no reachable Templar heal with more than one
   target was found (Chakra of Light 803844 only modifies a different melee ability's heal radius, itself a
   separate unbuilt clause); would also need a second party-member player actor just for this one check.
4. Pair the Benediction cast with item 118 (Minor Healing Potion, `data/sql/base/db_world/item_template.sql`
   `spellid_1` column, immutable base data read not edited). Its own spell 439 has `StartRecoveryCategory` 0
   (confirmed by direct field read), so `GlobalCooldownMgr::HasGlobalCooldown`'s category-keyed lookup never
   finds Benediction's active global cooldown under it: drinking it immediately after casting Benediction is
   never blocked by that cooldown (confirmed by reading both call sites, not assumed). Chosen: the pair lands
   well inside the 500 ms window using only the harness's existing `cast`/`use_item`/`add_item` actions, with
   no new timing precision and no second player actor.

## Decision

- `behaviours.py` gains `BEHAVIOUR_INTERNAL_COOLDOWN`, `InternalCooldownSpec`, `internal_cooldown_label`,
  `internal_cooldown_scenario` and `internal_cooldown_spec`, and the `internal_cooldown` kind in `KINDS`/
  `BEHAVIOUR_CHECKS`/`behaviour_scenario`'s dispatch. An entry names the aura `spell`, the `trigger_spell`
  (the heal cast), `observe_spell` (the triggered pulse), `item`/`item_spell` (the no-global-cooldown heal
  item and its own spell id) and `allowed_wait_ms` (generous enough to clear both the 500 ms window and the
  trigger spell's own global cooldown before the third cast).
- The scenario casts the trigger spell once (`first`, expected to fire the pulse), immediately uses the item
  (`blocked`, expected unchanged — the pair is exactly the tooltip's own "two heals within 0.5 sec of each
  other"), waits `allowed_wait_ms`, then casts the trigger spell again (`allowed`, expected to increase by
  exactly one). `fixture_health_step` resets the caster's missing health before every heal attempt so none
  of the three ever overheals to a zero effective heal.
- `compare.py` gains `behaviour_internal_cooldown_verdict`: reads the three `spell_cast_count` labels and is
  `ok` only when `blocked == first` (no change inside the window) and `allowed == first + 1` (one more fire
  past it); any other combination, or a missing measurement, is an alert.
- `passives.py`'s `BEHAVIOUR_LABELS` gains an `internal_cooldown` entry so a P5-linked passive naming this
  same spell resolves to its `behaviour_internal_cooldown` label instead of raising.
- One `classes/templar.json` entry closes Disciplined Blows' remaining clause.

## Consequences

- Any other Templar ICD clause (Sacred Defense 705306's 1 s window among the remaining clauses) can reuse
  this same kind once its own trigger can be fired twice within its window without the trigger's own global
  cooldown interfering — for a `taken_hit` trigger that is a striker attack, not a player cast, so it may not
  need the item technique at all; 705306 additionally needs its own truncating-damage confound resolved
  first (already documented in the workstream report), independent of this kind.
- The no-global-cooldown item technique (item 118, category-0 spell 439) is now a documented, reusable way to
  land two player-caused effects inside a sub-GCD window for any future class's ICD clause, without adding a
  second player actor or timing the scenario against an unrelated aura's own tick schedule.
