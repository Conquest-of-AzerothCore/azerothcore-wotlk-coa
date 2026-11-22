# 1037. A cooldown variant of `aura_fed_effect` reads a reset and a free recast from a real proc

- Status: proposed (provisional number, numbered at merge; the next free shared number on the class branch)
- Date: 2026-11-22
- Builds on: [ADR 1025](1025-sequenced-casts-earn-a-proc-aura-and-space-hits-around-a-timer.md),
  [ADR 1033](1033-heal-variant-of-aura-fed-effect-and-pre-cast-of-attacker-miss-share.md)

## Context

Sun Cleric Dawn's Arrival 503690 (ledger index 98, mentor D-203): "Casting Dawnbreak now has a $h% chance to reset the
cooldown of Gavels and causes the next one to not incur a cooldown." Mentor D-145 refuses `set_aura` of the free-Gavel
aura 503691 for the count: the sentence says Dawnbreak causes the free cast, so the grant is part of the claim. The
code puts the reset and the grant in one block, one roll (`AscensionSunClericAbilities.cpp:282-287`,
`Chance(player, 503690)` rolls the raw ProcChance), so one real Dawnbreak sequence can read both.
`cooldown_ms` is readback data (the server cooldown map), so the behaviour needs a recast.

## Decision

Python only, opt-in (`variant: "cooldown"`), no harness change, no change for any other variant:

1. Every trial casts the effect spell (Gavel of Light 800611, `CategoryRecoveryTime` 5000) for real and reads its
   remaining cooldown after the global cooldown. Treatment trials then run `cast_until_aura` on the feed (Dawnbreak
   800654, `every_ms` 1700, `reset_cooldown` for the feed only) until 503691 is on the caster; the harness never sets
   it. `max_casts` comes from the feed's DBC ProcChance, one roll per cast, for a residual of at most `residual_target`
   per pair.
2. Reset: read right after the aura appears. A feed that reaches the aura at its first or second cast finds the Gavel
   still cooling (natural 3400 or 1700 ms left), so a read of at most 100 ms is the reset; later casts find the
   cooldown over and are not judged. The casts per trial are the delta of `spell_go_count` of the feed. Control
   trials, without the feed, read the natural cooldown at the same two times, within 10% of the DBC value.
3. Free cast: the effect cooldown is reset as a precondition fixture (so the read does not depend on the reset), the
   Gavel is cast (A), `cooldown_ms` is read 500 ms later (readback, at most 100 ms), and cast again 1600 ms after A
   (B): the behaviour is B going off with `cast_failure` 0 in the treatment and refused with
   `SPELL_FAILED_NOT_READY` 67 in the control. Treatment trials cast it a third time (C), which must be refused: only
   the next cast is free.
4. The entry must carry enough trials: a trial is judged for the reset with probability `1 - (1 - p)^2` (p the
   ProcChance), and the generator refuses fewer trials than keep a run without a judged trial at most
   `residual_target` per pair. A run without a judged trial is unmeasured, never a verdict. A correct server has no
   random outcome in a judged trial.

## Consequences

- Dawn's Arrival's free-cast and reset claims ride a real Dawnbreak; the 40% chance stays an owner question.
- The finished class digests (15, 19, 19 `--stack`, 23) are unchanged: no entry of them uses the variant.
- The judge reads only metrics the other kinds already read (`cooldown_ms`, `spell_go_count`, `cast_failure`, `aura`).
