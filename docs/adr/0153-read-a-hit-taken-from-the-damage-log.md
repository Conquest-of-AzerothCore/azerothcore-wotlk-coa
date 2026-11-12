# 0153. Read a hit taken from the damage log the caster receives

- Status: accepted
- Date: 2026-11-11

## Context

Several Templar clauses state what happens to damage the caster takes: Battlepriest 801202 ("While above 80% health
or below 20% health, you now take 20% reduced Magic damage."), Staffguard 705295 ("absorbing
${$706583m1+$STA*.3} damage, scaling with Stamina, parry and dodge rating"), Tome of Light 805422 ("Grants a shield
equal to 100% of your maximum health"), Keeping the Oath 92109 ("You now delay 40% of direct damage taken") and Holy
Books 706468. Their checks read `script_spell_damage_taken`, `aura_amount` or `cast_stat_ratio`: a calculation
called by the harness or a stored amount, with no hit applied. The trial ruling of 2026-11-11 (point 4) counts such
reads as readbacks; a damage read counts as behaviour when it comes from a damage event applied in the run. The
harness parsed `SMSG_SPELLNONMELEEDAMAGELOG` but skipped its absorbed field and dropped a hit an absorb took whole.

## Considered options

1. Read the shield's `aura_amount` after a hit. Rejected: still a stored amount, not the event.
2. Infer the absorbed amount from the damage of a fixed hit with and without the shield. Possible, but it needs the
   unshielded damage of the same hit in the same state, and a hit absorbed whole leaves no damage event.
3. Record the absorbed amount of every direct spell damage log the player receives, and have a creature cast a
   fixed-damage spell at the caster. Chosen.

## Decision

- The harness keeps every direct spell damage log, its damage and its absorbed amount, including a hit absorbed
  whole: `spell_log_count` and `spell_absorb_total`, with the `caster`, `target` and `critical` filters.
  `spell_damage_count` and `spell_damage_total` are unchanged.
- The `taken_hit` behaviour kind has a striker (creature 36, level 60) cast a fixed-damage spell at the caster
  (Light of the Naaru 41394, 1100 Holy, no die, no level scaling), in a control arm and in one or more treatment
  arms, and reads per trial the strike's damage, its absorbed amount and, for a delayed-damage debt, the debt's
  periodic damage paid before and after the debt's end. Judges: the damage ratio of non-critical strikes (the
  hit-ratio judge, ADR 0125), or every landed trial's absorbed amount compared exactly with no absorb, a formula of
  stats read in the arm (truncated in float as the server computes it), or a percent share of the strike.
- `threat_redirect` reads the dummy's threat on a grouped ally and on the caster around the ally's melee attack,
  before and after the redirecting cast. `fixed_count` takes `cast_target` (the caster), `uncapped` (every offered
  candidate stated) and a health fixture for a heal that triggers an area. `cast_leech_ratio` takes `auras` and a
  control cast that must heal nothing.

## Consequences

- The five clauses above, Barrier of Light 805417's threat redirect and Disciplined Blows 680397's area get
  behaviour checks with a control arm; the readback checks stay as data.
- Players and the striker are at level 60. A miss or a partial log leaves the trial out; each arm needs half its
  trials landed.
- No existing scenario changes.
- Tests: `test_runner.test_spell_log_metrics_need_a_spell_and_take_the_caster_filters`,
  `test_behaviours.TakenHitScenarioTests`, `ThreatRedirectScenarioTests`, `UncappedAreaAndControlledLeechTests`.
