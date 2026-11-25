# 1312. Outgoing avoidance elimination proves zero miss, dodge, and parry against a facing target

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39 (revisited under G-25); G-39 harness note (read-only counters + opt-in spawn orientation)

## Context

Cultist (class 25) level-20 Heretic passive Shadow Training `805607` (`Spell.dbc`, row 408) states:

> "In addition, you are now unable to miss your attacks and you cannot be parried or dodged."

`Spell.dbc` `805607` applies `Effect[0]` `SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT` (`+100%` hit via
`AuraEffect::HandleAscensionModHitChanceAll` -> `HandleModHitChance` -> `Unit::MeleeSpellMissChance`) and `Effect[1]`
`SPELL_AURA_MOD_EXPERTISE` (`+100` expertise -> `Player::GetExpertiseDodgeOrParryReduction` `-25%` dodge and parry in
`Unit::RollMeleeOutcomeAgainst`, `Unit.cpp:3384,3420`). Against a level-60 creature (`DUMMY_ENTRY = 36`,
`flags_extra = 0`), `ClassicPlusCombat` grants `5%` base miss, `5%` base dodge, and `5%` base parry when the target
faces the attacker (`Unit.cpp:3411`).

Earlier triage (`cu-rt3/review.md:175-180,205`, D-39) deferred this single claim on estimated C++ footprint. Re-inspecting
`CoAGameplayTest.cpp:1855-1895` shows `ObservePacket` already decodes `SMSG_ATTACKERSTATEUPDATE` completely (`hitInfo`,
`attacker`, `victim`, `damage`, and `victimState`), so recording outgoing miss, dodge, and parry counts and orienting a
creature fixture toward its owner requires only ~30 lines of opt-in, read-only harness C++ with zero gameplay side
effects.

## Options

- Accept a permanent tool gap on `805607` row 408. Rejected under G-25 once the real harness footprint proved small and
  cleanly read-only.
- Add opt-in `face_caster`, three read-only outgoing avoidance counters, and a dedicated opt-in kind
  `outgoing_avoidance_elimination` (`ORDER = 61`). Chosen.

## Decision

1. **Opt-in creature spawn orientation `face_caster`** (`CoAGameplayTest.cpp` `CreateTargets`, `run.py`, `test_runner.py`,
   `README.md`):
   - Optional boolean `face_caster` (default `false`) on creature fixtures sets `SetOrientation`, `SetFacingToObject`,
     and home orientation toward the owner player at spawn. Default spawn orientation is unchanged when omitted.
2. **Read-only outgoing melee avoidance metrics** (`CoAGameplayTest.cpp` `Actor`/`ObservePacket`/`Measure`, `run.py`):
   - `melee_misses_dealt`, `melee_dodges_dealt`, and `melee_parries_dealt` (optional `hand` `0` or `1`) count outgoing
     `SMSG_ATTACKERSTATEUPDATE` packets where `attacker == actor.guid` and `(hitInfo & HITINFO_MISS) && victimState !=
     VICTIMSTATE_EVADES`, `victimState == VICTIMSTATE_DODGE`, or `victimState == VICTIMSTATE_PARRY`, respectively.
3. **Opt-in behaviour kind `outgoing_avoidance_elimination`** (`kinds/outgoing_avoidance_elimination.py`, `ORDER = 61`):
   - Registers `METRIC_EVIDENCE` (`event`) for all three metrics inside the kind module (zero edits to `coverage.py` or
     `behaviours.py`).
   - Runs an unlearned control arm and a learned treatment arm sequentially against the same stationary facing dummy
     under identical haste fixtures (`[62531, 2116852]`), resetting dummy health between arms and checking `knows_spell`,
     `alive`, `distance_2d`, dummy `position_o` facing error (`<= 0.15 rad`), haste auras, and post-`stop_attack`
     stillness at both start and end of every arm.
   - Enforces exact binomial minimum sample size `required_min_swings(rate, residual)`: at `rate = 0.05`,
     `residual = 0.001`, `N >= 170` per arm per run (`N = 200` on `805607`: control pair union-bound false-fail
     `<= 6 * 0.95^200 = 0.021%`, treatment pair union-bound false-pass `<= 3 * 0.95^400 = 3.7e-9`, and `<= 0.093%` even
     for a 2%-rate broken mutant).
   - Requires `>= 1` miss, `>= 1` dodge, and `>= 1` parry in control and exact `0/0/0` with `damaging_hits == swings` in
     treatment.

## Consequences

- Strictly opt-in: finished classes regenerate byte-identical (`coverage.py` and `behaviours.py` untouched).
- Closes Cultist Shadow Training `805607` row 408 with combat-event `behaviour` evidence across all three avoidance
  outcomes.
- Seeded tests in `test_outgoing_avoidance_elimination.py` cover generation, evidence registration, `ok`, mutants (single
  treatment miss/dodge/parry, unaccounted non-damaging hit, missing control miss/dodge/parry), `unmeasured` (start/end
  facing drift, death, lost haste, wrong `knows_spell`, stray post-stop swing, missing read), `insufficient_trials`, and
  spec refusals.
