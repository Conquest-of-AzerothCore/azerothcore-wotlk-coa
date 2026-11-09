# 0053. A dodge/parry override replaces retries in `behaviour_duration_ratio` scenarios

- Status: accepted
- Date: 2026-11-10
- Supersedes: [0050](0050-retry-melee-vehicle-casts-in-duration-ratio-scenarios.md)

## Context

0050 deferred the direct fix (zeroing the test caster's dodge/parry chance) and instead retried the melee-class
vehicle cast up to `MECHANIC_LAND_ATTEMPTS` (3) times, reasoning that the retry is harmless because the
vehicle's duration aura refreshes to full on every landed cast. Round 9's `mechanics-report.md` and round 10's
`judging-report.md` record that 712466's `behaviour_duration_ratio` kept reading `alert` on an unlucky run where
every attempt in a phase missed — rare with 3 attempts, but not eliminated, and each occurrence still needs a
rerun to tell a server defect apart from retry exhaustion. The underlying cause 0050 identified stands: Hamstring
1715 (`DmgClass SPELL_DAMAGE_CLASS_MELEE`) resolves through `Unit::MeleeSpellHitResult`, which rolls the victim's
own dodge and parry chance (`GetUnitDodgeChance`/`GetUnitParryChance`, backed by `Player::m_realDodge`/
`m_realParry`) independently of the striker's `spell_hit_bonus`.

## Considered options

1. Keep the retry-only design and raise `MECHANIC_LAND_ATTEMPTS`. Rejected: lowers the failure probability
   without removing it, and a higher count lengthens every scenario of this kind for no correctness gain.
2. Zero the test caster's dodge and parry chance directly, as 0050 originally deferred. Chosen now: `m_realDodge`
   and `m_realParry` are private `Player` fields with no existing setter, so this adds one symmetric,
   test-only accessor (`Player::SetRealDodgeParryForTest`, next to the existing public `GetRealDodge`/
   `GetRealParry`) plus a new, class-agnostic `CoAGameplayTest.cpp` scenario action (`set_combat_avoidance`)
   that calls it on a chosen player target. Both legs of `Unit::MeleeSpellHitResult`'s avoidance roll
   (`canDodge`/`canParry`) clamp to 0 once the victim's own chance is 0, independently of the attacker's skill
   or expertise, so a single cast now lands deterministically (barring the already-forced-to-0 miss roll).
2. (continued) considered but rejected: a reusable stock aura (`SPELL_AURA_ASCENSION_SUPPRESS_AVOIDANCE`,
   already checked at <= -100 by the same roll) would avoid touching `Player.h`, but every existing spell that
   carries it is owned by another CoA class's contract file; reusing one here would be a cross-class effect link,
   forbidden by this workstream's rules, and minting a new CoA-owned spell purely for this harness fixture would
   need a `Spell.dbc`/SQL entry for something that has no in-game existence, a larger and less honest footprint
   than one accessor method.

## Decision

- `Player::SetRealDodgeParryForTest(float dodge, float parry)` (`Player.h`) sets `m_realDodge`/`m_realParry`
  directly; test-only, symmetric to the existing `GetRealDodge`/`GetRealParry` getters.
- `CoAGameplayTest.cpp` gains a `set_combat_avoidance` scenario action (`actor`, optional `target`, optional
  `dodge`/`parry`, defaulting to 0): resolves a player target (the acting player, or an explicit `target`) and
  calls the new setter. `run.py`'s `ACTIONS`/`validate` gain the matching schema entry.
- `mechanic_duration_scenario`'s `phase()` helper (`behaviours.py`) opens each phase with
  `{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0}`, before the existing
  `MECHANIC_LAND_ATTEMPTS` retry loop and settle-and-measure read.
- The retry loop and `MECHANIC_LAND_ATTEMPTS` constant are kept as a safety margin (harmless, and shared by any
  non-melee vehicle that never needed them), but no longer load-bearing for a melee-class vehicle: the first
  attempt now lands deterministically. The contract text and `docs/behaviour-scenarios.md` are updated to say so.
- No change to `judge_hit`/`behaviour_duration_ratio` judging logic, the DR gap sizing, or any other
  `behaviour_duration_ratio` entry's expected ratio or tolerance.

## Consequences

- 712466's `behaviour_duration_ratio` (and 705271/707851/707754's, which share `mechanic_duration_scenario`)
  stop depending on retry luck; a run that still alerts is now attributable to the measured passive, not to the
  vehicle cast missing.
- Any future `mechanic_duration_scenario` entry inherits the override automatically, with no per-entry
  configuration; a non-melee vehicle is unaffected in practice (dodge/parry do not apply to its roll regardless).
- `Player::SetRealDodgeParryForTest` is a narrow, test-only addition to inherited AzerothCore source; it has no
  caller outside `CoAGameplayTest.cpp` and does not change any production code path.
