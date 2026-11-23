# 0191. Strike the caster with physical, area, periodic and player hits

- Status: accepted
- Date: 2026-11-12

## Context

`taken_hit` (ADR 0153) had a creature cast one fixed-damage Holy spell at the caster. Seven Templar claims about
damage taken need other strikes and two other judges:

- Libram of Tenacity 801461, "reducing your Physical Damage taken by $s2%" and "($s3% against players)": a
  physical strike, from a creature and from a player (the class script takes Effect[2] when the attacker's charmer,
  owner or self is a player);
- Blessed Padding 301311 and 301360, "reduces damage taken from area of effect attacks by $s2%": an area strike;
- Light's Ward 301283, "reduces your damage taken from periodic effects by $301283s2%": a periodic strike;
- Sacred Defense 705306, "strike back at enemies for $s1% of the damage dealt as Holy damage": the returned hit's
  size against the strike that caused it;
- Untainted 705299, "reduces your Physical damage taken by" 10 plus 10% of Stamina (owner ruling 2026-11-11): a
  flat reduction applied before armor, so the caster's armor scales it.

A first run also showed that a 1000-point strike kills the fixture caster within three trials, that `set_aura` keeps
the remaining duration of an aura it finds (Light's Ward 301283 lasts 11 s and ran out mid-arm), that a player striker
of another race logs in at its own start, and that the returned 707720 hit is partly resisted in some trials.

## Considered options

1. A harness change for each strike shape. Rejected: the harness already logs periodic damage (`ObserveSpellDamage`
   reads `SMSG_PERIODICAURALOG`), casts as a player through the cast opcode and reads absorbed and resisted amounts.
2. Model the caster's armor in the judge for a flat reduction. Rejected: the CoA armor formula depends on the
   creature rows and the combat mode; the control strike already carries the same mitigation.
3. Extend the generator and the judge only, with strikes found in the DBC. Chosen.

## Decision

- Strikes: Void Zone 92559 (1000 Physical, DmgClass none), Holy Nova 101350 (2000 Holy, an area around the
  striker), Lacerating Slash 42395 (1735 Physical every 2 s), Night Slaughter 23583 (67 Physical). The entries hold the
  caster at 20000 health before every trial.
- `settle_ms` sets the wait after the strikes; an arm's `refresh` removes its auras before setting them each trial.
- `striker_race` makes the striker a player of that race and the caster's class, both PvP-flagged at one
  location (`TAKEN_HIT_PVP_LOCATION`, the catalog PvP location in Elwynn Forest); it learns and casts the strike.
- `reduction: "formula"` judges a flat reduction: each strike lies within floor((B - R) C / B) and
  ceil((B - R)(C + 1) / B) - 1, with C the control strike, B the strike's fixed base and R the formula. It tells the
  stated reduction from one 2 points away; 1 point is the limit armor rounding leaves.
- `returned_spell` with `returned_pct` judges a returned hit: damage plus absorbed plus resisted equals floor(pct% of
  the strike's damage) for every strike it answers; an arm at 0 returns nothing.
- Every new field defaults to the earlier behaviour.

## Consequences

- Claims 318, 319, 49, 52, 33, 223 and 215 become behaviour proven on one counted pair (worldserver
  69150c59f172): -30.03% and -15.06% physical, -10% and -20% area, -15.04% periodic, 15% returned in every judged
  trial, and Untainted's strikes at 48 against 64 with 17 off a 67 strike.
- Claim 33's `effect_value 301283e1` read is `not_measured` (an aura script sets the amount after CalcValue) and
  leaves the ledger; the periodic ratio is its evidence.
- The flat reduction is checked on a spell strike. A melee swing would take the whole flat amount too
  (`MeleeDamageBonusTaken`), but its damage is not fixed.
- No existing scenario changes: 1,418 and 40 stack scenarios regenerate byte-identical, with seven new ones. The
  manifest's "checked by" rules of 300529, 705298 and 705306 name the new entries.
- Tests: `test_behaviours.TakenHitScenarioTests` (player striker, area and periodic mutants, refresh and settle,
  strike back with its resisted part, reduction off the mitigated control strike, refused entries).
