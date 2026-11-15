# 0001. Spirit chance claims run set Spirits in two stack arms

- Status: proposed
- Date: 2026-11-15
- Tool half: [ADR 0662](../../0662-a-chance-per-aura-stack-is-judged-on-each-arm-total.md) (shared draft, number
  assigned at merge): the `stack_chance_rate` kind, its judge on each arm's total and its fixture rule.

## Context

Two Witch Doctor talents roll a chance that grows with the caster's Spirits (561136, `StackAmount` 5):
- Spirit Hunting 707504, ledger clause "Each active Spirit gives you a 15% chance when you cast Malefic Arrow to
  generate an additional Spirit.": `roll_chance_i(count * 15)` at `AscensionWitchDoctorAbilities.cpp:313-314`;
- Loa Spirits 705843, ledger clause "For each active Spirit on you, you have a $561361s1% chance for your Reclamation
  to cast an additional time." ($561361s1 is 561361 EffectBasePoints[0] 4 + DieSides 1, shown as 5):
  `roll_chance_i(count * 5)` at `AscensionWitchDoctorAbilities.cpp:308`.

`count` is the stack count that `OnSpellBeforeEffects` stores before the cast (`Abilities.cpp:101`). Every extra
Spirit is a cast of 561136 (`GainSpirit`, `Completion.cpp:137-150`, also at the cap), and every recast is a triggered
cast of Reclamation 806288. The class-file quotes are these full ledger clauses (mentor M-5); `behaviour_entry` matches
them against the cleaned tooltip, which keeps `$561361s1` unrendered.

## Decision

Both claims use the `stack_chance_rate` kind of ADR 0662.

- Fixture (mentor M-4, guide 3.4): Spirits are set by harness `set_aura` before every cast. A real Spirit costs one
  Reclamation cast each, so a 5-stack arm would cost five extra casts per trial, and every Reclamation adds a Spirit,
  so holding a fixed count with real Spirits would also need a removal between casts. The subject is the extra Spirit
  or the recast, which the server produces for real. Claims delivered through the SyncSpirits auras (SpiritStats
  561299, SpiritCast 561137, SpiritChance 561361, Juju Spirits 807296) keep real Spirits: `set_aura` runs SyncSpirits
  only through the Spirit apply hook (`AscensionWitchDoctorAuras.cpp:215-216`), so those auras can lag the fixture.
- Arms: the two cheapest stack counts, from the flip-proof size of each total (ADR 0662, mentor M-14 and M-14a, after
  the `prove-c2r` flip of Loa Spirits from `ok` to `measured`; b is the band half-width itself). Spirit Hunting:
  5 Spirits (75%, band 3.75 points) and 4 Spirits (60%, band 3 points), 5,284 and 10,568 casts below 10 parts, the
  9 parts it runs; 1, 2 and 3 Spirits need 12,632, 20,805 and 19,374. Loa Spirits: 1 Spirit (5%, band 2 points)
  and 2 Spirits (10%, band 2 points), 4,706 and 8,917 casts below 10 parts, 5,449 and 10,324 at the 13 parts they
  run (t quantile 3.055, 12 degrees of freedom); 3, 4 and 5 Spirits need 12,632, 15,851 and 18,576 below 10 parts.
- Parts: Spirit Hunting 9 parts of 588 and 1,175 casts (5,292 and 10,575 per run), with 10 control and 10 unlearned
  casts each (Malefic Arrow: 1,600 ms apart, cooldown reset each cast). A part holds 1,783 casts in 8,963 steps, so
  the 10,000-step cap sets the count: 8 parts would need 661 and 1,321 arm casts per part, 10,058 steps. Below 10
  parts, Wilson on the pooled count judges it. Loa Spirits 13 parts of 420 and 795 casts (5,460 and 10,335 per run),
  with 90 control and 8 unlearned casts each (Reclamation: 1,800 ms cast + 500 ranged, 2,500 ms apart). A part waits
  3,287.5 s, so the one-hour accelerated cap sets the count: 12 parts (t 3.106, 11 degrees of freedom, 5,532 and
  10,481 casts) would need 1,433 casts per part, above the 1,414 the cap allows, and 9 parts on Wilson 1,612. From
  10 parts the between-part t interval judges it (ADR 0647).
- Pilot (G-20 step 1), if the controller runs it first: override an entry with `"pilot": true, "parts": 1` and two
  arms of 300 casts (control and unlearned 50 each). The label is the same, so a pilot and a full entry cannot both be
  in the class file. If the pilot's rate is far from the stated total, the full sizing is recomputed from it.

### Cost of one counted pair (mentor M-6)

Game time is the sum of the waits: Spirit Hunting 1,783 casts x 1.6 s + 5 s settle = 2,857.8 s per part (47.6 game
minutes), 428.7 game minutes per run of 9 parts and 857.3 per counted pair. Loa Spirits 1,313 casts x 2.5 s + 5 s =
3,287.5 s per part (54.8 game minutes), 712.3 per run of 13 parts and 1,424.6 per counted pair. The generated
scenarios hold these timeouts (2,917,800 and 3,347,500 ms, 8,963 and 5,299 steps; generated outside the worktree,
22 scenarios).

The acceleration is not a fixed ratio: on the simulated clock a `wait` advances at most 25 ms of game time per world
update and a non-wait step 3 ms (`docs/coa/verification.md`, Accelerated single-server mode). The recorded ratios are
2,180 s of game time in 29 s (about 75x) and 1,850 s in 8.5 s (about 218x, ADR 0139). These cast loops are almost all
`wait`, like those runs. At 75x one counted pair takes about 11.4 wall minutes for Spirit Hunting and 19.0 for Loa
Spirits (3.9 and 6.5 at 218x). The G-20 step 3 limit of 90 wall minutes per claim is reached only below 9.5x and
15.8x, so neither claim crosses 90 minutes at either recorded ratio: both run the full pooled proof and are judged to
the band. Loa Spirits has the smaller margin; it would cross only at a ratio about a fifth of 75x.

## Consequences

- A flat chance alerts on the lower arm (Spirit Hunting: a flat 75% at 4 Spirits against 57% to 63%; Loa Spirits: a
  flat 5% at 2 Spirits against 8% to 12%). A per-stack chance outside the band of a total alerts.
- A roll on the count after Reclamation's own Spirit (5% x (N + 1)) alerts on both Loa arms (10% at 1 Spirit, 15% at
  2). Not seen: a roll that departs from the stated chance only at counts no arm runs, 3 to 5 Spirits for Loa Spirits
  (for example a cap at 2 or more) and 1 to 3 Spirits for Spirit Hunting.
- Native paths: both talents are passive with ProcFlags 0, so their aura 42 does not fire. Spirit Hunting's has
  ProcChance 0. Loa Spirits' (trigger 707422, which re-triggers 806288) has ProcChance 1, raised by SpiritChance 561361
  by 5 per stack; if it came alive, the 0-stack control would catch it with probability 1 - 0.99^n, 1 - 7.8 x 10^-6
  (99.9992%) for the 1,170 control casts of one run (13 parts of 90).
- Mana: `cast_power` 1000 is unverified for the bow. The 2,567 maximum mana read in compare-c1 was taken with the
  reference weapon (item 72038, the review's "2H mace"), not the bow 2000265 these scenarios equip. A `set_power`
  above the maximum errors the scenario rather than misjudging it.
- Expected outcome: ok for both. The code rolls `count x 15` and `count x 5`, with `count` read before the cast.
