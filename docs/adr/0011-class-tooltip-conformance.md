# 0011. Check each CoA class against its client tooltips

- Status: accepted
- Date: 2026-11-05

## Context

Balancing a CoA class needs a sound base first: every number the client shows should be what the server does,
and every difference should come from an identified outside element (an aura, a buff, a stat given on purpose,
the target's mitigation) whose own effect follows its tooltip. Without that base, "nerf the Templar" or "raise the
Barbarian" has no lever map and no way to see what else a change moved.

What existed on 2026-11-05: 109 Templar scenarios, 20 of them with a numeric assertion, mostly mechanics (an aura
is present, a modifier exists); a static audit of tooltips against server coefficients
(`.agents/plans/class-spell-audit/coef/audit_coef.py`, 192 readable spells of 3,937); and hand-made stacking
scenarios. A measurement of that day found Scourgebane at 0.71 of its tooltip on the usual dummy, unexplained.

The 0.71 factor was explained before any other conclusion: it is the Templar class tuning aura 887007 (-20% PvE
damage done at level 60, `SPELL_AURA_ASCENSION_MOD_PVE_DAMAGE_DONE_PCT`, restored on purpose by #250) times the
documented linear monster resistance for Holy at level 60 (0.880 measured, `docs/coa/monster-linear-resistance.md`)
times the integer truncations of the hit (about 0.995). Tooltips do not show 887007. Not a server defect.

## Considered options

1. Extend the static coefficient audit. Rejected as the judge: it reads server code, not what the server does,
   and it cannot see auras, mitigation or procs.
2. Hand-write catalog scenarios per spell. Rejected for the sweep: 221 Templar spell ids with ranks, and the same
   again for every class; hand-written expectations drift from the tooltip.
3. Generate exploratory scenarios from the client DBC and judge every run with one comparator. Chosen.

## Decision

The package `apps/coa-gameplay-test/conformance/` generates, per class, the scenarios and their expectations,
runs them through `tools/verify_all.py` only (`python -B tools/verify_all.py --stages gameplay --scenario ...`), and
judges the results with `compare.py`, the single judge of every check kind. Its README is the full reference; this
record keeps the method decisions and why.

### Expected values

- Expected values come from the effective client DBC set (`/srv/coa/server-data/dbc`), never from server code.
  The spell set of a class is every `RankSpell` of its `CharacterAdvancement` rows, through
  `CharacterAdvancementClassTypes` (ClassType is not ClassID); ranks come from
  `src/server/coa/AscensionSpellProgressionData.h`.
- Tooltip reading rules follow the stock 3.3.5a client parser (wowdecomp, evidence rather than authority). Whatever
  the reader cannot evaluate (conditionals, markup, unknown tokens, a `$<name>` the spell does not define) is
  `unreadable` with the entry verbatim, never guessed and never `ok`.
- "X% Weapon Damage plus Y" reads as Y added after the percent, for every spell. This record makes it the reading
  rule; it comes from the plan and ADR 0010, which applies that order on the server for the Argent Blade chain only
  and leaves every other spell in DBC order until it has its own evidence.
- `$sN`, `$mN` and `$MN` are shown unsigned while the record is signed: the expected value takes the sign of the
  points shown. Expressions keep their sign; a measured value of the opposite sign is `ambiguous_tooltip`.
- Values that scale with level (`EffectRealPointsPerLevel`, `DurationPerLevel`) stay unreadable with the field
  named. The client scales them by the player's skill rank in the spell's skill line divided by 5, not by the
  character level, and the scenarios do not measure that skill (wowdecomp `Spell_C_GetSpellLevel`). No level rule
  is invented.
- A rolled effect (`EffectDieSides` above 1) is judged against the range of the token over every roll, and only
  when the token is monotone in the roll. In a hit model each roll is one equally likely direct hit, since the
  server adds one `irand(1, EffectDieSides)` to the points of every direct hit; a model that reads the shown value
  alone gives a false alert. A rolled periodic amount is drawn once per aura and shared by its ticks
  (`AuraEffect::CalculateAmount`), so its hit is `unmodelled` until the model judges it per cast.

### Measurement

- The reference character of a class is naked at level 60 with one reference weapon (Templar: human, Walking
  Stick 2495) and fixture hit and expertise ratings, so that no aura or hit is lost to a miss. The class file
  `classes/<name>.json` holds it, its procs, its rotation, its talent stack and its talent modifiers. Its stats are
  measured in every scenario and every comparison uses the measured values.
- The reference target is creature 36 at level 60, stationary. Its armor (528 or 562 at spawn) and resistances are
  measured in the same run. Armor follows the native formula, magic the linear monster resistance with its partial
  resist steps.
- Known modifiers are the auras the naked character measurably carries (Templar: 887007 only). Each is evaluated
  from its own DBC record at the class level and listed in every report. The spec auras 887043 to 887045 join the
  `known_auras` of a class file whose reference character has a specialization; the Templar reference has none.
  Probe auras (Scourgebane 92111) are measured and reported, never used to explain a difference.
- Integer truncations of the server (after each modifier, armor, each partial resist) are modelled on every
  possible hit, never absorbed into a tolerance.
- A scenario provides what the spell record requires before a cast: the power cost, a reset cooldown, and the
  `CasterAuraSpell` of the record as a one-stack fixture aura (Righteous Upheaval requires Oath Chain 704576;
  without it every cast fails with `SPELL_FAILED_CASTER_AURASTATE`).
- Critical, blocked and glancing hits are excluded from hit means; the harness filters them (`critical`,
  `blocked`, `glancing` on the damage metrics).

### Statistics

| Check | Rule |
|---|---|
| effect value, aura amount, power cost | `abs(measured - expected) <= max(1, 0.5% of expected)` |
| cooldown, aura duration | `expected - W <= measured <= expected`, W the game time elapsed between the cast and the read |
| hit mean, melee mean | measured mean within `expected +- 2.576 sigma / sqrt(n)`; casts sized for a 1% half-width at 99%, scheduled at 1.5 times that number; fewer usable hits are `insufficient_trials` |
| proc rate | trials sized for a 2.5-point half-width at 99%; tooltip chance within the 99% Wilson interval |
| stack DPS, source DPS | mean of the passes and its 99% Student t interval (`measured`, never an alert) |
| talent delta | ratio of hit means with a 99% Welch interval; a half-width above 1% of the ratio is `insufficient_trials` |

### Statuses

`ok`, `alert`, `unreadable`, `unmodelled`, `ambiguous_tooltip`, `insufficient_trials`, `unmeasured` and
`measured`. Only `ok` claims conformance. Nothing that could not be read, modelled or measured is ever `ok`, and
an alert never disappears through a wider tolerance or an unjustified factor.

### Method rulings

| Ruling | Decision | Why |
|---|---|---|
| R2 | every run goes through `verify_all` | the repository's single verification path |
| R4 | 887007 and the spec auras are known external modifiers, evaluated from their own DBC values and listed in every report | they explain the 20% on every Templar number; hiding them would hide every Templar number |
| R5 | per-step integer truncation is modelled, never a tolerance | a tolerance would also hide small real errors |
| R6 | level-scaled values stay unreadable | the client computation needs a skill value the scenarios do not have; no invented rule |
| R7 | known auras are the measured set; Scourgebane is a probe | measurement outranks an example in the plan |
| R8 | times are judged one-sided over the measured elapsed window | a timer read after some game time can only be lower |
| R9 | 1.5 times the casts or swings are scheduled; fewer usable hits than needed are `insufficient_trials` | excluded outcomes (critical, block, glancing) must not shrink the sample silently |
| R10 | the harness melee metrics filter critical, glancing and blocked hits | crit-free means need it |
| R11 | a check after a failed single cast is `unmeasured` with the failure code | a failed cast measures nothing |
| R12 | a proc tooltip that leaves the trials open is judged under each reading; disagreement is `ambiguous_tooltip` | choosing a reading would invent a rule |
| R13 | `SPELL_FAILED_NOT_READY` inside a priority rotation is an expected attempt | the rotation presses spells on cooldown by design |
| R14 | a talent bonus with known modifiers is judged both multiplying and adding; disagreement is `ambiguous_tooltip` | neither the tooltip nor the DBC states the composition |

### Outputs

`compare` writes `report.md`, `alerts.tsv` (every verdict that is neither `ok` nor `measured`), `verdicts.json`
and, for a stack run, `levers.md`; `diff` writes `impact.md` between two compare outputs and flags the unintended
significant changes. A change is significant beyond the 99% intervals of the two measurements, or beyond the
deterministic tolerance plus the roll spread (`abs(EffectDieSides) - 1`) of a rolled effect, so that two runs of the
same build list nothing. Pilot results stay outside Git (`.agents/plans/class-conformance/<class>/`).

## Consequences

- Every class needs its own class file before it can be checked: the reference weapon and its `item_template` row,
  the measured known auras, the proc entries with their trigger text and DBC fields, the rotation and the stack.
- A large share of a class stays non-evaluable until the reader or the models grow: free-text effects, level-scaled
  values, effects of several models, and spells whose effect needs state the scenarios do not build. Those are listed
  by status and reason, never counted as conformant.
- A full class run takes a few minutes of real time on the simulated clock, without a server build.
- A spell whose flat weapon effect precedes its percent in the DBC (Sacred Swing first) is an alert under this
  reading until its own evidence decides between the reading and the server order (ADR 0010).
- An alert is a lead for the owner, not a defect: it is triaged by hand, and a fix gets its own regression.
- An owner ruling on an open question below adds a reading rule here (a new ADR superseding this one) and turns
  the matching `ambiguous_tooltip` verdicts into `ok` or `alert`.

## Open owner rulings

1. Trial denominator of Scourgebane 92111 ("direct damage dealt": the auto attacks only, or every direct damage
   event, its own strikes included) and of Light's Echo 520017 and 520883 (the player's Argent Blade casts only, or
   every Argent Blade strike, extra strikes included).
2. Trigger of Zealotry for Paladin Training 504808 and Blade Sermon 572548 and 572554: the tooltips do not say what
   triggers it.
3. Target of Transcendent Guardian 804571: the tooltip says a charge to an ally, the code rolls it for any target
   other than the caster.
4. Composition of a talent bonus with a known modifier (R14): does a percent bonus multiply the hit that already
   carries 887007, or add to its -20%?
5. Passes and bound of the lever map: with 5 passes no configuration's DPS change is decisive (1% half-width of the
   ratio); more passes per configuration or a wider bound.
6. Deterministic tolerance `max(1, 0.5%)`: on values under 200 it accepts a 1-point difference, more than 0.5%.
7. Legacy of the Silver Hand 806522, "Increases the critical damage of Scourgebane by $s2%": the whole critical hit
   or its critical bonus.
