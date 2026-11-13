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
| `behaviour_cast_condition` (`kind: "cast_state"`) | "Usable while feared."-shaped claims: a spell allowed in a caster state that refuses a control spell |
| `behaviour_immunity` (`kind: "immunity"`) | "granting immunity to fear ... effects": each named effect lands before the cast and none lands after it |
| `behaviour_threat_slope` (`kind: "threat_slope"`) | "High Threat" damage: threat per point of damage of one landed hit, the flat `SPELL_EFFECT_THREAT` amount taken out |
| `behaviour_event_delay` (`kind: "event_delay"`) | "After a short delay": the time from a cast to the delayed cast of another spell, read from event stamps |
| `behaviour_dispel_count` (`kind: "dispel_count"`) | a cast that dispels a stated number of effects per dispel type from an ally, counted per cast against a control arm |
| `behaviour_metric_delta` (`kind: "dispel_removal"`) | a dispel/cleanse active that removes a named debuff aura from a target (self or a grouped ally) the moment it is cast, read as the generic `aura` metric going from present to absent |
| `behaviour_metric_delta` (`kind: "aura_presence"`) | an active that grants an arbitrary metric's "present" state (an aura, a water-walk flag, ...) on a target (self or a grouped ally) the moment it is cast, read going from absent to present |
| `behaviour_taken_hit` (`kind: "taken_hit"`) | a hit the caster takes: a striker's fixed-damage spell, its absorbed amount, absorbed share or delayed debt read from the damage logs the caster receives |
| `behaviour_threat_redirect` (`kind: "threat_redirect"`) | "threat generated by your allies is redirected to you": the dummy's threat on a grouped ally and on the caster around the ally's attack |
| `hit_mean` (`kind: "script_hit"`) | the amount of a hit a class script casts on an event, read from the tooltip of the spell that states it, with a control arm that counts no hit |
| `behaviour_immunity` (`kind: "charm_immunity"`) | immunity to a charm: a real charm cast by the dummy at the caster, without and with the immunity, read inside the charm, removed and cleaned up after each read |
| `behaviour_taken_outcome` (`kind: "taken_outcome"`) | a changed chance of an outcome of melee attacks the caster takes ("your chance to parry is increased by"): the outcome rate of incoming swings with and without an aura |

Every `Expectation.rule` of these checks starts with the literal prefix `prose: ` followed by the quoted
`Description[enUS]` fragment that states the number, e.g.
`prose: "strikes 2 additional enemies near the primary target" (525024)`. This is the one thing that must never be
skipped: it is what keeps a behaviour `ok` honestly distinguishable from a token `ok` if anyone audits later.

| Field | Content |
|---|---|
| `spell`, `name` | the passive and its `SpellName[enUS]` |
| `kind` | `count`, `ratio`, `duration`, `duration_ratio`, `duration_refresh`, `trigger`, `spread`, `metric_delta`, `health_ratio`, `crit_guarantee`, `aura_grant`, `oath_consumption`, `oath_consumption_removal`, `cast_gate`, `cast_condition`, `dispel_removal` or `aura_presence`: which scenario builder and judge rule apply |
| `quote` | the exact prose fragment of `Description[enUS]`, checked to be a substring at generation time |
| `expected` | the number, ratio or duration the quote states (not used by `health_ratio`, which states its ratios in `levels` instead, one per health percentage, or by `duration`, which states its milliseconds in `expected_ms` instead) |
| `variant` | optional; disambiguates the generated manifest key (`conformance.add_behaviour`) when a class legitimately needs more than one `behaviours` entry on the same `spell` id, e.g. a tooltip that makes two independently checkable claims about the same passive (magnitude, then an interaction with another buff). Defaults to `''`, which reproduces the pre-`variant` key exactly, so every existing entry is unaffected. |
| `gameplay_clock` | `dispel_removal` only, optional, `'real'` when set; omit for a clause with no clock dependency. Threaded into every `Expectation.model` the entry builds; `compare.judge_expectation` reports `unmeasured` instead of judging the measured values when the recorded run's own clock (read from the case's `summary.json`) does not match, so a default simulated-clock run of a clock-sensitive clause (ADR 0060) is never mistaken for a regression of a real-clock-confirmed `ok`. Conformance scenarios are always exploratory files, so `batch.py --real-pace-rerun` never reaches them; `--gameplay-clock real` for the whole run is the only way to exercise such a clause. |
| kind-specific fields | `count`: `target_rank` (the active spell cast), `radius` and `radius_reason` (the source citation that grounds the fixture placement, never a guessed distance), `metric` (`spell_damage_count`, the default, for a spell with a school-damage effect, or `aura` for a spell whose own effect is not damage, such as a silence); `ratio`: `targets`, a list of `[rank_id, name]` pairs; `spread`: `seed_spell` (cast on the primary dummy to install the aura the passive must copy), `aura_spell` (the aura id measured on every extra dummy), `target_rank` (the active whose damage triggers the copy), `radius`/`radius_reason`; `trigger`: `shield_aura` (the absorb aura that must be fully consumed), `trigger_spell` (the spell the break casts), `breaker_spell` (a spell of the absorb's own school that the striker casts directly at the caster to deplete it deterministically), `striker_entry` (a creature template entry to cast it from), `break_timeout_ms` (how long to wait for the aura to clear once the breaker spell lands, default 3000); `metric_delta`: `trigger_spell` (the active spell cast to create the measurable state, learned once up front since it is not otherwise granted to the reference character), `metric`/`fields` (the harness metric and its query fields, e.g. `owned_creature_count`/`{"entry": ...}`, `aura_amount`/`{"spell": ..., "effect": ...}` or `power`/`{"power": <type>}`), `before_expected` (the DBC-derived baseline value asserted on the "before" measurement), `wait_ms` (settle time after the cast before measuring, default 3000), `expire_ms` (wait after the learn before the second cast, long enough for the first cast's effect to fully expire so it cannot contaminate the second measurement, default 20500), `target` (`"caster"`, the default, or `"dummy"` for a trigger spell that needs a hostile target, such as a periodic-damage spell; adds the stock creature fixture only when set to `"dummy"`), `disable_regeneration` (default `false`; `true` sets `allow_regeneration: false` on the player fixture, for a `power` metric whose resource type regenerates on its own — a resource pool's passive regen (confirmed empirically: Energy regenerated ~10/sec of real time during the cast-and-wait window, contaminating both the "before" and "after" absolute reads by the same roughly-equal amount, even though it cancels out of the delta) would otherwise make the check's required exact-equality baseline nondeterministic, since the exact regen gained during a fixed wait is itself a live-timing read, not a DBC-derived constant); `setup_casts` (default `()`, an empty tuple reproduces every existing entry's generated scenario byte-for-byte): spell ids cast at `target` immediately before each timed `trigger_spell` cast, in both phases, each preceded by its own power/cooldown/`required_aura_steps` fixtures exactly as `trigger_spell` itself gets them, with `trigger_spell`'s own power re-asserted afterwards so a setup cast's cost never starves the timed cast that follows it — for a passive whose condition needs a second, independent spell's effect already present on the target when `trigger_spell` is cast (Transcending Strikes 804897 needs the caster's own Blade of Faith 803872 on the target before Divine Force 806153 is cast); setup_only_after` (default `false`, omitting it reproduces every existing entry's generated scenario byte-for-byte): when `true`, the gate spell (`gate_spell` or `spell`) is learned once at the very start instead of between phases, and `setup_casts` are cast only in the "after" phase, never the "before" one — for a clause whose trigger spell's effect is gated on a *second*, independent condition (a target's own debuff) rather than on the passive itself, so the passive must stay known throughout while the other condition is the one phase-dependent variable (Transcending Strikes 804897's "target_gate" variant: 804897 known in both phases, Blade of Faith 803872 withheld from the dummy in the first phase and cast on it in the second, isolating the clause's "when used on enemies affected by Blade of Faith" half from the already-proven "while 804897 is known" half); requires a non-empty `setup_casts` (ADR 0058); `setup_wait_ms` (default 0, which adds no step): a wait after each setup cast, for setup casts of one spell that the global cooldown would otherwise refuse (Tyr's Blessing 705285: four Condemn 804906 casts 1500 ms apart before the timed fifth, ADR 0144); `setup_actor_aura` (default `None`, omitting it reproduces every existing entry's generated scenario byte-for-byte): a spell id applied to the caster with the existing `set_aura` action (1 stack) at the very start of each `cast_steps()` call, in both the "before" and "after" phase, for a passive whose tooltip claims an interaction with a second, independently-learnable buff that must already be present when `trigger_spell` is cast and stay present through the wait (Whirling Tempest 300504's "stacks with Courage" clause needs Courage 707754 active in both phases so the delta reflects the two auras together, not 300504 alone); `cast_in_before` (default `true`, omitting it reproduces every pre-round10 entry's generated scenario byte-for-byte): `false` skips the "before" phase's own `reset_cooldown`/mana-fixture/`cast`/`wait` steps (while still applying `setup_actor_aura`), for a `trigger_spell == spell` entry whose own cast is what the clause measures, so the baseline must not already include it (Crusader's Presence 562302's mounted-speed clause: the "before" reading is the mount alone, the "after" reading is the mount plus an actual 562302 cast); `gate_spell` (default `None`, omitting it reproduces every existing entry's generated scenario byte-for-byte): learned between the "before" and "after" cast in place of `spell`, for a passive that is never itself learnable because the server only ever casts it internally on another aura's apply hook, so the real known/unknown toggle belongs to a different, parent spell (Whirling Tempest 301340's own slow immunity is gated on `player->HasAura(300504)`, the parent passive, not on 301340 itself being learned); `duration_refresh`: `target_aura` (the aura whose `aura_duration_ms` is read before and after the breaker cast), `gating_aura`/`gating_stacks` (the stack-gated aura and the stack count the breaker's own code checks, held fixed in both phases since the passive's presence is the axis under test here, not the stack threshold), `apply_spell` (cast at the creature fixture to apply `target_aura`), `breaker_spell` (cast afterwards; refreshes `target_aura` only when the passive is known and `gating_aura` has at least `gating_stacks`), `decay_ms` (wait between the apply and the breaker cast, default 4000), `refresh_margin_ms` (how close to the DBC's own full duration the "with" phase's refreshed reading must land, default 500); `health_ratio`: `probe_spell` (a magic-school spell not exempted from damage-taken modifiers, fed to `script_spell_damage_taken` as a stand-in hit), `levels` (a list of `[health_pct, expected_ratio]` pairs, one `Expectation` per pair); `duration`: `target_aura` (the aura whose `aura_duration_ms` is read before and after one forced melee crit), `expected_ms` (the milliseconds the quote states, added on top of the one swing interval that elapses naturally), `debt_aura` (the real absorb aura that must carry a nonzero debt amount before the crit, so the forcing fixture exercises the real damage-absorb hook instead of a bare `set_aura`), `breaker_spell`/`striker_entry` (the spell and creature template entry that deplete `debt_aura` deterministically before the measured crit), `mechanism_file`/`override_file`/`reduce_function` (free text naming the server source file that resets the duration, the file that overrides the aura's periodic base points, and the function whose early-removal branch the debt fixture must avoid triggering for the wrong reason — generated into the scenario's own `contract` field, so each class supplies its own instead of the builder hardcoding one class's names); `duration_ratio`: `vehicle_spell` (a stock, non-class spell whose own mechanic the passive's `SPELL_AURA_MECHANIC_DURATION_MOD` effect targets, cast by a striker at the caster once before and once after the passive is learned), `striker_entry` (a creature template entry, default 36); `crit_guarantee`: `trial_spell` (the spell whose landed hits are measured), `target_entry` (a `creature_template` entry of the claimed type, overriding the shared dummy), `target_type`/`target_type_name` (the `creature_template.type` value and its name, both documentation only — never read back by the code, so a mismatch cannot silently pass), `attempts` (auto-attack swings, default 100), `minimum_events` (default 5; fewer triggered hits of `trial_spell` than this reports `insufficient_trials` instead of judging a ratio); `aura_grant`: `trigger_spell` (the ability cast once), `oath_aura` (the specific aura it must apply, read via the `aura` metric after the cast), `chain_aura` (the stacking aura whose `aura_stacks` is read before and after the cast, default 704576, the Templar's Oath Chain); `oath_consumption`: `trigger_spell` (the Breaker ability cast once to prove consumption), `oath_spell` (the Oath aura fixtured to 1 stack with `set_aura`, no cast, between the "before" and "after" formula reads), `relation` (`"ratio"`, for a `SPELLMOD_PCT` modifier, multiplying the "before" reading, or `"flat"`, for a `SPELLMOD_FLAT` one, added to it), `expected` (the ratio or flat delta the Oath's own registered `Player::m_spellMods` entry/entries produce — ground-truthed with the harness's own `spell_modifier` metric, base 1000, against the live op, never hand-derived from raw `Spell.dbc` `EffectBasePoints`, since `SpellEffectInfo::CalcValue`'s `DieSides == 1` roll adds +1, not +0), `metric` (`"spell_damage_done"` or `"spell_healing_done"`), `effect` (the formula's own effect index, default 0), `periodic` (default `false`; `true` reads the formula's `DOT`/`SPELLMOD_DOT` path instead of the direct-damage/`SPELLMOD_DAMAGE` one, for a spell whose own effect is `SPELL_AURA_PERIODIC_DAMAGE`), `target` (default `"dummy"`; `"caster"` for a self-targeted heal); `oath_consumption_removal`: `trigger_spell` (the ability cast once, whose own aura both bakes the bonus and later removes the Oaths), `oath_spells` (a list of Oath aura ids fixtured to 1 stack each with `set_aura`, no cast, before the trigger is cast; more than one proves "for each consumed" sums across different Oath types rather than special-casing a single id), `oath_effect` (the Oath's own `AuraEffect` index summed by the trigger's script, default 2), `settle_ms` (wait after the cast before reading the trigger's own `aura_script_value` and the Oaths' `aura_stacks`, default 500, kept well inside the trigger's own DBC duration), `expire_margin_ms` (added on top of the trigger's own remaining duration before the final `aura_stacks` read, so the wait reliably outlasts natural expiry, default 1500); `cast_gate`: `bypass_spell`/`bypass_name`/`bypass_quote` (a second spell cast on the caster between the "blocked" and "allowed" attempts, whose own tooltip clause is proven by a third attempt made with it active and the target fixture untouched); `cast_condition`: `condition` (`"outdoors"` or `"mounted"`, which caster-state setup pair to apply) and `blocked_result` (the `SpellCastResult` the quote's restriction is expected to fail with when the condition is unmet); `cast_combat`: no extra fields beyond `spell`/`name`/`quote` - the setup (attack a dummy, kill the ally fixture) is fixed, since the only modelled shape so far is a spell whose only effect targets a dead ally |

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
repeats the casts and the measurement. The scenario offers `expected + 1` extra dummies inside the radius
(`behaviours.COUNT_HEADROOM`, model `headroom` 1), so a server that reaches one target too many is seen. The judge
(`compare.behaviour_count_verdict`) counts, among the extra dummies only, how many were hit before the learn and
how many were newly hit after (`after - before > 0`), then compares that count with `expected` exactly
(`compare.exact_count_verdict`, ADR 0124): one target too few or too many is an `alert`; `unmeasured` when an extra
dummy was already hit before the learn (the before phase is the negative arm), since the delta cannot then be
isolated. For a `spell_damage_count` entry the judged phase also reads every dummy after every cast (model
`per_cast`); the judge then counts, for each cast that hit the primary dummy, the extra dummies that cast hit, and
judges the widest cast (`compare.per_cast_count_verdict`), since a melee chain's in-front filter or an aura the
casts themselves grant can move the targets between casts. A `fixed_count` entry (Holy Cleave 573049) names
`clear_auras`, set to 0 stacks before every cast: Holy Cleave's own Oath 804903 adds a jump target
(`SPELLMOD_JUMP_TARGETS`) to the next cast, which the per-cast reads showed as [1, 2] before the Oath was cleared.
A matching count from a scenario without a candidate beyond the stated number (model `headroom` 0 or absent) is
`insufficient_trials`: a server reaching more would read the same. An ally-heal-breadth entry
(`kind: "ally_heal_breadth"`) states every offered ally (model `all_offered`), so its match is judged.

A `fixed_count` entry may set `pull_reads`: every dummy's `distance_2d` to the caster is read before the casts and
after them, and the verdict is an `alert` unless each dummy inside the radius ends at least 1 yd closer and the one
beyond it moves less than 0.5 yd (ADR 0186). Templar Rituals 520534 pulls the dummies at 3.75, 7.5 and 11.25 yd to
0, 0 and 1.23 yd, and leaves the one at 20 yd in place, after one Righteous Tempest.

`cast_power` (on `hit_ratio`, `taken_hit` and `metric_delta`) sets the caster's power to that value before each cast
in place of the plain cost, for a channel that also drains power per second (ADR 0187): at exactly its 15 cost,
Testament of Fortitude 500678 ends at its first drain and never heals. With 100 Energy its heal reads 5% of the maximum
health (108 of 2173, 217 under +100% health), its first tick lands between 950 and 1050 ms, and a Holy strike under it
reads 550 against 1100.

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
`compare.behaviour_count_verdict` judges it: `alert` on a count other than `expected` (the absent-effect case this
check exists to catch), `unmeasured` when an extra dummy already carries the aura before the passive is learned.
The scenario offers no dummy beyond `expected` (model `headroom` 0): `SpreadCondemn` copies Condemn to the next
dummy not yet afflicted on every Righteous Tempest hit, so a further dummy would also be afflicted by a correct
server over one cast. A matching count is therefore `insufficient_trials`, not `ok`, until a scenario can show
that one extra dummy stays clear.

`first_tick: true` reads the spread after one damaging hit instead (ADR 0150). Each phase seeds once, casts
`target_rank` once and reads every extra dummy half a period after its first tick, before the second; the before
phase then waits out the periodic buff, so no tick of its cast reaches the after phase. The scenario offers
`expected + 1` extra dummies (model `headroom` 1), all placed beyond the reach of the periodic trigger's own radius
(`SPREAD_CLEARANCE_YD` past it) and within `radius` of the primary dummy, so only the primary is hit and every
copy comes from its hit: one copy on one of two dummies is `ok`, a copy on both is an `alert`. Holy Tempest 301339
reads 1 of 2 after the first tick of Righteous Tempest 807274 (570205, 5 yd).

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
damage logs of real hits, which do need a tolerance band. (`melee_damage_taken`/`spell_damage_taken` are not such
logs: they return the damage-taken calculation of a fixed 1000 with no hit, so they are readbacks, ADR 0153.)
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

`cast_in_before` (round10, ADR 0052; default `true`, omitting it reproduces every pre-round10 entry's generated
scenario byte-for-byte) controls whether the "before" phase's `cast_steps()` call casts `trigger_spell` at all.
Every entry above this field's introduction has `trigger_spell != spec.spell`: a separate active spell whose
*own* effect a known/unknown passive changes, so casting it in both phases is required to observe that
difference. `trigger_spell == spec.spell` is also valid (an active spell whose own cast is what the clause
measures, already castable on its own without a parent passive) but then casting it in the "before" phase
would already include the effect under test, leaving no ungated baseline; `cast_in_before: false` skips the
`reset_cooldown`/mana-fixture/`cast`/`wait` steps for that one phase while still applying `setup_actor_aura`
(so a caster-state precondition like being mounted is still set up), and the "after" phase casts normally.

The caster is armed for `trigger_spell` (`values.armed_for`): a trigger that needs another weapon class than the
reference weapon gets the class file's matching alternate (Divine Fury 500689, a one-hand weapon).

`attack_swings` (default 0, omitting it reproduces every existing entry's generated scenario byte-for-byte) replaces
the cast with auto attacks at the dummy, for a passive whose trigger is a swing: each phase attacks for
`attack_swings` reference swing intervals and stops before its reading, the gate is learned between the phases, and
`trigger_spell` names the observed spell without being cast. It requires `target: "dummy"` and the default
`gate_timing`, and refuses `setup_casts`, `setup_actor_aura` and `trigger_only_after`. `force_crit` (`melee` or
`spell`) sets the forced crit rating on the caster, as the trigger entries do. The scenario's `timeout_ms` is its
summed waits plus the 60 s margin. Parry Dance 804912 uses it to read the `aura_stacks` of 560651 after ten
forced-crit swings: 0 without the passive, the cap of 5 with it.

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

The `oath_consumption` reads are computed formula calls with no hit applied, so they are readbacks (the internal
damage read ruling of 2026-11-11). "Dealing additional damage/healing for each consumed" is proven by a `hit_ratio`
entry, `variant` and `label_suffix` `oaths`: the Breaker's level 60 rank is cast at the dummy (or Benediction at the
ally, `metric: "spell_heal_total"`), with no Oath in the control arm and two distinct Oaths set before every
treatment cast, 804904 (Righteous Lunge, +5% and +30%) and 804922 (Condemn, +30%), whose `SPELLMOD_DAMAGE` effects
carry the Breaker mask (`EffectSpellClassMask` word 2 bit 128). The percent mods multiply, so the stated ratio is
1.05 x 1.30 x 1.30 = 1.7745; one Oath's 1.365 or an additive 1.65 lies outside the band. A Holy Breaker sets 823764
in both arms, a stat fixture makes the scaled term dominate the die, and only non-critical hits count. The ledger
row keeps the `oath_consumption` label beside the hit ratio, because its stacks read after a real cast proves the
removal. Reckoning 805421 (572741) and Benediction 578276 read +77.3% and +77.45% (`20261111-221450`).

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

### Cast-condition scenarios (`behaviour_cast_condition`, `kind: "cast_condition"`)

Some tooltips state a castability condition on the *caster*'s own transient state rather than the target's
health: "Can only be used outdoors." or "Can only be used while Mounted." `cast_condition_scenario` attempts the
gated `spell` on itself twice, `reset_cooldown` and a fresh `set_power` before each attempt: once with the
condition deliberately unmet (expecting refusal with `blocked_result`), once with it met (expecting
`NO_CAST_FAILURE`, 0). Two conditions are modelled: `"outdoors"` teleports the caster between a known indoor
location and a known outdoor one (the same pair already proven in
`scenarios/reaper-ghost-form-indoor-corpse-reclaim-6437.json`, map 0, Firebrew Inn indoor at
`(-4840.67, -857.094, 501.997)` versus open-world outdoor at `(-9617.06, -288.949, 57.3053)`), each followed by a
2000 ms settle wait before the attempt; `"mounted"` applies or removes a generic ground-mount fixture aura
(458, Brown Horse, confirmed `SPELL_AURA_MOUNTED` in Spell.dbc effect 0) directly through the existing
`set_aura` action, independent of any class-specific mount ability.

The judge reuses `compare.behaviour_cast_gate_verdict` unchanged (the same exact `cast_failure`-vs-reason-code
comparison `cast_gate` uses): `ok` only when the measured reason matches exactly, `alert` otherwise, including a
"blocked" attempt that actually went through or an "allowed" attempt still refused.

### Cast-combat scenarios (`behaviour_cast_combat`, `kind: "cast_combat"`)

Some tooltips state the opposite of a castability restriction: that the spell works even in a state that, for a
sibling spell of the same shape, would normally block it. "Usable while in combat." on a spell whose only effect
is `SPELL_EFFECT_RESURRECT` is this shape: a stock resurrection spell (e.g. Redemption 7328) carries
`SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL`, which the engine's own `CheckCasterAuras` path refuses with
`SPELL_FAILED_AFFECTING_COMBAT` whenever `caster->IsInCombat()`; the clause states this spell carries no such
restriction. `cast_combat_scenario` has the caster attack the stock `dummy` fixture (a real `CMSG_ATTACKSWING`,
so `Unit::IsInCombat()` - the harness's own `combat` metric - reads true, not a scripted shortcut), kills the
`ALLY` player fixture (`die`, the same dead-ally shape the generic rank scenario already proves for any
`targets_resurrect()` spell) and casts `spell` at `ALLY` while still fighting the dummy. Two measurements prove
the clause together, not one: `combat` (must read 1 - without this, a broken fixture that never actually entered
combat would let the cast "succeed" for the wrong reason, proving nothing) and `cast_failure` (must read
`NO_CAST_FAILURE`, 0).

The judge reuses `compare.behaviour_cast_gate_verdict` unchanged for both measurements (it only compares a
measured value to the `Expectation.displayed` float, regardless of which metric produced it): `ok` only when
each measured value matches exactly, `alert` otherwise, including a fixture that never reached real combat or a
cast still refused while in it.

### Cast-state scenarios (`behaviour_cast_condition`, `kind: "cast_state"`)

"Usable while feared." states that a spell goes through in a caster state that refuses other spells.
`cast_state_scenario` has the dummy apply `state_aura` to the caster (`set_aura` with `caster: dummy`, so the
aura is applied by `AddAura` from a hostile unit), attempts `control_spell` on the caster (a spell of the class
without the allowing attribute: must be refused with `blocked_result`), reads `aura` of `state_aura` (must still be
1, so the state held at the attempt), then attempts `spell` on the caster (must read `NO_CAST_FAILURE`). The control
comes first because the spell under test may remove the state it is allowed in. The three readings are judged by
`compare.behaviour_cast_gate_verdict` (exact).

### Mount-block scenarios (`behaviour_cast_condition`, `kind: "mount_block"`, ADR 0202)

"preventing them from mounting" states that a unit holding `spell` cannot mount. `mount_block_scenario` teleports the
caster to the open-world outdoor site of the `cast_condition` kind (mounts are OUTDOORS_ONLY), learns `mount_spell`
(default Brown Horse 458, which must apply SPELL_AURA_MOUNTED), and sets `spell` on the caster with `set_aura`, cast by
the caster itself so that the aura's apply hooks run. It then attempts the mount: `<spell> mount_block <mount>
blocked` must read SPELL_FAILED_CASTER_AURASTATE (22) and `... unmounted` (the mount aura, after the cast time) 0.
`spell` is removed and the mount attempted again: `... allowed` reads 0 and `... mounted` 1, the control that the
mount works at this site. `spell` is then set again on the mounted caster: `... dismounted` must read 0. The five
readings are judged exactly (`compare.behaviour_cast_gate_verdict`).

### Flee-block scenarios (`behaviour_cast_condition`, `kind: "flee_block"`, ADR 0298)

"preventing them from fleeing" states that a creature holding `spell` does not flee at low health.
`flee_block_scenario` spawns two defensive (`reaction` 1) creatures of `creature_entry`, which must have a SmartAI
flee-for-assistance row at low health, with 1,000,000 health each. The caster casts `spell` at the first
(`<spell> flee_block <entry> cast` reads 0, `... branded` 1), attacks it for 1000 ms so that it takes the caster as its
victim (`Creature::DoFleeToGetAssistance` needs one), stops and brings it to `flee_health_pct` with `set_health_pct`.
`moving` is then read `reads` times, `read_interval_ms` apart: `... blocked` is their sum and must be 0, and
`... held` (the brand, after the reads) 1. The second creature goes through the same steps without the brand:
`... control` is the sum of its reads and must be at least 1. Sums are judged by
`compare.behaviour_cast_gate_verdict` (`sum_labels`, exact, or a floor with `at_least`).

### Immunity scenarios (`behaviour_immunity`, `kind: "immunity"`)

"granting immunity to fear, charm, and horrify effects" states that named effects no longer land. `effects` lists
one fixture spell per named word (`words` must appear in `quote`), each with a single aura effect, so an immune
effect leaves no aura behind. `immunity_scenario` applies each fixture from the dummy with `set_aura` and reads its
`aura` (must be 1: the caster is not immune by itself), removes it, casts `spell` on the caster (cast reads
`NO_CAST_FAILURE`, `aura` of `spell` reads 1), then has the dummy cast each fixture at the caster `IMMUNITY_CASTS`
(3) times, a real creature cast with `TRIGGERED_FULL_MASK`, and reads its `aura` (must be 0). An accepted cast
that never lands reads 0 as well, so the scenario then waits out `spell`'s DBC duration (`<spell> immunity <spell>
expired` reads 0) and has the same dummy cast each fixture the same way again: `<spell> immunity <effect> control`
must read 1, the proof that the cast route lands at all (ADR 0134; the shape of the catalog's
`runemaster-hurricane-fear-immunity-7716`). Each control aura is removed after its reading. The control runs after
the immune window, not before it, because a landed creature fear raises the player's diminishing-returns level and
would shorten later fears for a reason unrelated to the immunity. A named word without a fixture stays an unproven
claim of the ledger entry. Judged exactly (`compare.behaviour_immunity_verdict`).
`target: "ally"` (ADR 0204) makes the grouped ally the subject: the ally player is added and grouped, the fixtures are
set on and cast at the ally, `spell` is cast at the ally and every reading is the ally's (Testament of Will 801455,
TARGET_UNIT_TARGET_ALLY: a slow 35317 and a root 47021).

### Threat-slope scenarios (`behaviour_threat_slope`, `kind: "threat_slope"`)

"High Threat" damage carries no number in the tooltip; the owner set the expectation (2026-11-10: threat x2 on
damage, the flat +100 of `SPELL_EFFECT_THREAT` kept). `threat_slope_scenario` casts `hit_spell` once at a fresh
dummy and reads the dummy's `health` before and after and its `threat` on the caster. The judge
(`compare.behaviour_threat_slope_verdict`) takes the sum of the `SPELL_EFFECT_THREAT` (63) points of `hit_spell`
from the DBC as the flat part and computes `(threat - flat) / health lost`: `ok` within 0.001 of `expected_slope`,
`alert` outside, `unmeasured` when the cast failed or no health was lost. The verdict states the excluded slopes.

A `threat_slope` entry may name `flat_spells`, spells the hit triggers on the dummy whose `SPELL_EFFECT_THREAT` points
join the flat part, and the hit spell's `CasterAuraSpell` is set before its cast (ADR 0225). Sacred Swing 572769: the
slow 301061 it triggers adds a flat 50.

### Event-delay scenarios (`behaviour_event_delay`, `kind: "event_delay"`)

A spell whose effect casts another spell some time later (`SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED`, ADR 0144)
names `observe_spell`, the delayed spell, and `expected_ms`, the delay its own `Spell.dbc` points give.
`event_delay_scenario` casts `spell` at the dummy `trials` times (default 3), `wait_ms` apart (default 3000, which
must exceed `expected_ms`), resetting its cooldown and setting its power each time. After each cast it reads
`event_first_ms` of the `spell_damage` stream of `observe_spell` on the dummy twice: since the cast packet of
`spell`, and since the cast packet of `observe_spell` itself (its cast-to-hit time, such as a missile's travel), and
the cumulative `spell_damage_count`. The judge (`compare.behaviour_event_delay_verdict`) takes, per cast, the first
reading less the second: the time from the cast to the delayed cast. It is `ok` when every delay lies within
`max(5% of expected_ms, 50 ms)` (two 25 ms stamps) of `expected_ms`, and `alert` otherwise, or when a cast is not
followed by a stamped hit. The second stamp is the in-trial control: a first version that compared the hit with the
cast alone read Norgannon's Wrath's blast at 1628-1636 ms (`.cache/verify-all/20261111-142214`), its 1500 ms delay
plus the 125 ms flight of 524740 (`Speed` 30). An entry whose `observe_spell` is its own `spell` is refused.

### Proc-reset scenarios (`behaviour_proc_reset`, `kind: "proc_reset"`)

"Melee damage dealt now has a 10% chance to reset the cooldown and reduce the Energy cost of your next Argent Blade by
50%" states two outcomes of one chance roll. `proc_reset_scenario` casts `reset_spell` `baseline_trials` (20) times
without the passive and `trials` (100) times with it, each time from a reset cooldown and twice its power cost
(regeneration off), one cast per `cast_interval`. After each cast it reads the spell's `cooldown_ms`, the power left
and the cumulative `spell_cast_count` of `marker_spell`, the spell the proc casts. A trial fired when its count rose.
The judge (`compare.behaviour_proc_reset_verdict`, ADR 0150) needs, in every trial, a fired trial to read no cooldown
and a quiet one the cooldown still running, and the cast right after a fired trial to cost the reduced amount
(`marker_spell`'s one `SPELLMOD_COST` percent modifier applied to the cost) and every other cast the full cost; a
fired trial without the passive is a fault too, so the 20 baseline casts are the control arm. Any fault is an
`alert`; fewer than `min_events` (3) fired, quiet or discounted trials is `insufficient_trials`. The reset spell's
cooldown must outlast the interval between trials, or the scenario is `NotModelled`. So is a `marker_spell`
without exactly one `SPELLMOD_COST` percent modifier: the cost half of the claim would go unjudged. The cooldown
read depends on
the engine sending the cooldown before the hits (`Spell::_cast`, Spell.cpp:4029 and :4134), so a proc on the cast's
own hit resets the cooldown that cast started.

### Aggro-redirect scenarios (`behaviour_aggro_redirect`, `kind: "aggro_redirect"`)

Some tooltips state that casting the spell makes one or more hostile creatures switch their current attack
target (their "victim") to the caster: "Taunt an enemy to attack you" (single target) and "Taunt all enemies
within $N yds" (self-centred area). `Spell::EffectTaunt`/`AuraEffect::HandleModTaunt` both no-op unless the
target already has a non-empty threat list, so each listed dummy fixture must genuinely be in combat with
another actor first. Every creature fixture elsewhere in this harness spawns `REACT_PASSIVE`, under which
`CreatureAI::UpdateVictim` unconditionally calls `AttackStop()` on any victim every AI tick (confirmed by two
independent gameplay runs before this kind existed, see ADR 0056); `aggro_redirect_scenario` instead spawns
each dummy `REACT_DEFENSIVE` (`AGGRO_REDIRECT_REACTION`), relocates the `ALLY` actor next to it (the dummy is
stationary, to keep its own distance from the caster — what an area clause's radius is judged against —
unchanged) and has `ALLY` really attack it for one swing interval before stopping; a `victim` reading before
the gated cast asserts this precondition itself (the dummy's own victim is really `ALLY`), and one after the
cast per dummy proves whether it switched to `CASTER`. A `self_cast: true` entry (an area clause) casts
`spell` with no explicit target; otherwise the cast targets the first listed dummy (a single-target clause).

The judge (`compare.behaviour_aggro_redirect_verdict`) is an exact 0/1 comparison of the measured `victim`
reading against `Expectation.displayed`: `ok` only when a dummy expected to redirect reads `1` and one
expected not to redirect reads `0`, `alert` otherwise.

### Mount-grant scenarios (`behaviour_mount_grant`, `kind: "mount_grant"`)

Some tooltips grant a mount to the caster *and* the caster's party, and separately claim the caster can keep
casting afterwards without losing it: "You and your party members leap upon a divine steed," and "While active,
casting does not dismount you or your allies." `mount_grant_scenario` groups the caster with a second player
actor (`ALLY`, `values.ALLY`) in range, then casts `spell` once and reads `mount_display_id`
(`Unit::GetMountID()`) on both actors (the `granted` moment). It then casts a second, unrelated `persist_spell`
on the caster and reads `mount_display_id` on both actors again (the `persisted` moment). Each moment produces
one `Expectation` whose model carries both actors' own measurement labels (`caster_label`/`ally_label`) rather
than a single label, since both actors must satisfy the same clause together.

The judge (`compare.behaviour_mount_grant_verdict`) reads both of a moment's labels and compares each to the
entry's own `mount_display_id` for exact equality (`FLOAT_EPSILON`): `ok` only when both the caster and the ally
read the expected display id, `alert` if either does not, with the explanation naming both readings.

A `dispel_removal` entry may list `arms` (`name`, `target` `ally` or `dummy`, `removed`, optional `away_yd`,
`refused` and `caster_removed`): each arm sets the debuffs on the caster and on its target, reads them, steps
`away_yd` back, casts the spell at the target, reads the cast's `cast_failure` (judged exactly against `refused`,
default 0) and the debuffs again (0 when `removed`, else 1), and steps forward again (ADR 0189). `caster_removed`,
when set, replaces `removed` for the caster's reads of that arm only (ADR 0291). Silverhand Incantation 801465 clears
Sacred Restraint 102208 from both on an ally, from the caster alone on the dummy (ADR 0292), and from neither when
refused out of range (97).

### Amount-match scenarios (`behaviour_amount_match`, `kind: "amount_match"`)

"For the same amount" compares two amounts of one cast (ADR 0200). `amount_match_scenario` casts `cast_spell` at
`cast_target` once per trial, with the entry's `auras` set before each cast, and after `wait_ms` reads the non-critical
total and count of two sides, `first` and `second` (`metric` `spell_damage_total` or `spell_heal_total`, `spell`,
`target` the dummy, the ally or the caster). The judge requires, in every trial with an event on both sides, per-event
amounts within `tolerance` (default 1) of each other; fewer than half the trials with both is `unmeasured`. Silverhand
Incantation 801465 reads 740 damage on the dummy and 740 heal on the grouped ally per cast.

### Aura-presence scenarios (`behaviour_metric_delta`, `kind: "aura_presence"`)

Some active spells grant a metric's "present" state to a target rather than remove one: a self-targeted area
aura that radiates to nearby party/raid members ("granting the ability to walk on water"), or any other active
whose effect a harness metric already reads as a 0/1 flag. `aura_presence_scenario` learns `spell`, groups the
caster with `target` first when `target` is not the caster (the `group` action, so a party/raid area aura
reaches the second player fixture), measures `metric`/`fields` on `target` ("before"), casts `spell` on the
caster and waits `wait_ms`, then measures the same metric again ("after"). The judge
(`compare.behaviour_metric_delta_verdict`, the same one `metric_delta` and `dispel_removal` use) requires the
"before" reading to match `before_expected` (0.0: the metric must be absent beforehand) and the "after" reading
to match `expected` (1.0: the metric must be present once the spell has had time to apply); `alert` on either
mismatch, including a target that already carried the metric before the cast (a fixture bug, not a server
proof) or one that never gains it.

### Heal-block scenarios (`behaviour_heal_block`, `kind: "heal_block"`)

Some active spells make a target unable to be healed for a condition the tooltip states (a creature type, in
Interdict's case). `heal_block_scenario` casts `spell` on a `creature_entry` fixture (an enemy-targeted, hostile
fixture, unlike `aura_presence`'s ally one), measuring the `aura` metric for `block_spell` (the DBC-confirmed
heal-block mechanism's own spell id) on that creature before the cast and `wait_ms` after. The judge
(`compare.behaviour_heal_block_verdict`) reuses `behaviour_metric_delta_verdict`'s exact-match pattern:
`blocked: true` expects the mechanism aura present (1.0) after the cast, `blocked: false` expects it to stay
absent (0.0); both expect 0.0 before the cast. A creature self-casting an actual heal spell was tried first and
found unreliable in this harness independent of Interdict or creature type (see ADR 0059); measuring the
mechanism's own aura, the same idiom `dispel_removal`/`aura_presence` already use, sidesteps that entirely.
Several entries for the same spell (one per creature type under test) are disambiguated by the class file's
own `variant` field, the same mechanism `whirling_tempest`'s existing multi-entry clauses already use.

### Group-stack-cap scenarios (`behaviour_group_stack_cap`, `kind: "group_stack_cap"`)

"Does not stack with similar effects": `group_stack_cap_scenario` reads `metric` with neither passive known, after
learning `spell` alone and after also learning `partner`. The judge expects the combined reading at the stronger of
the two percentages (`effect` of `spell`, `partner_effect` of `partner`, read from the DBC), times any uncapped
`personal_effect`. The stronger is the one of larger magnitude in the direction both move the metric
(`behaviours.strongest_percent`): +5% over +4%, and -10% over -6% for reductions, as the server keeps the highest
absolute amount of an exclusive spell group (`Unit::GetHighestExclusiveSameEffectSpellGroupValue`,
Unit.cpp:5312-5314) and the most negative amount of a capped negative aura type (`Unit::GetMaxNegativeAuraModifier`,
Unit.cpp:7107-7121). Two percentages of opposite signs are refused when the scenario is generated.

### Hit-ratio scenarios (`behaviour_hit_ratio`, `kind: "hit_ratio"`)

A percent bonus on the damage of one observed spell ("increases the damage of Chastise by 25% on enemies affected by
Tranquil Circle"): `hit_ratio_scenario` casts `observe_spell` at the dummy `trials` times in a control arm, then
`trials` times in a treatment arm, each arm with its own `auras` (`set_aura` before every trial) and `casts` (made
before every observed cast). It reads the cumulative `spell_damage_total` and `spell_damage_count` of the observed
spell at the dummy (`critical` filters hits) at the start of each arm and after every trial, so each trial gives
its own damage and hit count. `target_health_pct` holds the dummy at a health percent, `force_crit` forces melee or
spell crits, `learn` adds spells to learn, `label_suffix` names the label `<spell> behaviour_hit_ratio <suffix>`.
The trials must fit one scenario (`model.trial_limit`); a larger count is refused when the scenario is generated.
`cast_wait_ms` without a `cast_spell` (ADR 0203) waits that long after each cast of `observe_spell` itself, for an
observed spell whose hits are its own periodic ticks (Blade of Faith 803880, every 3000 ms: 3500 ms per trial).
`ally_distance` (ADR 0207) groups the ally with the caster and moves it that far before the trials, for an aura that
reaches party members within a radius; the ally must be the caster or the target (Fortified Body 300515: a self heal
of the ally at 30 yd and at 45 yd).

The judge (`compare.behaviour_hit_ratio_verdict`, rules in `bonus.py`, ADR 0125) computes each arm's mean per hit
and the variance of that mean from the trials (`bonus.per_event_sample`), the bonus `(treatment / control - 1) x
100` and its 99% Welch half-width in points (`bonus.bonus_of`). The bonus passes inside the band of the owner's
ruling of 2026-11-11, the larger of 5% of the stated bonus and 2 points (`bonus.bonus_band`: "+20%" passes from +18%
to +22%, "+100%" from +95% to +105%):

- `alert` when the 99% interval lies outside the band, whatever the trial count;
- `insufficient_trials` when the half-width is above half the band (power), with `trials_needed` per arm;
- `insufficient_trials` when the interval holds 0 against a nonzero stated bonus (negative arm: the treatment arm
  is not told apart from the control arm);
- otherwise `ok` inside the band, `alert` outside it. There is no `tolerated` status.

Every judged verdict states the interval it actually excludes: a true bonus below `stated - band - half` or above
`stated + band + half` reads `ok` with less than a 0.5% chance (`bonus.excluded_text`). `detail.sized_trials` is the
trial count whose half-width would be 0.8 of the power limit; the `prove` pilot (`pilot.hit_ratio_pilot`) runs the
hit-ratio entries at 20 trials, then generates the judged runs at that size, capped at the trial limit. Fewer hits
than half the trials in either arm is `unmeasured`.

The other ratio checks (`behaviour_ratio`, `behaviour_party_stat_ratio`, `behaviour_duration_ratio`,
`behaviour_metric_ratio_delta`, `behaviour_absorb_pierce_ratio`, `behaviour_group_stack_cap`,
`behaviour_crit_magnitude`) judge one reading each; their explanation and `detail.excluded` state the conformant
range they exclude outside (`compare.with_excluded_band`, the `tolerated` range included for `behaviour_ratio`),
without a sampling interval.

### Group-target scenarios (`behaviour_cast_condition`, `kind: "group_target"`)

"Place a blessing on a party or raid member" states who may receive a spell. `group_target_scenario` casts `spell` at
the `ally` player while it is ungrouped (`<spell> group_target outsider cast` must read `outsider_result`,
`SPELL_FAILED_BAD_TARGETS` 12 by default, and `outsider aura` 0), then groups it and casts again (`party cast` 0,
`party aura` 1), then, unless `raid` is false, adds three fillers and a fifth member, which converts the full party to
a raid (`group` action), and casts at that member (`raid cast` 0, `raid aura` 1). The outsider arm is the control:
the same cast refused without the group. Judged exactly (`compare.behaviour_cast_gate_verdict`).

### Cost-gate scenarios (`behaviour_cast_condition`, `kind: "cost_gate"`)

"Reduces the Energy cost of X by 5" and "Reduces the cooldown of X by 5 sec" state a reduction that decides whether
a cast goes through. `cost_gate_scenario` attempts `gated_spell` at the reduced level: `resource: "power"` sets the
caster's power to the reduced cost (rounded up; regeneration is off), `resource: "cooldown"` attempts it
`reduction` less than its cooldown plus `margin_ms` (500) after a priming cast. Arms, each with its own
`cast_failure` reading `<spell> cost_gate <gated>[ <label_suffix>] <arm>`:

- `without`: the talent unknown, refused (`SPELL_FAILED_NO_POWER` 85 or `SPELL_FAILED_NOT_READY` 67): the control;
- `with`: the talent learned (or `talent_aura` set, whose presence is then read before each talent arm's attempt as
  `<label> aura`, expected 1), goes through (0);
- `next` (`next_arm`): a second attempt right after `with`, without the `setup_casts`, refused: only the next cast
  is reduced;
- `beyond`: one power point below the reduced cost (two when the reduced cost is fractional), or `margin_ms` before
  the reduced cooldown, refused: the reduction is no larger than stated;
- `held` and `expired` (`aura_duration_ms`, power gates opened by `setup_casts` only): the attempt
  `duration_margin_ms` (300) before and after the stated end of the aura the setup cast grants, through and refused.

`setup_casts` (`[spell, target]` pairs) are cast before each arm's attempt, for a reduction granted by another cast
("Casting Benediction now reduces the cost of your next Temple Guardian"). A `target` of `ally` adds the ally
player, and the caster steps back `CHARGE_OFFSET_YD` before each attempt of a spell that closes the distance. A
reduction that leaves no level only it separates (`beyond` below 0, the reduced level at or above the base, or a
cooldown wait under the global cooldown) is `NotModelled`. Judged exactly (`compare.behaviour_cast_gate_verdict`).

`after_casts` (`[spell, target]` pairs, cooldown gates only) are cast `after_wait_ms` after the priming cast, each
after a reset of its own cooldown; the cooldown wait is shortened by the same `after_wait_ms`, so every arm is still
timed from the priming cast. An after cast that is the entry's own `spell` is cast and learned only in the arms with
it; every other after cast is learned at the start and cast in the `without` arm too, so the control differs from the
talent arms in the talent alone (Eternally Devoted 573452 casts Righteous Upheaval in all three arms). It is for an
active that cuts a running cooldown:
Profound Enlightenment 680953 "reducing the remaining cooldown of Testaments by $s1%" is cast 20000 ms after Testament
of Faith 801478, when 160000 ms remain, so `reduction` is 80000; a cut of half the full cooldown would let the
`beyond` attempt through. A power gate, or an `after_wait_ms` not below the `beyond` wait, is refused.

The `after_casts` spells are learned with the gated spell (One With The Light 504807: Righteous Upheaval 572027
after the priming cast of a Libram, Force of Golganneth, Divine Force or Testament of Will). `talent_aura_each_arm`
sets the `talent_aura` afresh (stacks 0, then 1) before every talent arm with a setup, for a buff shorter than the
cooldown wait (Libram of Zeal 801466, 20000 ms, gating Righteous Upheaval's 20000 ms cooldown).

`target_health_pct` (ADR 0205, the dummy only) sets the dummy to that percent of its health once before the arms, for a
gated spell with a target health aura state (Titanstrike 806521, below 20%, under Testament of Strength 300514).
`charges` (ADR 0211, a cooldown gate of a `talent_aura`) attempts the gated spell again after the `with` arm, at the
same wait and without a fresh aura or a cooldown reset: casts 3 to `charges + 1` go through and cast `charges + 2` is
refused (labels `... cast_<n>`; Testament of Strength's next 3 Titanstrikes).

A cooldown gate may wait up to the accelerated cap (`hits.MAX_ACCELERATED_SCENARIO_MS`, ADR 0152), as expiry
scenarios may; a power gate keeps the ten-minute budget. Eternally Devoted 573452 gates Libram of Tenacity 801461's
180000 ms cooldown and waits 549400 ms, so it runs only on the accelerated clock.

A power gate whose reduction leaves the cost at 0 ("free of cost") has no `beyond` arm: no level lies below 0 (ADR
0185). A setup cast at the `ally` adds the ally player whatever the entry's `target`; a setup cast that closes the
distance is preceded by the step back, and `restore_charges` restores its charges first. Determined 705256: Holy
Cleave 573049 at 0 Energy is refused without it, goes through after a Temple Guardian 803792, is refused on the next
attempt, and goes through 300 ms before and is refused 300 ms after the 5000 ms end.

A negative `reduction` on a cooldown gate states a longer cooldown ("and its cooldown by 5 sec", Patience 712678 on
Interdict 560116). The arms are then `without` (through `margin_ms` after the base cooldown, the control), `base`
(with the talent, refused at that same wait), `with` (through `margin_ms` after the lengthened cooldown) and `beyond`
(refused `margin_ms` before it). An increase not above twice `margin_ms` is `NotModelled`; next, duration and
after-cast arms are refused.

`resets: true` (cooldown gates with `after_casts` only) states a reset of the running cooldown: the two arms attempt
the gated spell `margin_ms` after the after casts, `without` refused (the control) and `with` through; there is no
`beyond` arm, since any later attempt goes through. Tome of Light 805422 resets Barrier of Light 805417
(`AscensionTemplarAuras.cpp:122-128`): Barrier is primed, Tome is cast 2000 ms later, Barrier is attempted at 2500 ms.

### Hit-ratio heals and actors

A `hit_ratio` entry may set `metric: "heal"` to read `spell_heal_total` and `spell_heal_count` instead of the damage
metrics, `caster` (default `caster`) for the player that casts the observed spell and takes the readings (the
harness reads a player's own heals), and `target` (default the dummy). An `ally` caster or target adds the ally
player. The arms' `auras` are still set on the caster, so a talent set in the treatment arm reaches healing done when
the caster heals and healing received when the ally heals the caster. The caster is armed for the observed rank
(`values.armed_for`), so a rank that needs a weapon class can be observed.
With a player `target`, `target_health_pct` sets that player to the percent of the fixture maximum before every
observed and warm-up heal instead of holding the dummy once, for a heal whose script only reacts to a healed amount
(Light's Guidance 524765 casts nothing after a Benediction on a target at full health).

A `hit_ratio` entry may also set `fixture` (`attack_power`, `ranged_attack_power`, `spell_power`: flat fixture bonuses
of the caster player, `README.md` player fixture fields) so the stat part of a formula dominates its die, and
`warmup` (spells cast at the start of each arm, after the arm's auras and before its start reading) so a stacking
damage over time is read at full stacks in both arms. A magic-school observation against the dummy sets the aura
823764 ("beeg spellpen", `SPELL_AURA_MOD_TARGET_RESISTANCE` -9999 on the magic schools) in both arms: the dummy's
level-based magic resistance (`Unit::GetEffectiveResistChance`, `UsesLinearMonsterResistance`) otherwise spreads the
hits by partial resists (Chastise: 269 to 408 per non-critical hit), which no trial count within one scenario
overcomes.

`off_hand_item` (an item of the class file's `off_hand_weapons`) wields that off hand beside the class file's
one-handed main hand: the main hand replaces the reference weapon and the off hand is equipped after the base steps,
with no Dual Wield grant. A spell carrying `SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON` then reads the off hand. With
`swing_hand` (0 main hand, 1 off hand) and `metric: "melee_damage_total"` the arms observe auto attacks instead of a
cast: each trial attacks the dummy for one swing interval of that hand's weapon, stops, settles 100 ms and reads the
plain (not critical unless `critical` says so, not glancing) hits of that hand. Stopping before the reads keeps a
swing from landing between the total and the count. An off-hand `swing_hand` needs `off_hand_item`; a swing entry
takes no casts, warmup or target health, and has no `observe_spell` (ADR 0142).

`cast_spell` casts that spell in each trial in place of `observe_spell`, and `cast_wait_ms` waits after it before
the reads, for an ability whose hits are another spell's (ADR 0183): Righteous Tempest 807274's aura hits with
570205 at the cast and every second for 5 s. Its Oaths read +59.4% and +59.6% with two (1 + (30 + 30) / 100, additive)
and +29.5% to +29.8% with one, at 30 trials per arm.
A swing entry may also state a flat amount at a level (ADR 0193): `level` puts the caster and the target at that
level (at most the class level), `target_entry` picks the target creature, `refresh` sets the arms' auras again before
every swing, `expected_token` names the tooltip token read at that level (it must not depend on stats) and
`scale_auras` lists [spell, effect] whose percent amounts, read in each arm, multiply it. The judge then compares the
difference of the per-hit means with that amount inside the larger of 5% of it and 2. Holy Constitution 706323 swings
at Mindless Zombie 1501 at levels 50 and 60 with Brute Force 54678 removing its armor, scaled by the class tuning
887007.

A cast the server refuses unless the caster is mounted takes a mount first (ADR 0194): the class-file section
`cast_auras` (`[{"spell", "auras", "reason"}]`) sets its auras before a value scenario's cast, and `cast_applies_aura`
and `aura_presence` entries take `caster_auras`. `aura_presence` also takes `target_distance` (the grouped ally is
relocated that far) and `present: false` (the ally stays without the aura while a second expectation requires it on
the caster).

A `hit_ratio` entry may pool `parts` identical scenarios under one label (ADR 0195): the judge concatenates the
trials of every part and needs all of them to have run. `rate: "critical"` (critical over all hits of the observed
spell) or `rate: "proc"` (hits of `rate_spell` over them) with `expected_points` judges the arms' difference of rates in
percent points inside the larger of 5% of it and 2 points. Scourge-Defense Training 520608's crit chance pools 76 parts
of 166 Argent Blades per arm (`argent_blade_crit_rate`), the pooled proof after the 300-cast `crit_rate` step (ADR 0173).

`kind: "detection"` (ADR 0197) reads `can_detect` (`Unit::CanSeeOrDetect` of the caster for a dummy `distance` yd
away) with the dummy shown, hidden by each of `hide_auras`, with `reveal_aura` set on it by the caster, and with it
removed; hidden, revealed and unrevealed are each compared exactly. It is a readback.
`read: "client"` (ADR 0222) reads `nearby_creature_at_client` (`Player::HaveAtClient`, the caster's client-visible
set) instead. Before each read, the caster steps `step_yd` (3) aside and back, `step_wait_ms` (1000) apart, so the
server runs its own visibility update. The labels read `behaviour_detection client`, and the read counts as behaviour.

`kind: "source_stack"` (ADR 0199) has the caster and a grouped ally, both carrying `caster_auras`, cast the spell in
turn; `metrics` are read on the caster with no source, its own and both. Each stat one source moved must read the same
with both (`behaviour_source_stack`, behaviour evidence); a second copy the engine refuses is stated.

### Site-purchase scenarios (`behaviour_cast_condition`, `kind: "site_purchase"`)

"Pay a tithe of 1 silver to learn a special new ability" states a price and a place. `site_purchase_scenario`
teleports the caster to `outside` (away from every site), adds `price` copper and casts `spell` (`<spell>
site_purchase outside`: the first site's reward not known), teleports to the first site and casts (`paid`: known),
teleports to the second site, adds `price - 1` copper and casts (`spent`: the second reward not known, so the first
payment was taken), adds 1 copper and casts again (`topped_up`: known). Each reading is `knows_spell` of the reward,
judged exactly.

### Cast-applies-aura casts

A `cast_applies_aura` entry may name `cast_spell` (and `cast_target`) when the aura comes from casting another spell
than the entry's own, for example a talent whose aura a class ability grants: the talent is learned, `cast_spell` is
learned, its power and caster aura are set, and it is cast at `cast_target` (default `target`). The expiry pair is
timed from that cast.

`cast_target_health_pct` sets the `cast_spell` target to that percent of the fixture maximum right before each cast,
for an aura a heal grants only when it heals (Light's Guidance 524766 after Benediction 578276).
A `cast_target` of `ally` adds the ally player, grouped with the caster after the base steps, in the readback and in
the expiry scenario (ADR 0212): Binding Scripture 801457's 707307 on the caster after a heal of the ally.

`force_crit` (`melee` or `spell`, with a `cast_spell`) sets the forced crit rating on the caster in the readback and
in the expiry scenario, for an aura that only a critical hit grants (ADR 0182): Scarlet Champion 805415's 805416
after one forced-crit Argent Blade 807268, ending after 19500 and by 20625 ms against 20000.

A passive that lengthens another spell's aura states its control arm as `control: {"expected_ms": <ms>,
"clear_auras": [<id>, ...]}` (ADR 0142). The expiry scenario then has two arms: `without`, the `cast_spell` cast
before the entry's spell is learned and ending at `control.expected_ms`, and `with`, cast again after the
`clear_auras` are removed (a lockout such as Sacred Restraint 102208), a cooldown reset and the learn, ending at
`expected_ms`. Both arms need the aura absent before the first cast. A `control` without a `cast_spell` is refused.
`label_suffix` names the labels `<spell> behaviour_cast_applies_aura <suffix>` and `<spell> behaviour_expiry
<suffix>`, so one passive can carry an entry per affected spell (Deep Secrets 705263: `libram` and `testament`).

A spell that lengthens an aura when it is cast, rather than when it is learned, adds `extra_cast: {"spell", "target",
"after_ms"}` to its `control` (ADR 0144). The entry's spell, and the extra cast's spell, are learned before both arms,
and the extra cast's target health is set for its `TargetAuraState`. The `with` arm casts `extra_cast.spell` at
`extra_cast.target` `after_ms` after the `cast_spell` cast, inside the arm, so the margins take its steps into
account; the arms differ by that cast only. The readback scenario makes the same extra cast before its second read,
which then expects `expected_ms` less `after_ms`. Titanstrike 806521: Condemn 804906 grants Oath Chain 704576
(15000 ms), and a Titanstrike 5000 ms later ends it at 18000 ms. `after_ms` must differ from the extension: with
5000 ms a refresh of the chain to its maximum would end it at 20000 ms, which the `with` arm excludes, while a
Titanstrike at 3000 ms would give 18000 ms either way. An `extra_cast` that does not name exactly `spell`,
`target` and `after_ms` is refused.

### Periodic-dispel scenarios (`behaviour_cast_condition`, `kind: "periodic_dispel"`)

"Each second you will also remove 1 disease effect from yourself" states a removal per period and a count per
removal. `periodic_dispel_scenario` sets every `debuffs` fixture (at least two, of the dispelled type) on the caster
and reads them after the whole window with no cast (`<spell> periodic_dispel control`: all present, the time-matched
control), removes and sets them again, casts `spell`, and reads them `margin_ms` (200) before the first `period_ms`
(`before_first`: all present) and `margin_ms` after each period (`after_<n>`: one fewer each time). The removal order
is not fixed, so each reading is the sum of the fixtures' `aura` values (`sum_labels`), judged exactly by
`compare.behaviour_cast_gate_verdict`. The fixtures must outlast the window. `power` sets the caster's power before the cast in place of the plain
cost, for a channel that also drains power per second (Testament of Fortitude: `ManaPerSecond` 15 on top of
`ManaCost` 15; at exactly the cost the channel ended at its first tick).

### Dispel-count scenarios (`behaviour_dispel_count`, `kind: "dispel_count"`)

"causes it to dispel 2 poison and disease effects" states a count per dispel type. `dispel_count_scenario` puts a
second level 60 player, the ally, beside the caster and gives it every `debuffs` fixture (`[[dispel type, [spell,
...]], ...]`; each fixture's `Dispel` must be that type in Spell.dbc). Each arm sets its `auras` on the caster, then,
for each of `trials` (3), sets the fixtures on the ally, reads each one's `aura` before and `wait_ms` (800) after a cast
of `cast_spell` at the ally, and removes them. An arm without auras is the control and is required. Each arm states
its `expected` count per type; the verdict `<spell> behaviour_dispel_count <arm> <type>` counts, per cast, the
fixtures of that type present before and absent after, and is `ok` only when every cast removes exactly that many
(`compare.behaviour_dispel_count_verdict`). A fixture missing before a cast makes the verdict `unmeasured`. The count
cannot show more removals than the fixtures of a type, so a type needs at least as many fixtures as its count.
Disciplined Mind 680399 / 681483 (ADR 0158) uses Frost Fever 55095 and Blood Plague 55078 (disease), Deadly Poison
2818 and Mind-numbing Poison 25810 (poison), and Benediction 578276.

### Threat-tick periods

A `threat_tick_ratio` entry may set `ticks` (default 1) and `label_suffix`: the wait then lets that many periodic ticks
fire and the label reads `<spell> behaviour_metric_ratio_delta <suffix>`. Righteous Custodian holds three entries,
0 ticks at 600 ms (ratio 1, the control), 1 at 1200 ms (0.98) and 3 at 3200 ms (0.98^3 = 0.941192), which together
place the period in (800, 1067] ms.

An entry may also set `cast_target` (`"caster"` or `"ally"`; ADR 0263): the scenario learns `aura_spell` and casts it
on that unit instead of setting it, reads its `aura_duration_ms` before and after the cast
(`<spell> <aura> aura_duration_ms threat_tick_cast before|after`), and reads the threat baseline after the cast, since
the positive cast's own threat reaches the dummy (Spell::HandleThreatSpells). With `"ally"`, the ally is grouped with
the caster and both build threat by melee; `threat_unit` (default the cast target, else `"caster"`) names whose threat
toward the dummy is read. The verdict is `ok` only when the aura reads 0 before the cast and not 0 after it (-1 is a
permanent aura) and the ratio is within tolerance. Righteous Custodian casts 572808 in all five arms (rule 4 amendment
point 2b): the three tick-count arms on the caster, `ally` on a grouped ally (0.98 on the ally's threat) and
`ally_caster_control` (1 on the caster's threat over the same tick), which separates the blessed unit from the
blessing's caster (review I1).

### Expiry pairs (`behaviour_expiry`)

A stated duration is judged by its expiry pair (ADR 0126): the effect is present just before its stated end and
absent just after it, timed from the act that applies it. The remaining-time readbacks of the duration kinds above
(`aura_duration_ms` read by `behaviour_duration`, `behaviour_duration_ratio`, `behaviour_duration_refresh`,
`behaviour_cast_applies_aura` and the trigger `duration_delta`) stay data-conformant reads; the pair is the
behaviour proof. `expiry.py` builds one extra scenario per class-file entry of those kinds
(`conformance-<class>-expiry-...`, manifest kind `expiry`, label `<spell> behaviour_expiry`); the readback scenarios
are unchanged.

Each scenario has one arm per stated end, each arm one act:

- `cast_applies_aura`: one arm from the cast, ending at the applied aura's DBC duration; the aura is read absent
  before the cast.
- `duration_refresh`: without the passive, from the apply cast, ending at the DBC duration (the breaker must not
  refresh it); with it, from the breaker cast, ending at the DBC duration.
- `duration_ratio`: one landed vehicle cast per arm, the arms 17 s apart after the first end (diminishing returns
  reset), ending at the DBC duration, then at `expected_ratio` x the DBC duration.
- `duration` (a delta per crit): from the striker hit that sets the aura, ending at the DBC duration without the
  passive and at the DBC duration - `expected_ms` with it; one forced crit per arm (`melee_damage_count`, cumulative:
  1, then 2).
- trigger `duration_delta`: from the observed spell's cast, the trigger cast `decay_wait_ms` later, ending at the DBC
  duration without the passive and at it + `expected_delta_ms` with it.

The act step carries the label `<prefix> <arm> expiry act`; an assert right after it (`aura` >= 1, or the
duration kind's debt amount, within 2000 ms) bounds when the effect began. The harness runs one step per world tick
and records each step's `elapsed_ms` (`CoAGameplayTest.cpp` `Progress`, `RunStep`, `Tick`); the time between two
steps is at most one tick, `max_step_ms`. From the recorded steps the judge (`expiry.arm_reading`) bounds the time
from the effect's start to each reading: at least the summed `elapsed_ms` of the steps between, at most that sum plus
`max_step_ms` per step, plus the act's own window (one tick when the assert waited, the act step and the assert
otherwise). With `E` the stated end and `shift = max(5% of E, 50 ms)`:

- `unmeasured` when the before reading may come at or after `E`, or the after reading less than one tick after `E`
  (a correct server could read either way), when the before reading may come earlier than `E - shift + max_step_ms`
  or the after reading as late as `E + shift` (a server `shift` off could read the same), when a stated
  precondition reads otherwise (the crit count, the absence before the cast), or when the run has no step timing;
- `alert` when the effect is absent before or present after, or a reading is missing;
- `ok` otherwise. The verdict states the end interval it shows: after the before reading's lower bound and by the
  after reading's upper bound; every end outside it is excluded.

The readings are placed from the stated end at generation (`expiry.margins_of`): the before reading
`max(2.5% of E, (k + 4) x 25 ms + 1)` before `E` and the after reading `min(that, shift - (k + 7) x 25 ms - 1)`
after it, `k` counting the steps between the act and the readings (a wait counts twice, for its own overshoot). An end
too short for both conditions at 25 ms per step is `unmodelled` (about 4.5 s with no step between act and readings),
except for a single-arm `cast_applies_aura` whose cast spell applies its own aura within its cast step (cast time 0,
Speed 0, `expiry.lands_within_its_cast_step`; ADR 0143). That arm has no applied assert and is timed from the cast
itself (`expiry.act_anchored_arm`): the before reading `floor(shift) - 26` ms before `E`, the after reading 26 ms after
it (`expiry.act_margins_of`), which leaves a judgeable pair down to about 2.54 s. Beckon 804914's 3000 ms taunt is
read on the dummy 2876 ms and 3026 ms after the cast.
A clause whose ledger entry lists the `behaviour_expiry` label is behaviour-proven by it; an `unmeasured` or `alert`
pair leaves the clause unproven.

An expiry scenario may wait up to one hour of game time (`hits.MAX_ACCELERATED_SCENARIO_MS`, ADR 0139), and
`generate` validates every scenario for the accelerated clock. An end past the real-pace cap, such as Righteous
Custodian's 30 minutes, therefore runs only through the default accelerated gameplay stage; its pair (1755 s and
1845 s after the cast) took about 9 s of real time.

### Taken-hit scenarios (`behaviour_taken_hit`, `kind: "taken_hit"`)

A clause about damage the caster takes is read from a hit actually applied (ADR 0153). A passive, stationary
striker (creature `striker_entry`, default 36, at the class level, passive so that nothing but the strikes reaches
the caster) casts `strike_spell` at the caster `strikes` times per trial
(an arm may set its own `strikes`), `trials` trials per arm. `arms` lists named arms, the first the control; each
sets its `auras` on the caster, makes its `casts` (`[spell, target]`) before the strikes and its `after_casts`
after them, every trial. `caster_health_pct` with `caster_max_health` sets the caster's health, and maximum, at
the arm start and before every trial. After every trial the scenario reads the strike's `spell_damage_total` and
`spell_damage_count` (caster `striker`, target the caster), its `spell_absorb_total` and its `spell_log_count`:
a trial with fewer logs than strikes did not land and is left out; each arm needs half its trials landed.

- `judge: "damage_ratio"` takes exactly the arms `control` and `treatment`, reads non-critical strikes and is judged
  as a hit ratio (`behaviour_hit_ratio`, ADR 0125) against `expected`. Battlepriest 801202 holds the caster at 90%,
  50% and 10% of 100000 health: 880 against 1100 at 90% and 10%, 1100 against 1100 at 50%.
- `judge: "absorb"` compares every landed trial's absorbed amount exactly, per arm: `absorb: "none"` (0),
  `"formula"` (`absorb_constant` plus each of `absorb_terms`, a `coefficient` times the sum of its `reads`, stat
  metrics read on the caster at the arm start, computed in float in that order and truncated toward zero, as
  `int32(125 + .3f * Stamina + .25f * (dodge + parry))` is) or `"share"` with `share_pct` (floor of that percent
  of the strike's damage plus absorbed amount; one strike per trial).
- `debt_spell` with an arm's `debt_removed_pct` also reads that debt's periodic damage paid by the caster and its
  aura 500 ms before and 500 ms after the debt's duration from the strike: by the end the debt is gone and has
  paid the absorbed amount less floor(`debt_removed_pct`% of it). `debt_ends: true` also needs the debt present
  with less paid just before its end: the damage is taken over the whole duration. Each debt read also records the
  count of the debt's damage logs (`payments early`, `payments late`, `spell_damage_count`), which the judge does not
  use: it shows how many payments the debt was split into.

- `settle_ms` (default 500) is the wait after each trial's strikes, longer for a periodic strike's ticks or an
  internal cooldown. An arm's `refresh: true` removes its `auras` before setting them every trial, so an aura
  shorter than the arm does not run out mid-arm (`set_aura` keeps the remaining duration of an aura it finds).
- `striker_race` (default 0, a creature striker) makes the striker a player of that race and the caster's class,
  both PvP-flagged at the scenario `location` of `TAKEN_HIT_PVP_LOCATION` (Elwynn Forest, the location of the
  catalog PvP scenarios); the striker learns `strike_spell` and casts it through the client cast opcode, so the
  strike needs no cost, cooldown or global cooldown in its trials. Libram of Tenacity 801461 "($s3% against
  players)" uses an orc striker.
- An arm's `reduction: "formula"` (absorb judge, a `control` arm and `absorb_terms` required) judges a flat
  damage-taken reduction applied before the strike's mitigation: the control strikes must read one damage `C`, and
  each landed strike of the arm must lie between floor((B - R) x C / B) and ceil((B - R) x (C + 1) / B) - 1, with
  `B` the strike's fixed base (`strike_base`, its one SPELL_EFFECT_SCHOOL_DAMAGE effect's base points plus die
  sides of at most 1) and `R` the formula. The control's mitigation is thereby carried over without modelling armor.
- `returned_spell`, with every arm's `returned_pct`, reads that spell's damage, absorbed and resisted amounts and its
  logs from the caster onto the striker after each trial: an arm at 0 must return nothing; otherwise each landed
  strike answered by one non-critical hit must have returned exactly floor(`returned_pct`% of the strike's logged
  damage) as damage plus absorbed plus resisted; a strike the striker avoided is left out, and half the trials must
  be judged.

Strikes the class file uses: Light of the Naaru 41394 (1100 Holy, DmgClass 1 magic), Void Zone 92559 (1000
Physical, DmgClass 0 none: it neither misses nor crits), Holy Nova 101350 (2000 Holy around the striker, 15 yd, an
area strike, magic), Lacerating Slash 42395 (1735 Physical every 2 s for 18 s, a periodic strike), Night Slaughter
23583 (67 Physical, DmgClass 2 melee: it can miss and crit) and Tetanus 8014 (a magic-class disease). A resist rate
needs a magic-class strike: a melee-class spell goes to `MeleeSpellHitResult`, which reads no debuff resistance. A strike heavier than the caster's health kills it: hold `caster_health_pct` and
`caster_max_health`.

- `judge: "resist_rate"` with `expected_points` (ADR 0196) reads, 300 ms after each strike, whether its aura is on the
  caster and removes it; the arms' resisted shares, in percent, must differ by the stated points inside the larger of
  5% of them and 2 points. With `parts` the parts are pooled.

The control arm is the negative arm: without the talent nothing is absorbed or reduced.

An arm cast may target `ally` (ADR 0212): the scenario then adds the ally player, grouped with the caster after the
learns, and `ally_health_pct` sets the ally to that percent of the fixture maximum before every cast at it, so a heal
is effective. Binding Scripture 801457 heals the ally with Testament of Faith 801478 before each strike: one heal
reads 0.95, four heals 0.85 (3 stacks); a heal of the caster itself reads 1.00.

### Threat-redirect scenarios (`behaviour_threat_redirect`, `kind: "threat_redirect"`)

The ally, grouped with the caster and relocated next to a REACT_DEFENSIVE dummy, melee-attacks it for `swings`
swing intervals (default 3); the caster then casts `spell` at itself and, `settle_ms` later (default 3500, past a
periodic redirect trigger), the ally attacks again. The dummy's `threat` on the ally and on the caster is read
before and after each attack. `ok` when, without the spell, the ally gains threat and the caster none, and, with
it, the ally gains none and the caster some: the whole of the ally's threat goes to the caster.

### Script-cast hits (`hit_mean`, `kind: "script_hit"`)

A tooltip may state the amount of a hit that a class script casts on an event, such as a pulse on a heal or a
strike when a shield breaks (ADR 0160). `hit_spell` is the spell the script casts and `spell` the passive whose
tooltip shows its amount. Every trial sets `caster_auras` on the caster, holds the caster at `caster_health_pct`
of 10000 health, makes the `casts` (`[spell, target]`, after their power, cooldown and required-aura fixtures)
and, with `strike_spell`, has a passive, stationary striker (creature `striker_entry`, default 36) cast it at the
caster; it then waits `settle_ms` (default 500). `trials` trials run without `spell` known (the control arm,
whose `hit_spell` hits on the `receiver` must count 0) and `trials` with it. The `receiver` is the dummy or the
striker; its armor, view level and resistances are read for the mitigation model. The mean non-critical hit is
judged by the hit judge (`compare.judge_hit`) against the tooltip value of `hit_spell`'s tokens in `spell`'s
tooltip, read with the measured stats and re-indexed to `hit_spell`'s effects (`hits.triggered_readout`), each
roll of the hit's die read again through that tooltip, then the known modifiers and mitigation. At least
`minimum_hits` hits are needed. When the hit's effect has a fractional per-level term, the stock engine truncates
it before the sum (SpellInfo.cpp:497, ADR 0147): a mean outside the tooltip model is `ok` only inside the engine
model's 99% interval, the verdict names that known engine rounding and `detail['per_level_rounding']` holds both
means; a mean neither model explains alerts. Disciplined Blows 680397 (pulse 680398 on Benediction 578276),
Pulverizing 524620 (524619 on Condemn 804906's damage) and Armor of Faith 804930 (801546 when Staffguard 706583
breaks under the striker's Light of the Naaru 41394) use it.
`control_casts` (ADR 0206) replaces the control arm's `casts` (an empty list makes none), and `spell` is then known in
both arms: for a hit the spell itself sets off, the control is the same trial without that cast (Crusader's Brand
300513 on the striker, Divine Charge 527023) or with another cast (Argent Blade 807268 against Righteous Lunge 570233).
A hit of one school damage effect and one weapon percent effect adds the weapon part, read from the tooltip's percent
of that effect, to the school part (ADR 0208, the Scourgebane strike 801832 from 92111's tooltip); `value_spell` and
`value_effect` read the hit's value from another spell's effect token onto its school effect (Divine Charge's trample
527269 from `$527270m3`).
`stat_auras` (ADR 0210) are set on the caster before its stats are measured, so the hit model reads the stats they
leave; `label_suffix` names a second entry of the same hit (Divine Charge `no_power`: Demoralizing Shout 1159613 holds
attack power at 0, so only the trample's base term is read).

### Taken-outcome scenarios (`behaviour_taken_outcome`, `kind: "taken_outcome"`)

`attackers` aggressive, stationary creatures (default 8, entry `attacker_entry`, default 36, at the class level)
stand 3 yd in front of the caster; each may carry `attacker_auras` (set once, from itself) and is engaged by one
caster swing before the caster stops attacking. The caster's health is reset to 1000000 every `refresh_ms`
(default 4000). Two arms of `arm_ms` each follow: the control, then the treatment, where `aura` is set on the caster
at `stacks` stacks every `refresh_ms`, removed first because `set_aura` keeps the remaining duration of an aura
it finds (a first run that only set the stacks again let 560651's 5000 ms run out between refreshes). Each arm
reads, at its start and end, `melee_attacks_taken` and
`melee_attacks_taken` with `victim_state` (the `VictimState` of `SMSG_ATTACKERSTATEUPDATE`, 3 for a parry). The
judge takes the outcome rate of each arm, needs 100 swings in each, and compares the difference in points, with its
99% normal interval, to `expected_points` under the percent bonus band (the larger of 5% of it and 2 points,
`bonus.bonus_status`): the interval must not lie outside the band, its half-width must be at most half the band,
and the reading must lie inside it (ADR 0161). Parry Dance 804912 sets 560651 at 5 stacks (15 points) without
learning 804912, so that its own parry rating from Agility stays out of the contrast; Graceful Fighter 705303 is
known in both arms, since the caster parries only once it or a parry-percent aura sets `CanParry`; its attackers
carry Self Root Forever (No Visual) 42716, because `stationary` did not keep them in front (a diagnostic read three
of eight behind the caster, where no swing is parried), and Molten 62531 and Enrage 2116852 to swing four times as
often. `state_metric` (here `parry_chance`) is read
once per arm, after the first refresh, and reported, not judged.

### Charm-immunity scenarios (`behaviour_immunity`, `kind: "charm_immunity"`)

A charm immunity is proven with a real charm (ADR 0163). The dummy (with `spell_hit_bonus` 100) casts `charm_spell`
at the caster through the harness `cast` action (the creature's own `Unit::CastSpell`), once without `spell` (the
control: the charm aura must be present) and once after the caster has cast `spell` on itself (the charm aura must
be absent). Each charm aura is read 500 ms after the cast, inside the charm, and the charm is then removed with
`set_aura` `stacks: 0` from the dummy. After each arm the scenario asserts, each within 15000 ms and failing the
scenario otherwise: no charm aura, `charmed` 0 (no charmer), `controls_self` 1, the caster's `faction` equal to its
snapshot before the first charm, and a dummy whose `victim` is not the caster. The dummy's `combat` is read and not
asserted: a passive fixture keeps its PvE combat reference with the caster after a hostile spell
(`CreatureAI::UpdateVictim`, CreatureAI.cpp:364-377, never evades while in combat), and no harness action ends it.
Testament of Resolve 804228 uses Domination 37122 (aura 6 SPELL_AURA_MOD_CHARM, Mechanic 1, 10 s).

### Uncapped areas and controlled leech ratios

A `fixed_count` entry may set `cast_target: "caster"` for an area centred on the caster (a heal on itself that
triggers a pulse): every dummy, the primary included, stands inside `radius` of the caster and the far dummy
`FIXED_COUNT_FAR_MARGIN_YD` beyond it. `cast_target_health_pct` sets the cast target's health before every cast,
`learn` adds spells to learn, and `uncapped: true` offers no headroom dummy and states every offered candidate
(model `all_offered`): Disciplined Blows 680397's pulse 680398 must hit all four dummies inside 5 yd and not the
one at 10 yd.

A `cast_leech_ratio` entry may name `cast_spell` (the damage spell cast, default the entry's spell), `auras` set on
the caster before the judged cast, and `label_suffix`. With `auras`, a first cast without them is the control: it
must heal nothing with `heal_spell`, and its damage and healing are taken off the judged cast's. A heal spell with
`SPELL_ATTR6_IGNORE_HEALTH_MODIFIERS` skips the caster's percent healing modifiers (`Unit::SpellPctHealingModsDone`),
as one with `SPELL_ATTR3_IGNORE_CASTER_MODIFIERS` does. Glory 801481's Downfall 801482 and Redemption 801483 heal
for half the damage of a Sacred Swing.

### Templar entries

| Passive | Kind | Quote | Expected | Mechanism |
|---|---|---|---|---|
| Pious Sweep 520034 (`label_suffix: "tranquil_circle"`) | hit_ratio | "on enemies above 75% health or affected by Tranquil Circle." | +25% (ratio 1.25) | 520034 `Effect[1]` aura 107 `SPELL_AURA_ADD_FLAT_MODIFIER`, `EffectMiscValue[1]` 23 (`SPELLMOD_EFFECT3`, SpellDefines.h:99), $s1 25, on Tranquil Circle 801205, whose `Effect[2]` aura 271 `SPELL_AURA_MOD_DAMAGE_FROM_CASTER` is 0 on its own; the treatment arm casts 801205 at the dummy before every Chastise 503141, the dummy is held at 50% health so the `Effect[0]` aura 303 versus `AURA_STATE_HEALTH_ABOVE_75_PERCENT` (SharedDefines.h:1416) half stays closed, non-critical hits only. Not cited by the clause ledger until it is proven |
| Scarlet Judicator 525024 | count | "strikes 2 additional enemies near the primary target" | 2 | Divine Force 807805's school-damage effect (`TARGET_UNIT_TARGET_ENEMY`, `DmgClass` 2/melee) always routes through `Spell::SelectImplicitChainTargets` (`Spell.cpp:1905-1923`), which applies Scarlet Judicator's `SPELLMOD_JUMP_TARGETS` flat modifier to `ChainTarget` and searches a 10-yard jump radius for a melee spell with no `JumpDistance` override (`Spell.cpp:2200-2213`) |
| Justice 712437 | count | "strikes 1 additional nearby target" | 1 | scripted hook `templar_casts::OnSpellBeforeEffects` (`AscensionTemplarAbilities.cpp:95-102`): casting Interdict 560116 with Justice known adds exactly one unit from `Nearby(primary, 8.0f)`; the DBC's own effect 1 (`PROC_TRIGGER_SPELL` to 712364, Sacred Oath's own trigger) does not implement this sentence at all and is not used |
| Interdict 560116 (`variant: "undead"`/`"demon"`/`"control"`) | heal_block | "If they are an Undead or Demon they are unable to be healed for the duration." | 561309 present on Undead/Demon, absent on the control | round10 `cc-dispel-movement` — **confirmed defect, fixed this round**: 561309 "Atone for your Sins!" (the `EffectTriggerSpell[1]` the silence effect triggers) applied its `SPELL_AURA_MOD_HEALING_PCT -101` heal-block unconditionally, to every Interdict target regardless of creature type; `Spell::EffectTriggerSpell` (`SpellEffects.cpp`) has no generic creature-type gate, and no CoA script referenced either spell id before this fix. Fixed in `AscensionTemplarAbilities.cpp`'s `templar_casts::OnSpellCalculatedTarget`: `hit.missCondition = SPELL_MISS_IMMUNE` for the 561309 cast when the target's `GetCreatureType()` is neither `CREATURE_TYPE_UNDEAD` nor `CREATURE_TYPE_DEMON`. Creature entry 201 (Brittlebones Skeleton, type 6 Undead) and 416 (Imp, type 3 Demon) prove the block holds (561309 measured present); entry 36 (Harvest Golem, type 9 Mechanical, `DUMMY_ENTRY` elsewhere in this tool) is the positive control proving 561309 stays absent when neither type matches — pre-fix, this control entry alerted (561309 present when it should not be) |
| Final Prayer 705268 | ratio | "Doubles the healing done to you" | 2.0 | two named targets: Testament of Faith 501606 (a direct heal, `SPELL_AURA_MOD_HEALING_RECEIVED` taken-side, method `"taken"`, measured with `spell_healing_taken`; round8/round9 found method `"cast"`/`spell_healing_done` structurally blind to this aura — `Unit::SpellHealingBonusDone` is the healer's own caster-side multiplier and never reads a taken-side aura of the healed unit, so it measured the same 800 before and after regardless of whether the server doubles the heal) and Testament of Fortitude 500678 (a `SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE` self-heal whose doubling is a `SPELLMOD_EFFECT1` percent modifier read inside its own effect-0 `CalcValue`, needing no cast at all, method `"effect_value"`, measured with `spell_effect_value {spell: 500678, effect: 0}`) |
| Testament of Resolve 804228 | cast_state | "Usable while feared." | control 34, state 1, spell 0 | 804228 `AttributesEx5` `SPELL_ATTR5_ALLOW_WHILE_FLEEING`; `Spell::CheckCasterAuras` (Spell.cpp:7143-7144) refuses a fleeing caster with `SPELL_FAILED_FLEEING` (34) otherwise; state Fear 12096 from the dummy, control Testament of Strength 300514 |
| Testament of Resolve 804228 | immunity | "granting immunity to fear, charm, and horrify effects" | fear and horrify fixtures absent after the cast, present again once 804228 has expired | `Effect[0]` aura 147 misc 512 (bit 9, `SPELL_AURA_MOD_FEAR` aura-type immunity, SpellInfo.cpp:2738-2739), `Effect[2]` aura 77 misc 24 (`MECHANIC_HORROR`); fixtures Fear 12096 and Psychic Horror 64044. Charm has no fixture and no 804228 effect names it |
| Faith Guard 705259 | threat_slope | "High Threat Holy damage" | 2 | Faith 706466 cast at a fresh dummy, flat 100 from its `Effect[1]` 63; spell_threat pctMod 2 (rev_20261103_01_templar_faith_threat.sql); owner ruling 2026-11-10 |
| Testament of Resolve 804228 | cast_applies_aura | "Applies Sacred Restraint for" | 60000 ms | `Effect[1]` 64 `SPELL_EFFECT_TRIGGER_SPELL` 102208 on the ally target (the caster here); no CoA code casts 102208 for 804228; proven by its expiry pair |
| Light's Guidance 524765 (`label_suffix: "next_benediction"`) | hit_ratio (heal) | "now causes your next Benediction to heal for" | 1.25 | 524765 set in the treatment arm, ally at 50% before each Benediction 578276, a warm-up Benediction per arm; `AscensionTemplarAbilities.cpp:279-280` casts 524766 (aura 108 `SPELLMOD_DAMAGE` +25%, one charge) after a healing hit |
| Light's Guidance 524765 | cast_applies_aura (`cast_spell` 578276 at the caster, `cast_target_health_pct` 50) | "to heal for" | 30000 ms | 524766 `DurationIndex` 9 |
| Warrior of Dawn 560648 | proc_reset | "chance to reset the cooldown and reduce the Energy cost of your next Argent Blade by" | cooldown 0 after a proc, the next Argent Blade 807268 at 25 Energy instead of 50 | `AscensionTemplarEvents.cpp:71-72` (melee damage, not periodic) and `:152-154` (`Reduce(player, 804929, INT32_MAX)`, `Cast(player, player, 561156)`); 561156 `Effect[0]` aura 108 `SPELLMOD_COST` -50%, one charge (`AscensionTemplarAuras.cpp:116-120`), dropped by the next Argent Blade (`AscensionTemplarAbilities.cpp:26-27`). 561167's effect 195 is not on the path |
| Holy Tempest 301339 | spread (`first_tick`) | "spreads Condemn on affected enemies to a nearby enemy" | 1 of 2 after the first tick | `AscensionTemplarAbilities.cpp:294-295` (`OnSpellHitResult`): on a confirmed hit of Righteous Tempest's periodic damage (ranks `805410`/`570200..570205`) with the passive known, `AscensionTemplar.cpp:224-257` (`SpreadCondemn`) copies the Condemn aura already present on the hit target onto the first valid, non-already-afflicted, line-of-sight enemy within `Nearby(target, 10.0f)` - a hardcoded radius, not read from any DBC field |
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
| Whirling Tempest 301340, effect 1 | metric_delta | "you now cannot be slowed" | 1 (immune) | round6 `owner-rulings-2026-11-09.md` — **confirmed defect, fixed this round**: `AscensionTemplarContracts.cpp`'s `id == 301340` branch unconditionally zeroed effect 1 (`info->Effects[1].Effect = 0`), discarding the raw DBC's own `SPELL_EFFECT_APPLY_AURA` there with no substitute mechanism anywhere in the Templar files. Fixed by setting that effect to `SPELL_AURA_MECHANIC_IMMUNITY`/`MECHANIC_SNARE` instead (the same per-class idiom already used by `AscensionStarcallerContracts.cpp`/`AscensionPrimalistBoulder.cpp`); the stock `AuraEffect::HandleModMechanicImmunity` grants the immunity for exactly 301340's own application window, which `AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle` already ties to Righteous Tempest 805409's apply/remove, so no new Templar lifecycle code is needed. The metric is the harness's own `spell_effect_immune` probe (`player->IsImmunedToSpellEffect`) against Hamstring 1715's own snare effect (effect 0), not an actual landed cast of it: an exploratory run cross-checked that an *actual* Hamstring cast at a caster carrying 301340's effect 0 (`SPELL_AURA_MOD_SPEED_ALWAYS`) never lands at all regardless of this fix (`1715 present` reads `0` with the fix applied and with it reverted alike — the same `SPELL_AURA_MOD_SPEED_ALWAYS` aura type, cross-checked with the equal-magnitude but differently-typed Courage Rank 2 712466 (`SPELL_AURA_MOD_INCREASE_SPEED`), which does not reproduce it), an unrelated engine/harness interaction this round did not chase further since the direct immunity probe sidesteps it entirely and is the more precise signal anyway. `gate_spell: 300504` learns the real parent passive between phases (301340 is never itself learnable: the server only casts it internally); `trigger_spell: 805409` is cast in both `cast_steps()` calls so the "before" phase still proves the probe can read `false` while 300504 is unknown. Pre-fix, this entry reads `0` (not immune) after 300504 is learned, against `expected` 1 — an alert; post-fix it reads `1`, matching exactly. Follow-up (2026-11-10, measured with a real slow): catalog scenario `templar-whirling-tempest-slow-immunity` has a hostile creature cast Slow 31589 at the Templar during Righteous Tempest; without 300504 its snare effect 0 lands (amount -60, run speed 0.40), with 300504 the snare is not applied (run speed 1.20, 0.48 if it were) while Slow's unmechanised haste effects still land, and after the window the snare lands again (0.40) |
| Blessing of Aggramar 300502 | duration_refresh | "now refreshes the duration of Blade of Faith on all nearby enemies." | 30000 ms (`SpellDuration.dbc` id 9) | `AscensionTemplarAbilities.cpp` `Breaker(info)`: `player->HasAura(300502) && spell->GetScriptValue(704576) >= 10` refreshes every nearby Blade of Faith 803872 aura to its own max duration; matches the already-working 9-vs-10-stack threshold the issue scenario `templar-blessing-of-aggramar-blade-refresh-7806.json` (#7806) proves, varying the passive's presence instead of the stack count |
| Righteous Custodian 572808 (`variant: "before_tick"`/`"period"`) | threat_tick_ratio | "every" | 1.0 at 600 ms, 0.941192 at 3200 ms | `EffectAmplitude[0]` 1000 ms, 572809 at -2% per tick (`ThreatManager.h:150` multiplies) |
| Righteous Custodian 572808 | group_target | "Place a blessing on a party or raid member" | outsider 12/0, party 0/1, raid 0/1 | `EffectImplicitTargetA[0]` 57 `TARGET_UNIT_TARGET_RAID`; `SpellInfo::CheckExplicitTarget` (`SpellInfo.cpp:2186-2197`) |
| Holy Upheaval 572547 (`variant: "talent"`/`"without_talent"`) | hit_ratio | "Increases the effectiveness Righteous Upheaval gains per trigger of Zealotry by" | 7.0 with the talent and 30 stacks of 807764, 4.0 without | `Effect[0]` aura 108 `SPELLMOD_EFFECT1` on 807764 (10% per stack); 807764 multiplies `SPELLMOD_DAMAGE`; observed rank 501562 |
| Sacred Style 705278 (`variant: "done"`/`"received"`) | hit_ratio (heal) | "Increases your Holy healing done and received by" | 1.08 each | `Effect[1]` aura 136 for the caster's heal of the ally, `Effect[0]` aura 118 for the ally's heal of the caster; Chakra of Light 803845 (fixed heal) |
| Grace of Aman'thul 301059 (`variant: "righteous_lunge"`/`"sacred_swing"`) | cost_gate (power) | "Reduces the Energy cost of Righteous Lunge by" / "and Sacred Swing by" | 35 and 10 Energy | aura 107 `SPELLMOD_COST` -5 on 570233 (40), -10 on 572769 (20) |
| Battle Hardened 706309 | cost_gate (cooldown) | "Reduces the cooldown of Righteous Upheaval by" | 15000 ms | aura 107 `SPELLMOD_COOLDOWN` -5000 on 572027 (`CategoryRecoveryTime` 20000) |
| Profound Enlightenment 680953 | cost_gate (cooldown, `after_casts`) | "reducing the remaining cooldown of Testaments by" | 80000 ms of Testament of Faith 801478's 180000 ms, cut 20000 ms after the priming cast | `AscensionTemplarAbilities.cpp:377-388` (Enlighten, bound at :424-425) replaces the three effect-192 effects: `ModifySpellCooldown(-CalculatePct(remaining, 50))` on each known Testament rank |
| Guardian of the Light 707364 | cost_gate (power, next, duration) | "Casting Benediction now reduces the cost of your next Temple Guardian by" | 8 Energy for 6000 ms, next cast only | 712378 aura 108 `SPELLMOD_COST` -50% for 6000 ms, one charge (`AscensionTemplarAuras.cpp:116-121`, `AscensionTemplarAbilities.cpp:227-229`) |
| One-Punch Man 705284 (`variant: "oath_breakers"`/`"condemn"`/`"titanstrike"`) | hit_ratio | "Increases the the damage of Oath Breakers, Condemn, and Titanstrike by" | 1.2 each | `Effect[0]` aura 108 `SPELLMOD_DAMAGE` (masks 16/64/128), `Effect[1]` `SPELLMOD_DOT` on Condemn; fixture power, resistance fixture for Holy |
| Judgement 300520 (`variant: "titanstrike"`/`"scourgebane"`/`"scarlet_hammer"`) | hit_ratio | "Increases the damage of Scourgebane, Scarlet Hammer, and Titanstrike by" | 1.25 each at 10% health | `AscensionTemplarAbilities.cpp:140-142` (launch damage) and `AscensionTemplarContracts.cpp` `ModifySpellDamageTaken` (Titanstrike's leech damage) |
| Pious Sweep 520034 (`variant: "above_75"`/`"below_75"`) | hit_ratio | "Increases the damage of Chastise by" / "on enemies above 75% health or affected by Tranquil Circle." | 1.25 at full health, 1.0 at 50% | aura 303 on `AURA_STATE_HEALTH_ABOVE_75_PERCENT`, Chastise mask (`AscensionTemplarContracts.cpp:152-156`) |
| Force of Golganneth 500694 | cost_gate (`talent_aura`) | "While active, your Temple Guardian spell has its Energy cost reduced by" | 8 Energy while the aura is up | aura 108 `SPELLMOD_COST` -50% |
| Testament of Fortitude 500678 | cast_applies_aura | "Meditate for" | 15000 ms | `DurationIndex` 8 |
| Beckon 804914 | cast_applies_aura | "Taunt an enemy to attack you for" | 3000 ms on the dummy | `DurationIndex` 27, `Effect[1]` aura 11 `SPELL_AURA_MOD_TAUNT` at `TARGET_UNIT_TARGET_ENEMY`; instant, Speed 0, so the pair is timed from the cast (ADR 0143) |
| Testament of Fortitude 500678 | periodic_dispel | "Each second you will also remove 1 disease effect from yourself." | 2 without the spell, 2 at 800 ms, 1 at 1200 ms, 0 at 2200 ms | Frost Fever 55095 and Blood Plague 55078 (15000 ms each); 500690 `Effect[2]` `SPELL_EFFECT_DISPEL` disease, every 1000 ms |
| Pious Sweep 520034 (`variant: "circle_without_talent"`) | hit_ratio | "on enemies above 75% health or affected by Tranquil Circle." | 1.0 | the Tranquil Circle arm without Pious Sweep learned: the without-talent control of the circle claim |
| Staffguard 705295 | cast_applies_aura (`cast_spell` 572769) | "for" | 8000 ms | `AscensionTemplarAbilities.cpp:239-243`, 706583 `DurationIndex` 31 |
| Tithe 804781 | site_purchase | "Pay a tithe of 1 silver to learn a special new ability" | 100 copper, Light's Hope Chapel then Strahnbrad | `AscensionTemplarTithe.cpp` (`TITHE_COST`, site table) |
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
| Disciplined Blows 680397 | internal_cooldown_gate (`trigger_spell: 578276`, `internal_cooldown_ms: 500`) | "Only occurs once every 0.5 sec." (streamed; the DBC reads "Cnly occur") | no new event 250 ms after the first fire, exactly 1 new event 750 ms after that | `AscensionTemplarEvents.cpp:74-76,157-159`'s `State(player).cooldowns` timer, not `spell_proc.Cooldown`; `ok` in both runs |
| Untainted 705298 | internal_cooldown_gate (`trigger_spell: 803792`, `internal_cooldown_ms: 15000`, `restore_charges: true`) | "Can only occur every 15 sec." | no new event 7500 ms after the first fire, exactly 1 new event 8000 ms after that | same `State(player).cooldowns` timer mechanism; 803792's own `SPELL_EFFECT_CHARGE` pulls the caster to melee range of the ally on every successful cast, so `icd_gate_attempt_fixtures` relocates the caster +10 yd before every attempt (not once), matching the 5-30 yd range its `SpellRange.dbc` entry needs; a first attempt without the per-attempt relocate measured two real `SPELL_FAILED_TOO_CLOSE` cast failures; `ok` in both runs |
| Scarlet Champion 805415 | internal_cooldown_gate (`trigger_spell: 807268`, `internal_cooldown_ms: 1000`, `force_crit: melee`) | "Can only occur once per sec." | no new event 500 ms after the first fire, exactly 1 new event 1000 ms after that | same `State(player).cooldowns` timer mechanism; `ok` in both runs |
| Temple Guardian 803792 | charge_recharge | "3 Charges, 35 sec recharge" | 3 charges, 35000 ms recharge | round10 `formula-value-scaling`: Spell.dbc's own charge fields for 803792 are all zero (`ProcCharges`/`RecoveryTime`/`Category`, `coa-dbc-viewer record --table Spell --id 803792`); the real numbers come from `SpellCharges.dbc` (`Spell=803792 -> Category=251`) and `SpellChargesCategory.dbc` (`ID=251, MaxCharges=3, RecoveryTime=35000`), applied to `SpellInfo` by `ApplyClientSpellCharges` (`AscensionClassMechanics.cpp:1082-1096`), called unconditionally for every spell — a class-agnostic native system, no Templar script involved. Target `"ally"` reuses the same relocate-and-charge fixture the existing 804571/705256/705298 trigger entries above already exercise on this same spell (803792's effect 0 is `SPELL_EFFECT_CHARGE`) |
| Titanstrike 806521 | cast_gate | "Only usable on enemies below 35% health." | refused (111) above the gate, succeeds below it | `SpellInfo::CheckTarget` (`SpellInfo.cpp` ~2135-2141) returns `SPELL_FAILED_TARGET_AURASTATE` when the target lacks `AuraStateType(TargetAuraState)`; 806521's own `TargetAuraState` (DBC field) is 13 (`AURA_STATE_HEALTHLESS_35_PERCENT`), the same state `values.py`'s `required_target_health_steps` already fixtures to 30% for the unrelated `effect_value` scenario, which never itself asserted the gate refuses a higher-health target |
| Testament of Strength 300514 (`bypass_spell` of the Titanstrike entry above) | cast_gate | "are usable regardless of your target's health percentage," | succeeds at full target health once 300514 is cast | `Unit::HasAuraState` (`Unit.cpp` ~8522) checks `Caster->GetAuraEffectsByType(SPELL_AURA_ABILITY_IGNORE_AURASTATE)` before consulting the target's own state, returning `true` (gate satisfied) for any matching effect whose `IsAffectedOnSpell(spellProto)` holds, regardless of the target; 300514's own effect 2 (`EffectApplyAuraName[2]` 262, `SPELL_AURA_ABILITY_IGNORE_AURASTATE`) is exactly this bypass, scoped to Titanstrike by its own `EffectSpellClassMask`. No CoA-specific code is involved; this is the stock engine path |
| Divine Charge 527023 | cast_condition | "Can only be used outdoors." | refused (93, `SPELL_FAILED_ONLY_OUTDOORS`) indoors, succeeds outdoors | stock engine `Spell.cpp:5857-5859`: `m_spellInfo->HasAttribute(SPELL_ATTR0_ONLY_OUTDOORS)` (527023's own `Attributes` DBC field carries this bit) returns `SPELL_FAILED_ONLY_OUTDOORS` when `!caster->IsOutdoors()`. No CoA-specific code is involved; this is the stock engine path |
| Crusader's Presence 562302 | cast_condition | "Can only be used while Mounted." | refused (91, `SPELL_FAILED_ONLY_MOUNTED`) unmounted, succeeds mounted | round10 `cast-conditions-cooldowns` investigation (2026-11): no attribute, `CasterAuraState`/`CasterAuraSpell` field or Templar script enforced this clause before this round — 562302's own `Attributes` carries only `SPELL_ATTR0_ALLOW_WHILE_MOUNTED` (which permits casting *while* mounted, bypassing the generic dismount-exempt check at `Spell.cpp:6189-6197`, and is unrelated to requiring it) and `CasterAuraState`/`CasterAuraSpell` are both 0. **Confirmed defect, fixed this round**: an unmounted cast was reproduced succeeding (no refusal) before the fix. Fixed by a new `OnSpellCheckCast` hook on the existing Templar-scoped `templar_casts` `AllSpellScript` (`AscensionTemplarAbilities.cpp`, `SpellFamilyName == 25`), `if (info->Id == 562302 && !player->IsMounted()) result = SPELL_FAILED_ONLY_MOUNTED;` — the same per-class `AllSpellScript`+`SPELL_FAILED_ONLY_MOUNTED` idiom `AscensionTinkerAbilities.cpp`'s `tinker_spells::OnSpellCheckCast` already uses for an analogous Tinker-only mounted-form gate, scoped here to Templar's own `SpellFamilyName` so no other class's cast check is touched |
| Crusader's Presence 562302 (`variant: "mounted_speed"`) | metric_delta | "Increases mounted movement speed by $s1%" | 2.40 (1.60 before) | round10 `cast-conditions-cooldowns` investigation (2026-11), ADR 0052: `cast_in_before: false` (`trigger_spell == spell`, 562302's own cast is what the clause measures). `setup_actor_aura: 458` (Brown Horse) grants `IsMounted()` the same fixture way the `cast_condition` entry above already proves. `Unit::UpdateSpeed`'s `MOVE_RUN` + `IsMounted()` branch (`Unit.cpp` ~12410-12415) reads 458's own `SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED` (type 32, `+60%`) as `main_speed_mod`, and 562302's own three `SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK`/`MOD_FLIGHT_SPEED_MOUNTED_NOT_STACKING`/`MOD_FLIGHT_SPEED_NOT_STACKING` effects (all `+50%`) as `non_stack_bonus` (type 172 alone, since no other type-172 aura is present); the final speed (`Unit.cpp` ~12497-12498, `speed = max(non_stack_bonus, stack_bonus); AddPct(speed, main_speed_mod)`) is `max(1.0,1.0)*1.60=1.60` mounted alone and `max(1.5,1.0)*1.60=2.40` once 562302 is also cast. `run_speed_rate` is the metric; no server defect, stock engine math, unaudited by any existing scenario before this entry |
| Divine Charge 527023 (`variant: "mount_grant"`) | mount_grant | "You and your party members leap upon a divine steed," / "While active, casting does not dismount you or your allies." | `mount_display_id` 14584 on the caster and a grouped ally, both before and after an unrelated cast | round10 `cast-conditions-cooldowns` investigation (2026-11): `AscensionTemplarAuras.cpp`'s `aura_ascension_templar_lifecycle::Apply` (`id == 527023`) casts each live player target's own 527272/527270 the first time 527023's own `TARGET_UNIT_DEST_AREA_PARTY` aura (effect 0, `EffectRadiusIndex[0]` 9 -> `SpellRadius.dbc` `RadiusMax` 20.0 yd) applies to it while unmounted; 527272's own `Apply` calls `GetTarget()->Mount(14584)` directly. The persistence clause is `Spell.cpp:6189-6197`'s own Divine-Charge-named bypass: `m_caster->IsOnDivineSteed()` (`Unit.cpp` ~18925, true when `GetAura(527272)`'s caster is a class-19 player — `CLASS_MONK` is this engine's enum name for the class whose in-game title is Templar, `SharedDefines.h:145` — and `GetMountID() == 14584`) exempts any non-passive cast from the generic `IsMounted()`-forces-`SPELL_FAILED_NOT_MOUNTED` gate, for the caster and, independently of the ally's own class, for the ally too, since `IsOnDivineSteed()` only inspects 527272's *caster*. The scenario casts the already-proven Crusader's Presence 562302 (`persist_spell`) as the unrelated cast; no server defect, both clauses are stock-engine/CoA-script behaviour unaudited by any existing scenario before this entry |
| Spiritual Ascension 500688 | cast_combat | "Usable while in combat." | `combat` reads 1 (real fight), `cast_failure` reads 0 at a dead ally while fighting | round10 `cast-conditions-cooldowns` investigation (2026-11): 500688's own `Attributes` DBC field carries `NOT_SHAPESHIFTED`/`AURA_IS_DEBUFF`/`ALLOW_WHILE_SITTING`/`NO_AURA_CANCEL` only, no `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL` - unlike a stock combat-blocked resurrection spell such as Redemption 7328, whose own `Attributes` carries exactly that one flag. The stock `CheckCasterAuras` path that would otherwise refuse the cast with `SPELL_FAILED_AFFECTING_COMBAT` therefore never triggers for 500688; no CoA-specific code is involved, no server defect |
| Beckon 804914 | aggro_redirect | "Taunt an enemy to attack you" | the gated dummy's `victim` switches from `ALLY` to `CASTER` | round10 `cast-conditions-cooldowns` investigation (2026-11), ADR 0056: `EffectImplicitTargetA` all `TARGET_UNIT_TARGET_ENEMY` (single explicit target); `Effect[0]` 114 `SPELL_EFFECT_ATTACK_ME` (`Spell::EffectTaunt`) + `Effect[1]` 11 `SPELL_AURA_MOD_TAUNT`. Stock engine path, no CoA-specific code, no server defect |
| Absolution 800424 | aggro_redirect | "Taunt all enemies within 8 yds" | dummies at 3.0/6.0 yd switch `victim` to `CASTER`; one at 20.0 yd does not | round10 `cast-conditions-cooldowns` investigation (2026-11), ADR 0056: `EffectImplicitTargetA[0]` 22 `TARGET_SRC_CASTER` + `EffectImplicitTargetB[0]` 15 `TARGET_UNIT_SRC_AREA_ENEMY`, `EffectRadiusIndex[0]` 14 (`SpellRadius.dbc` `RadiusMax` 8.0) — a self-centred area taunt (`Effect[0]` 6 `SPELL_EFFECT_APPLY_AURA`, `EffectApplyAuraName[0]` 11 `SPELL_AURA_MOD_TAUNT`) matching the tooltip's own figure. A dummy at 10.0 yd (just past the nominal radius) measured redirected too, read as area-search hitbox padding around the boundary rather than a defect in the 8-yard figure (ADR 0056); the "outside" target was moved to 20.0 yd to prove the clause unambiguously instead. Stock engine path, no CoA-specific code, no server defect |
| Condemnation 704175 (`variant: "oath"`) | metric_delta | "Increases the critical strike chance gained through Condemn by $s1%" | melee crit 10.146 before, 13.146 after (7.146 without the Oath) | `Effect[0]` aura 107 `SPELLMOD_EFFECT1` +3 on Oath: Condemn 804922's `Effect[0]` aura 290 (+3% crit chance), granted by a Condemn 804906 cast through `GrantOath`; `melee_crit_chance` is the state the clause names |
| Condemnation 704175 (`variant: "talent_without_oath"`) | metric_delta (`gate_timing: start`, `trigger_only_after`) | "Increases the critical strike chance gained through Condemn by $s1%" | refreshed melee crit 7.146 with the talent and no Oath, 13.146 after a Condemn cast | the arm the `oath` variant leaves out: no crit gained without Condemn |
| Condemnation 704175 (`variant: "periodic_crit"`) | metric_delta | "allows its periodic damage to critically strike" | 0 before, 3 after | `Effect[2]` aura 286 on Condemn 804906; Condemn is a melee-class DoT, so its tick crit chance is the melee crit percentage, forced on the caster; critical ticks 10500 ms after the cast |
| Deep Secrets 705263 (`variant: "libram"`/`"testament"`) | cast_applies_aura with control | "Increases the duration of your Librams and Testaments by $/1000;s1 sec." | Libram of Zeal 801466 20000 then 30000 ms; Testament of Resolve 804228 10000 then 20000 ms | `Effect[0]` aura 107 `SPELLMOD_DURATION` +10000; the testament arm removes Sacred Restraint 102208 before its second cast |
| Norgannon's Wrath 524739 | event_delay | "After a short delay, you blast them with immense holy force" | 1500 ms from the cast to the cast of 524740 | `Effect[1]` 183 `SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED`, points 1500, `EffectTriggerSpell[1]` 524740 (`Speed` 30, its flight read from its own cast packet); no CoA code names 524739 |
| Titanstrike 806521 | cast_applies_aura with an extra-cast control | "extending the duration of your Oath Chain by $/1000;707896s1 sec." | Oath Chain 704576 15000 ms without, 18000 ms with a Titanstrike 5000 ms after Condemn 804906 (a refresh to the maximum would give 20000 ms) | `Effect[1]` triggers 707896, whose `Effect[0]` 177 `SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION` adds 3000 ms to the caster's own 704576 |
| Tyr's Blessing 705285 | metric_delta (`setup_wait_ms`) | "Condemn now stacks $s1 additional time." | Condemn 804906 `aura_stacks` on the dummy 3 before, 4 after five casts | `Effect[0]` aura 107, `EffectMiscValue[0]` 31 `SPELLMOD_MAX_AURA_STACKS`, read by `SpellInfo::CalcMaxAuraStacks` on every stack increase |
| Barrier of Light 805417 (`variant: "received"`) | hit_ratio | "increasing the healing received by nearby party and raid members by $s3% for $d" | 1.40 | `Effect[2]` area aura 319 `SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT`, read by `Unit::SpellHealingBonusTaken` (Unit.cpp:10898); the ally's Chakra of Light 803845 heals the caster, who casts Barrier before every treatment heal |
| Oath Flow 705283 | cast_applies_aura with control | "Increases the duration of Oath Chain by $s1%." | Oath Chain 704576 15000 then 18000 ms | `Effect[0]` aura 108 `SPELLMOD_DURATION` +20%; `GrantOath` sets the chain to `GetMaxDuration()` after a Condemn 804906 cast |
| Chivalric 705272 (`variant: "spell"`/`"ability"`) | hit_ratio | "Increases your critical damage with Holy spells and abilities by $s1%." | 1.15 | `Effect[0]` aura 163 Holy; forced crits of Reckoning 572741 (magic) and Titanstrike 806521 (melee), critical hits only |
| Blade Sermon 572548 / 572554 (`variant: "off_hand"`) | hit_ratio | "Increases the Weapon Damage dealt by Zealotry by $s1%" | 1.125 / 1.25 | Zealotry 801450 cast with the off hand wielded; its weapon percent 80 becomes 90 / 100 |
| Bursting Impact 705276 (`variant: "swing"`/`"zealotry"`/`"blade_sermon"`/`"empty_off_hand"`/`"share"`) | hit_ratio | "Increases your off-hand weapon damage by $s1%." | swing 1.25, zealotry 1.25, blade_sermon 1.5625, empty_off_hand 1.0 | `Effect[0]` aura 122 on the off-hand `TOTAL_PCT` for plain swings; for Zealotry 801450, whose Holy hit skips `TOTAL_PCT`, the Templar hook sets its weapon damage multiplier when an off-hand weapon is equipped (owner ruling 2026-11-11, ADR 0146); `blade_sermon` multiplies with Blade Sermon 572554; `share` judges the same 1.25 at 313 attack power with the narrow-range off-hand Cudgel 2492; Zealotry's own 80% without the talent follows from the Blade Sermon rank 2 ratio, (p + 20) / p |

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


### Auras set around behaviour casts (ADR 0170)

Four kinds can set auras around their casts. Without the fields every scenario is unchanged.

- `metric_delta` `phase_auras` and `after_auras`: lists of `[spell, stacks, on, by]`, with `on` and `by` each
  `caster` or `dummy` (the holder and the aura's caster). `phase_auras` are set at the start of both phases,
  `after_auras` at the start of the after phase only, before the phase auras; a stack count of 0 removes the aura.
  Crusader's Brand 300513: Courage 707754 on the dummy before and after a brand cast (`speed_cap`), and a fear 12096
  set on the caster by the dummy in both phases with the brand set on it in the second (`flee`).
- `fixed_count` `auras`: `[spell, stacks]` set on the caster before every cast. Libram of Consecration 803893 is held
  before each Chastise, so 804148 strikes the primary and 4 nearby enemies.
- `absorb_pierce_ratio` `target_auras`: `[spell, stacks]` set on the dummy before both casts. Blessed Resilience
  33143 (aura 197, -1000% attacker crit chance) keeps either cast from critting, which read 1.5 instead of 1.
- `group_stack_cap` `value_spell`, `swing_ms`, `marker_spell` and `tolerance`: the own percent is read from
  `value_spell`'s effect when the learned spell only casts the aura (Devotion of Khaz'goroth 560096 casts 567572).
  With `swing_ms`, each of the three phases casts `marker_spell` on the caster, swings at the dummy for `swing_ms`
  and reads `event_interval_median_ms` of the main-hand hits since the marker (an event read); the judge divides the
  baseline interval by each haste factor (`relation: inverse`) within `tolerance` ms.
- `taken_hit` arm `opening_casts`: `[spell, target]` cast once before the arm's first read, followed by a 1500 ms
  settle. Testament of Hope 1397742 summons its two copies once, before the treatment arm's strikes.

### School lockouts and positioned taken hits (ADR 0171)

- `school_lockout` (`expiry.school_lockout_scenario`): an interrupt's school lockout on a creature, judged as an
  expiry pair. The dummy channels `channel_spell` on itself (refused unless its PreventionType is silence and its
  ChannelInterruptFlags hold the interrupt flag); the caster then casts `cast_spell`, an instant spell, at it. The
  stated end is the DBC duration of `interrupt_spell`, timed from the cast (an act-anchored arm), and read with the
  harness metric `school_prohibited` (`Creature::IsSpellProhibited`) for the channel's school mask. The pair needs
  the dummy channelling and its school free just before the cast. Divine Force 806153: 807805 casts
  SPELL_INTERRUPT_NONPLAYER 32747 at a creature target; Evocation 12051's Arcane school is locked 2876 ms after the
  cast and free 3026 ms after it, against 3000 ms. The 6 s stun of the same cast does not change that read.
- `taken_hit` `targets` (`[[id, distance], ...]`, extra stationary dummies at that distance) and arm fields
  `select` (one of those ids, selected by the caster after the opening casts), `select_settle_ms` (wait after the
  selection) and `checks` (harness asserts after it, each a metric with a bound; a failed check fails the
  scenario). Testament of Hope 1397742's copies attack the owner's selected enemy, so selecting a dummy places them:
  within 16.5 yd with `near` (16 yd) selected, beyond 20 yd with `far` (24 yd); the strike hits 890 near and 1100
  far, judged as 1 / 0.81.

### Crit-rate scenarios (`behaviour_crit_rate`, `kind: "crit_rate"`, ADR 0173)

`crit_rate` uses the hit_ratio fields (`observe_spell`, `control` and `treatment` auras or casts, `learn`, `trials`,
default 300) and refuses a forced crit, a crit filter, another cast spell and swings. Each arm sets its auras before
every cast and counts the landed hits of `observe_spell` and the critical ones between a start and an end read
(`spell_damage_count`, then with `critical: true`); the scenario uses the accelerated cap. The judge takes the 99%
Newcombe interval of the difference of the critical shares (Wilson per arm) against `expected` points with the
5%-or-2-points band: ok inside the band, alert outside it, `measured` across its edge ("effect present, interval
stated, not final", with the hits per arm an interval inside the band would need). Scourge-Defense Training 520608:
300 Argent Blades per arm with Warrior of Dawn 561156, 520608 set first in the treatment.

### Selected dummy and lower bound in metric_delta (ADR 0174)

`metric_delta` `select_dummy` (default `false`) adds the dummy fixture and selects it at the start of both phases;
`after_at_least` (default none) judges the after read as at least that value instead of equal to `expected`, while
the before read stays exact. Testament of Hope 1397742 `combat`: the copies attack the selected dummy, 0
`owned_creature_damage_count` before the cast and at least 1 hit 6000 ms after it (6 in the diagnostic).

### Stat-gain scenarios (`behaviour_metric_delta`, `kind: "stat_gain"`, ADR 0213)

A `stat_gain` entry judges what a real cast adds to a stat of its target against the caster's own stats. It names
`cast_spell`, `cast_target` (`caster` or `ally`; the ally is grouped, ADR 0212, and `target_health_pct` sets its health
before each cast), the target `metric` and `fields`, `terms` (a `coefficient` times the sum of its `reads`, stat metrics
read on the caster), `clear_auras` (removed from the target before each cast), `wait_ms` (default 500) and `arms`. Each
arm learns its `learn` spells, sets its `auras` on the caster, reads the terms and the target metric, casts, waits and
reads the metric again. An arm with `gain` must gain exactly that; an arm without it must gain the formula on the
stats it read, inside floor(x) to ceil(x). Improved Benediction 705287: the grouped ally's armor gains 0 without the
talent, Agility + Stamina with it, and again with Agility 58451 and with Stamina 48101 set; Libram of Fervor 805423:
Holy spell power +30% of Agility and attack power +30% of Intellect, at the reference stats and with Agility 58451 or
Intellect 48100 set.

An entry has an `attribution` (ADR 0258) when two things hold:
- the cast spell is the entry's spell with its aura in `clear_auras`, or the first arm lacks the entry's spell,
  states its control `gain`, and a later arm learns the spell;
- the metric has a named read in `STAT_GAIN_READS`, which the verdict reports as `read`.

Each arm then reads these on the cast target:
- before and after the cast, the `clear_auras` and the auras the DBC says the cast applies, plus
  `applied_aura_count` and the caster's `spell_cast_count` of the cast spell (the cast landed);
- after the `clear_auras` are removed, the stat again (`return`).

The judge stamps `contrast: learned` when all of the following hold in every arm:
- the cast landed;
- the attributed auras read absent before the cast, and present after it in every arm except the withheld control
  arm;
- no unlisted aura appeared;
- any other applied aura comes with an arm without the spell;
- the stat returns to its reading before the cast.

Otherwise it stamps `condition`, and coverage keeps the state read at data. `applied_auras` in the detail lists what
each arm's cast applied.

### An enemy player in metric_delta (ADR 0214)

`enemy_player_race` adds `enemy`, a player of that race and the caster's class, at `TAKEN_HIT_PVP_LOCATION`; both
players are flagged for PvP after the base steps. The entry's `target` and `measure_actor` may then name `enemy`, and
only then. Tranquil Circle 801205's Tranquil State 850010 lasts 8000 ms on an orc in the circle (read 9800 ms and
10200 ms after the cast, its first tick at about 2000 ms) and 40000 ms on the dummy.

### A fixed-count dummy behind the caster (ADR 0223)

A `fixed_count` entry may set `behind_yd` (inside `radius`) for a cone: every dummy spawns `2 x behind_yd` further
out, one more dummy spawns `behind_yd` from the caster, and the caster is relocated `2 x behind_yd` along its facing
before the first cast, so that dummy stands `behind_yd` behind it and must stay unhit (model `behind_label`). Sacred
Swing 572769, "Swing at enemies in front of you": the four dummies 1.2 to 4.8 yd in front hit, the one 11 yd away and
the one 3 yd behind never.

### Cost-gate unset arm, fixed_count settle and layout, avoided casts (ADR 0216-0218)

- `cost_gate` `unset_arm: true` adds an arm `unset` after `with`: the talent known, the cooldown reset and the gated
  spell primed, but the `setup_casts` skipped; the attempt at the reduced level is refused. Transcending Strikes 804897:
  Divine Force 806153 primed at a dummy without Blade of Faith keeps its full 120000 ms cooldown.
- `fixed_count` `settle_ms` waits after each cast (the timeout then covers the waits), and `layout: "caster"` places the
  dummies around the caster while the cast still targets the primary dummy. Pulverizing 524620: five Condemns 804906
  at the primary, 21500 ms each; its pulse 524619 at the Templar's position hits the four dummies within 5 yd and never
  the one at 10 yd. Norgannon's Wrath 524739: `settle_ms` 2500 for the delayed strike.
- `cast_condition` `condition: "avoided"` (with `learn`) adds an aggressive, rooted attacker in front of the caster. The
  blocked attempt comes before any attack; the allowed one after Evasion 26669, one engaging swing interval and 6000 ms
  of the attacker's swings (the dodges are read). The attempts set no caster aura. Sacred Swing 572769 with Keeping the
  Oath 92109: 22 before, 0 after.
- `script_hit` `receiver: "caster"` reads a heal the script casts on the caster (a damage hit on the caster is refused);
  `model_auras` names auras the treatment casts put on the caster, which the hit model then counts among its modifiers
  (they must be cast by the entry), and `unresisted: true` drops the resistance mitigation for a hit that ignores it.
  The hit model now reads SPELL_AURA_MOD_DAMAGE_PERCENT_DONE (79) and SPELL_AURA_MOD_HEALING_PCT (118) modifiers of
  those auras (ADR 0219, ADR 0220). Libram of Grace 801463's Grace 804150 on the Templar under its own +20% healing
  received, Eternal Blessing 705300's 707111 under its own +15% Holy damage, Norgannon's Wrath's 524740 unresisted.

### fixed_count cap arms (ADR 0221)

The harness admits twelve creatures (eight before). `fixed_count` `headroom` sets how many candidates beyond the stated
count a capped entry offers, `far_dummy: false` places no dummy beyond the radius, and `primary_distance_reads: true`
reads each additional dummy's `distance_2d` to the primary before the casts, judged under `radius` (a dummy outside
alerts). Norgannon's Wrath 524739 `cap`: twelve dummies, each cast strikes the primary and exactly 9 others (10 in all);
`cap_control`: ten dummies, all struck. Their labels take the suffix after the spell id, as every `fixed_count`
`label_suffix` does (ADR 0240): `524739 cap behaviour_fixed_count`.

`cluster_yd` (ADR 0254), on a target-centred entry with `primary_distance_reads`, places the additional dummies within
that distance of the primary instead of within `radius`, and judges their reads under it. Norgannon's Wrath 524739
`cap_cluster`: twelve dummies within 2.5 yd of the primary, six casts.

### Blade of Faith ticks and crit (ADR 0243)

Blade of Faith's periodic ticks can crit since ADR 0243. Its crit entries force melee crit (it is a melee-class spell),
and the control forces 0 with Reduce Critical Strike Chance -100% 64481; every scenario that reads a Blade tick value
sets 64481 in both arms instead of only selecting non-critical ticks.

### Aggro-redirect range arms and cast auras in hit scenarios (ADR 0244, ADR 0245)

- `aggro_redirect` `rooted: true` roots every dummy (Self Root Forever 42716) before the engagement and reads its
  `distance_2d` to the caster right before the cast; a read more than 0.25 yd from the placed distance alerts.
  `label_suffix` names a second entry of the same spell. Absolution 800424 `range`: dummies read at 7.5 and 8.5 yd.
- `aggro_redirect` `geometry: true` (rooted entries only, ADR 0253) also reads, before the cast, every dummy's
  `combat_reach` and `position_z` and the caster's `combat_reach`, `position_z` and `run_speed_rate`, as information
  for the edge arithmetic; nothing is judged on them. Absolution 800424 `edge` brackets the engine's edge (11.6-12.35
  yd), `cap` places six dummies within 8 yd against MaxAffectedTargets 5, and the stock Challenging Shout 1161 `edge`
  (9.5 yd, then 13.6-14.35 yd) is the control. Controls live in `controls/<class>.json` (`class_id`, `behaviours`,
  each entry with `control_for`), outside the class file, its ledger, coverage and score; `generate --controls`
  writes only them, with the same scenario keys (ADR 0255).
- A class-file `cast_auras` entry now also sets its auras before every cast of the rank's hit and periodic-total
  scenarios. Blade of Faith's ranks set Reduce Critical Strike Chance -100% 64481, so their tick reads stay at a 0 crit
  chance.

### Cost-gate weapons, raised costs and removed cooldowns; fixed-count suffixes; resurrections (ADR 0233-0236)

- `cost_gate` arms the gated spell's weapon (an alternate weapon when the reference one does not fit: Vindication
  573324 under Radiance 706318). `arm_wait_ms` lengthens the wait before every arm, for a gated spell whose own aura
  would still be running (Righteous Tempest 807274, 5500). `cast_power` sets a cooldown gate's power before each cast
  (Justicar of the Light's cooldown arm, whose talent also raises Benediction's cost).
- A negative `reduction` on a power gate is a raised cost: `without` at the base cost goes through, `base` with the
  talent there is refused, `with` at the raised cost goes through, `beyond` one point below it is refused (Justicar of
  the Light 707663: Benediction 20 -> 30). A cooldown gate whose `reduction` equals the cooldown is a removal: both arms
  are attempted `margin_ms` after the global-cooldown wait, refused without the talent and through with it, and there
  is no `beyond` arm.
- `fixed_count` `label_suffix` puts the suffix after the spell id in the count and every dummy read, for two entries
  of one talent (Holy Edge on Scourgebane and Scarlet Hammer, with `learn` and expected-0 controls).
- `cast_combat` `resurrect: true` (with `cast_spell` and `label_suffix`): the dead ally answers the resurrection
  (`client_packet` 348) before the cast, and must stay dead, and after it, and must be alive (Spiritual Ascension
  500688, rank 500758).

### Fall damage and removed-cooldown limits (ADR 0237, ADR 0238)

- `fall_damage` (`behaviour_fall_damage`): `cast_spell`, `height`, `receiver` (`ally`, the default, grouped, or
  `caster`). The receiver is set to 10000 maximum health and lands from `height` through the harness `fall` action
  (a harness-simulated landing through `Player::HandleFall`), before and after a real cast of `cast_spell`; its health
  is read right before and right after each landing, and the aura on it after the cast. The loss with the aura must be
  at least 0 and below the loss without it. Harmonic Disposition 560653: 2973 and 1173 from 30 yd.
- A cost gate that removes a cooldown states, in its verdict, the time of the second cast, the spell's global
  cooldown and that a cooldown left below that time reads the same as none.
- `hit_ratio` `stated` (`bonus`, `parts`, ADR 0239) judges a talent that scales other effects in the talent's own unit:
  the measured ratio is read back as the bonus with prod(1 + part x (1 + bonus)) / prod(1 + part), and the band applies
  to it (Combat Training 706320, 20% on an Oath's +30%: 18-22%). A cost gate's `removal_wait_ms` attempts the second
  cast that long after the first, past the spell's own global cooldown, and reads the remaining cooldown right after the
  first cast (0 with the talent).

### A stated bonus read through int32 amounts (ADR 0241)

`hit_ratio` `stated` `truncated: true` scales each part as `SpellEffectInfo::CalcValue` does, int32 toward zero
(the integer-truncation ruling of 2026-11-11), so the ratio is a step function of the bonus. The expected ratio must
be the stated bonus's step. The judge reads the 99% interval back as the bonuses whose int32 amounts give it. Only
the stated step passes (amendment of 2026-11-12): `ok` when the interval holds one step and its amounts are the ones
the engine computation gives at the stated bonus, `insufficient_trials` when it holds the stated step and another,
and `alert` otherwise (between two steps, another step, or several steps without the stated one). Radiant Blade
524822 and 525080 (+25% and +50% on Oath: Righteous Lunge's +5% and +30%): amounts 6 and 37, 7 and 45, against the
Oath alone.
