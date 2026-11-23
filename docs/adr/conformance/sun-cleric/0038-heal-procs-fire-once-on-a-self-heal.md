# 0038. Nine heal and critical-strike procs fire once on a self-heal, from the actor-side event

- Status: accepted (mentor D-255/D-258, confirmed defect under the tooltips, 2026-11-23; 704920 and the case table
  mentor D-276/D-278, 2026-11-23)
- Date: 2026-11-23

## Context

A heal by the caster on the caster doubled nine procs of the class, while the same heal on an ally fired them once.
The first eight come from the valid self / ally readings. Pre-fix: verify stamps 20261122-234650 and 20261122-234725.
Post-fix: 20261122-234822 and 20261122-234910, then 20261123-000746 and 20261123-001507. The table shows the pre-fix
numbers:

| Spell | Tooltip trigger | Read | Self | Ally |
|---|---|---|---|---|
| 300943 Pious | "your critical strikes grant allies Replenishment" | casts of 1257670 | 2 | 1 |
| 704928 Bastion of Hope | "Critical strikes now bless you" | energize 704926 (tooltip 40.5) | 80 | 40 |
| 300336 Light The Way | "Healing done by Shine or Illumination" | casts of 300337 | 2 | 1 |
| 300339 The Redeemer | "When you critically heal your target" | casts of 301005 | 2 | 1 |
| 704563 Warmth | "Direct healing now increases the target's health" | casts of 704564 | 2 | 1 |
| 707077 | "Direct healing done now increases the target's Armor" | casts of 804405 | 2 | 1 |
| 534267 Heat Wave | "Healing with Illumination, Shine, and Daybreak" | heals of 801215 | 4 | 2 |
| 704936 | "Your Illumination now shields you" | casts of 802598 | 2 | 1 |

The ninth is a rate. 704920 Cultivate Divinity: "Effectively healing with Radiant Cascade has a $h% chance to increase
the healing of your next Illumination by $301293s1%. Effectively healing with Illumination has a $707520h% chance to
increase the healing of your next Radiant Cascade by $300354s1%." (Spell.dbc 704920 ProcChance 20, 707520 ProcChance
40). G-20 step 1 at 12062c774e (per-roll reads, 300 rolls per arm, verify stamps 20261122-235014 and 20261122-235115):
self 0.62-0.66 on Illumination and 0.32-0.38 on Radiant Cascade, the doubled rate 1-(1-p)^2; ally 0.37-0.39 and
0.18-0.21, at the chance.

Effective spell_proc rows: the nine auras have one row each at `rev_20260909_13_sun_cleric_completion.sql`, ProcFlags
1048575 (both sides); the six Vows carry the split rows of `rev_20260927_93`, 349524 (done) and 699048 (taken).

Every trigger names the healer's side: a heal or critical strike the Sun Cleric deals.

Cause, from the code (the same mechanism as [Sun Cleric ADR 0037](0037-blessing-of-kings-cuts-once-per-critical-strike.md)):

- `Unit::TriggerAurasProcOnEvent` builds one event for the actor's auras and one for the action target's auras. On a
  self-heal both lists are the caster's, so each aura is offered the heal twice, with the DONE flags and then with the
  TAKEN flags.
- The spell_proc rows of the nine auras (`rev_20260909_13_sun_cleric_completion.sql`, ProcFlags 1048575) accept
  both sides, and their cases in the class check (`AscensionSunClericEvents.cpp`, from e36bc50aad) asked only for an
  own heal or critical hit, true on both events. For 704920 the later rows change Chance only (`rev_20260919_20`, then
  `rev_20261003_10` at 100); `rev_20260927_93` split the sides of the six Vows only. Its `Proc` calls `roll_chance_i`
  once per accepted event, so a self-heal rolls twice. On a damage hit the target's auras belong to the enemy, so damage
  procs were single.

Hope 300349 ("Your critical heals now reduce the cooldown of Solar Invocation spells by 1 sec ... once per sec") reads
once on a self-heal (26885 / 26887 ms against 26888 ms on an ally): its case calls `Chance(player, id, 1000)`, which
schedules a 1000 ms timer on the first accepted event, and the second event of the same heal finds the timer running
(`AscensionSunCleric.cpp`, `Chance`).

## Options

1. In the class check, accept the nine cases only on the actor-side event (`DONE_HIT_PROC_FLAG_MASK`), as 561327
   does since ADR 0037.
2. Remove the TAKEN flags from the eight spell_proc rows. Equivalent in effect, but a new SQL file for eight script
   rules.
3. One filter for every case of the check. Rejected: the received-side cases (301005, 680646, 680888, 807547, 560095,
   92137, 680663, 560492, 300355, 704941, 707629) need the TAKEN event.
4. Deduplicate proc events in `Unit::TriggerAurasProcOnEvent`. Rejected: a shared engine path for every class.

Every case of the check, against the criterion "no side filter" (on a self-cast, actor = action target = aura holder,
a case without one accepts both events). Lines are `AscensionSunClericEvents.cpp` after this change. *Filtered*: a
`done` term, the DONE mask, or a one-sided spell_proc row. *Taken-side*: the tooltip names damage, an avoid, a block or
a deflect taken, which a self-heal never produces. *Timer*: the first event arms a timer the second finds running.
*Not reachable*: damage only (`damage` is 0 on a heal, :50), and the class's damage lands on an enemy, whose own auras
take the target-side event. Rows are spell_proc 1048575 (`rev_20260909_13`) unless stated.

| Case (line) | Spell | Tooltip trigger | Class |
|---|---|---|---|
| 301005 (:78) | Redeemed | "When the target is next hit by a direct spell or attack" | taken-side; aura removed :386 |
| 680646 (:80) | Scroll of Hope | "If any ally falls below 35%" | taken-side; script value :299 |
| 680911 (:82) | Blessing of Triumph | (no tooltip) damage by the holder | not reachable |
| 806123 (:85) | Solar Invigoration | "their direct damage dealt ... once every 3 sec" | not reachable; 3000 ms script timer |
| 680888 (:88) | Blessing of Retribution | (no tooltip) deflect or reflect | taken-side; aura removed :409 |
| 505342 (:90) | Blinded | (no tooltip) melee by the holder | not reachable; aura removed :410 |
| 680624 (:92) | Divine Retribution | "25% of your damage dealt to on the target" | not reachable (aura on the enemy) |
| 807547 (:96) | Vow of Light | "Direct damage taken or direct healing taken by you" | filtered: taken row 699048 (`rev_20260927_93`) |
| 560095 (:98) | Seraphic Bulwark | "Lasts for $n blocks" | taken-side |
| 92137, 680663 (:100) | Angelic Presence, Blessed Bulwark | "Avoiding an attack" | taken-side |
| 560492 (:102) | Protector of the Flame | "Avoiding an attack ... once per sec" | taken-side; 1000 ms timer |
| 300355 (:104) | Stalwart | "Melee critical strikes against you" | taken-side |
| 704941 (:106) | Light of the Sun | "Parrying an attack" | taken-side |
| 707629 (:108) | Sunflare Aegis | "Blocking attacks" | taken-side |
| 803489, 803491, 803719, 807435 (:114) | Vows of Radiance, Dawn, Grace, the Eclipse | "Direct ability damage or healing" | filtered: done row 349524 (`rev_20260927_93`) |
| 807749 (:115) | Vow of the Valkyr | "Auto attacks" | filtered: done row 349524; damage only |
| 300369, 804629 (:116) | Fire from the Heavens, Spears of Glory | "Damage dealt by Radiant Flame" | not reachable |
| 301239, 560861, 806024 (:117) | City of Light, The Coming Dawn, Purgation | "damage dealt by Radiant Flame" | not reachable |
| 300943, 704928 (:118) | Pious, Bastion of Hope | "your critical strikes", "Critical strikes now bless you" | filtered: `done` |
| 561327 (:119) | Blessing of Kings | "Critical strikes now reduce" | filtered: DONE mask (ADR 0037) |
| 300336 (:120) | Light The Way | "Healing done by Shine or Illumination" | filtered: `done` |
| 572885 (:121) | Touch of Light | "Enemies struck by Blessing of Absolution" | not reachable |
| 806116 (:122) | Duality of Light | "your Holy damage dealt" | not reachable |
| 704563, 707077 (:123) | Warmth, Faith | "Direct healing (done) now increases the target's" | filtered: `done` |
| 681252 (:124) | Radiant Halberd | "Direct Physical damage dealt" | not reachable |
| 704934 (:125) | Sunwalker | "Dealing melee damage" | not reachable |
| 806699, 802935 (:126) | Odyn's Vanguard, Sunsworn | "Melee attacks", "auto attacks" | not reachable |
| 680641 (:127) | Sun Strider | "Critical strikes with Gavels or Dawnbreak" | not reachable (the case requires damage) |
| 807343, 804632, 547214 (:128) | Lights of Absolution, Flames of Absolution, Luminary Mendicant | "Damage dealt by Horusath Blast" | not reachable |
| 582832 (:129) | Pure Heart | "Melee critical strikes" | not reachable |
| 805647 (:130) | Knight of Dawn | "Glorious Execution ... strike" | not reachable |
| 300349 (:131) | Hope | "Your critical heals ... Can occur only once per sec" | timer: `Chance(player, id, 1000)`, ProcChance 100 |
| 806058 (:132) | Herald of Purity | "Damage dealt by Justice" | not reachable |
| 301266 (:133) | Solar Concord | "their damage dealt" | not reachable |
| 680643 (:136) | Valiance | "first auto attack on a target" | not reachable |
| 300371 (:138) | Censure | "Dealing direct damage ... once per sec" | not reachable; 1000 ms timer |
| 704920 (:139) | Cultivate Divinity | "Effectively healing with Radiant Cascade / Illumination" | filtered: `done` (this change; unfiltered before) |
| 534267 (:140) | Heat Wave | "Healing with Illumination, Shine, and Daybreak" | filtered: `done` |
| 704903 (:141) | Adjudicator | "Your Justicar's Wrath now deals" | not reachable |
| 704936 (:142) | The Chosen | "Your Illumination now shields you" | filtered: `done` |
| 800612 (:143) | Champion of the Sun | "your melee auto attacks" | not reachable |
| 300339 (:144) | The Redeemer | "When you critically heal your target" | filtered: `done` |

54 cases: 16 filtered (10 by `done` or the DONE mask, 6 by a one-sided Vow row), 10 taken-side, 1 heal timer (300349),
27 not reachable by a self-cast. No case is left unfiltered on the done side.

## Decision

Option 1. The check computes `done = event.GetTypeMask() & DONE_HIT_PROC_FLAG_MASK` once, and the cases of 300943,
704928, 300336, 300339, 704563, 707077, 534267, 704936 and 704920 require it. For The Redeemer only the trigger 300339
is filtered: its return aura 301005 keeps its own case on the received side. 561327 keeps its ADR 0037 line, 300349 is
untouched, and no SQL row changes.

## Consequences

- A heal by the caster on the caster fires each of the nine procs once (704920 rolls once), as a heal on an ally;
  damage routes are unchanged (one actor-side event each).
- Readers of the changed lines: only these nine auras, all Sun Cleric spells. 704920 appears elsewhere only in the
  script's aura list (`AscensionSunClericData.h`) and mod-spellbook data; its buffs 301293 and 300354 are read by
  `AscensionSunClericAbilities.cpp`, `AscensionSunClericContracts.cpp` and `SpellInfo.cpp`, which this change does not
  touch. No other class code names them;
  `AscensionStockCoefficientData.h` lists 300943 and 301005 in coefficient tables that the check does not read, and
  `mod-spellbook` lists them in its spellbook data only.
- Regression: the class file's d245_self/d245_ally (300943, 704928) and d255_self/d255_ally (300336, 300339, 704563,
  707077, 534267, 704936) metric_delta entries, the ally arm being the control, with `void_on_cast_failure`; for
  704920 the four hasted pooled `heal_rate` entries (ADR 1235, D-275): self and ally must both read the
  single rate inside the G-20 band (38-42%, 18-22%), the ally arm being the control.
- Client text unchanged.
