# 1262. Taken-hit reads primed resists, capped absorbs and exact per-trial counts

- Status: proposed
- Date: 2026-11-24
- Related: [ADR 0196](0196-count-how-often-a-strike-takes-hold-on-the-caster.md) (the `resist_rate` judge),
  [ADR 0999](0999-a-taken-hit-arm-can-open-with-striker-casts-and-attributed-auras.md) (striker fixtures),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (the closed evidence tables, unchanged here).
- Decided by: controller go of 2026-11-23 (Felsworn last round, batch L1).

## Context

Five Felsworn claims are read on the enemy side of a hit the caster takes, and `taken_hit` could not express them:

- Doomstride 804613 "Can only occur once every 10 sec.": `resist_rate` casts one strike per trial, so the 10 s internal
  cooldown (706818) is never crossed inside a trial.
- Tyrannical Resolve 804823 "up to 100% of your maximum health.": the `share` absorb judges each strike alone; the
  server caps the absorbed total over the effect.
- Tyrannical Resolve 804823 "When this ends, you unleash a Felfire Blast that leeches health ... based on how many
  times you took damage": the closing hit lands on the striker after the effect, and only its rise with the hit count
  is stated.
- Felbane 525001 "causing the next spell they cast ... to be reflected onto them": the striker's strike must be read on
  the striker itself, and the server ignores triggered casts, which is how creature strikes were cast.
- Warlock Training 560641 "unable to critically strike": `damage_ratio` with `critical` leaves out a trial with no
  critical log, so the arm under Crippling Pain had nothing to judge.

## Options

- One new kind per claim. Rejected: each repeats the striker, arms and trials of `taken_hit`.
- A share or rate judge for counts (critical share, reflected share) with a tolerance. Rejected: the stated outcomes
  are exact per trial once natural misses are removed, and a tolerance would hide one wrong trial.
- Opt-in fields on `taken_hit`, each absent by default, with exact per-trial judging.

## Decision

The third option, in `behaviours.py` and `compare.py`; existing judges, tolerances, evidence classes and closing
keys are unchanged, and the label check stays `behaviour_taken_hit`.

- Arm `prime_gap_ms` (`resist_rate` only): a priming strike, a wait of the gap, the removal of the strike's aura, then
  the judged strike.
- `striker_spell_hit` (spell hit bonus 100 on the creature striker, so `MagicSpellHitResult` caps its hit chance at
  100%) and `striker_untriggered` (the strike cast step carries `triggered: false`). Fixtures of a creature striker,
  stated in the contract.
- Arm `absorb: "capped_share"` with `cap_pct`: the expected absorb of a trial is
  `min(floor(share% x (damage + absorb)), cap - absorbed so far in the arm)`, with `cap = cap_pct% x caster_max_health`.
  The verdict is `unmeasured` unless one judged trial lies below the cap and one is held by it.
- `judge: "counts"` with `count_reads`, `count_total`, arm `counts`, optional `rising`, `equal`, `state` reads and arm
  `require`. A trial is judged when the `count_total` deltas reach its strikes and its `require` states hold;
  otherwise it is void. Each judged trial must match exactly. An arm with fewer than half its trials judged
  (`TAKEN_HIT_MINIMUM_SHARE`) leaves the verdict `unmeasured`: a skipped trial never counts toward a pass.

## Consequences

- Finished classes (Witch Hunter 15, Templar 19 with and without `--stack`, Necromancer 23, Sun Cleric 27)
  regenerate byte-identical: no entry of theirs uses a new field.
- Seeded tests and mutants in `test_taken_hit_counts.py`: an uncapped absorb, a missing cooldown, a strike that is
  not reflected, a flat closing blast and an unequal leech each alert; too few judged trials and a voiding state
  read stay `unmeasured`.
- The `counts` judge reads exact integers; a claim whose outcome is a rate needs the existing rate judges.
