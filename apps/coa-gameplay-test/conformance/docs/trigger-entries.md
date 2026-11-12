# Trigger entries

A `triggers` entry of the class file is a passive whose tooltip says that something always happens on a trigger
("Casting Sacred Swing now grants you Staffguard"): a proc entry whose chance is 100%, without a chance token.

| Field | Content |
|---|---|
| `aura`, `name` | the passive and its `SpellName[enUS]` |
| `tooltip` | its `Description[enUS]`, copied verbatim from the client DBC |
| `trigger` | `{"action": "cast", "spell": <rank>, "target": "self"/"dummy"/"ally"}`, `{"action": "attack", "spell": 0}`, `{"action": "periodic", "amplitude_ms": <ms>}` for a trigger that is the aura's own tick, not a player action, or `{"action": "taken_hit", "spell": <id>, "striker_entry": <entry>}` for a trigger a hostile creature's own hit starts, not a player action (see "Taken-hit trigger entries" below) |
| `trigger_text` | the words of the cleaned tooltip that name the trigger |
| `trigger_spell_text` | for a cast, the words of the rank's name or cleaned tooltip that make it such a trigger |
| `trial_metric` | one trial: `spell_cast_count`, `spell_damage_count`, `melee_attack_count`, `melee_damage_count`; for `periodic`, always `spell_cast_count` (descriptive only, no trial-count measurement is taken) |
| `trial_spell` | optional, `cast`/`taken_hit` action with `trial_metric: "spell_damage_count"` only: counts landed-hit events of this spell id instead of `trigger.spell`, for a trigger condition keyed on a different spell actually hitting (a server-cast ability, not the ability the scenario casts), regardless of what caused that spell to fire; the harness still drives attempts by casting `trigger.spell` as usual, it only reads a different spell's hits as the trial count (Priest Training 504561 and Iron Penance 523712: the scenario casts Vindication 573324 to drive attempts, but the real trigger is a landed hit of Zealotry 801450, which Vindication's own handler casts at a ratio that is not a fixed 1:1, so the trial reads `spell_damage_count` of 801450 directly) |
| `observe_spell`, `observe_source` | the spell a trigger casts, from `EffectTriggerSpell[n]` or tooltip `@s:<id>:0@` |
| `observe_note` | with a tooltip reference, why the text's spell is observed instead of an `EffectTriggerSpell` |
| `attempt_auras` | `{"spell", "stacks", "source"}` set before every cast, `source` quoting the tooltip behind it |
| `ally_health_pct` | for a `target: "ally"` cast, the ally's health percent set before every cast so the heal is effective |
| `caster_health_pct` | the caster's own health percent set before every cast, for a trigger the server code gates on an effective self-heal (`GetHealInfo()->GetEffectiveHeal()`), which is 0 at full health |
| `restore_charges` | for a cast trigger, restores the trigger rank's native charges before every attempt (needed when the rank is also a charge-counting `procs` entry's trigger) |
| `co_learn` | spell ids learned once, right after the aura's own `learn`, before any attempt; for a trigger whose server-side mechanism also requires a second, independent passive to be known |
| `force_crit` | `"melee"` or `"spell"`: the scenario's own player fixture (not the class file's shared `ratings`) gets `melee_crit_rating`/`spell_crit_rating` set to `FORCED_CRIT_RATING`, for a trigger the server code gates on `PROC_HIT_CRITICAL` |
| `trial_metric_fields` | optional, `attack` action only (`trial_metric` one of `MELEE_COUNTS`): extra fields merged into the trial measurement's `hand: "main_hand"` default, for example `{"critical": true}` to count only the swings that landed a critical hit, when the trigger's own condition is narrower than "every swing" (Parry Dance 804912's outgoing-crit leg: `melee_damage_count` filtered to `critical: true`, paired with `force_crit: "melee"` so most scheduled swings are valid trials) |
| `internal_cooldown_ms` | spaces scheduled attempts at least this many ms apart, on top of the trigger rank's own cast time and recovery, for a trigger the server code gates on an internal cooldown |
| `observe_metric` | `spell_cast_count`, `spell_energize_count` or `aura_apply_count` of `observe_spell` |
| `observe_actor` | `"caster"` (default) or `"target"`: which actor's `observe_metric` is measured, for a trigger whose effect lands on the target rather than the caster (`Unit::AddAura`, not a `CastSpell`) |
| `per_trigger`, `per_trigger_text` | the events per trial, 1 or 0.5 for "Every 2nd" (a whole number above 1 for a trigger that casts its spell several times, such as Disciplined Mind rank 2 681483: 2), and the words that state it |
| `trial_attempts_factor`, `trial_attempts_reason` | multiplies the scheduled attempts (default 1, unchanged); a cited reason, for a trigger whose own cast sometimes executes as a different spell id and so is not counted as a trial of itself |
| `periodic_initial_tick` | for a `periodic` trigger only: the aura's own `AttributesEx5` carries `SPELL_ATTR5_EXTRA_INITIAL_PERIOD`, so one extra tick is expected per counted part on top of `attempts x per_trigger` |
| `status`, `reason` | `unmodelled` or `ambiguous_tooltip` for an entry without a scenario, and why |
| `trigger` (status entries) | optional: a `status` entry with no real trigger mechanism to point to (dead effect, or reachable only through a mechanism this harness cannot drive) omits `trigger`, `trigger_spell_text` and `trial_metric` entirely rather than carry a fabricated shape; the entry-shape test only enforces the full `trigger` shape on entries that have one |
| `question` | the finding text when the entry's verdict is an `alert` the server code explains: a server finding goes to the open conformance checks list, not into a verdict change |
| `effect` | optional: disambiguates two entries sharing one `aura` (one DBC spell with more than one proc/trigger effect that each need their own check or disposition); the generated scenario key includes it so the two do not collide |
| `kind` | optional: `"cooldown_delta"` for a trigger whose effect is a fixed cooldown reduction rather than a counted cast/energize/aura-apply event (see "Cooldown-delta trigger entries" below); omitted for every ordinary entry, which keeps the shape above unchanged |
| `expected_delta_ms` | `kind: "cooldown_delta"` only: the expected reduction in milliseconds, read once as a magnitude (`abs(EffectBasePoints + 1)`), never cast |
| `observe_target` | `kind: "cooldown_delta"` only, optional: `"self"`/`"dummy"`/`"ally"`, the same vocabulary as `trigger`'s own `target`. Casts the observed rank at that target instead of with no target at all, for an observed rank whose own effect needs an explicit hostile/ally target to pass `CheckCast` (ADR 0054); omitted, the observed rank is cast with no target, unchanged from before this field existed. When set, `cooldown_trial_steps` also waits out the observed rank's own global cooldown (`observe_interval`) before casting the trigger, and `attempt_interval` reserves that wait a second time (once for this mid-trial wait, once for the existing end-of-trial spacing) |

When a tooltip names more than one independent trigger spell for the same effect ("Casting Righteous Upheaval
or Blade of Faith now grants you..."), each named spell gets its own entry: same `aura` and `observe_spell`,
different `trigger.spell`. `trigger_scenario` (ADR 0053) then labels the `Expectation` `"<aura> trigger_count
<trigger.spell>"` instead of the plain `"<aura> trigger_count"`, and the generated scenario key does the same,
so the entries never collide; a single-entry aura's label is unaffected. `checked_trigger_set` (run by
`trigger_entries()` over the whole class) rejects two default-kind entries that share both `aura` and trigger
spell, catching the mistake this disambiguation exists to prevent. `proc_rate` entries (`procs.py`) already
had the equivalent shape (`proc_label(aura, proc_spell, trigger)`); see Condemnation 706325 below for a
per-trigger-spell `proc_rate` example and Fervent Castigation 707606 / Blessing of Eonar 705290 for
`trigger_count` ones.

`aura_proc_rate` is not a judge of these entries: their passives have `ProcFlags` 0 and are scripted (design D10).
The observed spell is the passive's `EffectTriggerSpell[n]` (`observe_source` `EffectTriggerSpell[n] of <aura>`)
unless the text names another spell through an `@s:` reference; then the entry observes the named spell
(`tooltip reference @s:<id>:0@ of <aura>`) and says why in `observe_note`. An `attempt_auras` fixture keeps a
condition stated by another tooltip from blocking the claim, for example a cap on stacks.
A trigger is cast as the hit scenarios cast: before each cast the power is set to the cost, the cooldown is reset and
the `CasterAuraSpell` fixture is applied (Sacred Swing 681170, Righteous Upheaval 704576), one cast every
`max(StartRecoveryTime, cast time) + 500 ms`; a `self` trigger is cast without a target. An `attack` trigger attacks
`dummy` for the attempts times the weapon speed. A `target: "ally"` trigger adds a second player `ally`, groups the
caster with it once before the first cast (`{"action": "group", "actor": "caster", "target": "ally"}`, a raid group
so `Unit::IsInRaidWith` holds). If the trigger rank's own effects close the distance to its target
(`values.closes_distance`), the caster is also relocated `CHARGE_OFFSET_YD` away before every cast at the ally
(the same fixture `hits.py`'s ally-targeted hit scenarios use, needed so a charge-type rank is not already in its
minimum range); a stationary ally heal such as Testament of Faith (Binding Scripture's trigger cast) has no such
effect and leaves the caster in place. With `ally_health_pct` set, the ally's health is lowered to that percent of
a 10000 fixed maximum before every cast so a heal lands an effective, non-zero amount. With `caster_health_pct`
set, the caster's own
health is lowered the same way before every cast, for a trigger the server code only recognises on a self-heal
with a nonzero `GetEffectiveHeal()` (the reference caster starts at full health, so an uncapped self-heal would
otherwise always read as 0 effective healing and never fire). With `restore_charges` set, the trigger rank's
charge pool is restored before every cast (`"restore_charges"` fixture), needed for a charge-limited rank cast at
the harness's scheduled attempt rate rather than its native recharge rate. With `internal_cooldown_ms` set, each
attempt is spaced at least that long apart (`max(StartRecoveryTime, cast time, internal_cooldown_ms) + 500 ms`),
for a trigger the server code gates behind its own internal cooldown rather than the trigger rank's. With
`co_learn` set, each listed spell is learned once right after the aura's own `learn`, before the baseline and
the scheduled attempts, for a trigger whose server code also requires a second, independent passive to be known
before the mechanism runs at all. Divine Strikes 705255 still co-learns Righteousness 680891 from when the
entry's trigger cast Chastise (which needs Righteousness to cast Scourgebane); the entry's trigger now casts
Argent Blade 807268 instead, which casts Scourgebane unconditionally, so this `co_learn` is no longer required
by the mechanism, only kept as a harmless fixture leftover. With `force_crit` set to `"melee"` or `"spell"`, the scenario's own player
fixture (not the class file's shared `ratings`, which would force every scenario's crit chance) gets
`melee_crit_rating`/`spell_crit_rating` set to `FORCED_CRIT_RATING` (100000, shared with `behaviours.py`'s own
duration-scenario fixture), for a trigger the server code gates on `PROC_HIT_CRITICAL`: every scheduled attempt
is then a valid trial of the crit-gated condition (Deliverance 704116 needs a crit on Vindication or Righteous
Lunge).

A `periodic` trigger is not a player action at all: it is `SPELL_AURA_PERIODIC_TRIGGER_SPELL`'s own amplitude tick,
running from the generic engine's periodic-effect path rather than the proc-event path, so it is unaffected by
`ProcFlags` and needs no learned trigger rank. The scenario only learns the passive and waits
`attempts x amplitude_ms`; there is no cast, no attack and no `trial_metric` measurement (the `counts()` step pair
collapses to the single `observe_metric` count). Judging compares the events measured against the attempt count
computed at generation time (`part_attempts`, known from the scheduled wait), not against a game-measured trial
count: `|events - attempts x per_trigger| <= 1`, with the same no-event-in-the-baseline rule as every other
trigger. `per_trigger` is still required and is 1 for every `periodic` entry seen so far (one trigger-spell cast
per tick). The main-phase wait is not followed by the generic `drain` step every other trigger action gets: the
periodic aura keeps ticking for as long as it is applied, so any extra wait after the scheduled attempts would
let more ticks bleed into the same count; the events measurement is taken the instant the scheduled wait ends.
`periodic_initial_tick`, when true, adds one event per counted part on top of `attempts x per_trigger`, for a
passive whose own `Spell.dbc` `AttributesEx5` carries `SPELL_ATTR5_EXTRA_INITIAL_PERIOD` (0x200, "Immediately do
periodic tick on apply"): each part is a separate scenario that re-learns the passive from scratch, so each part
gets its own extra tick at apply, on top of the regular amplitude cadence.

`dual_wield` (`attack` triggers only) is `{"spell": <id>, "off_hand_item": <id>, "source": <citation>}` or
`{"known_spell": <id>, "off_hand_item": <id>, "source": <citation>}`: the class file's one-handed alternate weapon
replaces the reference main hand, and before the baseline the caster either learns `spell` or, with `known_spell`,
is only read (`knows_spell`, label `<aura> dual_wield knows <id>`) and keeps the dual wield it was created with;
it then equips `off_hand_item` in the off hand (slot 16). The harness `equip` step fails the scenario when the server
refuses the item, so an off-hand equip without a grant shows that the character can dual wield. With
`trial_metric_fields: {"hand": 1}` the trials are damaging off-hand swings, and the rule names the off hand.
Zealotry 92108 ("Your off-hand auto attacks now trigger Zealotry") reads Dual Wield 674, which every Templar learns
at login (`AscensionLiveBaselineData.h:128`), and equips Cudgel 2492 (ADR 0142).

### Taken-hit trigger entries

A `taken_hit` trigger is the mirror image of `attack`: the aura's own tooltip condition starts on a hit the
caster *takes*, never one it deals ("When you take Physical damage you now strike back..."), so there is no
caster action to drive at all. A `striker` creature fixture (`entry: trigger["striker_entry"]`, reusing
`behaviours.py`'s `STRIKER`/`STRIKER_HEALTH`/`STRIKER_DISTANCE` constants, `reaction: 0`/`stationary: true` so it
never engages or chases once the caster's own retaliation starts landing on it) repeatedly casts `trigger["spell"]`
directly at the caster instead, spaced `max(StartRecoveryTime, cast time, internal_cooldown_ms) + 500 ms` apart
(reusing `cast_interval` against the striker's own spell, not the caster's). Each attempt is a single
`{"action": "cast", "actor": "striker", "spell": trigger["spell"], "target": "caster"}`, with no auto-attack
`wait`/`stop_attack` bracket. A trial is counted the same way `attack`'s trials already are, but reversed:
`trial_metric` is always `spell_damage_count`, read with `actor: "caster"` (a player; the harness can only read a
combat-log metric from a player actor) and `caster: "striker"`, `target: "caster"` (a cast query selecting its
source rather than its target). `observe_metric`/`observe_spell`/`observe_actor` are unchanged. The breaker
spell chosen for `trigger["spell"]` must actually be castable by a generic NPC through `CastSpell(...,
TRIGGERED_FULL_MASK)`: a player spell with a nonzero `CasterAuraState` (Revenge 6572's `AURA_STATE_DEFENSE`,
requiring a prior block/dodge/parry the striker never has) still fails `Spell::CheckCast` with
`SPELL_FAILED_BAD_TARGETS` even triggered, so the chosen spell needs `CasterAuraState` 0 (confirmed empirically,
not by reading `TRIGGERED_FULL_MASK`'s own flag bits, since those did not resolve it); Claw (Pet) 16827
(`SchoolMask` 1, `DmgClass` 2, `Effect[0]` 2 `SCHOOL_DAMAGE`, `CasterAuraState` 0) is the one confirmed working so
far, reused by the Sacred Defense (705306) entry.

Every taken-hit attempt first sets the caster to its full fixture health (`set_health` 10000 of 10000), so a long
run of strikes never kills it. A `magnitude_ratio` and a `gate_absence` entry also take a `taken_hit` trigger (ADR
0181). The magnitude reads the striker's `spell_damage_total` and `spell_damage_count` on the caster as the trigger
side and the caster's copy as the observed side; a magic copy is judged after the striker's own level-based partial
resist (`target_steps` reads the striker). The gate absence learns only the aura and strikes from the creature
whose kind withholds the gate. Sacred Defense strikes with 32247 (a flat 1000 physical, `SPELL_ATTR3_ALWAYS_HIT`):
Harvest Golem 36 reads 0.1316 against 0.15 x 0.88 with 273 strikes back in 273 hits, and Heroic Training Dummy
31146, a boss by `type_flags` 4,
reads 0 in 273 (the first counted run, `20261111-222153`). A `gate_absence` entry may set `label_suffix`
(label `<aura> gate_absence_count <suffix>`, scenario key `(<aura>, "gate", <suffix>)`), so one aura can withhold
several gates (ADR 0184): Sacred Defense's second arm strikes from Sneed 643, a dungeon boss by its instance encounter.

### Cooldown-delta trigger entries

A `kind: "cooldown_delta"` entry is for a trigger whose tooltip states a fixed cooldown reduction on another,
unrelated rank rather than a cast, an energize or an aura application: the server code reads the trigger
effect's magnitude once per trigger and subtracts it from a native spell cooldown, without ever casting the
triggered spell. The ordinary `trial_metric`/`per_trigger`/`observe_metric` shape cannot express "a cooldown
drops by a fixed amount", so this kind carries its own narrower shape: `trigger` (always `action: "cast"`),
`observe_spell` (the rank whose cooldown is read, not the dead `EffectTriggerSpell` target), `observe_metric`
(always `cooldown_ms`) and `expected_delta_ms` (a positive magnitude) in place of `trial_metric`/`per_trigger`.
`checked_entry` validates this narrower shape through its own `checked_cooldown_entry` branch (cast only,
`cooldown_ms` only, a positive `expected_delta_ms`) instead of the standard one.

The scenario (`cooldown_trigger_scenario`) repeats, per trial: reset the observed rank's native cooldown, cast
it once (filling its cooldown back to its native `RecoveryTime`), measure `cooldown_ms`, cast the trigger once,
measure `cooldown_ms` again. Each trial is independent (the observed rank is always freshly reset before it),
so the per-trial time cost never grows with the number of trials; the same `TRIGGER_TRIALS`/`BASELINE_ATTEMPTS`
sizing and part-splitting as every other trigger entry applies (`trigger_plan`, reused unchanged). A baseline
part (the passive not learned) runs first and must measure a delta of exactly 0 in every trial. The judged
label is `<aura> trigger_cooldown_delta`, not `<aura> trigger_count`: a nonzero baseline delta is an `alert`;
with the passive learned, each trial's `before - after` must fall within `max(1, 0.5% of expected_delta_ms)`
of `expected_delta_ms` (the same tolerance formula `effect_value`/`passive_delta` already use) or the whole
check is an `alert`; an absent effect reads as a 0 ms delta, which is always outside that band, so it can
never pass by accident. Fewer than `TRIGGER_TRIALS` usable trials is `insufficient_trials`; a mean within
tolerance but no baseline trial is `unmeasured`, the same as the count-based check.

With `setup_casts` set, each listed spell is learned once up front (alongside the trigger and observed ranks,
before the baseline), then reset and cast at self first in every trial, before that trial's own observed-rank
cast and trigger cast, in both the baseline and the measured phases (the same semantics `metric_delta`'s own
`setup_casts` already gives the behaviour-scenario kind, reused here for the cooldown-delta kind). Each
setup cast's own wait (`cast_interval`) is spent once, right after it, instead of being folded a second time
into the trial's trailing spacing wait (which stays `observe_interval + trigger_interval`): `attempt_interval`
still sums all three for scheduling and for the scenario's own declared duration, so the two must never double
count the same wait or the generated scenario silently needs more real time than its own `timeout_ms` allows. This is for a cooldown-delta trigger whose
server code gates the reduction behind a second, independently-cast buff rather than a known-passive check:
Eternally Devoted 573452 needs Eternal Blessing 705300 *active*, not merely known — 705300 carries
`SPELL_ATTR0_IS_ABILITY` with a real `RecoveryTime`/`DurationIndex` (a 60 s cooldown, a 30 s buff), not
`SPELL_ATTR0_PASSIVE`, so the harness's `learn` action alone never applies its aura the way it does for an
always-on passive. Casting it fresh before every trigger cast keeps its buff active exactly when
`AscensionTemplarAbilities.cpp`'s `Breaker(info)` block checks `player->HasAura(705300)` to cast the hidden
707111 whose hit is what actually gates the reduction; `setup_casts` runs in the baseline phase too, since
705300 being active changes nothing there (the reduction itself still requires Eternally Devoted's own aura,
checked only in `OnSpellHitResult`), so a baseline delta still proves nothing fires without the checked aura
itself. A `setup_casts` entry equal to `aura` itself (Libram of Zeal 801466, below) is the one exception:
`cooldown_trial_steps` skips casting it specifically during the baseline phase, since casting it there would
apply the very aura the baseline exists to withhold (confirmed by a real baseline alert, "cooldown delta 3518
ms ... in a baseline trial without the passive", before this exclusion existed); every other `setup_casts`
spell differs from `aura` and keeps running in both phases exactly as described above.

`aura_apply_count` counts a target's `AuraApplyCounter` (`CoAGameplayTest.cpp`), a static `(unit, spell)` map
recorded from `UnitScript::OnAuraApply`, the generic engine hook `Unit::_ApplyAura` calls after every aura
application, including one made by `Unit::AddAura` (which never builds a `Spell` object, so `ProcCounter`'s
`OnSpellCast`-based metrics never see it). It is for an effect applied this way rather than through `CastSpell`;
`observe_actor: "target"` then measures it on the hostile `dummy` fixture instead of the caster.

`TRIGGER_TRIALS` is 182, the smallest N with 0.975^N <= 0.01: a trigger that fires 2.5 points under 100% of the time
misses at least once in 182 trials with 99% probability. The scenario learns the trigger rank, makes
`BASELINE_ATTEMPTS` (20, a choice, not derived) attempts and measures the trials and the events, learns the passive,
makes 273 attempts (`ceil(1.5 x 182)`, ruling R9) and measures the trials, the events and the passive's aura. Parts
split the attempts so that each wait fits the 600 s limit with the 60 s margin; only the first part holds the
baseline. The `trigger_count` expectation of every part has the label `<aura> trigger_count`; the comparison sums the
trials and the events after the learn of the parts whose run measured the aura. Any event in the baseline is an
`alert`; no usable trial is `unmeasured`; fewer than 182 trials are `insufficient_trials`; otherwise
`|events - trials x per_trigger| <= 1` is `ok` and anything else `alert`. A baseline without a trial never gives
`ok`: its verdict is `unmeasured`.

The Templar entries quote their trigger words from the cleaned DBC tooltips:

| Passive | Trigger | Trials | Observed | Per trial |
|---|---|---|---|---|
| Scarlet Secrets 520812 | "Every 2nd cast of Argent Blade", 807268 at `dummy` | casts | 804924 casts (`@s:`) | 0.5 |
| Sanctify 705274 | "Your Libram spells", Libram of Tenacity 801461, `self` | casts | 705275 casts | 1 |
| Blessing of Eonar 705290 | "Using Libram spells", 801461, `self` | casts | 520537 casts | 1 |
| Staffguard 705295 | "Casting Sacred Swing", 572769 at `dummy` | casts | 706583 casts | 1 |
| Conviction 712677 | "Casting Sacred Swing", 572769 at `dummy` | casts | 712679 casts | 1 |
| Fervent Castigation 707606 | "Casting Righteous Upheaval", 572027 at `dummy` | casts | 804924 casts | 1 |
| Mending Ward 806273 | "Oath Breakers", 572027 ("a dominating Oath Breaker") | casts | 806353 casts | 1 |
| Unbroken Creed 804932 | "Damaging abilities", 807268 at `dummy` | damage events | 807648 casts | 1 |
| Heaven's Finest 806516 | "Damaging abilities", 807268 at `dummy` | damage events | 805390 casts | 1 |
| Chakra of Power 803158 | "Melee attacks", auto attack | swings | 804181 energizes | 1 |
| Parry Dance 804912, effect 1 (crit leg only) | "critically strike with auto attacks", auto attack, `critical: true` | critical melee damage events (`force_crit: "melee"`) | 560651 casts | 1 |
| Way of the Monk 805420 | "Damage dealt by Sacred Swing", 572769 at `dummy` | damage events | 572052 casts | 1 |
| Chakra of Light 803844, 803159 | "Oath Breakers", 572027 ("a dominating Oath Breaker") | casts | 803160 casts | 1 |
| Scarlet Training 301065 | "Casting Argent Blade", 807268 at `dummy` | casts | 301172 casts | 1 |
| Binding Scripture 801457 | "Healing an ally", Testament of Faith 801478 at `ally` | casts | 705309 casts | 1 |
| Whirling Tempest 300504 | "While Righteous Tempest is active", 805409 (channel start) `self` | casts | 301340 aura applies | 1 |
| Light's Ward 300529 | periodic, 2000 ms amplitude | ticks | 301283 casts | 1 |
| Light's Chosen 301310 | periodic, 5000 ms amplitude | ticks | 301369 casts | 1 |
| Disciplined Mind 680399 | "causes it to dispel", 578276 at `self` | casts | 525052 casts (`EffectTriggerSpell[1]`) | 1 |
| Disciplined Mind 681483 | "causes it to dispel 2 poison and disease effects", 578276 at `ally` | casts | 525052 casts (`EffectTriggerSpell[1]`/`[2]`, cast once) | 1 |
| Deliverance 704116 | "Critically striking with Vindication", 573324 at `dummy`, `force_crit: "melee"` | casts | 801456 casts (`EffectTriggerSpell[0]`) | 1 |
| Lorescribe 804927 (effect 1, `kind: "cooldown_delta"`) | "Casting Oath Breaker abilities", 572027 at `dummy` | cooldown delta of Libram of Tenacity 801461 | 4000 ms reduction (`Amount(806106)`, never cast) | n/a |
| Libram of Zeal 801466 (`kind: "cooldown_delta"`) | "causes your damaging abilities to reduce the cooldown", Holy Cleave 801445 at `dummy`, `force_crit: "melee"` (most non-crit hits read 0 damage against the dummy fixture), `setup_casts: [801466]` (== `aura`, excluded from the baseline phase) | cooldown delta of Righteous Upheaval 572027 (the reference character's own known rank; `Reduce()` names rank-1 501562, matched by `spell_ranks` chain), `observe_target: "dummy"` (ADR 0054) | 2000 ms reduction (`Amount(575328)`, never cast) | n/a |
| Scarlet Champion 805415 | "Your damaging critical strikes", 807268 at `dummy`, `force_crit: "melee"` | damage events | 805416 casts (`EffectTriggerSpell[0]`) | 1 |
| Legacy of the Silver Hand 806522 | "Casting Argent Blade", 807268 at `dummy` | casts | 806523 casts (`EffectTriggerSpell[0]`) | 1 |

Chakra of Light's two ranks share Mending Ward's 806273 `Breaker()` condition and its 572027 fixture (same
`AscensionTemplarAbilities.cpp:192-198`): both are in `TemplarCastDrivers`, so the DBC's own `EffectTriggerSpell[0]`
803160 never fires natively (routed to `SPELL_AURA_DUMMY`, same P3-R8 pattern as Mending Ward); the scripted hook
casts it unconditionally on every Oath Breaker cast, once for the solo caster. Scarlet Training is also in
`TemplarCastDrivers` (its own `EffectTriggerSpell[0]` 301172 likewise decorative); the real condition
(`AscensionTemplarAbilities.cpp:232-235`) is casting Argent Blade 804929-family while a `GetScriptValue(704576)`
set by Warrior of Dawn 561156's apply hook (`AscensionTemplarAuras.cpp:114-120`) is non-zero, which the harness's
`set_aura` fixture (`attempt_auras`) satisfies by applying 561156 fresh before every cast. Once the transform fires,
the next scheduled Argent Blade 807268 cast executes as Scarlet Hammer 807035 instead (`SetTemporarySpellReplacement`)
and is not counted as an 807268 trial, roughly halving the usable trials per scheduled attempt; `trial_attempts_factor`
2 schedules 546 attempts so enough stay valid. Binding Scripture is in `TemplarEvents`; its condition
(`AscensionTemplarEvents.cpp:77-78`) is an effective heal (`GetEffectiveHeal()` non-zero) on a raid member other than
the caster, with no roll (matches `ProcChance` 100): the scenario groups the caster with the `ally` player once and
sets the ally to 50% of a 10000 fixed health before every Testament of Faith 801478 cast, so every heal is effective.

Whirling Tempest 300504 is in `TemplarCastDrivers`, so `ApplyContracts` zeroes its `EffectApplyAuraName[0]`
(`PROC_TRIGGER_SPELL`) at runtime and sets `ProcFlags` 0; the behaviour the entry measures is scripted
(`AscensionTemplarAuras.cpp:154-158`, an apply hook keyed on `Named(GetSpellInfo(), 805409)`, i.e. the self aura
805409 that starts the Righteous Tempest channel being applied while 300504 is known — not its periodic damage
tick 805410, which applies no aura to the caster and so never reaches this hook), not the generic engine. The entry still cites
`EffectTriggerSpell[0] of 300504` as `observe_source` because the DBC's own field happens to equal the real
observed spell (301340) even though the runtime path that actually casts it is the scripted hook, not the DBC
effect — the same coincidence `301065 Scarlet Training` and `301254 Improved Scarlet Hammer` already rely on.
805409 is its own self-channel (`SpellDuration.dbc` id 27, 3000 ms) with `RecoveryTime` and `CategoryRecoveryTime`
both 0, so nothing stops the harness from scheduling the next cast before the current one's 3000 ms duration
ends; recasting into an active channel fails `SPELL_FAILED_SPELL_IN_PROGRESS` (measured live: 146 failed casts
of 273 scheduled before this was caught). The entry sets `internal_cooldown_ms: 3000` to space attempts at least
that far apart; this is not a server-scripted cooldown like Untainted's, only the self-channel's own duration,
reusing the field for the same effect (a floor below the harness's own `CAST_MARGIN_MS` spacing) rather than
adding a second field with an identical mechanism.
Light's Ward 300529 and Light's Chosen 301310 are in neither `TemplarEvents` nor `TemplarCastDrivers`: their
`SPELL_AURA_PERIODIC_TRIGGER_SPELL` effects (23) run unmodified through the generic engine's amplitude tick
(2000 ms and 5000 ms), using the new `periodic` trigger action described above. Keeping the Oath 92109 also
carries a `SPELL_AURA_PROC_TRIGGER_SPELL` effect (42,
`EffectTriggerSpell` 681170 `SPELL_RECENTLY_PARRIED_OR_DODGED`), and `ApplyContracts` sets its DBC `ProcFlags` to
0 at runtime the same way, but this one is reachable: `data/sql/updates/pending_db_world/rev_20261001_04_templar_keeping_the_oath_avoid.sql`
(merged, PR #6159) gives 92109 an explicit `spell_proc` row (`ProcFlags` 40, `HitMask` 48 = dodge or parry,
`Chance` 100), and `LoadSpellProcs` populates `mSpellProcMap` from that row before the DBC-autogeneration gate
`SpellMgr.cpp:2512` ever runs, so the generic engine's `AuraEffect::HandleProcTriggerSpellAuraProc` casts 681170
on a taken melee dodge or parry with no scripted `OnProc` case needed. The entry is still `status: "unmodelled"`,
without a `trigger` field, because this harness has no action that makes a creature melee-attack the player
(`hits.py`'s `creature_fixture` is a stationary, non-aggressive dummy) nor one that forces or statistically
bounds a dodge/parry outcome — the same kind of missing-capability gap as Zealotry below, not a dead effect.
Zealotry 92108 carries a second `SPELL_AURA_PROC_TRIGGER_SPELL` effect (effect 1, `EffectTriggerSpell` 801450),
reachable the same way as 92109 (`rev_20260909_04_templar_completion.sql` gives it an explicit `spell_proc` row
and a `spell_script_names` entry, bypassing its own zeroed `ProcFlags`): `AscensionTemplarEvents.cpp`'s `Check`
fires unconditionally on a damaging *off-hand* auto-attack hit. This harness's reference Templar carries only a
main-hand weapon, and no code path under `src/server/coa/` grants Templar `CanDualWield` (every `SetCanDualWield`
call site is scoped to `CLASS_SON_OF_ARUGAL`, `AscensionCompat.cpp:1104-1109, 9583-9594`), so `Player::CanEquipItem`
(`Player.cpp:13412`) would refuse an off-hand weapon on this class file's character before an off-hand swing could
even be attempted; the entry is `status: "unmodelled"`, without a `trigger` field, for that harness-capability
reason. Warrior of Tyr 301253's own `SPELL_AURA_PROC_TRIGGER_SPELL` effect is likewise unreachable through the
proc/`ProcFlags` path `AscensionTemplarEvents.cpp` implements (no case, no `spell_proc` row for it or its
`EffectTriggerSpell`), but the tooltip's effect is reachable through a separate mechanism this `triggers` schema
cannot express (a power gain, not a discrete trigger count): see `classes/templar.json`'s `behaviours` entry for
301253 (`metric_delta`, "Behaviour scenarios" below) instead. Holy Tempest 301339 and Holy Combatant 500011 remain
genuinely open P5-family gaps (round3 `trigger-lot-5-spec.md`, part A); 301339 in particular needs a second
creature fixture for the hit's spread target that this round did not build.

Lorescribe 804927 carries two `SPELL_AURA_PROC_TRIGGER_SPELL` effects. Effect 0's `EffectTriggerSpell` 806089
is dead the same way Warrior of Tyr's own effect is unreachable through the proc path above: no `spell_proc` row
(`rev_20260909_04_templar_completion.sql` deletes any auto-generated one for 804927), no `OnProc` case, and no
reference to 806089 anywhere under `src/server/coa/`; the tooltip's single stated amount is sourced from effect 1
alone, so the entry is `status: "unmodelled"`, without a `trigger` field, the same shape as Keeping the Oath and
Zealotry above. Effect 1's `EffectTriggerSpell` 806106 is never cast either, but is not dead: `AscensionTemplarAbilities.cpp`'s
`OnSpellCast` reads `Amount(806106)` as a magnitude on every `Breaker()` cast while 804927 is known and reduces
every known Libram rank's native cooldown by it (`ReduceLibrams`). This is the `kind: "cooldown_delta"` entry
documented above: the observed rank is Libram of Tenacity 801461 (the same representative Libram the Sanctify
705274 and Blessing of Eonar 705290 entries already use), the trigger cast is Righteous Upheaval 572027 (the
same representative Oath Breaker cast Mending Ward 806273 uses), and `expected_delta_ms` is 4000 (806106's own
`EffectBasePoints[0]` -4001, `EffectDieSides[0]` 1, so `Amount()` is -4000; the tooltip's own
`$/1000;806106s1 sec` token divides that same magnitude by 1000).

Scarlet Champion 805415's `EffectTriggerSpell[0]` (805416) is cast from `AscensionTemplarEvents.cpp`'s scripted
`Check`/`OnProc` pair on any damaging critical strike, gated at most once per second
(`State(player).cooldowns.HasTimeUntilEvent`/`ScheduleEvent`, matching the tooltip's own "Can only occur once per
sec"); the condition is not restricted to a spell family, but the representative cast is Argent Blade 807268 (a
weapon-damage effect, so `force_crit: "melee"`), the same representative "damaging ability" Unbroken Creed 804932
and Heaven's Finest 806516 already use. `internal_cooldown_ms` is 1000, matching the scripted gate, and
`trial_metric` is `spell_damage_count` (the condition also requires `damage` nonzero, so only a hit, not every
cast, counts as a trial). The effect's 5-stack branch to High General 524617 is a separate, already-`ok` check
(`805415 effect_value 524617e0 #3`), not part of this entry.

Legacy of the Silver Hand 806522's `EffectTriggerSpell[0]` (806523) is cast unconditionally from the same
`talent` lambda Mending Ward 806273 uses, gated on casting Argent Blade (`Named(info, 804929)`, any rank) or
Scarlet Hammer (`info->Id == 807035`), matching the tooltip's "Casting Argent Blade or Scarlet Hammer" verbatim
and `ProcChance` 100 on 806522's own row; the representative cast is Argent Blade 807268, with no `force_crit`
needed (the trigger has no crit gate). 806523's own role (two guaranteed-crit charges on Scourgebane) is a
separate, already-reachable behaviour this entry does not need to reach to prove the cast fires.

Measured on 2026-11-07 (stamp `20261107-184729`, simulated clock, gameplay stage 57.0 s for 10 parts, no failed
cast, 20 baseline trials and no baseline event in each entry): all four entries are `ok` with 273 events in 273
trials.

Scarlet Secrets' `EffectTriggerSpell[0]` is 520926, a dummy aura its text does not name; the server never cast it in
273 Argent Blade casts (stamp `20261106-092819`), while the text grants Oath: Retribution 804924. Oath Chain 704576
caps the Oaths ("Once 10 stacks are reached you are unable to build more Oaths."): with the chain kept, 100 of 273
casts granted the Oath (stamp `20261106-093118`), so the entry removes the chain before every attempt.

Measured on 2026-11-06 (stamp `20261106-093404`, simulated clock, gameplay stage 29.8 s for 12 parts, no failed
cast, 20 baseline trials and no baseline event in each entry): nine entries are `ok` with 273 events in 273 trials
(Scarlet Secrets 136 in 273, expected 136.5). Two are `alert`, both explained by server code:

- Fervent Castigation 707606: 0 casts of 804924 in 273 Righteous Upheaval casts. The cast only sets a flag
  (`AscensionTemplarAbilities.cpp:178-179`); the Oath is granted when a later Oath starts a new chain
  (`AscensionTemplar.cpp:177-181`), not on the cast as the text says.
- Heaven's Finest 806516: 150 casts of 805390 in 273 Argent Blade hits. At 6 stacks the aura casts The Finest of
  Heaven 806517 and is removed (`AscensionTemplarAuras.cpp:134-138`), and no stack is granted while 806517 (8 s) is
  up (`AscensionTemplarEvents.cpp:208-214`); the text, its `@s:805390:0@` reference included, does not say so.
  6f0ed44e04 then granted a stack on every hit and kept 805390 at 6 stacks, which let every hit at 6 stacks
  refresh 806517 as well; 806517 is now cast only while it is absent, so it ends 8 s after its first application
  ("Additional applications do not refresh the duration", scenario `templar-finest-of-heaven-no-refresh`).

Both entries carry a `question`, so their alerts go to the "Findings" section of `questions.md`.

### Duration-delta trigger entries

A `kind: "duration_delta"` entry is for a trigger whose tooltip states a fixed extension of a *foreign* aura's
remaining duration on the trigger cast's target, the `aura_duration_ms` analogue of `cooldown_delta`'s
`cooldown_ms`: `trigger` (always `action: "cast"`, `target` one of `"self"`/`"dummy"`/`"ally"`), `observe_spell`
(the aura whose remaining duration is read, cast and read on the same unit `trigger["target"]` names, not the
caster), `observe_metric` (always `aura_duration_ms`), `expected_delta_ms` (a positive magnitude) and
`decay_wait_ms` (a wait, strictly greater than `expected_delta_ms`, spent between casting `observe_spell` and
reading its "before" duration) in place of `trial_metric`/`per_trigger`. The wait matters because the
observed aura's own duration only ever counts down on its own; reading it immediately after casting it (at or
near its `MaxDuration`) would clamp any real extension to 0 and the check could not tell "mechanism present"
from "mechanism absent" (the same "must be able to fail" rule every other check follows) — `decay_wait_ms` lets
it decay below `MaxDuration - expected_delta_ms` first, so a successful extension has somewhere to go.
`checked_entry` validates this narrower shape through its own `checked_duration_entry` branch (cast only,
`aura_duration_ms` only, a positive `expected_delta_ms`, `decay_wait_ms` strictly greater than it) instead of
the standard one.

The scenario (`duration_trigger_scenario`) repeats, per trial: cast the observed aura at `trigger["target"]`,
wait `decay_wait_ms`, measure `aura_duration_ms`, cast the trigger once at the same target, measure
`aura_duration_ms` again. A baseline part (the passive not learned) runs first; without the trigger's own
extension, the measured delta is only the aura's own natural decay over the real time the trial's steps take,
so the baseline tolerance band is `[-(elapsed window + margin), margin]`, not a flat 0 (the same "comparison
against the real elapsed window" `cooldown_delta`'s own baseline check already uses, mirrored because here the
passive *adds* duration back against the same natural decay rather than subtracting further). The judged label
is `<aura> trigger_duration_delta`; with the passive learned, each trial's `after - before` must fall within
`[expected_delta_ms - elapsed window - margin, expected_delta_ms + margin]` of `expected_delta_ms` (`margin` is
`max(1, 0.5% of expected_delta_ms)`, the usual formula) or the whole check is an `alert`; an absent effect reads
as a delta no larger than the window's own natural decay, which is always outside that band, so it can never
pass by accident. Fewer than `TRIGGER_TRIALS` usable trials is `insufficient_trials`; a mean within tolerance
but no baseline trial is `unmeasured`.

### Magnitude-ratio trigger entries

A `kind: "magnitude_ratio"` entry is for a tooltip whose trigger spell casts a second, distinct spell whose own
magnitude is a fixed percentage of the triggering hit's own (variable, crit-dependent) damage or heal — "now
deals/heals X% of the damage dealt", as opposed to a fixed flat amount. `trial_metric`/`per_trigger`/
`observe_metric` (the `trigger_count` family, `spell_cast_count`/`aura_apply_count`/`spell_energize_count`) prove
the triggered spell fires at all, but never that its amount tracks the specific hit that triggered it, which is
what this clause literally claims. A `magnitude_ratio` entry is added **alongside** the class file's existing
plain entry for the same aura (same `aura`, a distinct `effect` ordinal so the two scenario keys do not collide):
it does not replace the `trigger_count` entry, which keeps proving the "fires at all" half of the clause.

Fields: `trigger` (`action: "cast"` with `target` one of `"self"`/`"dummy"`/`"ally"`, or `action: "attack"` with
`spell: 0` for a plain main-hand melee swing with no trigger spell), `trigger_metric` (the metric summing the
trigger side's own output: `spell_damage_total` for a `cast` trigger, `melee_damage_total` for an `attack`
trigger), `observe_spell` (the triggered copy spell), `observe_metric` (`spell_damage_total` for a damage bonus,
`spell_heal_total` for a self-heal), `expected_ratio` (the tooltip's `$s1`/100 fraction) and an optional
`force_crit` in place of `trial_metric`/`per_trigger`/the plain `observe_metric` values. `checked_magnitude_entry`
validates this shape, including that `trigger_metric` matches the trigger's own action (an `attack` trigger
naming a spell, or pairing the wrong metric with either action, is rejected).

The scenario (`magnitude_ratio_scenario`) reuses the same `trigger_plan`/`attempt_interval` scheduling as every
other trigger kind, learns the passive (plus the trigger spell, for a `cast` trigger) with no baseline part: the
trigger side always deals its own damage/heal regardless of the passive, so a zero-passive control proves
nothing about the *ratio*, only about presence, which a sibling `trigger_count`/`proc_rate` entry already
covers. A `cast` trigger repeats the trigger cast across the part's scheduled attempts; an `attack` trigger
instead swings a main-hand weapon at the target for the same number of attempts (`attack`/`wait`/`stop_attack`,
the same shape `trigger_scenario`'s own `ATTACK` branch uses). The part then reads four cumulative numbers once
at the end: the trigger side's own `trigger_metric` total and its matching count (`spell_damage_count` of the
trigger spell for `cast`, `melee_damage_count` of the main hand for `attack`), and the triggered spell's
`observe_metric` total **and** its matching count (`spell_damage_count`/`spell_heal_count` of `observe_spell`).

`judge_trigger_magnitude` sums each of the four numbers across every part, then judges
`ratio = (observe_total / observe_count) / (trigger_total / trigger_count)` — the triggered spell's own mean
amount per occurrence, over the trigger side's own mean amount per attempt — against `expected_ratio` within
`max(0.01, 5% of expected)` (the owner's own "within 5% on numbers" standard), everything outside is `alert`.
The explanation and `detail.excluded` state the ratio range the check excludes (`compare.magnitude_excluded`): the
band widened by the 99% half-width of the mean of the per-part ratios when two parts or more were usable, otherwise
the band alone with the statement that one part gives no sampling interval.
When the observed copy is a magic-school `spell_damage_total` struck at the dummy, the scenario also reads the
dummy's `view_level` and resistance and the expected value is `expected_ratio` times the kept fraction of
`expected_mitigation` (linear monster resistance with its partial-resist steps, ADR 0092).
Normalising by each side's *own* event count, rather than taking a plain ratio of the two raw sums, matters
whenever the trigger does not fire on every attempt: summing raw totals instead would measure
`expected_ratio × (the trigger's own fire rate) × (events per trigger)`, diluted by however rarely the aura
procs, not the tooltip's `$s1` fraction alone (discovered empirically on Retribution 707391, ADR 0052). For a
trigger that fires on every attempt with exactly one triggered event each (Deliverance, Uther's Legacy),
`trigger_count == observe_count` and the two counts cancel, so the formula reduces to ADR 0051's original
sum-ratio exactly; the per-event form is a strict generalisation, not a different check for those two.
`insufficient_trials` compares `observe_count` (not `trigger_count`) against `TRIGGER_TRIALS`, since that is the
actual number of magnitude samples feeding the ratio — for a trigger that always fires this is the same number
as `trigger_count`, but for a probabilistic one it can be far smaller, needing a `trial_attempts_factor` to
schedule enough attempts; no usable part at all (the passive never learned, or a run with no measurement) is
`unmeasured`.

Deliverance 704116 (round10 `proc-chains`): "Critically striking with Vindication or Righteous Lunge now deals
$s1% additional Physical damage" — `$s1` is `EffectBasePoints[0]` 49 + `EffectDieSides[0]` 1 = 50 (`704116`'s own
`EffectApplyAuraName[0]` 354 `SPELL_AURA_ASCENSION_PROC_PERCENT_EVENT`, a scripted percent-of-event aura, not the
generic engine). The entry casts Vindication 573324 at a dummy with every swing forced to crit, and reads
`spell_damage_total` of 573324 against `spell_damage_total` of the crit-bonus copy 801456.

Uther's Legacy 706385 (round10 `proc-chains`): "Your Condemn now heals you for $s1% of the damage dealt" — `$s1`
is `EffectBasePoints[0]` 74 + `EffectDieSides[0]` 1 = 75 (same `SPELL_AURA_ASCENSION_PROC_PERCENT_EVENT` aura).
The entry casts Condemn 804906 at a dummy and reads `spell_damage_total` of 804906 against `spell_heal_total` of
the self-heal copy 707302.

Retribution 707391 (round10 `proc-chains`, the first `attack`-trigger entry of this kind): "Melee damage dealt
now has a $h% chance to strike 2 additional times for $s1% of the damage dealt as Holy Damage" — `$s1` is
`EffectBasePoints[0]` 29 + `EffectDieSides[0]` 1 = 30; `EffectTriggerSpell[0..2]` all name the extra-strike copy
525028 (`SchoolMask` 2 Holy, `ProcChance` 20). The `$h%` chance-to-trigger half of this clause is already proven
by the sibling `proc_rate` entry in `procs.py` (`707391 proc_rate`, `ok`, measured ~0.187 vs 0.2); this entry's
own job is the other half, that the extra strikes' own Holy damage tracks the triggering swing's damage rather
than being a flat amount. The trigger is a plain main-hand auto attack (`action: "attack"`, `spell: 0`, no
trigger spell to learn or cast) against a dummy; the scenario reads `melee_damage_total`/`melee_damage_count` of
the main hand against `spell_damage_total`/`spell_damage_count` of 525028, with `trial_attempts_factor: 2` (a
~20%-chance, 2-strikes-per-proc trigger only yields ~0.4 observed strikes per scheduled swing).

A first attempt without the per-event normalisation (ADR 0052) measured `0.1066` against a naive
`expected_ratio: 0.3` and alerted; that was the ratio-of-sums dilution the ADR fixes, not a server defect. After
the fix, three independent full-schedule gameplay runs (stamps `20261109-230914`/its two re-derived parts)
measured a consistent `0.2627`/`0.2626`/`0.2650` (mean ≈`0.263`) against the DBC's `0.3`, still an `alert`: a
reproducible ~12% shortfall, not sampling noise (three independent 15-lane runs agree to within 0.002). Read
this session and ruled out: `spell_bonus_data` zeroes 525028's AP/SP coefficients (so no bonus is added on top
of the override); `EffectRealPointsPerLevel[0]` is 0 for 525028, so `SpellEffectInfo::CalcValue`'s per-level
scaling branch never runs (`SpellInfo.cpp:474`) and the `BaseLevel`/`SpellLevel` 26 vs the level-60 test
character cannot explain the gap that way; the dummy's measured (authored) Holy resistance is `0`; the generic
engine's own `HandleAscensionPercentEventProc`
(`SpellAuraEffects.cpp:7283`) returns immediately for 707391 (its hardcoded id list does not include it), so
the whole effect runs through the CoA-scripted path alone, `AscensionTemplarEvents.cpp`'s shared `Check`/`Proc`
(`case 707391: return damage && melee && !periodic;` / `Copy(player, target, 525028, uint64(damage) * 30 / 100);`
called twice), read in full. The "Holy resistance 0" reading was the dummy's authored resistance only: monster
linear resistance adds 60 Holy resistance at level 60 at combat time (`docs/coa/monster-linear-resistance.md`),
12% average resist, and 0.3 x 0.88 = 0.264 is the measured ratio. The copy is not exempt from resistance
(`TemplarCopies` ignores armor and modifiers only), so the check now multiplies the tooltip fraction by the
dummy's kept fraction (ADR 0092); round 10's 0.2664 falls inside the new band around 0.264. The gameplay scenario
`templar-retribution-holy-strike-resist` pins 30% against a level-1 dummy and 26.4% against a level-60 one.
Holy Combatant 500011 (round5 `trigger-accounting`): "Your Argent Blade now also extends the duration of
Interdict on your target by 1 sec" extends Interdict 560116's remaining duration by `Amount(500014)` (1000 ms)
on every landed Argent Blade hit when the target still carries the caster's own Interdict
(`AscensionTemplarAbilities.cpp:296-303`). Interdict's own `SpellDuration.dbc` row (id 32) has `Duration` and
`MaxDuration` both 6000 ms, so `decay_wait_ms` 1500 lets it decay to 4500 ms remaining before the Argent Blade
cast, leaving headroom under the 6000 ms cap for the 1000 ms extension. Measured this round (stamp
`20261109-132802`): `ok`, mean 987.12 ms over 273 trials against the expected 1000 ms.

One With The Light 504807's own effect 2 (round5 `trigger-accounting`) is a plain `cooldown_delta` entry, not a
`duration_delta` one, observing Libram of Tenacity 801461's `cooldown_ms` the same way effect 1's existing entry
already observes Zealotry 801450's `spell_cast_count` (`checked by triggers entry` links the generic P5 report
at both effects to their own check, "Unmodelled by rule" above); measured this round (stamp `20261109-133249` and
again `20261109-134641`): `ok`, mean ~1018 ms against the expected 1000 ms. Effect 0's own claim (`Reduce(player,
root, 1000)` for each of `{500694, 806153, 801455}`, the same `Breaker(info)` block whose adjacent
`ReduceLibrams` call effect 2 confirms `ok`) could not get a working entry of its own this round: none of its
three roots fits the existing `cooldown_trigger_scenario`/`cooldown_trial_steps` shape, which self-casts the
observed rank with no explicit target and no wait before the trigger cast — 806153 (Divine Force) and 801455
(Testament of Will) need a hostile/friendly target they never get from a self-cast, and 500694 (Force of
Golganneth) can self-cast but its own 1250 ms `StartRecoveryTime` (its GCD) collides with the immediately
following, zero-wait trigger cast, which `Spell::CheckCast`'s global-cooldown check (`Spell.cpp:5846`) then
rejects with `SPELL_FAILED_NOT_READY`; measured this round (stamp `20261109-133249`), 162 of 244 scheduled
trigger casts failed that way, diluting the mean delta to 17.996 ms. Rather than report that dilution as an
`alert` on a mechanism effect 2's own sibling check already confirms works, effect 0 is closed through
`unmodelled_effects` (`passives.py`, checked ahead of `trigger_link`) with this evidence; a harness change (a
trigger-cast wait sized to the observed rank's own GCD, or a target-capable observed cast) would be needed to
measure it, out of this item's scope.

Fervent Castigation 707606 (round10 `proc-chains`, per-trigger-spell breakdown): "Casting Righteous Upheaval or
Blade of Faith now grants you Oath: Retribution" names two trigger spells; the existing entry (Righteous
Upheaval 572027) only proved one. Added a second entry, trigger spell Blade of Faith 803880 (chain-matches
803872, `AscensionTemplarAbilities.cpp:178`'s `Named(info, 501562) || Named(info, 803872)` Breaker(info) gate),
same `observe_spell` 804924. Both measured `ok` (two independent full runs, stamp `20261110-001004`/
`20261110-001147`): 572027's entry unchanged, 803880's entry events/trials matching 1:1.

Condemnation 706325 (round10 `proc-chains`, per-trigger-spell breakdown, `procs.py`, zero new tool code):
"Dealing damage with Condemn, Holy Cleave, or Blade of Faith now has a $h% chance to trigger Zealotry" names
three trigger spells; the existing entry (Blade of Faith 803880) only proved one.
`AscensionTemplarEvents.cpp:84`'s `Check()` reads, verbatim: `case 706325: return damage && (Named(info,
804906) || Named(info, 801445) || Named(info, 803872)) && IsWithinMeleeRange(...)`. Added two more entries,
trigger spells Condemn 804906 and Holy Cleave 801445, same `proc_spell` 801450; `procs.py`'s existing
`shares_aura`/`shares_proc_spell`/`trigger_key` disambiguation (used already by Lightkeeper and Might of
Aggramar) needed no changes. All three measured `ok` in two independent full runs.

Blessing of Eonar 705290 (round10 `proc-chains`, alternate trigger + a confirmed server defect): the clause
"$?s520007[ or Silverhand Incantation][]" is a conditional display token (if the caster knows spell 520007,
the tooltip adds "or Silverhand Incantation" to the trigger list); the existing entry (Libram of Tenacity
801461) only proved the unconditional half. Read `AscensionTemplarTemporaryLibramProcs.cpp`'s
`CheckProc`: it allows the proc when the finishing cast is Silverhand Incantation 801465 (`SPELL_SILVERHAND`)
and `player->HasSpell(520007) || player->HasSpell(92111)` (`92111`, "Scourgebane", is the already-learnable
rank an existing proc entry uses, so the new entry's `co_learn: [92111]` satisfies this without guessing
whether 520007 itself is directly learnable). The new entry first measured `alert` (0/273 events); misread as
an id mismatch, since 801465 itself deals no damage (its `EffectTriggerSpell[0]` 801501, same name, does) —
changing `SPELL_SILVERHAND` to 801501 in C++ still measured 0/273, disproving that guess (reverted, no diff
survives). The real cause, confirmed by reading `Spell::finish()` and `SpellMgr::CanSpellTriggerProcOnEvent`:
705290's `spell_proc` row (`ProcFlags` 16400, i.e. `PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS |
PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS`) only ever matches a *positive* cast — true for Libram of Tenacity (a
self-buff) but not for Silverhand Incantation (a harmful cast at the dummy, whose finish-phase `procAttacker`
is the `_NEG` flag, never in the row's mask) — so the proc-flag gate itself rejected every attempt, before
`CheckProc` (and its id) ever ran. Fixed in a *new* migration,
`rev_20261110_01_blessing_of_eonar_silverhand_proc_flags.sql` (`UPDATE spell_proc SET ProcFlags = 81936 WHERE
SpellId = 705290`, adding the `_NEG` bit), **not** by editing the original
`rev_20260909_04_templar_completion.sql` in place: a first attempt did exactly that, and the edit's changed
checksum made the world-cache refresh re-apply that already-merged file's own `INSERT` (which sets
Condemnation 706325's `spell_proc.Chance` to 100) without re-running the later, corrective
`rev_20260919_20_coa_proc_chance_parity.sql` (`UPDATE ... SET Chance = 0 WHERE SpellId IN (..., 706325, ...)`)
that depends on it running afterward — reproduced twice (Condemnation's three entries all read 100% instead of
~15%, same rebuilt binary sha256 as the passing baseline). Both halves measured `ok` after the new-file fix,
in two independent full runs.

### Gate-absence trigger entries

A `kind: "gate_absence"` entry is for a tooltip clause whose trigger is conditional ("**While a Libram is
active**, your Chastise will now unleash..."): added **alongside** the class file's existing plain
`trigger_count` entry for the same `aura` (same precedent as `magnitude_ratio`), it proves the opposite half of
the clause — that the effect does *not* fire when the named condition is withheld, even though the passive
itself is known. The plain entry's own baseline (no passive learned) cannot stand in for this: it proves "the
passive is required", not "the named condition is required while the passive is known".

Fields: the same `trigger` (`action: "cast"`, or `"taken_hit"` with its striker),
`trial_metric`, `observe_spell`/`observe_source`/
`observe_metric`/`observe_actor`, `trigger_text` as the default shape, plus `gate_text` (the tooltip words
naming the withheld condition) in place of `per_trigger`/`per_trigger_text`. `checked_gate_absence_entry`
additionally forbids `attempt_auras`: the entry must run with every optional fixture at its default, absent
state, or it would silently reapply the very condition it claims to withhold.

`gate_absence_scenario` reuses `trigger_plan`/`attempt_interval`/`attempt_steps`/`counts` unchanged: it learns
the trigger spell and the aura (the passive must be known; only the named condition is withheld), then runs
every scheduled attempt as a single measured phase with no baseline at all, the same single-phase shape
`self_trigger_scenario` already uses. `judge_gate_absence` sums `trials`/`events` across parts and requires
`events == 0` over at least `TRIGGER_TRIALS` trials: any nonzero count is `alert`; fewer trials is
`insufficient_trials`; no trial at all is `alert` (there is no "as-expected absence" case to distinguish it
from, the same choice `judge_self_trigger` already made). The judged label is `<aura> gate_absence_count`, and
`add_trigger` (`conformance.py`) keys its scenario `(<aura>, "gate")` so it never collides with the plain
`trigger_count` entry sharing the same `aura`.

`away_yd` (a dummy target only, at most 20 yd) withholds a range condition: the caster steps `away_yd` back once
before the attempts, steps forward before each cast and back again right after it, so the trigger's later damage,
such as a periodic tick, lands while the caster is out of range. The scenario then casts `observe_spell` at the dummy
from that position and reads its `cast_failure` (`<aura> gate away control cast`): a spell with its own range shorter
than the away position would read 0 events with or without the gate, so a refused control cast makes the verdict
`unmeasured`. Condemnation 706325 ("if you are within melee range of your target") waits its Condemn 804906 ticks
6.5 yd from the dummy, outside the 5 yd melee range and inside Zealotry 801450's 7.775 yd (5 + both combat reaches):
0 Zealotry casts in 594 ticks, and the control cast goes through (diagnostic 20261111-194228). Its in-range rate is
the `706325 proc_rate 801450 804906` entry. A first version stood 18 yd away, where Zealotry's own range hid the gate.

Faith Guard 705259 (round10 `proc-chains`): "While a Libram is active, your Chastise will now unleash a line of
holy power..." The reference Templar carries no Libram by default (the sibling `trigger_count` entry needs its
own `attempt_auras` to set one), so this entry withholds the condition for free, with no extra fixture. Two
independent gameplay runs (stamps `20261110-024138` and `20261110-024246`) each measured 0 events of 706466
over 273 trials of Chastise 503141, `gate_absence_count` `ok`.

### Self-trigger entries

A `kind: "self_trigger"` entry is for a tooltip clause whose own cast is unconditionally its own trigger, with
no separate passive to learn and gate a baseline against (`trigger.spell == aura`): "Applies X" or "triggering
Y" stated on the ability's own tooltip, not on a passive that modifies it. The default `trigger_count` shape
cannot prove this (ADR 0055): it always learns `trigger.spell` before running a baseline phase (needed to cast
it at all), so when the aura *is* the trigger spell that `learn` already teaches it before the baseline/measured
split exists, and `judge_trigger`'s own guard then forces the verdict to `unmeasured` by design, since no part
ever carries a real "without the passive" baseline.

Fields: the same `trigger` (`action: "cast"` only, `trigger.spell` must equal `aura`), `trial_metric`,
`observe_spell`/`observe_source`/`observe_metric`/`observe_actor`, `per_trigger`/`per_trigger_text`, `co_learn`,
`force_crit`, `attempt_auras` and `trial_attempts_factor`/`trial_attempts_reason` as the default shape.
`checked_self_trigger_entry` enforces `trigger.spell == aura` and runs the rest of the default shape's checks.
`self_trigger_scenario` reuses `trigger_plan`/`attempt_interval`/`attempt_steps`/`counts` with no baseline phase
at all: it learns the aura once, runs every scheduled attempt as a single measured phase, and reads `trials`/
`events` once at the end — no "aura present" measurement, since an active ability learned into the spellbook is
not an aura to check presence of. `judge_self_trigger` sums `trials`/`events` across parts and judges `events`
against `trials x per_trigger` exactly like `judge_trigger`'s own measured-phase arithmetic, with no baseline
or "absent passive" branch: a part with no measurement at all is an `alert` (there is no corresponding "the
passive was absent, as expected" case left to distinguish it from).

Testament of Fortitude 500678 (round10 `proc-chains`): "Applies Sacred Restraint for $102208d" —
`EffectTriggerSpell[2]` of 500678 is 102208 (`Effect[2]` `SPELL_EFFECT_TRIGGER_SPELL`), cast on every cast of
500678 itself; `observe_metric: "aura_apply_count"` of 102208. Two independent runs each measured 273/273,
`self_trigger_count` `ok`.

Vindication 573324 (round10 `proc-chains`): "triggering Zealotry" — `AscensionTemplarAbilities.cpp:305-307`
(`OnSpellHitResult`) casts Zealotry (801450) unconditionally on every landed hit of the Vindication chain
(`Named(info, 801446)`). A first run with no `attempt_auras` fixture measured 501 events over 273 trials, far
above `per_trigger: 1` — reproduced, not an artifact: every Vindication cast also unconditionally grants/stacks
Oath: Vindication (805332) via `GrantOath()` (`AscensionTemplarAbilities.cpp:155-162`, `OnSpellCast`), and that
aura's own roll (`AscensionTemplarAbilities.cpp:311-313`) adds a second, cumulative Zealotry trigger as the
stack grows across repeated casts — the tooltip's own separate "Oath" clause, not this one. An `attempt_auras`
fixture (`{"spell": 805332, "stacks": 0, ...}`, the existing `set_aura` action with `stacks: 0`, which already
removes the aura regardless of caster) clears the Oath before every attempt. Two independent runs after that
fix each measured 273/273, `self_trigger_count` `ok`; the Oath's own chance clause remains separately unproven.
