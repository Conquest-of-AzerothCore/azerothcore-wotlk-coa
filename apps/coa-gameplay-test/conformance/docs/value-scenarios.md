# Value scenarios (no-combat)

## No-combat scenario of a rank

`value_scenario` returns a schema 1 scenario of one rank and its `Expectation(label, check, spell_id, rank_id,
effect_index, displayed, rule)` list. `label` is also the label of the measurement step, and is unique in the scenario.
`displayed` is the token as written in the DBC: the comparison reads the tooltip again with the measured caster
stats, since the value depends on them. The scenario learns the rank, then measures (assertions with extreme bounds):

| `check` | Measurement | Expected from |
|---|---|---|
| `effect_value` | `spell_effect_value` of the token's effect | the tooltip token (`rule` `read <kind>`) |
| `effect_value` of another spell | `spell_effect_value` of the effect of the token's first `$<id>sN`/`$<id>mN`, `model` `{'effect_spell': id, 'effect': n}` | the tooltip token, label `<rank> effect_value <id>e<n> #<ordinal>` |
| `max_stacks` | `spell_max_stacks` of spell `<id>` of a `$<id>u` token, `model` `{'effect_spell': id}` | `StackAmount` of that spell, compared exactly |
| `spell_duration` | `spell_duration_ms` of spell `<id>` of a `$<id>d` token, `model` `{'effect_spell': id}`, label `<rank> spell_duration <id> #<ordinal>` | the token: `Duration` of that spell, capped by `MaxDuration` |
| `power_cost` | `spell_power_cost` before any cast | `ManaCost` divided by the client display divisor of the power type (1, 10 rage and runic power, 1000 happiness) |
| `cooldown_ms` | `cooldown_ms` right after the cast | `max(RecoveryTime, CategoryRecoveryTime)`, as the client tooltip |
| `aura_amount` | `aura_amount` of the effect after the cast | the same tooltip token as `effect_value`, for an effect that applies an aura |
| `aura_duration_ms` | `aura_duration_ms` after the cast | the `$d` token of the rank, for an instant spell that applies an aura |
| `known_aura` | `aura` before any learn | the class file; the aura's own tooltip gives its modifier |

A rolled effect (`EffectDieSides` neither 0 nor 1) of an own or foreign `effect_value` is read k times: the step
`<label>` and its copies `<label> sample <n>` for n = 1 .. k - 1, each one `CalcValue` roll. k is the hit-mean count
`ceil((Z x sigma / (1% x |mean|))^2)`, Z 2.576, with the mean and the population sigma of the token read once per
roll (`ForcedPoints`) at the structure stats, and is kept as `model['samples']`. The copies must fit in what the
other steps leave of the harness's 10000-step limit (`MAX_SCENARIO_STEPS`, `run.py` `validate`) and in 1800 reads
(`READ_BUDGET_MS` 45 s, half the 90 s default `timeout_ms`, at `READ_STEP_MS` 25 ms, the largest step of the
simulated clock; the harness runs one step per world update); otherwise the effect is read once and its verdict is
`measured`. Templar: 51 rolled tokens, 2 to 1716 reads (Vindication 501589 102, Reckoning 572741 366).

A token without an id names the spell whose tooltip holds it: for a token of an expanded `@s:` tooltip that is the
referenced spell, so its `$sN`, `$u` and `$d` are checked as tokens of another spell (Zealotry 92108 `$s2` is
`effect_value` of 801450 effect 1; Glory 801481 checks its own `$d` as `aura_duration_ms` and the `$d` of Downfall
801482 and Redemption 801483 as `spell_duration`). The sign of an unsigned expanded token comes from the referenced
spell's points.

The cast, when a cooldown or an aura is measured, targets the fixture creature `dummy` (entry 36) when an active
effect has an enemy target (implicit targets 2, 6, 15, 16, 24), a fixture ally player `ally` when an active effect
is a resurrection (`SPELL_EFFECT_RESURRECT` 18 or `SPELL_EFFECT_RESURRECT_NEW` 113, `targets_resurrect`) — the ally
is killed with a `die` step right before the cast, since `TARGET_FLAG_CORPSE_ALLY` needs a dead friendly unit, not
a living one (Templar: Spiritual Ascension 500688/500757/500758/500759/500760) — and the caster otherwise; an aura
whose target is the caster is read on the caster. A cost in a power other than mana is set to its cost before the
cast. A rank whose
record names a `CasterAuraSpell` gets that aura as a one-stack fixture (`set_aura`) right before the cast: without it
the server refuses the cast with `SPELL_FAILED_CASTER_AURASTATE` (22, `Spell.cpp:5930`). Templar: Oath Chain 704576
for Righteous Upheaval, Blade of Faith, Righteous Tempest and Reckoning; Recently Parried or Dodged 681170, a dummy
aura, for Sacred Swing. Two diagnostic measurements ride along without an `Expectation`: `<rank> cast_failure` and
`<rank> aura_present`.
The remaining aura duration is read in the cast step's own tick: measured 12 to 15 ms below the record on instants.
`cooldown_ms` is the remaining cooldown, measured 6 ms below the record right after the cast.
A rank whose record names a `TargetAuraState` gets a health fixture on its hostile target before the cast
(`required_target_health_steps`, `values.py`): `AURA_STATE_HEALTHLESS_35_PERCENT` (13) sets the target to 30% of its
max health, strictly below the 35% gate and above any lower-threshold check that might also apply, then waits 1000
ms for `Unit::Update` to recompute the derived aura state flag. Without the wait the cast can still see the stale
flag and fail `SPELL_FAILED_TARGET_AURASTATE` (111). An unmapped `TargetAuraState` is `unmodelled: target aura state
<n> has no scenario fixture`, never silently skipped. Templar: Titanstrike 806521/806834/806835.

A value that cannot be compared is never dropped; its `rule` starts with a stable prefix:
`unreadable: <entry>` for a part the reader could not evaluate (the scenario measures the spell's first active effect
beside it, which is not the token's own effect),
`unreadable: ManaCostPercentage ...` or `unreadable: ManaCostPerlevel ...` for a cost the DBC alone does not give,
`generic: tooltip has no $ token to check (prose-only effect; see README "Tooltip reading")` for an empty readout
(an `unreadable: tooltip without value` row before this item; never a number either way, so classified `unmodelled`
rather than left for the reader to keep re-investigating),
`generic: client extension note, never a number: <entry>` for a `readout.unreadable` entry that is only a client
`@ext:...:ext@` note, and
`unmeasurable: <reason>` for a readable token with no no-combat metric (a periodic total or `mixed` token left to
the hit scenario, a chance token, an aura of a passive or cast-time spell, a foreign amplitude or an amplitude of a
passive effect, another spell's effect or radius that `Spell.dbc` does not define or that `disabled_foreign_effects`
names, which `spell_effect_value`/`spell_effect_radius` refuse). Only `unmeasurable` expectations may lack a
measurement step. The rank's own radius (`$aN`), own period (`$tN`/`$TN` after an instant cast) and own stack count
(`$u`) are measured, through `spell_effect_radius`, `aura_amplitude_ms` and `spell_max_stacks`; `$i`
(`MaxAffectedTargets`) still has no no-combat metric.
`$<id>h` stays `unmeasurable: chance_pct token ...`: `spell_proc_chance` needs a `spell_proc` row of that spell, so
no step reads it. A `$/1000;sN sec` token (own or of another spell) is an `effect_value` in ms: Liberty 705266
`$/1000;s1` expects −30000. A `$<id>d` token of another spell is a `spell_duration`, read without a cast: Keeping
the Oath 92109 `$803237d` expects 8000. The reader leaves a token of a spell missing from the DBC set unreadable,
so a step names only spells of that set; a spell the server's store lacks still fails its scenario (`Unknown
spell in metric`). `spell_duration_ms` is the base duration after the player's spell modifiers, before script
hooks: every `spell_duration` verdict carries that limit in `detail['scope']`.
Known limit: a duration that a `ScriptMgr::OnCalcMaxDuration` script changes (`Aura::CalcMaxDuration`,
`SpellAuras.cpp:815`) is not covered, so such a spell needs a cast-based `aura_duration_ms` check instead. A
`spell_duration` check also never proves the foreign spell is actually granted by casting the rank, only that its
computed duration matches the token; a class file's `foreign_aura_grants` (`{spell, target, reason}`, the `reason`
citing the DBC trigger effect or the script that applies it) lists the pairs this has been confirmed for, and
`value_scenario` adds a live `aura_duration_ms` check on top for each one, on the caster or on a dedicated `ally`
test player reached by its own reset-cooldown-and-recast sequence, chosen by whether the rank's own effects target
`TARGET_UNIT_TARGET_ALLY` (`targets_ally`). Only the listed pairs get this extra check, so an uninvestigated
`foreign_duration` match elsewhere in the class is unaffected (ADR 0051).
`spell_effect_value` is `SpellEffectInfo::CalcValue`, before aura scripts: every `effect_value` verdict carries
`detail['scope']` "CalcValue before aura scripts (CalcAmount hooks not covered)". Each judged `effect_value` read
(`read <kind>` rule, own or foreign effect) is followed by `<label> calc_amount_hooks`, the harness metric
`spell_calc_amount_hooks` of the same spell and effect: the number of `DoEffectCalcAmount` handlers of the aura scripts
bound to that spell that apply to that effect. Above 0, the verdict is `not_measured` whatever CalcValue reads
(`detail` `calc_amount_hooks` and `calc_value_status`, the status the read alone would have had); 0 judges the read as
before; a scenario without the reading gives `unmeasured` (regenerate it). An `aura_amount` check on a present aura
is the remedy. Staffguard 706583 and Untainted 705299: `AscensionTemplarAuras.cpp:60-67`
(`aura_ascension_templar_lifecycle::Calculate`) sets the applied amounts to 125 + 0.3 × Stamina + 0.25 × (dodge +
parry rating) and -10 - 0.1 × Stamina, while CalcValue gives 305 and -41 at level 60. The Templar class file still
lists both as `disabled_foreign_effects`, so their reads are not generated; without those rows they would read
`not_measured` (ADR 0118). The count covers aura scripts bound through `spell_script_names`, not global
`OnAfterAuraEffectCalculateAmount` hooks.
