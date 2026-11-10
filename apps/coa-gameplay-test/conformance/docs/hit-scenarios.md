# Max-rank hit scenarios

`hit_parts(class_file, spell, casts)` models the spell's highest rank from its effects, its tooltip read with the
reference stats, the known auras and the reference target. `casts` is the number of casts the mean needs; the scenario
performs `scheduled_casts(casts)`, `ceil(casts x 1.5)`, so that the hits excluded from the mean (critical, blocked)
rarely leave fewer usable hits (ruling R9). It learns the rank, measures the target, then repeats: `set_power` to the
cost (when the cost is a plain `ManaCost`), `reset_cooldown`, the `CasterAuraSpell` fixture of the record (see
above), `cast`, and a wait of
`max(StartRecoveryTime, cast time, duration of a periodic aura) + 500 ms`; a 3 s drain precedes the measurements.

| `kind` | Effects | Hit before modifiers |
|---|---|---|
| `weapon` | 31 percent, 17/58/121 flat | the floored flats added to the roll, truncated, times the percent (DBC order); `(roll x percent) + flats` for a rank the class file lists in `weapon_percent_before_flat` (ADR 0010) |
| `school` | 2 | the floored tooltip value of each effect, or each integer from `$mN` to `$MN`, or each roll (below) |
| `leech` | 9 (`SPELL_EFFECT_HEALTH_LEECH`) | as `school`: the same `SpellDamageBonusDone`/`Taken` path, with mitigation and damage modifiers |
| `heal` | 10 | as `school`, on the caster, without mitigation |
| `periodic_damage`, `periodic_heal` | 6, aura 3 or 8 | one tick; `hits_per_cast` is `Duration / EffectAmplitude` |
| `triggered_weapon` | 6, aura 23 whose `EffectTriggerSpell` is a `weapon` hit | the `weapon` hit of the triggered spell, per tick; `hits_per_cast` is `Duration / EffectAmplitude` |

`hit_kind` can face an effect without its own token, or several effects whose types belong to different kinds.
Temple Guardian 801165/803792 charges an ally and heals both it and the caster for the same amount
(`Effect[1]`/`Effect[2]` both `HEAL`, equal `EffectBasePoints`/`EffectDieSides`), but `Description[enUS]` carries one
`$m2` token on effect 1 only. For a `heal` kind, an effect with no own token whose `Effect`/`EffectBasePoints`/
`EffectDieSides` exactly match a sibling effect's (`matching_sibling`) borrows that sibling's reading and roll, so
both effects contribute the same expected value; this is conservative on purpose (`SHARED_TOKEN_KINDS`), since
`shown_values`/`value_range`/`fixed_value` stay pure functions of their own effect for every other kind and for
rolled/periodic reads. `effect_hit` never sums several effect indexes into one combined roll: each index is an
independent per-cast event (one heal landing on the ally, another on the caster for Temple Guardian), mixed
(equally-weighted averaged) into one distribution, and `expected_hit` multiplies `hits_per_cast` by the index
count so the measured event total still has to clear all of them (ADR 0027). Chastise 503141 has a `school`
effect with a readable token (`$m1`) and a `WEAPON_PERCENT_DAMAGE`
effect gated by an unparsed `$?s` conditional with no token of its own; `hit_kind` resolves several candidate kinds to
one by keeping only the kinds that have an own token on one of their effects (`readout.values`), and raises `effects of
several hit models` as before when more than one kind still has one (or none does).

A periodic effect's token is a total when it grows with `$d` and shrinks with that effect's `$TN` in proportion
(design D15): `period_reading(records, spell_id, caster, shown, effect)` reads the token text alone, then again with
the rank's duration doubled, then with the effect's period doubled (`ScaledPeriod`), and returns `total` when the
value doubles, then halves, `tick` when it does not change, and `mixed` otherwise. The three reads share the same
context (the token alone), so a token whose value depends on the text after it (`$/1000;s1 sec` is ms only before
`sec`) is compared with itself. `periodic_tick_readout` divides a total into one
tick, `total x period / duration`: Blade of Faith 803880's `${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}` is ten ticks,
and its tick is the total x 3000 / 30000. A `mixed` token (`${($d*1000/$T1)+1}`) is `unmodelled`, and in the
no-combat scenario it is `unmeasurable` (`a total over the ticks of periodic effect <n>; the hit scenario judges one
tick`): `spell_effect_value` and `aura_amount` are one tick. A `total` token is not left unmeasurable: the
no-combat scenario (`value_scenario`) hands it back as a third return value, `periodic_totals`
(`[{'label': ..., 'effect': ...}]`, same label the `effect_value` expectation would otherwise have used), and
`add_periodic_total` (`conformance.py`) builds a companion `periodic_total` scenario for that rank from
`hit_parts(..., rank_id=<rank>, label=..., check='periodic_total')`: it casts the rank, waits its full tick
duration, and reuses the `hit_mean` non-crit per-tick mean (`spell_damage_total`/`_count` or
`spell_heal_total`/`_count`, `critical: False`) and its 99% interval. `judge_hit` scales `mean`, `expected_mean`
and the interval half-width by `model['hits_per_cast']` (the DBC tick count) for a `periodic_total` check only, so
the `ok`/`alert` boundary is exactly the one the per-tick comparison would have given (both sides of the interval
are multiplied by the same positive constant); only the reported numbers and wording ("total over N ticks" instead
of "mean") change. Only effects that tick are
read this way: an aura the server makes periodic (`AuraEffect::CalculatePeriodic`, `SpellAuraEffects.cpp:682-702`:
3, 8, 20, 21, 23, 24, 48, 53, 62, 64, 89, 162, 226, 227) with a positive `EffectAmplitude`. Rapid 680323 (aura 107,
amplitude 1500) keeps its `$/1000;s1` as an `effect_value` in ms.

`hits_per_cast` clearing the combined event count (above) proves a `heal` kind's events landed somewhere, but not on
whom: two heals both landing on the ally would still clear `minimum_hits` for Temple Guardian. A class file's
`dual_target_effects` list (`[{spell, primary_effect, secondary_effect, secondary_actor, reason}]`, ADR 0054) names a
rank whose tooltip claims two differently-targeted recipients for a `heal` kind; `hit_parts` then adds a second,
`target`-filtered `spell_heal_total`/`spell_heal_count` measurement (`critical: False`, same as the combined pair)
for `secondary_actor`, and a second `hit_mean` expectation at `secondary_effect` whose `minimum_hits` is `casts`
(one event per cast, not `hits_per_cast x casts`) since this measurement only ever sees one of the two events. The
combined, unfiltered expectation (`hit.indexes[0]`) and its `minimum_hits` are unchanged, so every other caller of
`hit_parts` is unaffected. `judge_hit` recomputes the expected mean from `expectation.rank_id` the same way for both
expectations (the model does not depend on which effect index asked for it), so the secondary expectation is judged
against the same formula value as the combined one, by the identity of the recipient instead of only the count.

A `triggered_weapon` effect reads the tokens of the described spell's tooltip that belong to the triggered spell, each
on the effect of its first `$<id>sN`/`$<id>mN`, and models them as a `weapon` hit of the triggered spell's effects,
with the same DBC effect order (`weapon_percent_before_flat` is not consulted for a triggered spell). The triggered
spell's school gives the mitigation and the modifiers, and its damage is
measured: `hit_spell` in the model (the rank itself for the other kinds) names the spell of `spell_damage_*`,
`critical_hits` and `blocked_hits`; `cast_count` stays the rank. Righteous Tempest 807274: aura 23 every 1000 ms for
5000 ms triggers 570205 (effects 121 and 31); its tooltip shows `$570205s2`% (100) Weapon Damage plus
`${$570205m1+$SP*0.3}` (154), five hits per cast. Known limits: the tokens of the triggered spell are not given the
total reading (a `${$<id>m1*$d/$t1}` there would be modelled as one tick, an alert); and `hits_per_cast` ignores the
extra tick on apply of `AttributesEx5 & 0x200` (`SPELL_ATTR5_EXTRA_INITIAL_PERIOD`): Righteous Tempest lands 6 hits
per cast, so it schedules more casts than needed, while the judged mean is unaffected.

A `school`, `leech` or `heal` effect whose `EffectDieSides` is above 1 and whose tooltip shows one token (Righteous Upheaval:
`${$m1+0+$AP*0.45+$SP*0.45}`, `EffectBasePoints` 658, `EffectDieSides` 224 at rank 572027) is read again with each
roll `EffectBasePoints + 1` .. `EffectBasePoints + EffectDieSides` in place of its points, as the comparison of rolled
effect values does: the server adds one `irand(1, EffectDieSides)` to the points of every direct hit
(`SpellEffectInfo::CalcValue`), so each roll is one equally likely hit and `tooltip_mean` is their mean. A periodic
effect whose amount rolls (one token or `$mN` to `$MN`) is `unmodelled`: `AuraEffect::CalculateAmount` rolls it once
when the aura is applied and every tick reuses it, so the ticks of a cast are not independent hits and an interval
over ticks would be too narrow. Such a spread
can need more casts than one scenario holds: the scheduled casts are split as evenly as possible into the fewest parts
whose casts fit `PART_BUDGET_MS` (532 s: the 600 s scenario limit less the 60 s margin, the 5 s settle and the 3 s
drain; design D16), each part a full scenario with the same measurement labels, named `... part <n> of <parts>` and
keyed `conformance-<class>-hit-<rank>-part-<n>`; a hit that fits one scenario keeps the key
`conformance-<class>-hit-<rank>`. Righteous Upheaval 572027 needs 335 casts, schedules 503 of 1.5 s, in 2 parts of 252
and 251; Reckoning 572741 needs 722, schedules 1083 of 1.75 s, in 4 parts of 271, 271, 271 and 270. A single cast
longer than the budget is `unmodelled`.

The weapon roll is `urand(floor(min + AP / 14 x speed), floor(max + AP / 14 x speed))` (`Unit::CalculateDamage`),
with the normalized speed when an effect is 121 and the weapon speed otherwise. `tooltip_mean` is the same sum without
integer steps: for Argent Blade 807268, 2.15 x ((min + max) / 2 + AP / 14 x 3.3) + (421 + 0.4725 x AP).
Each server integer step is then applied to every possible hit, never as a tolerance:

1. a known aura's modifier, `floor(hit x (100 + percent) / 100)` (`Unit::SpellDamageBonusDone`,
   `Unit::MeleeDamageBonusDone`, `Unit::SpellHealingBonusDone`): aura 341 for damage of its `EffectMiscValue`
   schools, aura 136 for healing, with the amount `SpellEffectInfo::CalcValue` gives at the class level (887007:
   -1 + int(50 x -0.4) + 1 = -20). Only the known auras whose `known_aura` measurement is 1 count, and the model lists
   them (`Modifier`) by spell and effect;
2. armor, `ceil(hit x kept)` (`Unit::CalcArmorReducedDamage`), or each partial-resist step `i` with its share,
   `hit - floor(hit x i / 10)` (`Unit::CalcAbsorbResist`), from `expected_mitigation` and its `resist_shares`.

`mean` and `sigma` are the mean and standard deviation of the resulting distribution; the comparison judges the
measured mean against `mean`, and `tooltip_mean` is shown beside it. `casts_needed(model)` is the Global Constraints
rule: `ceil((2.576 x sigma / (0.01 x mean))^2)` hits, at least one, divided by `hits_per_cast`.

The `hit_mean` expectation carries `model`: the kind, school mask, weapon, modifiers, reference mean, sigma and casts,
`minimum_hits` (the needed casts times `hits_per_cast`: fewer usable hits are insufficient trials), `scheduled_casts`,
`part` (from 0), `parts` and `part_casts` (the casts of this part; every part repeats the totals above),
and the labels of its measurements: `<label> total` and `<label> count` (`spell_damage_*` on `dummy` with
`critical: false` and `blocked: false`, or `spell_heal_*` on the caster with `critical: false`), `target armor`,
`target view_level` and `target resistance <school>`.
`measured_hit_model(class_file, expectation, measured)` recomputes the model from a run's labelled values (caster
stats, known auras, armor, view level and resistances), since creature 36 spawns with armor 528 or 562. Two
diagnostics ride along: `<rank> critical_hits`, `<rank> blocked_hits` (damage only) and `<rank> cast_count`.

`melee_scenario(class_file, swings)` attacks `dummy` for `ceil(swings x 1.5)` weapon swings and measures the plain
main-hand hits (`melee_damage_total` and `melee_damage_count` with `critical`, `glancing` and `blocked` false) under
`melee melee_mean`, beside the swing, critical, glancing and blocked counts; `minimum_hits` is `swings`. Its model is
the weapon roll at weapon speed with the same modifier and armor steps.

A spell that fits no model is never dropped: its expectation has `check` `unmodelled` and a `rule` that starts with
`unmodelled: ` (a passive spell, no damage or healing effect, effects of several models, an effect without a readable
tooltip value, a periodic duration that is unreadable). Its scenario learns the rank and has no hit measurement. The
parts of the tooltip the reader could not evaluate become `hit_mean` expectations whose rule starts with
`unreadable: `, without a measurement. Not modelled: talent or proc modifiers, critical strikes, spell power
coefficients the tooltip does not show, and costs that are a percentage of base mana (no `set_power`).

A class file's `hit_notes` list (`[{"spell": <id>, "reason": "..."}]`, matched against the spell's own id or its
`max_rank`, same shape as `effect_notes` above) substitutes a specific explanation for `hit_parts`'s own generic
`unmodelled: ` reason, applied only when `rank_hit` already raised `Unmodelled` (it never turns a modelled hit
unmodelled, or the reverse: `hit_kind` still runs first and a spell whose effects do fit a model never consults
`hit_notes`). This documents, per spell, why its active has no `hit_mean` of its own — most often because every one
of its effects is a buff/debuff/utility aura, never a damage or heal effect `hit_kind` recognizes, so the
tooltip's real numbers are already measured and judged by that spell's own `effect_value`/`aura_amount`/
`aura_duration_ms`/`power_cost`/`cooldown_ms` verdicts instead. A reason beginning `no check needed: ` moves the
status to `closed` (same `CLOSED`/ADR 0037 mechanism `effect_notes` uses, checked in `hit_parts` before falling
back to `unmodelled`): this active's `hit_mean` gap is settled by that already-judged evidence, not left as open
work, so `coverage.md`/`report.md`/`summary.md`'s status tables and `alerts.tsv` count it apart from the
genuinely missing checks. Any other `hit_notes` reason keeps the `unmodelled` status and only replaces the
explanation text. Templar (round5 `aura-only-actives` investigation, 2026-11): 32 of the 35 Templar actives whose
own effects are all buffs/debuffs/utility are closed this way, each citing the concrete effects and the round4
value-scenario verdicts that already cover them; a `closed` reason may itself name a different, genuinely more
functional check (dispel-success, taunt-success, mechanic-immunity, mounted/ground `run_speed_rate`) as deferred,
new-check-kind work out of this item's scope rather than an invented one — the `hit_mean` gap is still closed
because it has no claim of its own left unaccounted for, but the deferred check stays unbuilt and belongs to the
free-text reason until a future item builds it. 3 of the 35 (300514 Testament of Strength, 500678 Testament of
Fortitude, 500694 Force of Golganneth) found no existing evidence to cite and stay `unmodelled`.

## Self-stacking ranks (`self_stack_bonus`, ADR 0049)

`hit_parts`'s repeated casts (`casts_needed`/`scheduled_casts`) assume every cast is an independent, identically
distributed sample of the same hit — true for a plain weapon/school/heal hit, false for a rank whose own tooltip
documents a bonus that stacks on the caster from a *previous* cast of the same ability (a self-buffing active). A
class file's `self_stack_bonus` list (`[{"rank": <id>, "percent_per_stack": <float>}]`) names such a rank: `rank_hit`
still models a single, unstacked hit (the `displayed` tokens and `tooltip_mean` stay unstacked), but `hit_parts`
(generate time) and `measured_hit_model` (compare time, used by `judge_hit` through `HitModelSource`) both scale
that hit's mean by `1 + percent_per_stack/100 x (performed - 1)/2` for a part performing `performed` casts — the
average multiplier over stacks `0, 1, ..., performed - 1`, since the buff is granted *after* each cast and each
scenario part starts a fresh character (no stacks carry in). This is additive and class-agnostic: a class file that
omits `self_stack_bonus` gets multiplier 1.0 (today's unstacked behaviour) for every rank.

