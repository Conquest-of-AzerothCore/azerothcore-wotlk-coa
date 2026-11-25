# 1296. Portal single cast proves one direct cast from an allowed set and post-cast despawn before lifetime

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39, D-43; G-39 harness note approved

## Context

Three Cultist (class 25) talents summon Void Portal `533030` (`AscensionCultistSummons.cpp:290-297`), each stating that
the portal "casts either Gaze of C'thun, Horrorbolt, or Obliteration Beam before disappearing":

- Depths of Madness `706911` (row 321): 15% raw `Chance()` roll on Gaze of C'Thun `520332` damage.
- Sunderer of Realities `301068` (rows 66, 67): deterministic on subsequent Wrath of the Black Empire casts within
  `301067`.
- Apocalyptic Skies `301200` (row 75): deterministic on every Wrath of the Black Empire cast.

Merged entries proved that each of the three spells is seen across a sample of portals and that 100% of portal damage
and healing comes from those spells, but left two properties as tool gaps:

1. **Exactly one cast per portal, no unlisted spell:** `ProcCounter::CastCount` is keyed by `(owner, spell)` and
   `owned_creature_spell_cast_count` requires a single spell id and a living creature, so it cannot read total casts
   across all spells of one portal. Moreover, `OnSpellCast` records triggered sub-effects alongside direct casts
   (Gaze of C'Thun `500110` triggers `520334/520332/520335/520333/804095`, Obliteration Beam `805572` triggers
   `805573`), so a total-cast count must distinguish non-triggered casts (`!spell->IsTriggered()`) from triggered
   sub-effects.
2. **Disappears after its cast, strictly before summon lifetime:** `Summon()` gives `533030` a `12000 ms`
   `TEMPSUMMON_TIMED_DESPAWN` lifetime, and `AscensionCultistSummons.cpp:296` calls
   `me->DespawnOrUnsummon(IsChanneled() ? 10000ms : 5000ms)` after the portal's single cast (`Pulse` at `100 ms`). For
   `706911` (15% raw `roll_chance_f`), a fixed burst cannot deterministically isolate one portal's spawn time to check
   early despawn before `12000 ms`.

## Decision

1. **Opt-in harness read `owned_creature_total_cast_count`** (`CoAGameplayTest.cpp`, `run.py`):
   - `ProcCounter` tracks non-triggered casts in `_directCasts` alongside existing `_casts` (leaving `CastCount` and
     `owned_creature_spell_cast_count` unchanged).
   - `owned_creature_total_cast_count` takes `entry`, optional `spell`, and optional boolean `triggered` (default `true`;
     `false` reads `_directCasts`). Returns `-1.0` when no living owned creature of `entry` is present so void feed caps
     and premature-despawn alerts complete cleanly for the judge.
2. **Opt-in harness action `cast_until_owned_creature`** (`CoAGameplayTest.cpp`, `run.py`):
   - Mirrors `cast_until_aura`, submitting the same cast path every `every_ms` up to `max_casts` while
     `GetOwnedCreature(player, entry) == nullptr`, and completing immediately on the first world update where the summon
     exists. Records `attempts` and `stopped` (`creature` or `cap`).
3. **Opt-in behaviour kind `portal_single_cast`** (`kinds/portal_single_cast.py`, `ORDER = 57`):
   - Registers `METRIC_EVIDENCE = {'owned_creature_total_cast_count': 'event'}` inside the kind module (no edit to
     `coverage.py`).
   - Runs an unlearned control arm (alerts on any spawn), then observes at least `6` independent portals per run
     (pooled across `parts`; refuses smaller samples).
   - For each portal: verifies `0` before trigger, `1` on spawn, `1` alive at `cast_read_ms`,
     `owned_creature_total_cast_count(triggered=false) == 1`, summed allowed-spell direct casts `== 1`, and `0` living
     creatures at `direct_despawn_check_ms` (or `channeled_despawn_check_ms` if the chosen spell carries
     `SPELL_ATTR1_IS_CHANNELED | SPELL_ATTR1_IS_SELF_CHANNELED` in `Spell.dbc`), both required to be at least `500 ms`
     below `lifetime_ms`.
   - In `Spell.dbc`, `500110`, `800416`, and `805572` all have `AttributesEx & 0x44 == 0` (`IsChanneled() == false`), so
     all three follow the `5000 ms` despawn branch (checked absent at `6200 ms`, `5800 ms` before the `12000 ms`
     lifetime); the kind also supports and tests the `10000 ms` channeled branch (`10800 ms < 12000 ms`).

## Consequences

- Strictly opt-in: no existing scenario uses `owned_creature_total_cast_count`, `cast_until_owned_creature`, or
  `portal_single_cast`. Finished classes regenerate byte-identical.
- Closes the "exactly one cast" and "before disappearing" claims for Cultist `706911` (row 321), `301068` (rows 66, 67),
  and `301200` (row 75).
