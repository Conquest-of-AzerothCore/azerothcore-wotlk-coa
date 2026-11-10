# Behaviour scenarios

A `behaviours` entry of the class file is a passive whose tooltip states a behaviour in **prose**, with no `$`
token: "2 additional enemies," "an additional copy," "doubles the healing," "always triggers," "refreshes the
duration." Phase 2's design explicitly parked these as a non-goal of the token method (ADR 0011). This section
crosses that line on purpose, for a bounded, named list of spells, and never becomes a general prose parser.

The expected value is still DBC-derived: it is the literal number or count written in `Description[enUS]`, quoted
verbatim in the scenario's `rule`, never invented or rounded to "look right." Every `Expectation` built from a
`behaviours` entry uses a check name distinct from `effect_value`/`aura_amount`/`passive_delta`, so a reader of
`verdicts.json` can always tell a prose-sourced result from a token-sourced one, even though both ultimately
produce the same status vocabulary (`ok`, `alert`, `unmodelled`, `measured`, `ambiguous_tooltip`,
`insufficient_trials`, `unmeasured`; no new status is invented):

| Check | Claim |
|---|---|
| `behaviour_count` | a count ("N additional targets," "an additional copy" = +1, summon counts) |
| `behaviour_ratio` | a ratio ("doubles the healing" = x2, "twice the damage" = x2) |
| `behaviour_duration` | a duration refresh or reduction |
| `behaviour_duration_ratio` | a duration reduction on a mechanic the engine's own generic `SPELL_AURA_MECHANIC_DURATION_MOD` consumer applies, read off a named vehicle spell cast at the caster rather than off a forced crit |
| `behaviour_trigger` | a scripted "always fires" claim not reachable through `triggers.py`'s native `EffectTriggerSpell` path |
| `behaviour_metric_delta` | a passive whose change is read through a harness metric already used elsewhere in the scenario (`owned_creature_count`, `aura_amount`, `power`, ...) around a named active spell, judged by exact equality rather than a tolerance band |
| `behaviour_duration_refresh` | a passive that resets a named aura's remaining duration back to (near) its own DBC maximum when a named breaker spell is cast at a gating condition, with the same with/without-the-passive check every other `behaviours` kind applies |
| `behaviour_ratio` (`kind: "health_ratio"`) | a ratio conditional on the caster's own health, read at several health percentages in one scenario |
| `behaviour_crit_guarantee` (`kind: "crit_guarantee"`) | "this is guaranteed to critically strike against" a named creature type: every triggered hit of a named spell logged against an in-type creature fixture must be critical |
| `behaviour_aura_grant` (`kind: "aura_grant"`) | "and granting an Oath"-shaped claims: a single cast of a named ability must grant a named aura and increase a named stacking aura's `aura_stacks` by exactly 1, judged by exact equality (no tolerated band: an integer stack delta has no near-miss) |
| `behaviour_oath_consumption` (`kind: "oath_consumption"`) | "Consumes your Oaths, dealing additional damage/healing for each consumed"-shaped claims: a deterministic damage/healing formula metric is read before and after fixturing one Oath aura to the caster (no cast), then the trigger spell is actually cast once and the Oath's own `aura_stacks` is read afterward (must be 0, consumed) |
| `behaviour_oath_consumption_removal` (`kind: "oath_consumption_removal"`) | "Consumes your Oaths, dealing additional damage for each consumed"-shaped claims whose own ability bakes the bonus into its own aura's script value at cast time and consumes the Oaths only when that aura is later removed: one or more Oath auras are fixtured, each one's own `aura_amount` is read, the trigger spell is cast once, its own aura's `aura_script_value` is read shortly after (must equal the summed `aura_amount` readings) while every Oath's `aura_stacks` must still read 1, then after the aura expires naturally every Oath's `aura_stacks` must read 0 |
| `behaviour_charge_recharge` | a native spell-charge count ("N Charges") and its recharge interval ("T sec recharge"), proven by spending every charge one cast at a time, confirming an over-cast attempt is refused, and bracketing the recharge window at a tolerance |
| `behaviour_cast_gate` | a cast-attempt gate on the target's own `TargetAuraState`, and an optional bypass of that gate by a second, named spell's own ability-ignore-aurastate effect |

Every `Expectation.rule` of these checks starts with the literal prefix `prose: ` followed by the quoted
`Description[enUS]` fragment that states the number, e.g.
`prose: "strikes 2 additional enemies near the primary target" (525024)`. This is the one thing that must never be
skipped: it is what keeps a behaviour `ok` honestly distinguishable from a token `ok` if anyone audits later.

| Field | Content |
|---|---|
| `spell`, `name` | the passive and its `SpellName[enUS]` |
| `kind` | `count`, `ratio`, `duration`, `duration_ratio`, `duration_refresh`, `trigger`, `spread`, `metric_delta`, `health_ratio`, `crit_guarantee`, `aura_grant`, `oath_consumption` `oath_consumption_removal` or `cast_gate`: which scenario builder and judge rule apply |
| `quote` | the exact prose fragment of `Description[enUS]`, checked to be a substring at generation time |
| `expected` | the number, ratio or duration the quote states (not used by `health_ratio`, which states its ratios in `levels` instead, one per health percentage, or by `duration`, which states its milliseconds in `expected_ms` instead) |
| `variant` | optional; disambiguates the generated manifest key (`conformance.add_behaviour`) when a class legitimately needs more than one `behaviours` entry on the same `spell` id, e.g. a tooltip that makes two independently checkable claims about the same passive (magnitude, then an interaction with another buff). Defaults to `''`, which reproduces the pre-`variant` key exactly, so every existing entry is unaffected. |
| kind-specific fields | `count`: `target_rank` (the active spell cast), `radius` and `radius_reason` (the source citation that grounds the fixture placement, never a guessed distance), `metric` (`spell_damage_count`, the default, for a spell with a school-damage effect, or `aura` for a spell whose own effect is not damage, such as a silence); `ratio`: `targets`, a list of `[rank_id, name]` pairs; `spread`: `seed_spell` (cast on the primary dummy to install the aura the passive must copy), `aura_spell` (the aura id measured on every extra dummy), `target_rank` (the active whose damage triggers the copy), `radius`/`radius_reason`; `trigger`: `shield_aura` (the absorb aura that must be fully consumed), `trigger_spell` (the spell the break casts), `breaker_spell` (a spell of the absorb's own school that the striker casts directly at the caster to deplete it deterministically), `striker_entry` (a creature template entry to cast it from), `break_timeout_ms` (how long to wait for the aura to clear once the breaker spell lands, default 3000); `metric_delta`: `trigger_spell` (the active spell cast to create the measurable state, learned once up front since it is not otherwise granted to the reference character), `metric`/`fields` (the harness metric and its query fields, e.g. `owned_creature_count`/`{"entry": ...}`, `aura_amount`/`{"spell": ..., "effect": ...}` or `power`/`{"power": <type>}`), `before_expected` (the DBC-derived baseline value asserted on the "before" measurement), `wait_ms` (settle time after the cast before measuring, default 3000), `expire_ms` (wait after the learn before the second cast, long enough for the first cast's effect to fully expire so it cannot contaminate the second measurement, default 20500), `target` (`"caster"`, the default, or `"dummy"` for a trigger spell that needs a hostile target, such as a periodic-damage spell; adds the stock creature fixture only when set to `"dummy"`), `disable_regeneration` (default `false`; `true` sets `allow_regeneration: false` on the player fixture, for a `power` metric whose resource type regenerates on its own — a resource pool's passive regen (confirmed empirically: Energy regenerated ~10/sec of real time during the cast-and-wait window, contaminating both the "before" and "after" absolute reads by the same roughly-equal amount, even though it cancels out of the delta) would otherwise make the check's required exact-equality baseline nondeterministic, since the exact regen gained during a fixed wait is itself a live-timing read, not a DBC-derived constant); `setup_casts` (default `()`, an empty tuple reproduces every existing entry's generated scenario byte-for-byte): spell ids cast at `target` immediately before each timed `trigger_spell` cast, in both phases, each preceded by its own power/cooldown/`required_aura_steps` fixtures exactly as `trigger_spell` itself gets them, with `trigger_spell`'s own power re-asserted afterwards so a setup cast's cost never starves the timed cast that follows it — for a passive whose condition needs a second, independent spell's effect already present on the target when `trigger_spell` is cast (Transcending Strikes 804897 needs the caster's own Blade of Faith 803872 on the target before Divine Force 806153 is cast); setup_only_after` (default `false`, omitting it reproduces every existing entry's generated scenario byte-for-byte): when `true`, the gate spell (`gate_spell` or `spell`) is learned once at the very start instead of between phases, and `setup_casts` are cast only in the "after" phase, never the "before" one — for a clause whose trigger spell's effect is gated on a *second*, independent condition (a target's own debuff) rather than on the passive itself, so the passive must stay known throughout while the other condition is the one phase-dependent variable (Transcending Strikes 804897's "target_gate" variant: 804897 known in both phases, Blade of Faith 803872 withheld from the dummy in the first phase and cast on it in the second, isolating the clause's "when used on enemies affected by Blade of Faith" half from the already-proven "while 804897 is known" half); requires a non-empty `setup_casts` (ADR 0058); `setup_actor_aura` (default `None`, omitting it reproduces every existing entry's generated scenario byte-for-byte): a spell id applied to the caster with the existing `set_aura` action (1 stack) at the very start of each `cast_steps()` call, in both the "before" and "after" phase, for a passive whose tooltip claims an interaction with a second, independently-learnable buff that must already be present when `trigger_spell` is cast and stay present through the wait (Whirling Tempest 300504's "stacks with Courage" clause needs Courage 707754 active in both phases so the delta reflects the two auras together, not 300504 alone); `gate_spell` (default `None`, omitting it reproduces every existing entry's generated scenario byte-for-byte): learned between the "before" and "after" cast in place of `spell`, for a passive that is never itself learnable because the server only ever casts it internally on another aura's apply hook, so the real known/unknown toggle belongs to a different, parent spell (Whirling Tempest 301340's own slow immunity is gated on `player->HasAura(300504)`, the parent passive, not on 301340 itself being learned); `duration_refresh`: `target_aura` (the aura whose `aura_duration_ms` is read before and after the breaker cast), `gating_aura`/`gating_stacks` (the stack-gated aura and the stack count the breaker's own code checks, held fixed in both phases since the passive's presence is the axis under test here, not the stack threshold), `apply_spell` (cast at the creature fixture to apply `target_aura`), `breaker_spell` (cast afterwards; refreshes `target_aura` only when the passive is known and `gating_aura` has at least `gating_stacks`), `decay_ms` (wait between the apply and the breaker cast, default 4000), `refresh_margin_ms` (how close to the DBC's own full duration the "with" phase's refreshed reading must land, default 500); `health_ratio`: `probe_spell` (a magic-school spell not exempted from damage-taken modifiers, fed to `script_spell_damage_taken` as a stand-in hit), `levels` (a list of `[health_pct, expected_ratio]` pairs, one `Expectation` per pair); `duration`: `target_aura` (the aura whose `aura_duration_ms` is read before and after one forced melee crit), `expected_ms` (the milliseconds the quote states, added on top of the one swing interval that elapses naturally), `debt_aura` (the real absorb aura that must carry a nonzero debt amount before the crit, so the forcing fixture exercises the real damage-absorb hook instead of a bare `set_aura`), `breaker_spell`/`striker_entry` (the spell and creature template entry that deplete `debt_aura` deterministically before the measured crit), `mechanism_file`/`override_file`/`reduce_function` (free text naming the server source file that resets the duration, the file that overrides the aura's periodic base points, and the function whose early-removal branch the debt fixture must avoid triggering for the wrong reason — generated into the scenario's own `contract` field, so each class supplies its own instead of the builder hardcoding one class's names); `duration_ratio`: `vehicle_spell` (a stock, non-class spell whose own mechanic the passive's `SPELL_AURA_MECHANIC_DURATION_MOD` effect targets, cast by a striker at the caster once before and once after the passive is learned), `striker_entry` (a creature template entry, default 36); `crit_guarantee`: `trial_spell` (the spell whose landed hits are measured), `target_entry` (a `creature_template` entry of the claimed type, overriding the shared dummy), `target_type`/`target_type_name` (the `creature_template.type` value and its name, both documentation only — never read back by the code, so a mismatch cannot silently pass), `attempts` (auto-attack swings, default 100), `minimum_events` (default 5; fewer triggered hits of `trial_spell` than this reports `insufficient_trials` instead of judging a ratio); `aura_grant`: `trigger_spell` (the ability cast once), `oath_aura` (the specific aura it must apply, read via the `aura` metric after the cast), `chain_aura` (the stacking aura whose `aura_stacks` is read before and after the cast, default 704576, the Templar's Oath Chain); `oath_consumption`: `trigger_spell` (the Breaker ability cast once to prove consumption), `oath_spell` (the Oath aura fixtured to 1 stack with `set_aura`, no cast, between the "before" and "after" formula reads), `relation` (`"ratio"`, for a `SPELLMOD_PCT` modifier, multiplying the "before" reading, or `"flat"`, for a `SPELLMOD_FLAT` one, added to it), `expected` (the ratio or flat delta the Oath's own registered `Player::m_spellMods` entry/entries produce — ground-truthed with the harness's own `spell_modifier` metric, base 1000, against the live op, never hand-derived from raw `Spell.dbc` `EffectBasePoints`, since `SpellEffectInfo::CalcValue`'s `DieSides == 1` roll adds +1, not +0), `metric` (`"spell_damage_done"` or `"spell_healing_done"`), `effect` (the formula's own effect index, default 0), `periodic` (default `false`; `true` reads the formula's `DOT`/`SPELLMOD_DOT` path instead of the direct-damage/`SPELLMOD_DAMAGE` one, for a spell whose own effect is `SPELL_AURA_PERIODIC_DAMAGE`), `target` (default `"dummy"`; `"caster"` for a self-targeted heal); `oath_consumption_removal`: `trigger_spell` (the ability cast once, whose own aura both bakes the bonus and later removes the Oaths), `oath_spells` (a list of Oath aura ids fixtured to 1 stack each with `set_aura`, no cast, before the trigger is cast; more than one proves "for each consumed" sums across different Oath types rather than special-casing a single id), `oath_effect` (the Oath's own `AuraEffect` index summed by the trigger's script, default 2), `settle_ms` (wait after the cast before reading the trigger's own `aura_script_value` and the Oaths' `aura_stacks`, default 500, kept well inside the trigger's own DBC duration), `expire_margin_ms` (added on top of the trigger's own remaining duration before the final `aura_stacks` read, so the wait reliably outlasts natural expiry, default 1500); `cast_gate`: `bypass_spell`/`bypass_name`/`bypass_quote` (a second spell cast on the caster between the "blocked" and "allowed" attempts, whose own tooltip clause is proven by a third attempt made with it active and the target fixture untouched) |

`behaviours.py`'s `behaviour_scenario(class_file, entry)` dispatches on `kind` to a scenario builder shaped like
`passives.passive_scenario` (base steps, measure "before," `learn`, measure "after"), with a kind-specific measure
step instead of a stat-sheet read. `conformance.py generate --behaviour <spell>` selects one or more entries by
spell id; with no filter, every class behaviour entry is generated.

### Target-count scenarios (`behaviour_count`)

The scenario places `expected + 1` creature fixtures (one "primary," `expected` "extra") along the caster's fixed
spawn axis, the primary at 3 yards and the extras spread within `radius` yards of the primary (the harness places
every creature fixture at `owner position + (distance, 0, 0)`, `CoAGameplayTest.cpp` `CreateTargets`, so creatures
at different `distance` values share the same line). It learns `target_rank` once up front, before the first
cast (matching the pattern `hits.py` and `values.py` already use for their own cast targets, since the reference
character is created directly at level 60 and a cast of an unlearned spell is silently dropped by
`HandleCastSpellOpcode` rather than failing loudly), then casts it at the primary `repeats`
times (5, "ever hit at least once" per dummy rather than a single-cast snapshot, since neither this package nor a
probe established that the harness's AoE or chain targeting hits every dummy in range on one cast), measures
`spell_damage_count {spell, target}` per dummy (or, for an entry whose `metric` is `aura`, `aura {spell, caster}`
read on the dummy itself, for a target spell whose own effect is not a school-damage hit), learns the passive,
repeats the casts and the measurement. The
judge (`compare.behaviour_count_verdict`) counts, among the extra dummies only, how many were hit before the learn
and how many were newly hit after (`after - before > 0`), then judges that count delta against `expected` on the
delta scale (`compare.delta_status`): `ok` when `|delta - expected| <= max(1, 0.5% of expected)`, *except* that a
measured delta of exactly 0 against a nonzero `expected` is always `alert`, never `ok`, even though it would fall
inside that margin (`compare.delta_status`'s explicit zero-vs-nonzero guard); `unmeasured` when an extra dummy was
already hit before the learn, since the delta cannot then be isolated.

### Healing-ratio scenarios (`behaviour_ratio`)

Each `targets` entry is either a 2-element `[rank_id, name]` (method `"cast"`, the default) or a 3-element
`[rank_id, name, {"method": "effect_value" | "taken", ...}]`. A `"cast"` target is cast at the caster, then measured
with `spell_healing_done {spell, target: caster}`, for each phase: `spell_healing_done` calls
`Unit::SpellHealingBonusDone`, the *caster*-side healing-bonus multiplier (`SpellPctHealingModsDone` and the
caster's own fixed-bonus auras), so this method only sees a passive that augments the healer's own output. An
`"effect_value"` target is never cast at all — it is measured directly with `spell_effect_value {spell, effect}`
before and after the passive is learned, for a doubling that is fully determined by the target spell's own
`SpellEffectInfo::CalcValue` (a `SPELLMOD_EFFECT1`-style percent modifier applied while computing the effect's
amount) rather than by anything that shows up only once the spell is cast and ticks. A `"taken"` target is cast at
the caster like `"cast"`, but measured with `spell_healing_taken {spell, target: caster}`, which calls
`Unit::SpellHealingBonusTaken` on the target instead: the *target*-side multiplier (`SPELL_AURA_MOD_HEALING_RECEIVED`
and the other taken-side healing auras) that `spell_healing_done` cannot see, because `SpellHealingBonusDone` never
reads a taken-side aura of the healed unit. All three methods feed the same `Expectation` shape
(`before_label`/`after_label`/`expected`/`quote`/`target_name`), so the judge below needs no per-method branch. The
judge (`compare.behaviour_ratio_verdict`)
computes `ratio = after / before` for reporting, but judges the *delta* (`after - before`) against the delta the
expected ratio implies (`before * (expected_ratio - 1)`), on the metric's own scale rather than the ratio scale:
`ok` when `|delta - expected_delta| <= max(1, 0.5% of |expected_delta|)`, with the same zero-vs-nonzero guard as
`behaviour_count` (a measured delta of exactly 0 against a nonzero expected delta is always `alert`); `unmeasured`
when the before measurement is 0 or less, since a ratio needs a positive baseline.

### Aura-spread scenarios (`behaviour_count`, `kind: "spread"`)

`target_count_scenario`'s `aura` metric always reads the *cast* spell's own aura, which does not fit a passive
whose claim is that a different active's damage copies a *pre-existing, independent* aura onto a nearby target
(Holy Tempest 301339: Righteous Tempest's damage spreads Condemn, not Righteous Tempest's own aura). `behaviours.py`
adds a second, additive builder for this shape rather than overloading `TargetCountSpec`'s contract: `AuraSpreadSpec`
names `seed_spell` (cast on the primary dummy before each `target_rank` cast, to install the aura that must spread),
`aura_spell` (the aura id measured on every extra dummy; usually the same spell as `seed_spell`) and `target_rank`
(the active whose damage triggers the copy) separately. `aura_spread_scenario` learns both `seed_spell` and
`target_rank` once (talent-chain ranks this deep are not granted by the reference character automatically, unlike
some lower active ranks reused by other `behaviours` entries), then per phase and per repeat: casts `seed_spell` at
the primary dummy, waits past its cast time, waits one explicit global-cooldown interval, casts `target_rank` (no
explicit target: its own implicit targeting is "nearby enemies"), and waits its full periodic-buff duration
(`Records.duration_ms(target_rank)`) before the next repeat. It then measures `aura {aura_spell, caster}` on every
extra dummy only, never re-measuring the primary (its own copy of `seed_spell`'s aura is a setup fact, not part of
the behaviour under judgment). The resulting `Expectation` is shaped exactly like `target_count_scenario`'s, so
`compare.behaviour_count_verdict` judges it with no change: `ok` when every extra dummy gains the aura between the
before and after phase, `alert` on a measured 0 against a nonzero `expected` (the absent-effect case this check
exists to catch), `unmeasured` when an extra dummy already carries the aura before the passive is learned.

### Shield-break trigger scenarios (`behaviour_trigger`)

This is the first `behaviour_trigger` entry: a tooltip claim that is a scripted "always fires" cast, reachable
only from an `AfterEffectRemove`-style hook, not from `triggers.py`'s native `EffectTriggerSpell` path (that path
only recognises a cast or a swing the caster performs, `triggers.py:47-53`; here the triggering action is damage
*taken*, consumed by an absorb shield). `ShieldBreakTriggerSpec` names `shield_aura` (the absorb aura that must be
fully depleted), `trigger_spell` (the spell the break casts), `breaker_spell` (a spell of the absorb's own school,
cast directly by the striker at the caster, that reliably exceeds the absorb amount), `striker_entry` (a creature
template entry to cast it from) and `break_timeout_ms` (how long to wait for the aura to clear once the breaker
spell lands). `shield_aura`'s own `SchoolMask` decides what `breaker_spell` must be: a generic hostile creature's
melee is Physical and a `SPELL_AURA_SCHOOL_ABSORB` only intercepts its own school (confirmed empirically for
Staffguard 706583, Holy-only: a melee-only striker left its 8-second duration to expire untouched every time,
`without`/`with` elapsed consistently ~7980 ms regardless of real melee damage landing on the caster, never from
an `AURA_REMOVE_BY_ENEMY_SPELL` absorption), so a melee swing can never satisfy this check and a Holy nuke
(Smite 48123 here) must be cast directly at the caster instead. `shield_break_trigger_scenario` spawns one
"striker" fixture, then runs two phases, once without the passive known and once with it: apply `shield_aura`
fresh (`set_aura`), measure `spell_damage_count {trigger_spell, target: striker}` on the caster, have the striker
`cast` `breaker_spell` directly at the caster (the harness's own creature-cast action, bypassing AI pathing and
its timing variance entirely), wait `CAST_SETTLE_MS` (500 ms: the aura-removal callback was observed to still be
mid-flight on the very next assert without this wait, intermittently failing `the shield is fully consumed` even
though the cast had already landed), then assert `shield_aura` is fully gone (`metric: "aura", equals: 0`) within
`break_timeout_ms` (real incoming damage consuming the shield, not an expiry or a manual cancel), and measure
`spell_damage_count` again. The passive is `learn`ed between the two phases. The judge
(`compare.behaviour_trigger_verdict`) computes `without_delta` and `with_delta` (the after-minus-before
`spell_damage_count` of each phase): `ok` only when `without_delta == 0` (the damage never fires without the
passive known) **and** `with_delta >= expected` (it fires at least once, the one time the shield broke, with the
passive known); `alert` when `without_delta > 0` (the damage fires even without the passive, contradicting the
tooltip's gating) **or** `with_delta == 0` (the passive is known but the break never casts the trigger spell -
the absent-effect case this check exists to catch, since a zero effect must never read as `ok`).

### Metric-delta scenarios (`behaviour_metric_delta`)

Some prose passives change a quantity none of the shapes above fit: not a count of targets hit, not a healing
ratio, not a scripted "always fires" trigger, but a plain before/after read of a metric the harness already
exposes for other purposes (how many of a summon creature entry the caster owns, the computed amount of an
aura effect, ...). `metric_delta_scenario` learns `trigger_spell` once up front (the active spell a reference
character this deep in a talent chain is not otherwise granted, the same reason `aura_spread_scenario` learns
its own actives explicitly), casts it, waits `wait_ms`, measures `metric` with `fields` ("before"), `learn`s
the passive, waits `expire_ms` (long enough for the first cast's effect to fully expire, so a still-alive
summon or a still-ticking aura from the "before" phase cannot leak into the "after" reading), casts
`trigger_spell` again and measures again ("after"). The judge (`compare.behaviour_metric_delta_verdict`) checks
both reads by exact equality, not the shared tolerance-margin scale the other behaviour judges use: `ok` only
when `before == before_expected` **and** `after == expected`; `alert` otherwise, including when `before` alone
is wrong (an implementation that gets the delta right from a wrong baseline is still caught) and when `after`
is off by as little as one unit, since the shared margin's floor of 1 absolute unit would otherwise mask the
exact failure this check exists to catch (a modifier of +1 silently not applying). Exact equality is sound here
specifically because both metrics are deterministic integer reads taken with no combat in flight, unlike the
live combat-roll pipeline behind `melee_damage_taken`/`spell_damage_taken`, which does need a tolerance band.
"Exact" means within `compare.METRIC_DELTA_FLOAT_TOLERANCE` (1e-5), not `compare.FLOAT_EPSILON` (1e-9): every
`metric_delta` entry before round4's Whirling Tempest checks had an integer-valued `expected`/`before_expected`
(creature counts, aura amounts, power), for which the two tolerances behave identically. **Maintenance follow-up
(round4 `trigger-lot-r4-6` review)**: a `cooldown_ms` metric read some fixed time after a cast (Transcending
Strikes 804897) bakes the harness's own per-step simulated-clock overhead into the literal
`before_expected`/`expected` constants (e.g. 116994/112994, a 120000 ms base minus a 6 ms processing delta neither
entry derives from the DBC), because `behaviour_metric_delta_verdict` compares absolute readings, not their delta;
any future change to that overhead, unrelated to 804897's own mechanism, would turn this entry `alert` with no real
regression behind it. A `metric_delta` variant judged on `(after - before)` rather than on the two absolute values
would remove this fragility for any future wait-based metric and is a reasonable addition to `compare.py`'s judge
family; not built this round, since no existing entry needed it before 804897. `run_speed_rate`
(`Unit::GetSpeedRate`, a float32 ratio of percent-based aura modifiers) is the first non-integer metric this
kind measures, and it round-trips through the wire as e.g. `1.3200000524520874` for an exact `1.32f` on the
server — a ~5e-8 IEEE-754 single-precision artifact, not a defect. 1e-5 absorbs that noise while staying four
orders of magnitude tighter than the smallest defect this family of checks is meant to catch (a non-stacking
regression reads ~0.12 off, not ~1e-7).

### Health-threshold ratio scenarios (`behaviour_ratio`, `kind: "health_ratio"`)

Some passives state a ratio that only applies while the caster's own health sits above or below a threshold
("while above 80% health or below 20% health, ..."), a condition `healing_ratio_scenario`'s single before/after
pair cannot exercise, since it never varies the caster's health and a passive that always applied the ratio
would pass it just as well as one that gates it correctly. `health_threshold_ratio_scenario` instead sets the
caster's health with `set_health` (`actor` the caster, `maximum` fixed at 10000 so each `levels` percentage maps
to a round `value`) to each `levels` percentage in turn and measures `script_spell_damage_taken {spell:
probe_spell, target}` on the `dummy` fixture right after, once per level before the passive is learned and once
per level after. `script_spell_damage_taken` calls `ScriptMgr::ModifySpellDamageTaken` directly on a fixed probe
amount (1000), the same `UnitScript` hook a real hit of `probe_spell` would invoke, without needing a live caster
to actually land one. One `Expectation` per `levels` pair reuses `compare.behaviour_ratio_verdict` unmodified
(`before_label`/`after_label` naming that level's before/after measurement, `target_name` the health percentage):
`ok` when the measured damage delta matches `before * (expected_ratio - 1)` on the damage scale; `alert` on a
measured ratio of 1.0 (no change) against a `levels` entry whose `expected_ratio` is not 1.0 - the absent-effect
case this check exists to catch, since nulling the gate's health check or its aura check both collapse to this.
A `levels` entry with `expected_ratio` of exactly `1.0` (the mid-health case where neither threshold applies) is
what proves the gate itself is being tested, not just the reduction: a scenario that only measured the reduced
levels could not tell "the ratio is right" apart from "the ratio applies unconditionally."

### Leech-ratio scenarios (`behaviour_ratio`, `kind: "leech_ratio"`)

`healing_ratio_scenario`'s no-combat probe (`spell_healing_done`) never reaches `SpellEffectInfo::CalcValueMultiplier`,
the pipeline a `SPELLMOD_VALUE_MULTIPLIER` passive modifies, and its cast always targets the caster, which a hostile,
health-gated rank (Titanstrike) would refuse outright. `leech_ratio_scenario` instead casts the rank for real, once
before the passive is learned and once after, each at its own dummy (`set_health_pct` cannot raise health back up,
so the same dummy could not take a second cast once the fixture or the first cast's leech has already lowered it),
and measures the real `spell_damage_total` and `spell_heal_total` (`HealBySpell` always heals the caster, regardless
of the cast's target) of that one cast. Both effects of a `SPELL_EFFECT_HEALTH_LEECH` spell share the same random
roll (the heal is computed from the resolved, already-mitigated `damageInfo.damage`), so their ratio is exactly
deterministic once two measurement effects specific to this metric are accounted for:

- `spell_heal_total` sums every matching heal event since the scenario started, not since the last measurement, so
  the "after" phase's reading also carries the "before" phase's heal (the two casts heal the same caster with the
  same spell id). `leech_ratio_verdict` (`compare.py`) subtracts a `heal_baseline_label` (the "before" phase's own
  heal label; `null` for the "before" phase itself, which is naturally the first heal of the scenario) before
  computing the ratio.
- `Spell.cpp`'s health-leech handling computes the heal from `damageInfo.damage`, which already carries the
  reference character's own damage-done percent modifiers (`known_auras`, aura 341), then applies the healing-done
  percent modifiers of the same auras again on top (aura 136, through `SpellHealingBonusDone`/`Taken`) before
  calling `HealBySpell`. The two percents do not cancel against the recorded damage total, so the ratio the scenario
  can actually measure is `healMultiplier x heal_done_factor`, not `healMultiplier` alone.
  `leech_heal_modifier_factor` folds every known `heal`-side `Modifier` (`hits.aura_modifiers`) into the spec's
  `expected_before`/`expected_after` at scenario-build time, the same way `rank_hit` folds known auras into a
  `hit_mean` model, so the expected value stays DBC-plus-known-modifier derived, never invented.

`leech_ratio_verdict` reuses `behaviour_ratio_verdict`'s delta-on-the-damage-scale judging (`compare.py`):
`ok` when `|actual_heal - damage| <= max(1, 0.5% of damage x (expected - 1))`, `alert` otherwise, including a
measured 0 against a nonzero expected delta. Templar: Titanfall 300607 against Titanstrike 806835, expected 1.0
(no Titanfall) and 2.0 ("twice the damage dealt") before the known-modifier factor.

### Duration scenarios (`behaviour_duration`)

Some prose passives state a flat change to another aura's remaining duration ("removes 1 sec from the duration
of X"), gated on a condition — here, a critical strike — that neither `behaviour_count`/`behaviour_ratio`'s
no-combat before/after casts nor any existing `run.py` action can force directly: there is no "guarantee the next
swing crits" action or metric. `duration_scenario` forces the condition instead of adding one: it overrides the
scenario's own player fixture (not the shared class-file `ratings` other scenarios reuse) with an absurd
`melee_crit_rating` (100000), which drives `Unit::RollMeleeOutcomeAgainst`'s crit roll past 10000 (centipercent)
and guarantees the crit branch wins, once the fixture's existing `melee_hit_rating`/`expertise_rating` have
already suppressed miss/dodge/parry/glancing/block/crushing for other scenarios in this class file. The scenario
`learn`s the passive, `set_aura`s the target aura (`stacks: 1`, giving it its DBC `SpellDuration` on application),
measures `aura_duration_ms` ("before"), `attack`s a plain dummy, waits `CAST_SETTLE_MS` (500 ms, reused from the
shield-break scenario's own "let an async effect land" wait), `stop_attack`s, then measures `aura_duration_ms`
again ("after") and `melee_damage_count {hand: 0, critical: true}` as a sanity count of the forced crit. The wait
is `CAST_SETTLE_MS`, not the weapon's own `swing_interval(class_file)`, because starting an attack was observed
(an exploratory `coa-verify --ram` run of this exact scenario) to land its first swing immediately: a
`swing_interval`-length wait measured **two** crits, one essentially instant and one at the weapon's normal
speed, not one — `duration_scenario` therefore refuses to build at all (`NotModelled`) for any class whose
`swing_interval` does not comfortably exceed `CAST_SETTLE_MS`, rather than silently risk the same double-swing on
a faster weapon. The judge (`compare.behaviour_duration_verdict`) first checks the sanity count: anything other
than exactly 1 is `unmeasured`, not `ok` or `alert` — the forcing assumption, not the passive, failed (a miss, a
`CREATURE_FLAG_EXTRA_NO_CRIT` dummy, or the double-swing above, must never silently pass as a non-event or a false
alert). Only once exactly one crit is confirmed does it compute `measured = before - after` and judge it against
`expected = wait_ms + expected_ms` (the natural elapsed time of the wait, which the engine's own duration
decrement removes regardless of the passive, plus the claimed extra milliseconds): `ok` when
`expected - CAST_MARGIN_MS <= measured <= expected + run.max_step_ms` (the lower side is the one-sided window
`judge_time` uses for a wall-clock delta: the server can only lose *at least* the natural elapsed time, never
less; the upper side adds `run.max_step_ms`, the harness's own per-run tick-overshoot bound, because a `wait`
step's actual elapsed time can only round *up* from its nominal `ms`, never finish early, so a correct,
exactly-`expected_ms` fix still measures slightly more than `expected` on a real run), `alert` otherwise —
including exactly `wait_ms` with no extra milliseconds at all, the absent-effect case this check exists to
catch, and any overshoot beyond `run.max_step_ms`.

Templar's own Sacred Oath 712346 scenario (`coa-verify --ram --stages gameplay`, the same exploratory run that
surfaced the double-swing above) measured 2 forced crits, not 1, inside the original `swing_interval`-length wait
— `after` read `0` because the second `ReduceDebt` call emptied Oathkeeper 803237's tiny debt amount and removed
the aura outright (`AscensionTemplar.cpp`'s `if (reduction >= amount) aura->Remove();` branch), not because
anything set its duration directly. This matches the investigation's reading of `ReduceDebt`/`Tick` (neither
calls `SetDuration`) but by a more dramatic path than "no effect at all": a crit can destroy Oathkeeper early
through debt depletion, never shorten its timer the way the tooltip's "removes 1 sec" literally describes. The
fix (`CAST_SETTLE_MS` instead of `swing_interval`) isolates exactly one crit so the check measures the single-crit
claim the tooltip actually makes.

### Mechanic-duration-ratio scenarios (`behaviour_duration_ratio`, `kind: "duration_ratio"`)

`SPELL_AURA_MECHANIC_DURATION_MOD` (232) and `SPELL_AURA_MOD_DEBUFF_RESISTANCE` (178) are generic engine aura
types `passives.py` classifies as family `P6` ("scripted or crowd-control effect") because their handlers are
no-ops in `SpellAuraEffects.cpp` (`HandleNoImmediateEffect`): the real consumer is `Unit::ModSpellDuration`
(mechanic duration mod, called from the live cast path, not the passive's own effect handler) or
`Unit::MagicSpellHitResult` (debuff resistance, a hit/miss roll contribution). Neither is reachable from a
no-combat before/after stat read, but both are reachable through a real cast: `mechanic_duration_scenario`
has a striker (creature entry `striker_entry`, `spell_hit_bonus` forced to 100) cast `vehicle_spell` — a stock,
non-class spell whose own effect mechanic matches the passive's `EffectMiscValue` (e.g. `MECHANIC_DISARM`,
`MECHANIC_SNARE`) — directly at the caster, once before the passive is learned and once after, reading
`aura_duration_ms` of `vehicle_spell`'s own applied aura `CAST_MARGIN_MS` (500 ms) after the last of up to
`MECHANIC_LAND_ATTEMPTS` (3) casts, `MECHANIC_RETRY_WAIT_MS` (500 ms) apart, per phase. A `vehicle_spell` with
`DmgClass SPELL_DAMAGE_CLASS_MELEE`, such as Hamstring 1715, rolls the separate dodge/parry leg of the melee
combat table that `spell_hit_bonus` does not reach — only the miss roll does — so each phase opens with a
`set_combat_avoidance` fixture step (`Player::SetRealDodgeParryForTest`, round10 ADR 0053, superseding round9's
retry-only ADR 0050) that zeroes the caster's dodge and parry chance before the attempts, making the first
attempt land deterministically; 712466's `behaviour_duration_ratio` flipped `unmeasured`/`alert` across round
8's two runs before this fix, for exactly the dodge/parry-roll reason above. The retry loop itself stays as a
harmless safety margin (never needed once avoidance is zeroed, and a no-op for any non-melee vehicle, which
never rolled dodge/parry at all). `vehicle_spell` does not stack and refreshes to its full duration on every
landed cast, so the repeated attempts are safe: whichever attempt lands last is what
the final, fixed-delay-from-the-last-attempt read reflects, identically for the `before` and `after` phase).
The two phases are separated by `vehicle_spell`'s own DBC duration
plus 15000 ms plus a margin (`records.duration_ms(vehicle_spell) + MECHANIC_DR_RESET_MS + MECHANIC_GAP_MARGIN_MS`
in `behaviours.py`): this is a conservative allowance against a vehicle carrying its own stock
diminishing-returns reduction against a non-player caster (`SpellMgr.cpp`'s `GetDiminishingReturnsGroupForSpell`/
`GetDiminishingReturnsGroupType`), not a guarantee that it does. The generic mechanic-based match in that switch
defaults non-exempt groups to `DRTYPE_PLAYER`, but a spell can instead be matched first by its own
family-specific branch into a different group — one that can resolve to `DRTYPE_NONE` for a non-player caster,
which `Unit::ApplyDiminishingToDuration` then never reduces by percentage — so each vehicle's actual
diminishing-returns path has to be checked on its own rather than inferred from its mechanic alone. The gap
stays uniform across vehicles regardless, since an unneeded wait only slows the scenario and never produces a
wrong reading.

The judge (`compare.behaviour_duration_ratio_verdict`) computes `ratio = after / before` and
`expected_delta = before * (expected_ratio - 1.0)`: `unmeasured` when `before <= 0` (a ratio needs a positive
baseline — the vehicle cast landed nothing to read, the forced-hit fixture's own absent-effect case); `alert`
when `measured` (`after - before`) is 0 against a nonzero `expected_delta` (the absent-effect case the check
exists to catch); `ok` when `|measured - expected_delta| <= CAST_MARGIN_MS + run.max_step_ms`, `alert` otherwise.
The margin is sized on the full settle window rather than a small fraction of the expected delta because the
two `aura_duration_ms` reads are each taken a fixed wall-clock wait after their own cast, not a fixed number of
milliseconds into the aura's own remaining-duration countdown (missile travel time and tick scheduling both
vary slightly run to run); that per-read jitter is amplified by the ratio itself
(`ratio * elapsed_before - elapsed_after`), which an exploratory `coa-verify --ram` run of this exact scenario
measured at up to ~100 ms for Courage's -20% rank — within `CAST_MARGIN_MS`, comfortably outside the shared
delta-margin scale's usual 0.5%-of-expected floor.

### Duration-refresh scenarios (`behaviour_duration_refresh`, `kind: "duration_refresh"`)

Some prose passives refresh an existing aura's remaining duration back to its own maximum, rather than reducing
or extending a fresh one by a ratio: a condition that no shape above fits, since `duration_scenario` forces one
melee crit to read a *decrease* against a running debt mechanism, and `mechanic_duration_scenario` compares two
*fresh* applications of a stock vehicle spell rather than a refresh of one already-applied aura. `duration_refresh_scenario`
runs two phases, each casting `apply_spell` at the creature fixture (install `target_aura`), waiting `decay_ms`
for it to partially decay, measuring `aura_duration_ms` ("before"), setting `gating_aura` to `gating_stacks` and
casting `breaker_spell` (the real condition the server code checks), then measuring again ("after"): once
*without* the passive learned (the breaker must leave the decayed duration alone — the absent-effect case this
check exists to catch) and once *with* it (the breaker must return the duration to within `refresh_margin_ms` of
`records.duration_ms(target_aura)`, the DBC's own full duration, read once at generation time rather than
hardcoded). Both phases hold `gating_stacks` fixed at the breaker's own gating threshold, since only the
passive's presence varies between them; a scenario that also wanted to prove the stack *threshold* itself would
need the shape round3's `trigger-lot-5-spec.md` originally sketched, which (as with the issue scenario this
entry's mechanism matches, `apps/coa-gameplay-test/scenarios/templar-blessing-of-aggramar-blade-refresh-7806.json`)
holds the passive constant and varies the stack count instead — a different scenario for a different claim,
not duplicated here.

The judge (`compare.behaviour_duration_refresh_verdict`) reads all four measurements: `ok` only when the
without-phase's `after <= before` (any increase without the passive is always an alert, since the breaker's own
gating condition should never fire) **and** the with-phase's `after >= full_duration - refresh_margin_ms`
(a reading that stays merely decayed, rather than refreshed, is always an alert); `alert` otherwise. There is no
tolerance-margin scale here because the claim itself is binary (refreshed to near-full, or not), not a ratio or
a delta of a known magnitude.

### Amount-delta scenarios (`behaviour_amount_delta`, `kind: "amount_delta"`)

Some prose passives reduce a running debt aura's own stored amount by a percentage the moment a *different*
spell is cast ("Using a Libram now removes 70% of the delayed damage from Oathkeeper"): a condition
`metric_delta_scenario` cannot express, since its `before_expected`/`expected` are fixed constants read once at
generation time, not a fraction of whatever amount a fresh debt-establishing hit happens to produce, and
`duration_scenario` forces a melee crit to read a *duration* decrease, not an *amount* decrease around a cast of
an unrelated spell. `amount_delta_scenario` runs two phases, each: `set_aura`s `debt_aura` (`stacks: 1`), has a
`striker` creature (reusing `behaviours.py`'s `STRIKER` fixture, `spell_hit_bonus: 100` so the breaker cannot
miss) `cast` `breaker_spell` directly at the caster, asserts the resulting `target_aura`'s `aura_amount` effect 0
is nonzero (the same `DEBT_ASSERT_TIMEOUT_MS` pattern `duration_scenario` already uses), measures `aura_amount`
("before"), casts `trigger_spell` (self-targeted) and measures `aura_amount` again ("after") — once *without*
the passive learned (the reduction call is gated on it and must leave the amount unchanged — the absent-effect
case this check exists to catch) and once *with* it (must drop by exactly `fraction`, truncating integer
division, matching the server's own `uint64` arithmetic). The wait between the cast and the "after" read is
`AMOUNT_DELTA_CAST_WAIT_MS` (150 ms), not the usual `CAST_SETTLE_MS` (500 ms): an exploratory `coa-verify --ram`
run of this exact scenario at `CAST_SETTLE_MS` for both the debt-settle wait and the post-cast wait measured a
spurious reduction in the *without* phase too (293 before, 251 after, no passive known) — `target_aura` itself
carries `EffectApplyAuraName[0]` 3 (`SPELL_AURA_PERIODIC_DAMAGE`) at `EffectAmplitude[0]` 1000 ms (read from the
client DBC), releasing part of its own staggered amount on a 1-second cycle independent of any Libram cast, and
`500 + 500 = 1000` ms straddled that cycle on almost every run; shrinking the post-cast wait keeps the total
elapsed time from the debt-establishing hit to the "after" read comfortably under 1000 ms, so neither read
straddles a natural tick.

The judge (`compare.behaviour_amount_delta_verdict`) computes `percent = round(fraction * 100)` and
`with_expected = with_before - (int(with_before) * percent) // 100` (the same truncating integer division the
server's `ReduceDebt` performs, not a float multiply, so a server using ceiling or rounding instead of
truncation would be caught): `ok` only when the without-phase's `after == before` exactly **and** the
with-phase's `after == with_expected` exactly (a deterministic integer read with no combat-roll variance, so no
tolerance band beyond `FLOAT_EPSILON`); `alert` otherwise, including a without-phase change (the absent-effect
case) and a with-phase mismatch of any size.

### Crit-guarantee scenarios (`behaviour_crit_guarantee`, `kind: "crit_guarantee"`)

Some passives force a hit of a specific spell to critically strike whenever its target is a given
`creature_template.type` ("This is guaranteed to critically strike against Undead enemies."), implemented as a
hard override of the hit's own `TargetInfo.crit` at damage-calculation time (an `OnSpellCalculatedTarget`
hook), not a `SPELL_AURA_MOD_ATTACKER_SPELL_AND_WEAPON_CRIT_CHANCE`-style stat change. The already-existing
`spell_taken_crit_chance` metric (`player->SpellDoneCritChance`/`target->SpellTakenCritChance`, used for this
same clause shape on other classes, e.g. the hand-written `scenarios/chronomancer-wand-of-time-crits-undead-
demons-10851.json`) is structurally blind to this hook and would read the ordinary crit-chance stat regardless
of the target's type; a real per-hit measurement, filtered by target creature type, is needed (ADR 0055).

`crit_guarantee_scenario` overrides the shared `creature_fixture`'s `DUMMY_ENTRY` with the class file's own
`target_entry` (forcing `reaction: 0`, since an arbitrary creature template does not inherit the dummy's usual
implicit friendliness), learns the passive, then auto-attacks that creature for `attempts` swings (100 by
default) and measures `spell_damage_count` of `trial_spell` against it twice — once `critical=True`, once
`critical=False` — reusing the metric's existing `target`/`critical` filters unchanged (the same ones
`hits.py`'s `critical_hits`/`blocked_hits` measurements already use for other checks), so no
`CoAGameplayTest.cpp` change was needed.

The judge (`compare.behaviour_crit_guarantee_verdict`) sums `crit + noncrit`: below `minimum_events` (5 by
default — the scenario did not generate enough triggers of `trial_spell` to judge anything, for example a
`proc_rate` regression elsewhere) it reports `insufficient_trials`; otherwise `ratio = crit / total` is banded
against `1.0` through the shared `banded_status` tolerated-band mechanism (ADR 0051): `ok` at exactly 1.0,
`tolerated` within 5%, `alert` otherwise (any non-critical hit of `trial_spell` against the declared creature
type).

### Aura-grant scenarios (`behaviour_aura_grant`, `kind: "aura_grant"`)

Some abilities' tooltips state an unconditional self-effect of casting them, not a separate learnable passive
("... and granting an Oath"), implemented in a hook that runs once per cast regardless of hit/miss (e.g.
`OnSpellCast`, not a hit-result or chance-rolled proc hook). None of the existing kinds fit: `triggers.py`'s
shapes all model a passive that changes a *different*, repeated action's outcome (sized for a probabilistic
sample), and every other `behaviours.py` metric-delta kind compares a "without the gating passive" phase
against a "with it learned" phase — there is no separate passive to gate on here, the cast itself always does
it (ADR 0056).

`aura_grant_scenario` learns `trigger_spell`, resets its cooldown, reads `aura_stacks` of `chain_aura` (the
stacking aura that accumulates across repeated grants, before the cast), casts `trigger_spell` once at a fresh
creature fixture, waits 500 ms, then reads `aura_stacks` of `chain_aura` again (after) and `aura` of
`oath_aura` (the specific aura the cast must apply). No `CoAGameplayTest.cpp` change was needed: `aura_stacks`
and `aura` already exist and need only a `spell` field.

The judge (`compare.behaviour_aura_grant_verdict`) takes the integer delta `after - before`: `ok` only when it
equals exactly 1 and `oath_aura` is present after the cast, `alert` otherwise. There is no tolerated band —
an integer stack delta is either right or wrong, with no near-miss to tolerate.

### Oath-consumption scenarios (`behaviour_oath_consumption`, `kind: "oath_consumption"`)

Several Breaker abilities' tooltips state "Consumes your Oaths, dealing additional damage/healing for each
consumed," a claim about `Player::m_spellMods`, not about any CoA-specific code: every Oath aura
(`804903`/`804904`/`804922`/`804924`/`805332`) carries one or more `ADD_FLAT_MODIFIER`/`ADD_PCT_MODIFIER`
effects (`SpellAuraEffects.cpp:777-795`, `AuraEffect::CalculateSpellMod`) whose `EffectSpellClassMask` matches
the Breaker spell's own `SpellFamilyFlags`; holding one registers it in `Player::m_spellMods[op]`, and
`Unit::SpellDamageBonusDone`/`SpellHealingBonusDone` (`Unit.cpp:9920`/`10868`) apply every matching entry
through `Player::ApplySpellMod` when the Breaker spell's own damage/healing formula is computed, before
`AscensionTemplarAbilities.cpp`'s `Breaker(info)` branch calls `ClearOaths` on the same cast ("consumed"). No
existing kind fit a "read a deterministic formula, fixture one aura with no cast, read it again, then cast
once to confirm consumption" shape (ADR 0057).

`oath_consumption_scenario` learns `trigger_spell`, reads `metric` (`spell_damage_done`/`spell_healing_done`,
`effect`/`periodic`/`target` as given) as the "before" reading — a deterministic formula call with no combat
roll — then fixtures `oath_spell` to 1 stack with the existing `set_aura` action (no cast) and reads the same
metric again as "after." It then sets the trigger spell's power cost if any, resets its cooldown, applies any
`required_aura_steps` prerequisite (a Breaker spell typically requires at least one Oath already held to cast
at all, surfaced by `required_aura_steps` fixturing the Oath Chain `704576`), casts `trigger_spell` once, waits
500 ms, and reads `oath_spell`'s own `aura_stacks` (must be 0 afterward).

The judge (`compare.behaviour_oath_consumption_verdict`) takes `delta = after - before` and computes the
expected delta from `relation`/`expected` (`before * (expected - 1.0)` for `"ratio"`, `expected` itself for
`"flat"`), then bands it through the same `deterministic()`/`banded_status` tolerated-band mechanism (ADR
0051) every other deterministic-formula check in this file uses: `ok` within the usual tolerance,
`tolerated` within 5%, `alert` otherwise. A nonzero `aura_stacks` reading after the cast always downgrades an
otherwise-passing verdict to `alert` — the Oath must be consumed, not just read.

### Oath-consumption-on-removal scenarios (`behaviour_oath_consumption_removal`, `kind: "oath_consumption_removal"`)

Righteous Tempest 805409's own "Consumes your Oaths, dealing additional damage for each consumed." clause does
not fit `oath_consumption`'s shape: its own aura bakes the bonus from currently held Oaths at *apply* time
(`AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle::Calculate`, summing
`max(0, GetAuraEffect(oath, EFFECT_2)->GetAmount())` over `{804904, 804922, 804924, 805332}` into
`SetScriptValue(805409, bonus)`, read back by `OnSpellCalculatedTarget`'s `1.0 + scriptValue / 100.0` factor on
every triggered hit), and only clears the Oaths on that same aura's own *removal* (`::Remove`'s
`Named(GetSpellInfo(), 805409)` branch, which fires on natural expiry too, not just on cast — `OnSpellCast`'s
`Breaker(info)` branch explicitly exempts `Named(info, 805409)` from its usual unconditional `ClearOaths`)
(ADR 0058).

`oath_consumption_removal_scenario` fixtures every `oath_spells` entry to 1 stack with the existing `set_aura`
action (no cast) and reads each one's own `aura_amount` (effect `oath_effect`, default 2) — the same per-Oath
value the trigger's own `Calculate` hook sums. It then sets the trigger spell's power cost if any, resets its
cooldown, applies `required_aura_steps`, casts `trigger_spell` once at the caster, waits `settle_ms` (default
500, read against the trigger's own DBC duration via `Records.duration_ms` so it always lands well inside it),
and reads the trigger's own applied aura's `aura_script_value` (`key: trigger_spell`) plus every Oath's own
`aura_stacks` (expected 1, not yet consumed). It then waits out the remainder of the trigger's own duration
plus `expire_margin_ms` (default 1500) so the aura expires naturally, and reads every Oath's `aura_stacks`
again (expected 0, consumed only now).

The judge (`compare.behaviour_oath_consumption_removal_verdict`) sums the measured `aura_amount` readings as
the expected value and bands the measured `aura_script_value` against it through the same
`deterministic()`/`banded_status` tolerated-band mechanism (ADR 0051) every other deterministic-formula check
in this file uses. Either a wrong "still held" stacks reading (not 1) right after the cast or a wrong
"removed" stacks reading (not 0) once the aura has expired always downgrades an otherwise-passing verdict to
`alert`.

### Internal-cooldown-gate scenarios (`behaviour_internal_cooldown_gate`, `kind: "internal_cooldown_gate"`)

Some proc tooltips end in a sentence no existing kind measures: "Can only occur every/once per ...". The gating
auras already have proven `trigger_count` proc entries in `triggers.py`, but those entries deliberately space
every attempt past the cooldown (via `internal_cooldown_ms`) so the rate check is never contaminated by the
gate — which also means they never actually exercise the gate's own window. `AscensionTemplarEvents.cpp`'s
`Check`/`Proc` enforce it with a per-player `State(player).cooldowns` world-tick timer the CoA scripts own
directly (`ScheduleEvent`/`HasTimeUntilEvent`), not the engine's native `Aura::IsProcOnCooldown` (ADR 0059).

`icd_gate_scenario` casts `trigger_spell` three times (via `hits.cast_steps`, which resets its cooldown, sets its
power cost and applies `required_aura_steps` before each cast, plus any `restore_charges`/`caster_health_pct`
fixture reapplied every time): the gap after the first cast is half of `internal_cooldown_ms` (inside the
window), the gap after the second is the remaining half plus `reopen_margin_ms` (default 500 ms, past it).
`observe_spell`'s cumulative `spell_cast_count` is read right after each cast.

The judge (`compare.behaviour_internal_cooldown_gate_verdict`) checks the delta between the first two readings
first: nonzero is an immediate `alert` (fired again before the window closed). Only then does it check the delta
between the last two readings: exactly `+1` is `ok`, anything else `alert`. No tolerated band — an integer event
count at a fixed timing boundary has no near-miss.

### Charge-recharge scenarios (`behaviour_charge_recharge`, `kind: "charge_recharge"`)

A tooltip's "N Charges" / "T sec recharge" pair names the WotLK-era spell-charge system (`SpellInfo::MaxCharges`/
`ChargeRecoveryTime`, read by `Player::GetSpellCharges`/`HasSpellCooldown`), not a plain cooldown; no other
behaviour kind spends a resource down to zero and times its recovery. `charge_recharge_scenario` learns `spell`,
then casts it `max_charges` times in a row (relocating `CHARGE_OFFSET_YD` away between casts whenever `spell`
closes distance via `SPELL_EFFECT_CHARGE`/149, the same fixture the existing `triggers.py` entries that repeat-
cast this spell already use), snapshotting `spell_charges` after each cast. It then attempts one more cast past
the last charge and snapshots both `spell_charges` (must stay at 0) and `cast_failure` (must be nonzero: the
native `HasSpellCooldown` gate refuses a cast with `Available == 0` rather than letting a fourth consumption
through). Finally it waits to `recharge_ms * (1 - tolerance)` and snapshots `spell_charges` again (still 0, i.e.
not recharged early), then waits the rest of the way to `recharge_ms * (1 + tolerance)` and snapshots once more
(must now read 1, i.e. recharged by then). `tolerance` defaults to 0.05 (the owner's standing 5%-on-numbers
rule) and is carried in the model so the judge never hard-codes it.

The judge (`compare.behaviour_charge_recharge_verdict`) computes the whole expected sequence from `max_charges`
in Python (`max_charges - 1, max_charges - 2, ..., 0`) and compares it against the measured snapshots alongside
the over-cast refusal and the before/after-recharge pair; `ok` only when every one of those checks holds, `alert`
otherwise (a wrong starting count, a charge sequence that does not strictly decrement, a fourth charge granted
instead of refused, an early recharge, or a recharge that never arrives are all caught).

### Cast-gate scenarios (`behaviour_cast_gate`, `kind: "cast_gate"`)

Some tooltips state a castability condition on the *target*'s own health, rather than a magnitude or a count:
"Only usable on enemies below N% health." `values.py`'s `required_target_health_steps` already fixtures the
DBC's own `TargetAuraState` to the health percentage its own `AURA_STATE_HEALTHLESS_35_PERCENT`-style flag needs,
for the unrelated `effect_value` scenario that measures the spell's damage — but nothing asserted that the same
spell actually *refuses* the cast above that threshold, nor that a second spell's tooltip claim to bypass the
gate ("are usable regardless of your target's health percentage") does anything in practice.
`cast_gate_scenario` attempts the gated `spell` at the stock `dummy` fixture three times, `reset_cooldown` and a
fresh `set_power` before each attempt so a prior successful cast's cooldown or cost never contaminates the next:
once at the fixture's own default (full) health with neither spell known (must refuse with
`SPELL_FAILED_TARGET_AURASTATE`, 111); once with `bypass_spell` learned and cast on the caster first, at the same
untouched full health (must succeed, proving the bypass); and once with `bypass_spell` unlearned again and the
target's health lowered through `required_target_health_steps` (must succeed through the health gate itself, not
the bypass). The three attempts run in that order because `set_health_pct` can only lower a creature fixture's
health, never raise it back (`README.md`): the health fixture only applies to the last attempt, after both
full-health attempts are already measured. Each attempt's `cast_failure` is read straight off the harness's
existing metric (`cast_failure`), with no new metric: zero means the cast went through, any other value is the
native `SpellCastResult` reason the client was told.

The judge (`compare.behaviour_cast_gate_verdict`) reads the attempt's own `cast_failure` measurement and compares
it for exact equality against the `Expectation.displayed` reason code (`exact()`, the same integer-exact helper
`behaviour_count_verdict` uses): `ok` only when the measured reason matches exactly, `alert` otherwise, including
a "blocked" attempt that actually went through or an "allowed"/"bypassed" attempt still refused.

### Templar entries

| Passive | Kind | Quote | Expected | Mechanism |
|---|---|---|---|---|
| Scarlet Judicator 525024 | count | "strikes 2 additional enemies near the primary target" | 2 | Divine Force 807805's school-damage effect (`TARGET_UNIT_TARGET_ENEMY`, `DmgClass` 2/melee) always routes through `Spell::SelectImplicitChainTargets` (`Spell.cpp:1905-1923`), which applies Scarlet Judicator's `SPELLMOD_JUMP_TARGETS` flat modifier to `ChainTarget` and searches a 10-yard jump radius for a melee spell with no `JumpDistance` override (`Spell.cpp:2200-2213`) |
| Justice 712437 | count | "strikes 1 additional nearby target" | 1 | scripted hook `templar_casts::OnSpellBeforeEffects` (`AscensionTemplarAbilities.cpp:95-102`): casting Interdict 560116 with Justice known adds exactly one unit from `Nearby(primary, 8.0f)`; the DBC's own effect 1 (`PROC_TRIGGER_SPELL` to 712364, Sacred Oath's own trigger) does not implement this sentence at all and is not used |
| Final Prayer 705268 | ratio | "Doubles the healing done to you" | 2.0 | two named targets: Testament of Faith 501606 (a direct heal, `SPELL_AURA_MOD_HEALING_RECEIVED` taken-side, method `"taken"`, measured with `spell_healing_taken`; round8/round9 found method `"cast"`/`spell_healing_done` structurally blind to this aura — `Unit::SpellHealingBonusDone` is the healer's own caster-side multiplier and never reads a taken-side aura of the healed unit, so it measured the same 800 before and after regardless of whether the server doubles the heal) and Testament of Fortitude 500678 (a `SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE` self-heal whose doubling is a `SPELLMOD_EFFECT1` percent modifier read inside its own effect-0 `CalcValue`, needing no cast at all, method `"effect_value"`, measured with `spell_effect_value {spell: 500678, effect: 0}`) |
| Holy Tempest 301339 | spread | "spreads Condemn on affected enemies to a nearby enemy" | 1 | `AscensionTemplarAbilities.cpp:294-295` (`OnSpellHitResult`): on a confirmed hit of Righteous Tempest's periodic damage (ranks `805410`/`570200..570205`) with the passive known, `AscensionTemplar.cpp:224-257` (`SpreadCondemn`) copies the Condemn aura already present on the hit target onto the first valid, non-already-afflicted, line-of-sight enemy within `Nearby(target, 10.0f)` - a hardcoded radius, not read from any DBC field |
| Armor of Faith 804930 | trigger | "Whenever the absorption shield from Staffguard breaks, inflict" | 1 | `AscensionTemplarAuras.cpp:213-216` (`aura_ascension_templar_lifecycle::Remove`): when Staffguard 706583's absorb effect is fully depleted (`GetAmount() <= 0`) by `AURA_REMOVE_BY_ENEMY_SPELL` (an enemy's own damage, not an expiry or manual cancel) while the player is alive and knows 804930, it casts Armor of Faith's damage spell 801546 on the player, whose own nearby-enemy Holy damage effect then lands; the amount stays the pre-existing `$801546ppl1` open conformance check (`questions.md:368-374`), unchanged by this entry. Staffguard's absorb is Holy-only (`SchoolMask` 2), so the scenario's striker casts Smite 48123 (`breaker_spell`) directly at the caster rather than swinging at it |
| Tyr's Guard 560649 | metric_delta | "now summons an additional copy of yourself" | 3 | a plain stock `SPELLMOD_EFFECT1` aura (effect 2 of 560649, `EffectSpellClassMask[6]` matching Testament of Hope 1397742's family flags): the engine's own `Player::ApplySpellMod`/`SpellInfo::CalcValue` path adds 1 to Testament of Hope's summon effect's base points (1 -> 2, `CalcValue` 2 -> 3) with no CoA-specific code involved; `owned_creature_count` of the copy entry 50250 is the metric, before (2, no 560649) and after (3, 560649 learned) |
| Spiritual Abdicator 803219 | metric_delta | "reduces damage taken by an additional 5% per copy" | -15 | `AscensionTemplarContracts.cpp:278-281` (`templar_scaling::ModifySpellEffectBaseValue`): when the copy's owner (the Templar) has aura 803219, the copy's own owner-area aura 704409 effect 1 (`MOD_DAMAGE_PERCENT_TAKEN`, base `CalcValue` -10, confirmed by the existing Testament of Hope regression scenario) is overridden to -15 at load, the "additional 5%" the tooltip states on top of 704409's own 10%; 803219's own effect 0 is a pure marker (`dummy()` rewrites its `ApplyAuraName` to `SPELL_AURA_DUMMY` at load, no gameplay value of its own); `aura_amount` of spell 704409 effect 1 is the metric, before (-10, no 803219) and after (-15, 803219 learned) |
| Battlepriest 801202 | health_ratio | "take 20% reduced Magic damage" | 0.8 at 90%/10% health, 1.0 at 50% | the DBC's own mechanism (a periodic trigger casting a conditional `MOD_DAMAGE_PERCENT_TAKEN` aura, `CasterAuraState`-gated on `AURA_STATE_HEALTHLESS_20_PERCENT`/`ASCENSION_TARGET_HEALTH_ABOVE_80_PERCENT`) is `dummy()`-nulled at load (`AscensionTemplarContracts.cpp:151-154`); the real implementation is a direct multiplier in `templar_scaling::Mitigation` (`AscensionTemplarContracts.cpp:242-255`), `factor *= .8f` when the school is magic and the player both knows 801202 and is strictly above 80% or strictly below 20% health (`Unit::HealthAbovePct`/`HealthBelowPct`), called from `ModifySpellDamageTaken`/`ModifyPeriodicDamageAurasTick`/`ModifyMeleeDamage`'s hooks; `script_spell_damage_taken` with `probe_spell` Fireball 133 (magic school, no `TemplarCopies` attribute exemption) exercises the same `ModifySpellDamageTaken` hook the real pipeline uses |
| Titanfall 300607 | leech_ratio | "now heals you for twice the damage dealt" | 1.0 before, 2.0 after (before the known-modifier factor) | a plain data-driven `SPELLMOD_VALUE_MULTIPLIER` (`EffectMiscValue` 27) `ADD_PCT_MODIFIER` passive on Titanstrike's family mask (`EffectSpellClassMask` bit 4, `SpellFamilyName` 25), `EffectBasePoints` 99 (+100%); Titanstrike's own `SPELL_EFFECT_HEALTH_LEECH` effect has `ValueMultiplier` 1.0, run through the generic `Player::ApplySpellMod(SPELLMOD_VALUE_MULTIPLIER)` pipeline (`SpellInfo::CalcValueMultiplier`, `Spell.cpp:2929`) with no CoA-specific code involved; Titanstrike also requires its target below 35% health (`TargetAuraState` 13, `AURA_STATE_HEALTHLESS_35_PERCENT`, a flag `Unit::Update` recomputes every tick from current health, not a settable aura) |
| Sacred Oath 712346 | duration | "remove 1 sec from the duration of" | 1000 ms on top of the `CAST_SETTLE_MS` wait | `spell_proc` row for 712346 (`rev_20260909_04_templar_completion.sql`): `ProcFlags` 1048575, `Chance` 100, overriding the DBC's own `ProcFlags` 0; `aura_ascension_templar_event::Check` case 712346 (`AscensionTemplarEvents.cpp:84-85`) requires `damage && crit && player->HasAura(803237)`; `::Proc` (line 169-170) calls `ReduceDebt(player, 0, true)`, which only ever calls `effect->ChangeAmount(...)` on Oathkeeper 803237's own debt effect or, if the one-tick share would exceed what remains, `aura->Remove()` — it never calls `aura->SetDuration(...)`. An exploratory `coa-verify --ram` run confirmed this reading: with two forced crits in one window, `aura_duration_ms` read `0` (the aura removed outright by debt depletion), not `-1000` beyond the natural decay; a crit's own contribution to the aura's remaining duration is the debt-tick side effect described above, never a direct shortening of the timer the tooltip's "removes 1 sec" literally claims. The harness forces the striker's `spell_hit_bonus` to 100 so the debt-settle assert cannot flake on a missed Smite swing (round3/sacred-oath-flaky-spec.md; round2 misdiagnosed this as a wait-margin issue) |
| Finesse (Rank 1) 705271, effect 1 | duration_ratio | "reduces the duration of disarm effects against you by" | 0.85 | stock engine `SPELL_AURA_MECHANIC_DURATION_MOD` (232), `EffectMiscValue` 3 (`MECHANIC_DISARM`), no CoA code involved; vehicle Melt Weapon 301235 (`Mechanic` 3, `DurationIndex` 32 = 6000 ms), the striker's disarm landing on the caster's own equipped weapon (`class_file`'s `weapon`, already equipped by `base_steps`) |
| Finesse (Rank 2) 707851, effect 1 | duration_ratio | "reduces the duration of disarm effects against you by" | 0.70 | same mechanism and vehicle as Rank 1 |
| Courage (Rank 1) 707754, effect 1 | duration_ratio | "reduces the duration of movement slowing effects on you by" | 0.90 | stock engine `SPELL_AURA_MECHANIC_DURATION_MOD` (232), `EffectMiscValue` 11 (`MECHANIC_SNARE`), no CoA code involved; vehicle Hamstring 1715 (`EffectMechanic[0]` 11, `DurationIndex` 8 = 15000 ms); `MECHANIC_SNARE` is exempted from `ModSpellDuration`'s duration-mod reduction only when the applied spell's own mechanic mask also carries `MECHANIC_DISORIENTED`, which Hamstring does not |
| Courage (Rank 2) 712466, effect 1 | duration_ratio | "reduces the duration of movement slowing effects on you by" | 0.80 | same mechanism and vehicle as Rank 1 |
| Whirling Tempest 301340, effect 1 | metric_delta | "you now cannot be slowed" | 1 (immune) | round6 `owner-rulings-2026-11-09.md` — **confirmed defect, fixed this round**: `AscensionTemplarContracts.cpp`'s `id == 301340` branch unconditionally zeroed effect 1 (`info->Effects[1].Effect = 0`), discarding the raw DBC's own `SPELL_EFFECT_APPLY_AURA` there with no substitute mechanism anywhere in the Templar files. Fixed by setting that effect to `SPELL_AURA_MECHANIC_IMMUNITY`/`MECHANIC_SNARE` instead (the same per-class idiom already used by `AscensionStarcallerContracts.cpp`/`AscensionPrimalistBoulder.cpp`); the stock `AuraEffect::HandleModMechanicImmunity` grants the immunity for exactly 301340's own application window, which `AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle` already ties to Righteous Tempest 805409's apply/remove, so no new Templar lifecycle code is needed. The metric is the harness's own `spell_effect_immune` probe (`player->IsImmunedToSpellEffect`) against Hamstring 1715's own snare effect (effect 0), not an actual landed cast of it: an exploratory run cross-checked that an *actual* Hamstring cast at a caster carrying 301340's effect 0 (`SPELL_AURA_MOD_SPEED_ALWAYS`) never lands at all regardless of this fix (`1715 present` reads `0` with the fix applied and with it reverted alike — the same `SPELL_AURA_MOD_SPEED_ALWAYS` aura type, cross-checked with the equal-magnitude but differently-typed Courage Rank 2 712466 (`SPELL_AURA_MOD_INCREASE_SPEED`), which does not reproduce it), an unrelated engine/harness interaction this round did not chase further since the direct immunity probe sidesteps it entirely and is the more precise signal anyway. `gate_spell: 300504` learns the real parent passive between phases (301340 is never itself learnable: the server only casts it internally); `trigger_spell: 805409` is cast in both `cast_steps()` calls so the "before" phase still proves the probe can read `false` while 300504 is unknown. Pre-fix, this entry reads `0` (not immune) after 300504 is learned, against `expected` 1 — an alert; post-fix it reads `1`, matching exactly |
| Blessing of Aggramar 300502 | duration_refresh | "now refreshes the duration of Blade of Faith on all nearby enemies." | 30000 ms (`SpellDuration.dbc` id 9) | `AscensionTemplarAbilities.cpp` `Breaker(info)`: `player->HasAura(300502) && spell->GetScriptValue(704576) >= 10` refreshes every nearby Blade of Faith 803872 aura to its own max duration; matches the already-working 9-vs-10-stack threshold the issue scenario `templar-blessing-of-aggramar-blade-refresh-7806.json` (#7806) proves, varying the passive's presence instead of the stack count |
| Warrior of Tyr 301253 | metric_delta | "Periodic damage dealt now generates" | 10 (Energy, power type 3) | `AscensionCustomResourceData.h:475` `NativePowerGainRules` (`ClassId 19, PowerType 3, InternalAmount 10, Event PeriodicDamageTick, RequiredAuraSpellId 301253`), consumed by `AscensionCompat.cpp:3632-3680` `OnPeriodicDamageTick`; Condemn 567541 (periodic damage, 3000 ms ticks) is cast as a real tick source, with the scenario's own mana-cost fixture resetting Energy to a known baseline immediately before each cast; matches the already-written issue scenario `templar-5163-warrior-of-tyr-energy-generation.json` (#5163, #4432). No code or SQL fix needed — the prior `triggers` entry for 301253 (removed) searched only the `ProcFlags`/`spell_proc` path and missed this separate native-resource-rule path |
| Sacred Resistance 301309 | metric_delta | "now increases your Armor by" | 1 (aura present) | round4 `scripted-script-aura` investigation (2026-11): `talent(301309, 680870)` inside `OnSpellCast`'s generic `talent` helper (`AscensionTemplarAbilities.cpp:152-153`), `if (Named(info, 805421)) talent(301309, 680870)` i.e. `if (player->HasAura(301309)) Cast(player, player, 680870)` whenever the player casts a Reckoning rank (805421, family 25, `SpellFamilyFlags[2]` bit 128 set); `680870`'s own armor-percent and duration tokens are already `ok` (`301309 effect_value 680870e0 #0`, `301309 spell_duration 680870 #1`). 301309's own effect 0 (`BasePoints`/`MiscValue` both 0) is a pure flag, read nowhere by value: the metric is `aura {spell: 680870}` before and after learning 301309, around a cast of Reckoning's max rank 572741 (`EffectImplicitTargetA[0]` 6, TARGET_UNIT_TARGET_ENEMY, so `target: "dummy"`) |
| Keeping the Oath 92109, effect 1 | metric_delta | "you no longer consume your Oaths with Oath Breakers" | 1 (aura present) | round4 `scripted-script-aura` investigation (2026-11): `AscensionTemplarAbilities.cpp:174`, `if (!player->HasAura(92109) && !player->HasAura(803149) && !Named(info, 805409)) ClearOaths(player);` inside the `Breaker(info)` block, run on every cast satisfying `Breaker` (`SpellFamilyFlags[2]` bit 128, or `Named(info, 805409)`, Righteous Tempest); `ClearOaths` removes Oath Chain 704576 among others. Reckoning 572741 (max rank) satisfies `Breaker` through the `SpellFamilyFlags[2]` bit, not through `Named(info, 805409)`, so it exercises the 92109 gate specifically rather than the separate, always-exempt Righteous Tempest case; the scenario measures `aura {spell: 704576}` before and after learning 92109, around a Reckoning cast whose own `required_aura_steps` fixture re-grants Oath Chain fresh immediately before each cast (shared with the Sacred Resistance entry above, same `trigger_spell`) |
| Scourgebane 92111 (`trial_spell: 801832`) | crit_guarantee | "This is guaranteed to critically strike against Undead enemies." | ratio 1.0 | `AscensionTemplarAbilities.cpp:120` (`OnSpellCalculatedTarget`): `if (info->Id == 801832 && (target->GetCreatureType() == CREATURE_TYPE_UNDEAD || spell->GetScriptValue(806523))) hit.crit = true;` — against `target_entry` 1501 (Mindless Zombie, `creature_template.type` 6, Undead), 100 auto-attack swings measured 28 critical of 28 triggered 801832 hits in one run and 22 of 22 in a second, independent run; `ok` both times |
| Transcending Strikes 804897 | metric_delta | "Your Divine Force will now trigger a" | 112994 ms (Divine Force `cooldown_ms`) | round4 `trigger-lot-r4-6` investigation (2026-11): 804897's own effect 0 is dummied at load (804897 is in `TemplarCastDrivers`); the real effect is `AscensionTemplarAbilities.cpp:327-333` (`OnSpellCast`): `if (Named(info, 806153) && player->HasAura(804897) && !spell->GetScriptValue(804918))` and the target carries the caster's own Blade of Faith 803872, `Reduce(player, 806153, 4000)` cuts 4000 ms off every known Divine Force rank's cooldown, unconditionally, once per cast. `setup_casts: [803872]` casts Blade of Faith at the `dummy` fixture immediately before each timed Divine Force cast in both phases; `before_expected`/`expected` are Divine Force's own 120000 ms `CategoryRecoveryTime` minus the 3000 ms `wait_ms` minus a steady 6 ms simulated-clock processing delta (confirmed identical, a clean 4000 ms drop, across two independent gameplay runs); the tooltip's own duration token belongs to a different, unrelated spell (804918) and is out of this entry's scope. **Open owner question, not fixed this round** (`owner-decisions.md`): the tooltip's own displayed token (`$/1000;804918s1`, already confirmed `ok` at 30000 ms by a separate `effect_value` check) disagrees by 7.5x with the 4000 ms this entry measures and confirms the server actually applies; this check deliberately verifies the server's own coded mechanism (so it can alert if that mechanism itself regresses), not whether 4000 ms is the number the tooltip promises — that is a tooltip-vs-server discrepancy this round does not settle |
| Transcending Strikes 804897 (`variant: "target_gate"`) | metric_delta | "when used on enemies affected by Blade of Faith" | 86994 ms (116994 before) | round10 `proc-chains` (ADR 0058): isolates the other half of `AscensionTemplarAbilities.cpp:327-333`'s AND condition from the entry above it: `setup_only_after: true` keeps 804897 known throughout both phases and instead withholds Blade of Faith 803872 from the dummy in the first phase (no reduction, same 116994 reading as the passive-gated entry's own unreduced baseline) and casts it in the second (the full 30000 ms reduction, 86994), proving the clause's target-condition half independently of the passive-known half |
| Whirling Tempest 300504 | metric_delta | "you gain 20% increased movement speed" | 1.20 | round4 `tooltip-fixes-b` (2026-11): 300504's own `EffectTriggerSpell[0]` (`ApplyAuraName` 42) is dummied at load (300504 is in `TemplarCastDrivers`); the real wiring is `AscensionTemplarAuras.cpp:154-158` (`aura_ascension_templar_lifecycle::Apply`), which casts the hidden 301340 on the player whenever Righteous Tempest 805409 applies while 300504 is known, copying 805409's own 3000 ms duration onto it. 301340's effect 0 (`SPELL_AURA_MOD_INCREASE_SPEED`, `BasePoints 19`) is read by `Unit::UpdateSpeed`'s `main_speed_mod`; `run_speed_rate` is the metric, `wait_ms` 500 (not the 3000 ms default, since 805409/301340's own duration is exactly 3000 ms and the default would measure at or past expiry) |
| Whirling Tempest 300504 (`variant: "stacks_with_courage"`) | metric_delta | "stacks with Courage" | 1.32 (1.10 before) | round4 `tooltip-fixes-b` (2026-11) — **confirmed defect, fixed this round**: Courage Rank 1 707754 (`SPELL_AURA_MOD_INCREASE_SPEED`, `BasePoints 9`, +10%) and 301340 were both aura type 31 before this fix, so `Unit::UpdateSpeed`'s `main_speed_mod` (`GetMaxPositiveAuraModifier`, a max, not a sum) gave only `max(10%, 20%) = 20%` with both active, contradicting this clause. Fixed in `AscensionTemplarContracts.cpp`'s `id == 301340` branch by moving 301340's effect 0 to `SPELL_AURA_MOD_SPEED_ALWAYS` (129), which `UpdateSpeed` reads as a separate, multiplicative `stack_bonus` (`GetTotalAuraMultiplier`) on top of `main_speed_mod`; Courage's own aura type is untouched. `setup_actor_aura: 707754` applies Courage via `set_aura` before each phase's cast; `before_expected` 1.10 is Courage alone, `expected` 1.32 is `1.10 (main_speed_mod) x 1.20 (stack_bonus)` once the fix lands — pre-fix this entry reads `~1.20` against 1.32 and alerts, the failing case this check exists to catch. 301340's own `Description[enUS]` ("While Righteous Tempest is active you now cannot be slowed.") is a separate clause from 300504's speed/stacking claim and is now covered by its own `metric_delta` entry below (round6, `owner-rulings-2026-11-09.md`: confirmed defect, fixed) |
| Righteous Lunge 570233 | aura_grant | "and granting an Oath" | +1 stack, Oath aura present | `AscensionTemplarAbilities.cpp:155-165` (`OnSpellCast`, `Family(info, 2, 1)` block): chains to root 801443, `GrantOath(player, 804904)` ("Oath: Righteous Lunge"); the Oath Chain 704576 stack went 0 -> 1 and 804904 was present after the cast in two independent runs, both `ok` |
| Holy Cleave 573049 | aura_grant | "and granting an Oath" | +1 stack, Oath aura present | same `GrantOath` block; chains to root 801445, oath 804903 ("Oath: Holy Cleave"); 0 -> 1 and 804903 present in both runs, `ok` |
| Vindication 573324 | aura_grant | "and granting an Oath" | +1 stack, Oath aura present | same `GrantOath` block; matches neither the 801443 nor 801445 nor 804906 cases, falling to the ternary's `else` branch, oath 805332 ("Oath: Vindication"); 0 -> 1 and 805332 present in both runs, `ok` |
| Condemn 804906 | aura_grant | "and granting an Oath." | +1 stack, Oath aura present | same `GrantOath` block; `Named(info, 804906)` matches directly, oath 804922 ("Oath: Condemn"); 0 -> 1 and 804922 present in both runs, `ok` |
| Righteous Upheaval 572027 | oath_consumption (`oath_spell: 804904`) | "Consumes your Oaths, dealing additional damage for each consumed." | ratio 1.365 | 804904 ("Oath: Righteous Lunge") carries two `SPELLMOD_DAMAGE`-keyed `ADD_PCT_MODIFIER` effects whose class mask matches 572027's own `SpellFamilyFlags[2]` bit 128 (`Family(info, 2, 128)` == `Breaker`); ground-truthed with the `spell_modifier` metric (base 1000, op 0): 1000 -> 1364.9998779296875, i.e. 1.365 — not the 1.29 a naive `Spell.dbc` `EffectBasePoints` read would give (`4`/`29`, missing the `DieSides == 1` roll's `+1`); 800 (base) -> 1091-1092 measured in two independent runs, both `ok` |
| Chastise 503141 | oath_consumption (`oath_spell: 804904`) | "Consumes your Oaths, dealing additional damage for each consumed." | ratio 1.365 | same mechanism and ground-truthed ratio as Righteous Upheaval; `ok` in both runs |
| Benediction 578276 | oath_consumption (`oath_spell: 804904`) | "Consumes your Oaths, dealing additional healing for each consumed." | ratio 1.365 | same mechanism, the healing side (`Unit::SpellHealingBonusDone`, the same `SPELLMOD_DAMAGE` op list); `ok` in both runs |
| Blade of Faith 803872 | oath_consumption (`oath_spell: 804903`, `periodic: true`) | "Consumes your Oaths, dealing additional damage for each consumed." | flat +25 | 803872 is a periodic-damage spell, so its formula reads `SPELLMOD_DOT` instead of `SPELLMOD_DAMAGE`; only 804903 ("Oath: Holy Cleave") carries a `SPELLMOD_DOT`-keyed `ADD_FLAT_MODIFIER` effect matching 803872's `SpellFamilyFlags[1]` bit 2048 (the other 4 Oaths' matching effect is `SPELLMOD_DAMAGE`-keyed, never consulted by a DOT formula read); ground-truthed with `spell_modifier` (base 1000, op 22): 1000 -> 1025 exactly; `ok` in both runs, independent of the open dot-overshoot question (`round10/questions-judging.md`), which concerns 803872's own base `periodic_total` value, not this Oath delta |
| Reckoning 805421 (`trigger_spell: 572741`, its max rank) | oath_consumption (`oath_spell: 804904`) | "Consumes your Oaths, dealing additional damage for each consumed." | ratio 1.365 | same mechanism and ground-truthed ratio as Righteous Upheaval, proven via 805421's own max castable rank, 572741, the same spell the class file's existing headline-damage checks for this clause already use; `ok` in both runs |
| Righteous Tempest 805409 | oath_consumption_removal (`oath_spells: [804904, 804922]`) | "Consumes your Oaths, dealing additional damage for each consumed." | `aura_script_value` == summed `aura_amount` (both Oaths read 30 each, ground-truthed live, not hand-derived) | `aura_ascension_templar_lifecycle::Calculate` bakes the sum of the two fixtured Oaths' own `EFFECT_2` `aura_amount` into 805409's own aura `SetScriptValue(805409, ...)` at cast time; both Oaths' `aura_stacks` still read 1 immediately after the cast (not consumed by casting) and 0 once the aura expires naturally 3000 ms later plus margin (consumed only by `::Remove`); `ok` in both runs |
| Disciplined Blows 680397 | internal_cooldown_gate (`trigger_spell: 578276`, `internal_cooldown_ms: 500`) | "Cnly occur once every 0.5 sec." | no new event 250 ms after the first fire, exactly 1 new event 750 ms after that | `AscensionTemplarEvents.cpp:74-76,157-159`'s `State(player).cooldowns` timer, not `spell_proc.Cooldown`; `ok` in both runs |
| Untainted 705298 | internal_cooldown_gate (`trigger_spell: 803792`, `internal_cooldown_ms: 15000`, `restore_charges: true`) | "Can only occur every 15 sec." | no new event 7500 ms after the first fire, exactly 1 new event 8000 ms after that | same `State(player).cooldowns` timer mechanism; 803792's own `SPELL_EFFECT_CHARGE` pulls the caster to melee range of the ally on every successful cast, so `icd_gate_attempt_fixtures` relocates the caster +10 yd before every attempt (not once), matching the 5-30 yd range its `SpellRange.dbc` entry needs; a first attempt without the per-attempt relocate measured two real `SPELL_FAILED_TOO_CLOSE` cast failures; `ok` in both runs |
| Scarlet Champion 805415 | internal_cooldown_gate (`trigger_spell: 807268`, `internal_cooldown_ms: 1000`, `force_crit: melee`) | "Can only occur once per sec." | no new event 500 ms after the first fire, exactly 1 new event 1000 ms after that | same `State(player).cooldowns` timer mechanism; `ok` in both runs |
| Temple Guardian 803792 | charge_recharge | "3 Charges, 35 sec recharge" | 3 charges, 35000 ms recharge | round10 `formula-value-scaling`: Spell.dbc's own charge fields for 803792 are all zero (`ProcCharges`/`RecoveryTime`/`Category`, `coa-dbc-viewer record --table Spell --id 803792`); the real numbers come from `SpellCharges.dbc` (`Spell=803792 -> Category=251`) and `SpellChargesCategory.dbc` (`ID=251, MaxCharges=3, RecoveryTime=35000`), applied to `SpellInfo` by `ApplyClientSpellCharges` (`AscensionClassMechanics.cpp:1082-1096`), called unconditionally for every spell — a class-agnostic native system, no Templar script involved. Target `"ally"` reuses the same relocate-and-charge fixture the existing 804571/705256/705298 trigger entries above already exercise on this same spell (803792's effect 0 is `SPELL_EFFECT_CHARGE`) |
| Titanstrike 806521 | cast_gate | "Only usable on enemies below 35% health." | refused (111) above the gate, succeeds below it | `SpellInfo::CheckTarget` (`SpellInfo.cpp` ~2135-2141) returns `SPELL_FAILED_TARGET_AURASTATE` when the target lacks `AuraStateType(TargetAuraState)`; 806521's own `TargetAuraState` (DBC field) is 13 (`AURA_STATE_HEALTHLESS_35_PERCENT`), the same state `values.py`'s `required_target_health_steps` already fixtures to 30% for the unrelated `effect_value` scenario, which never itself asserted the gate refuses a higher-health target |
| Testament of Strength 300514 (`bypass_spell` of the Titanstrike entry above) | cast_gate | "are usable regardless of your target's health percentage," | succeeds at full target health once 300514 is cast | `Unit::HasAuraState` (`Unit.cpp` ~8522) checks `Caster->GetAuraEffectsByType(SPELL_AURA_ABILITY_IGNORE_AURASTATE)` before consulting the target's own state, returning `true` (gate satisfied) for any matching effect whose `IsAffectedOnSpell(spellProto)` holds, regardless of the target; 300514's own effect 2 (`EffectApplyAuraName[2]` 262, `SPELL_AURA_ABILITY_IGNORE_AURASTATE`) is exactly this bypass, scoped to Titanstrike by its own `EffectSpellClassMask`. No CoA-specific code is involved; this is the stock engine path |

The 10-yard and 8-yard fixture radii above are both read from server source, never guessed, per each entry's own
`radius_reason`.

Measured on 2026-11-09 (simulated clock, `coa-verify --ram`, exploratory native execution of each scenario alone,
not combined verification): Blessing of Aggramar 300502 `ok` (without the passive, 25991 ms before the breaker
cast and 25979 ms after, continuing to decay; with it learned, 21955 ms before and 30000 ms after, exactly its own
full duration); Warrior of Tyr 301253 `ok` (0 Energy before the learn, 10 after, exact). Blessing of Aggramar's
breaker spell Righteous Upheaval 501562 needs the alternate one-handed weapon (`EquippedItemSubClassMask` 41105
excludes the reference Walking Stick's subclass 10, the same exclusion the hit-scenario machinery already
documents for Vindication 573324): the first pass of this scenario, equipping only the reference weapon, measured
the breaker cast failing with `SPELL_FAILED_EQUIPPED_ITEM_CLASS` (29) every time, so `duration_refresh_scenario`
arms the whole scenario with `armed_for(class_file, records, breaker_spell)` (both 803872 and 501562 accept the
alternate weapon's subclass 4, confirmed by DBC read, so one weapon serves the whole scenario). Warrior of Tyr's
first pass (without `disable_regeneration`) measured Energy regenerating roughly 10/sec of real time during the
3300 ms wait (33 before the learn, 43 after — the +10 delta already correct, but the absolute reads this check's
exact-equality judge needs were not), matching standard Energy regen and the same contamination the issue
scenario `templar-5163-warrior-of-tyr-energy-generation.json` avoids with its own `allow_regeneration: false`
player fixture field; `metric_delta`'s new `disable_regeneration` field reuses that same harness field.

Measured on 2026-11-09 (round4 `scripted-script-aura`, simulated clock, `coa-verify --ram`, exploratory native
execution of each scenario alone, not combined verification): Sacred Resistance 301309 `ok` (aura 680870 read 0
before learning 301309, 1 after, exact); Keeping the Oath 92109 `ok` (aura 704576 read 0 before learning 92109 —
the Reckoning cast cleared the fresh Oath Chain, as Breaker spells do by default — and 1 after, exact: with 92109
known the clear is skipped and the freshly re-granted Oath Chain survives the cast). Both reuse Reckoning's max
rank 572741 as `trigger_spell`, which satisfies `Breaker(info)` through its own `SpellFamilyFlags[2]` bit 128, not
through `Named(info, 805409)` (Righteous Tempest, which the code exempts from clearing Oaths regardless of 92109),
so the scenario exercises the 92109 gate itself rather than that unrelated exemption.

