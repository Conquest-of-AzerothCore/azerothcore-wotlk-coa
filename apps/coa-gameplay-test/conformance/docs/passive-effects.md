# Passive effects

`passive_effects(class_file, spell)` classifies every effect of a passive's rank at the class level as
`PassiveEffect(spell_id, effect, aura, misc, misc_b, family, token, plans, targets, reason, points)`. It measures
nothing:
the scenarios and the judging build on it. `reason` starts with `unmodelled: ` for an unmodelled effect, which then
has no `plans`; it names the distinguishing marker below for an effect modelled through `aliased_token`, and is
empty for every other modelled effect.

Family by `(Effect, EffectApplyAuraName)` (`FAMILIES`, `family_of`): effect 3 (dummy) is `P6` whatever its aura;
otherwise the aura decides, and an aura absent from the table is `unknown` (`unmodelled: aura <n> has no passive
measurement`, or `unmodelled: effect <n> applies no aura` for aura 0).

| Family | Auras | Templar effects |
|---|---|---|
| `P1` spell modifier | 107, 108 | 71 |
| `P2` stat sheet | 29, 31, 47, 49, 132, 133, 137, 138, 142, 166, 167, 174, 220, 237, 240, 290, 327, 333 | 51 |
| `P3` done / received | 59, 79, 118, 122, 136, 163, 286, 303 | 9 |
| `P4` taken | 87, 229, 283 | 4 |
| `P5` proc / trigger | 23, 42, 231, 354 | 76 |
| `P6` scripted / crowd control | 4, 112, 178, 232, effect 3 | 21 |
| `P7` power | 72, 110 | 2 |

The expected value is the effect's own token (the first token of the passive's own tooltip whose `effect_index` is
the effect). An effect without one takes a sibling effect's plain `$sN` (or `$/N;sN`) token when both effects have the
same displayed points (`|EffectBasePoints + 1|`, single-valued): Sturdy 681009 effect 1 (Energy) shares `$s1` of
effect 0 (health), and Paladin Training 520009 effect 1 (cost, −20) shares `$s1` (+20) of effect 0, since the tooltip
says "Increases the damage and reduces the Energy cost ... by $s1%". `token.effect_index` then names the sibling.
A token's `value` is unsigned; `points` is the effect's own signed `EffectBasePoints + 1` (`None` when its points
scale with level), so the expected value is `token.value` with the sign of `points` (520009 effect 1: −20).
Otherwise: `unmodelled: no own token and no sibling token with equal points` (Graceful Fighter 705303 effect 2 has 0
points beside 20 and 20). On Templar, 18 effects share a token; 16 of them are modelled (Courage's two aura 31
effects stay unmodelled).

An effect whose points disagree with every sibling's own token can still be modelled when the tooltip's own
authoring reuses a sibling's literal `$sN` token verbatim for this effect's clause, rather than giving this effect
its own number at all (`aliased_token`): the sibling's token text must recur in a second sentence of the tooltip
(`SENTENCE_BREAK`-split), not merely a second time anywhere in the text, so a token legitimately repeated twice
within its owning effect's own clause is never mistaken for a second effect's clause. The expected value is then
that sibling's own signed points, not this effect's own (never displayed) raw `EffectBasePoints`: Fortified Body
300515 effect 1 (max health, raw points 10%) reuses effect 0's `$s1` (6%) for its own "increases your maximum
health by $s1%" sentence, so the expected value is 6%, matching both the client's rendered tooltip and CoA's own
`AscensionTemplarContracts.cpp` load-time patch of effect 1's `BasePoints` down to effect 0's value. `reason` then
reads `token <text> reused from effect <sibling>; expected value follows effect <sibling>, not own points`, so a
reviewer can tell this path apart from a directly-owned or evenly-shared token without reading the source.

A class file's `literal_tokens` list (`[{"spell": <id>, "effect": <n>, "quote": "<exact substring>", "value": <n>}]`)
gives `classify` a token for an effect whose tooltip clause expresses its magnitude in prose rather than a `$sN`
token, the same `{spell_id or rank_id, effect}` lookup as `passive_targets`/`effect_overrides`, consulted only after
`own_token`/`shared_token` both return nothing: `token = own_token(...) or shared_token(...) or literal_token(...)`.
The reader raises `ValueError` if `quote` is not a substring of the effect's own tooltip, the same discipline
`passive_targets`' `tooltip_words` already enforces. `DbcTooltips.read` (`compare.py`) also injects a matching
`Displayed` for each `literal_tokens` entry alongside the real `$sN` tokens it reads from `Spell.dbc`, so a judging
run's own tooltip re-read (`signed_token`) can still find the literal token by its exact text and derive its
expected numeric value from `value`, the same path a real token takes. Templar: Final Prayer 705268 effect 0
("Doubles the healing done to you by Testament of Fortitude...") and Justicar of the Light 707663 effect 0
("Removes the cooldown from Benediction...") each get a `literal_tokens` entry (`value: 100`), which makes both
effects modelled (`spell_effect_value`/`spell_modifier` plans) instead of `unmodelled: no own token and no sibling
token with equal points`.

Each `MetricPlan(metric, fields, relation, source, judged)` names a harness metric, its fields (the scenario adds
`spell` where the metric needs one), the relation of the delta to the token, for `share` the base-step label of the
source (`stat <n>` or `attack_power`), and whether the delta is judged (`judged` false: reported as `measured`):

| Aura | Plans | Relation |
|---|---|---|
| 107 / 108 | `spell_modifier {op, base: 1000}` per target; consumer of the op: 14 `spell_power_cost`, 10 `spell_cast_time_ms`, 5 `spell_max_range`, 31 `spell_max_stacks`, 3/12/23 `spell_effect_value {effect: 0/1/2}`, 7 `spell_done_crit_chance {target: dummy}`, 15 `spell_critical_damage {target: dummy}` | `spell_mod_flat` / `spell_mod_pct`; consumer `add` / `scale`, op 15 `crit_damage` |
| 29 / 137 | `stat {stat}`, all five for misc −1 | `add` / `scale` |
| 133, 132, 166, 167 | `max_health`, `max_power {power}`, `attack_power`, `ranged_attack_power` | `scale` |
| 240, 47, 49 | `expertise`, `parry_chance`, `dodge_chance` | `add` |
| 290 | `spell_crit_chance {school}` when the tooltip says "<School> critical strike chance"; else `melee_crit_chance_refreshed` plus `spell_crit_chance {school}` for schools 1 to 6 with `judged` false (D6) | `add` |
| 333 | `melee_hit_chance` and `spell_hit_chance` | `add` |
| 138 | `attack_time_ms {hand: 0}` | `haste` |
| 220 | `combat_rating {rating}`, one per bit of the misc mask | `share` |
| 174 / 237 | `spell_power {school}`, one per magic school of the misc mask | `share` |
| 327 | `stat {stat}` | `share` |
| 79 | `spell_damage_done {target: dummy}` (magic schools in the mask); physical: `weapon_damage_min {hand: 0}` | `composition`; physical `ratio` |
| 136 | `spell_healing_done {target: caster}` | `composition` |
| 118 | `spell_healing_taken {target: caster}` | `ratio` |
| 163 | `spell_critical_damage {target: dummy}` | `crit_damage` |
| 303 | `spell_damage_done {target: dummy}` | `ratio` |
| 229 | `aoe_damage_taken {school}`, one per school of the mask | `ratio` |
| 72 | `spell_power_cost` | `scale` |

The physical part of aura 79 enters the weapon damage (`Unit::UpdateDamagePctDoneMods`, `TOTAL_PCT` of the hand's
damage modifier), and `Unit::MeleeDamageBonusDone` skips aura 79 for a physical school mask (`Unit.cpp:11419`):
`melee_damage_done` stayed 800 → 800 with Serendipity 300929 learned, so the physical part is measured on
`weapon_damage_min` (`UNIT_FIELD_MINDAMAGE`, the character sheet's minimum damage).

A `composition` or `crit_damage` relation can read as more than one quantity (the bonus "multiplies" or "adds" to
known modifiers; a critical-hit percent applies to the "whole" hit or only to the "bonus" above the fixed base),
but only one of those readings is ever physically possible for a given effect's own mechanism, so `delta_readings`
gates each alternate on `model['aura']` instead of always offering it: a `composition` known modifier only offers
"adds" when its own `aura` (carried on every `known_modifiers` row) equals the effect's own `aura` — a known
modifier of a different aura can never enter the same `Unit::GetTotalAuraMultiplier` call as the effect under
test, so it cannot compose additively with it (Serendipity 300929's aura-79 effect against the Ascension tuning
aura's 341, `Unit::GetAscensionNormalTuningDamageMultiplier` and `Unit::SpellDamageBonusDone`,
`Unit.cpp:9284-9296, 9914-9930`). A `crit_damage` effect offers "whole" only for a direct aura 163 application
(`Unit::SpellCriticalDamageBonus`, `Unit.cpp:10527-10561`: aura 163's own percent scales the pre-subtraction value);
every other `crit_damage` plan — the spell-modifier op 15 consumer below — offers "bonus" only, since
`ApplySpellMod(..., SPELLMOD_CRIT_DAMAGE_BONUS, crit_bonus)` runs only on the bonus-above-base portion.

### Effect overrides

A class file's `effect_overrides` list (`[{"spell": <id>, "effect": <n>, "misc_value": <n>, "citation": "..."}]`)
substitutes a live-corrected `EffectMiscValue` for the raw client DBC value before `classify` builds any plan, the
same `{spell_id or rank_id, effect}` lookup as `passive_targets` (point 3 above). A class script can rewrite a
spell's effective `SpellInfo` at load time without changing `Spell.dbc`, so the raw DBC op the reader would
otherwise classify by was never the one actually registered. Templar: Upheave! 520442 effect 0 carries
`EffectMiscValue[0]` 7 (`SPELLMOD_CRITICAL_CHANCE`) in the client DBC, but `AscensionTemplarContracts.cpp:130`
rewrites it to 15 (`SPELLMOD_CRIT_DAMAGE_BONUS`) at load time to match its own "critical damage" tooltip wording;
the `effect_overrides` entry makes the reader classify it as op 15 (`spell_critical_damage`/`crit_damage`, the
"bonus" reading above), the op the live server actually installs.

An entry may carry `base_points` instead of (or beside) `misc_value`: the rewritten `EffectBasePoints`, which the
tooltip comparison reads in place of the record's own points, so an unsigned `$sN` token takes the sign of the
rewritten value (`DbcTooltips.effect_points`). An entry without `misc_value` leaves `classify` on the record's op.
Templar: Patience 712678 effect 1 is `EffectBasePoints[1]` -5001 (a 5 sec cooldown reduction on Interdict) in
`Spell.dbc`; the owner ruled on 2026-11-10 that its tooltip, "Increases the duration of Interdict by
$/1000;s1 sec and its cooldown by $/1000;s2 sec", lengthens the cooldown, `AscensionTemplarContracts.cpp` rewrites
the points to 4999 (+5000 ms) and `AscensionTemplarAbilities.cpp` adds that amount to Interdict's cooldown after
each cast; the entry `{"spell": 712678, "effect": 1, "base_points": 4999}` makes the `effect_value` check expect
+5000.

### Item-armor-subclass overrides

A class file's `item_armor_subclass_effects` list (`[{"spell": <id>, "effect": <n>, "subclass": <n>,
"item": <entry>, "slot": <n>, "required_level": <n>, "citation": "..."}]`) models aura 142 (`SPELL_AURA_MOD_BASE_RESISTANCE_PCT`) for
an effect whose `EffectMiscValueB` names an item-armor subclass (`ITEM_SUBCLASS_ARMOR_*`,
`ItemTemplate.h:390-400`) that `SpellInfo::GetItemArmorSubclassMask()` (`SpellInfo.cpp`) recognises for the
live `SpellInfo`, the same `{spell_id or rank_id, effect}` lookup as `effect_overrides`, checked before `aura
142`'s generic `OUT_OF_SCOPE` closure. `Player::UpdateArmor()` (`StatSystem.cpp`) scales only the armor that
subclass's equipped items contribute (`Player::GetItemArmorBySubclass`, raw and unscaled, tracked independently
of any aura on equip/unequip, `Player.cpp:7372`), not the character's total Armor, so the delta a passive-check
scenario measures on the generic `armor` metric cannot be judged against the tooltip percent directly: the
reference character does not otherwise wear that subclass, and even if it did, its base/weapon-sourced Armor
would inflate the "before" reading past the subclass-only contribution the percent actually multiplies. An
override entry equips `item` at `slot` in priming (`add_item` then `equip`, before the `before` measurement)
and gives effect 0 two plans instead of one: a non-judged `item_armor_by_subclass` probe (reads
`Player::GetItemArmorBySubclass(subclass)` directly, a CoAGameplayTest metric, constant across the `learn`) that
only *reports* its own before/after, and a judged `armor`/`share` plan whose `source` is that probe's own
`before` label — `compare.py`'s existing `share` relation (`delta_readings`) multiplies whatever `run.values`
holds under `source` by the tooltip's percent, with no change needed there. Templar: Blessed Padding 301311
(50%) and 301360 (100%) both carry `EffectMiscValueB[0]` 8 (`1 << ITEM_SUBCLASS_ARMOR_MAIL`) for a `SpellInfo`
whose `GetItemArmorSubclassMask()` previously whitelisted only `SpellFamilyName` 24, missing their own family
25 — a server defect masking the whole effect regardless of equipped gear (fixed alongside this override,
`SpellInfo.cpp`); both equip Void Slayer's Tunic 30298 (mail chest, `RequiredLevel` 60) at slot 4. The player
stays at the class file level: `required_level` is the `RequiredLevel` of the item's `item_template` row (SQL data
outside the DBC set, so the class file states it and cites where it was read), and `passive_scenario` refuses an
entry without it, one above the class file level, or one that sets a `level` of its own. The earlier fixture, chest
1065932 of `apps/coa-gameplay-test/scenarios/templar-blessed-padding.json`, requires level 80 and raised the
generated player to 80. A spell using aura 142 with no matching override entry still raises
`Closed(OUT_OF_SCOPE[142])` exactly as before.

### Conditional tooltips

A class file's `conditional_spells` list (`[{"spell": <rank>, "learn": <gating spell>, "reason": "..."}]`) names,
per rank, a `$?s<id>[...][...]` gating spell whose true branch carries a `$` token worth its own check, when
that token's value does not depend on live caster state (see "Tooltip reading" above and
[ADR 0039](../../../docs/adr/0039-conditional-tooltip-reads-the-chosen-branch.md)). `static_conditional_known`
looks up the entry and unions its gating spell into the *same* reading `value_scenario` already builds — no
live `learn` step, because this only steers which text the Python reader picks, never the live scenario. A
second, baseline-only reading finds which token `conditional_extra_values` added (by position, not just by
trailing length: the conditional is not always the last token in the description). That token goes through the
same per-token dispatch as every other one, with its `rule` documenting it as "the true branch of the
`$?s<gating>` conditional, read unconditionally because the referenced value does not depend on caster state";
every `Expectation`'s ordinal, including a later-positioned, pre-existing token's, is the token's real position
in this one reading — the same one `compare.py` re-derives at judge time from the `known_spells` recorded on
the manifest entry, so nothing drifts out of sync with a second, differently-ordered reading. A rank with no
`conditional_spells` entry gets no
extra check at all — including a rank whose true branch names its *own* effect through a live, caster-state-
dependent SpellMod (ADR 0039's 801461 case), where no check this reader can compute would be reliable; the
underlying live mechanism (`value_scenario`'s `known_spells` parameter and the `learn` step it adds) stays in
place, tested directly, for that kind of case if one is ever added.

Unmodelled by rule: `P5` (`proc or trigger effect without a trigger entry`) — unless the class file's own
`triggers`/`procs`/`behaviours` entry for this exact `{spell_id or rank_id, effect}` already checks it
(`trigger_link`, round5 `trigger-accounting`): when one or more match, the reason instead points at each
matched entry's own label and status (`checked by <triggers|procs|behaviours> entry "<name>" (verdict "<label>",
status <status>)`, joined with `; ` when more than one entry links), so a P5 effect a trigger lot already covers
is never reported as a second, duplicate `unmodelled` row. Each pointer's `<label>` is the exact label that
entry's own scenario produces: a plain `triggers` entry gets `trigger_count`, a `cooldown_delta` entry
`trigger_cooldown_delta` (disambiguated with its `observe_spell` when more than one `cooldown_delta` entry
shares the aura), a `duration_delta` entry `trigger_duration_delta`, and a `procs` entry `proc_rate`
(disambiguated with its `proc_spell` and then its trigger, exactly as `proc_scenario` disambiguates its own
label when more than one `procs` entry shares the aura or the `aura`+`proc_spell` pair) — never the bare,
undisambiguated label a shared-aura group would otherwise collide on. A `behaviours` entry gets its kind's label
(`passives.BEHAVIOUR_LABELS`); `hit_ratio` and `cast_applies_aura` carry their `label_suffix` (ADR 0142). A P5
effect with more than one candidate entry prefers the ones whose own `effect` field matches this effect index (the
same precedence `passive_targets`/`effect_overrides`/`effect_notes`/`unmodelled_effects` already use for their
`{spell_id, rank_id}` lookups); when none of the candidates for this effect carries an `effect` field at all,
every one of them is linked (never an arbitrary single pick), since more than one check can legitimately cover
the same single effect through different trigger paths (Templar: Might of Aggramar 803163 effect 0, two `procs`
entries sharing `proc_spell` 803164, one triggered by an auto-attack and one by a spell cast). A status-less
pointer's `status ok` is read once, at generation time, from the entry's own `status` field, not cross-checked
against that entry's own latest measured verdict in `verdicts.json`; if the linked check later regresses
without a matching `status` edit to its entry, the pointer text still reads `ok` even though the real row for
that entry now alerts — the independent row for the linked entry itself still carries the real, current
verdict, so the regression is not lost, but a reader who only skims the P5 pointer text would be told a stale
"ok". `P6`
(`scripted or crowd-control effect`), 59 (`damage versus a creature type is level-scaled`), 122 (`no off-hand
weapon damage metric`), 110 (`no energy regeneration metric`), a spell modifier op of 32 or more (`SpellModOp
<op> is not below MAX_SPELLMOD 32`: `spell_modifier` requires `op < MAX_SPELLMOD`), and the auras of the table
without a plan (31, 87, 283, 286: `aura <n> has no passive measurement`). Closed by rule without a matching
`item_armor_subclass_effects` entry: aura 142 (`closed: mail armor is out of scope`) — round5 `closed-statuses`
found the reference character's armor slot never equips a mail item and the harness had no action to re-gear
it for one passive check, a structural tool-scope gap the same shape as 59/122/110; round10 `judging` closed
that gap with the "Item-armor-subclass overrides" section above, so a spell with a matching override entry
(Blessed Padding 301311/301360, both ranks) is modelled instead of closed, and only a future aura-142 spell
with no override entry still falls back to this rule.

A class file's `unmodelled_effects` list (`[{"spell": <id>, "effect": <n>, "reason": "..."}]`) forces a specific
effect straight to `unmodelled`, the same `{spell_id or rank_id, effect}` lookup as `effect_overrides`, checked
before any family/aura rule and ahead of whatever plan `classify` would otherwise build — unlike `effect_notes`,
this *can* turn an effect `classify` would call modelled into `unmodelled`, because the generic reader has no way
to see that the live `SpellInfo` differs from what `Spell.dbc` describes. Templar (round4 `alert-triage`
investigation, 2026-11): `AscensionTemplarContracts.cpp` dummies every effect of Patience (712678) at load and
reimplements both as scripted per-cast hooks on Interdict (560116), so its `spell_modifier` probe looks for a static
table entry that is never populated. That is a confirmed tool defect (a generic check that can never pass, not a
server bug), left `unmodelled` and judged instead by the per-cast `behaviour_metric_delta` entries that measure the
scripted duration and cooldown. Aggramar's Rage (560650/561346) carried a second entry while the server rewrote its
crit effect into a classmask-scoped `SPELL_AURA_ADD_FLAT_MODIFIER`; since the 2026-11-10 fix the same contract makes
effect 0 a Holy-school `SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL` aura, the entry is gone and the generic Holy
`spell_crit_chance` probe judges it. Real rolls (2026-11-10) show it reaches melee Holy abilities too: rank 2 over
440 casts each, Chastise (Holy, melee damage class) crit 0 times without the talent and 21 with it (predicted
chance 0 and 6%), Scourgebane (Holy, magic) 14 and 45 (2.93% and 8.93%), Physical Argent Blade 0 and 0;
`templar-aggramars-rage-holy-crit-rolls` forces effect 0 to 100 so every Chastise and Scourgebane crits.

A class file's `effect_notes` list (`[{"spell": <id>, "effect": <n>, "reason": "..."}]`) substitutes a specific
explanation for `classify`'s own generic `unmodelled: ` reason, the same `{spell_id or rank_id, effect}` lookup as
`effect_overrides`, applied only when the generic reason already starts with `unmodelled: ` (it never turns a
modelled effect unmodelled, or the reverse). This documents, per effect, *why* a `P6` (scripted or crowd-control)
or similarly auto-labelled effect needs no check of its own — because a sibling effect of the same spell already
carries the number the tooltip states, or because the server-side behaviour is proven by an existing `behaviours`/
`triggers` entry on a different effect index — or, when an effect's own claim is real but this package cannot yet
measure it, that it is deferred and why. A reason beginning `no check needed: ` instead moves the status to
`closed` (`CLOSED = 'closed: '` in `passives.py`/`hits.py`, checked in `compare.py`'s `judge_expectation` ahead of
the `unmodelled` branch): this effect has no claim left to check, proven by evidence in the explanation, so it is
settled rather than open work; `coverage.md`/`report.md`/`summary.md`'s status tables and `alerts.tsv` (built from
`NOT_ALERTS`) count it apart from the genuinely missing checks. Every other `effect_notes` reason keeps the
`unmodelled` status: `effect_notes` only replaces the explanation text, never the verdict, for those. Templar
(round4 `scripted-script-aura` investigation, 2026-11): 300529 effect 1, 705263 effect 1, 705272 effect 1, 705274
effect 1, 705283 effect 1, 705287 effect 1, 705298 effect 1, 805420 effect 1 and 806516 effect 0 are reclassified
to `closed` this way (each a `P6`-family `DUMMY`/`OVERRIDE_CLASS_SCRIPTS` effect with no tooltip clause of its
own, read by no code by index, while a sibling effect of the same spell is already `ok`); 804930 effect 0 stays
`unmodelled`, reclassified only in text to cite the spell's own `804930 behaviour_trigger` check (below), which
already proves the behaviour this effect stands for. 92109 effect 0 (the absorb takeover from Keeping the Oath
803149 to 92109) and 300520 effect 0 (the sub-20%-health damage bonus) are genuine, real effects that this item
found no way to check with the harness's existing metrics (respectively: `aura_ascension_templar_stagger::Calculate`
forces both auras' amount to -1, so no existing metric distinguishes which of the two absorbed; the bonus needs a
statistical hit-mean comparison this package's exact-equality `behaviour_metric_delta` shape does not provide) —
`effect_notes` records that finding as a deferred reason instead of the generic label, pending a follow-up item.
Templar (round4 `no-own-token` investigation, part B, 2026-11): Condemnation 704175 effect 2 (aura 286
`SPELL_AURA_ABILITY_PERIODIC_CRIT` only gates periodic-crit eligibility; its `EffectBasePoints` is never read by
`AuraEffect::CalcPeriodicCritChance`, and the tooltip gives no number for this clause), Final Prayer 705268 effect 1
(targets Testament of Faith 801478 through aura 283, which has no passive-measurement plan in this tool; the
tooltip's real claim is already checked, and already alerts, through `behaviours.json`'s "705268 801478
behaviour_ratio"), Justice 712437 effect 0 (its `SPELLMOD_JUMP_TARGETS` targets Interdict 560116, whose own effect
is `SPELL_AURA_MOD_SILENCE` and performs no chain-target selection; the tooltip's "1 additional nearby target" is
already checked through the scripted hook in `AscensionTemplarAbilities.cpp:95-102`) and Spiritual Abdicator 803219
effect 0 (its own `EffectBasePoints` is 0; the "+5% per copy" it names is implemented on a different spell/effect,
704409 effect 1, and already checked through `behaviours.json`'s `metric_delta` entry) are each given an
`effect_notes` entry for the same reason: a real, textual tooltip claim that a different, already-working check
(elsewhere in this item's own effects or in `behaviours.json`) already covers, so the bare "no own token" label no
longer reads as an open gap.

### Targets of a spell modifier

1. Named: every `Spell.dbc` record of the passive's `SpellFamilyName` whose `SpellName[enUS]` appears in the tooltip
   (color codes removed, whole words, longest names first, overlapping matches skipped: "Oath: Condemn" before
   "Condemn"). A match followed by a space and a capitalised word is part of a longer proper noun and does not
   count: the spell "Oath" is not named by "Oath Breakers" (Blessed Strikes 704180, Chakra of Light 803159). A name
   inside a counter clause ("per trigger of", "per stack of", "per charge of", "for each time you triggered") is
   blanked out before matching and never counts as named: Holy Upheaval 572547's "Increases the effectiveness
   Righteous Upheaval gains per trigger of Zealotry by `$s1`%" grammatically raises Righteous Upheaval's own value,
   with Zealotry only the counted trigger, so Zealotry is not a target at all, named or otherwise
   (`without_counted_names`). Names are read in the sentence that holds the effect's token when the token sits in
   one sentence that names a spell, else in the whole tooltip (ADR 0017 D3: Legacy of the Silver Hand's `$s2`
   sentence names Scourgebane only). A named spell whose records meet this effect's mask has those records as
   targets, resolved to the ranks the class level reaches, records outside a chain all kept (ADR 0017 D1: Pure
   Focus 705253 on Scourgebane 520007, not
   92111, 801832, 801861 or 804916; Argent Knight 300512 on Righteous Tempest 570205, the level-60 rank of the chain
   805410, 570200 to 570205 that its cast ranks trigger, not the aura 807274). A named spell with no record in this
   mask but one in **any other effect of the same rank's** mask is that other effect's target only, not this one's —
   the sibling effect need not itself be a spell modifier
   (D2: Grace of Aman'thul's effect 1 takes Sacred Swing, not Righteous Lunge; Final Prayer 705268's effect 0,
   `SPELLMOD_EFFECT1`, does not claim Testament of Faith 501606/801478 because effect 1, `MOD_HEALING_RECEIVED`
   and not itself a `P1` effect, already claims it — round 5's `705268 e0 * 501606` fix). Otherwise a named spell
   resolves to its rank at the class level through the chains of `AscensionSpellProgressionData.h` and the chains
   their cast ranks trigger ([spell sets](spell-sets.md))
   (Righteous Lunge → 570233, Argent Blade → 807268), else to every record of that name, outside the mask.
   `named_targets(records, family_name, text, level, in_mask, sibling_mask)` returns them; `sibling_mask` is built
   from every other effect index of the rank (`classify`'s `siblings`), regardless of that effect's own family. A
   named spell neither in this mask nor in a sibling's gets a `passive_targets` entry instead (Pious Sweep 520034
   effect 1 names Chastise, whose own flags never meet the mask; the mask's real target is Tranquil Circle 801205,
   each a separate half of the tooltip sentence. Templar's Might 705291 effect 0 names its four boosted abilities,
   but the mask belongs to Condemn 567539, the stacking debuff that gates the boost).
2. Category: when nothing is named and the first capitalised word (four letters or more) of every name the class
   mask matches is in the tooltip ("Libram spells": Libram of Tenacity, Libram of Zeal, ...), the mask's spells are
   the targets.
3. Class file `passive_targets` overrides both: `{"spell", "effect", "targets": [ids], "tooltip_words": "..."}`
   (`spell` is the passive's spell id or its rank at the class level); the quoted words must be in the tooltip,
   else `ValueError`.
4. Otherwise `unmodelled: the tooltip names none of the spells the class mask affects (<names>)`. Templar: Deep
   Secrets 705263, Mark of Aggramar 804928 and Chakra of Light 803159/803844 say "Testaments" while their masks
   also match Ascetic and Mortal Abdication; Blessed Strikes 704180 says "Oath Breakers" while its mask matches
   Benediction, Blade of Faith, ... (no name starts with "Oath"). These have a `passive_targets` entry
   (`classes/templar.json`): Blessed Strikes' own `Description[enUS]` of each of the 10 mask-matched spells
   carries "Oath"/"Oaths", the in-fiction label `category_holds` cannot see because it only checks a candidate's
   `SpellName`.

`PassiveTarget(spell_id, name, named, in_mask)`: `in_mask` is whether the record's `SpellFamilyFlags` meet the
effect's `EffectSpellClassMask`. Mask spells whose name is not matched are listed too (`named` false, one rank per
name, selected by id), so a disagreement stays visible: Patience 712678 names Interdict 560116 (outside the mask)
while its mask matches only Sacred Restraint 102208.

### Phrase check

Every plan outside `P1` has a quantity, and the tooltip must contain one of its `PHRASES` (case-insensitive):
"parry rating", "Holy critical strike chance", "chance to hit", "maximum health", "Energy", "melee haste",
"expertise", "attack power", "spell power", "Holy spell damage", "damage taken from area of effect", "cost", ...
Missing: `unmodelled: the tooltip does not name <quantity>` (Call of the Monastery 560550 effect 1 is ranged attack
power, its tooltip says "attack power"). For `share`, `stat_after_token(text, token)` reads the stat or "attack
power" written after `<token>% of (your)`; the source comes from the tooltip, not from `EffectMiscValueB`, so a
mismatch shows as an alert when judged. No such words: `unmodelled: the tooltip names no stat or attack power after
<token>% of`.

### Passive scenario

ADR 0012 records the method. `passive_scenario(class_file, spell)` measures every plan of every modelled effect of
the passive's rank at the class level (`spell.max_rank`) twice in one no-combat scenario:

1. `base_steps(class_file)` (fixtures, stats, known and probe auras);
2. when any plan's metric is `parry_chance`, prime `CanParry()` with the rank's own aura (`set_aura` stacks 1 then
   stacks 0, the `cultist-adaptive-combatant.json` pattern), so the `before` snapshot already reflects the
   unlocked base parry chance with no rank bonus active; when any effect is aura 303 (`VERSUS_AURA_STATE`), wait
   `AURA_STATE_WAIT_MS` and measure `has_aura_state` on the dummy for that effect's state, labelled
   `<passive> e<n> <metric> <target> aura_state`;
3. each measurement labelled `<passive> e<n> <metric> <target> before`, plus a parallel `stat_exact` measurement
   labelled `<passive> e<n> <metric> <target> exact before` for every `stat`-metric plan;
4. `learn` the passive, then `aura` of the passive labelled `<passive> aura_present` (diagnostic);
5. the same measurements labelled `<passive> e<n> <metric> <target> after` (and `exact after` for `stat` plans).

`<target>` is the spell the metric is asked about, else the values of the plan's fields other than `target`
(`706431 e0 stat 0 before`, `705303 e0 combat_rating 3 after`, `561346 e1 expertise before`). A spell modifier and
its consumer metric (`spell_power_cost`, `spell_effect_value`, `spell_done_crit_chance`, ...) are measured on every
target of the effect, named or mask-only. A spell-bound metric without targets (`spell_damage_done`,
`spell_critical_damage`, `spell_healing_done`, `spell_healing_taken`, `spell_power_cost` of aura 72) is measured on a
reference spell: the first active class spell, at its rank for the class level, whose `SchoolMask` meets the effect's
mask (`EffectMiscValue`; its magic part for aura 79; every school for aura 303, whose misc value is an aura state)
and that has a school damage effect (2) for damage, a heal effect (10) for healing, or a plain cost (`ManaCost` above
0, no per-level or percentage cost) for the cost. Templar: Reckoning 572741 for Serendipity 300929 and Chivalric
705272, Crusader's Brand 300513 for the cost of Serendipity. The scenario adds the dummy creature when a measurement
targets it.

Expectations, one per measured pair: label `<passive> e<n> <metric> <target>`, check `passive_delta`, `displayed` the
token text, `rule` the plan's relation, and `model` with `family`, `effect`, `metric`, `fields` (the step's fields,
`spell` included), `relation`, `source_label` (the base-step label of a `share` source), `before_label`,
`after_label`, `exact_before_label` and `exact_after_label` (the parallel `stat_exact` labels, `None` off a `stat`
metric), `aura_state_label` (the `has_aura_state` label, `None` off aura 303), `target` (the spell measured, else
`None`), `named` and `in_mask` (spell modifier targets, else `None`), `points` (the effect's own signed points),
`judged` and `aura_label`. Not measured, check `unmodelled`:

- an effect without plans: one expectation labelled `<passive> e<n>` with the effect's reason (Condemnation 704175
  effect 1, op 40: no step is generated);
- a target without the effect a `spell_effect_value` consumer reads: `unmodelled: target <id> has no effect <n>`
  (the harness would stop the scenario);
- a target of a `spell_power_cost` consumer with no plain cost (`ManaCost`, `ManaCostPerlevel` and
  `ManaCostPercentage` all 0): `closed: target <id> has no power cost to modify` (`CalcPowerCost` clamps a
  negative cost to 0, so a flat reduction on a 0-cost target would measure a false 0 → 0 instead of its real
  token; Blessed Strikes 704180's Divine Fury 501567, Reckoning 572741 and Chakram 704573 have no plain cost — a
  DBC-proven not-applicable, status `closed` since round5 `closed-statuses`, not open work);
- a reference spell missing: `unmodelled: no active class spell with a heal effect in school mask <mask>` (Templar
  has no heal spell: Sacred Style 705278 and Fortified Body 300515 are unmodelled).

On Templar the 145 passives give 66 scenarios and 79 entries without one; 355 `passive_delta` and 145 `unmodelled`
expectations.

Probe of 2026-11-06 (`--passive` 706431 705266 520009 705303 561346 572555, simulated clock, every scenario
passed): `aura_present` was 1 in the step right after `learn` for all six, and the stats had moved by the next step.
Before → after: Pious 706431 stats 81/132/79/32/50 → 85/138/82/33/52; Liberty 705266 `spell_modifier` op 11 on the
five Librams 1000 → −29000; Paladin Training 520009 op 0 1000 → 1200, op 14 1000 → 800, `spell_power_cost` 40 → 32
(Righteous Lunge 570233) and 50 → 40 (Argent Blade 807268), 0 → 0 for Holy Master 504810 (no cost); Graceful
Fighter 705303 parry rating 0 → 26 and dodge rating 0 → 6; Aggramar's Rage 561346 expertise 4000 → 4010 while Holy
`spell_crit_chance` stayed 2.8592 → 2.8592; Solemn Soldier 572555 `attack_time_ms` 2500 → 2272.73 and expertise
4000 → 4010. `compare` judges these deltas (Verdicts, passive deltas).

Judged probe of 2026-11-06 (`--passive` 300929 705272 561346 705266 712678 572555, stamp 20261106-085206, six
scenarios passed): `ok` for Liberty on its five Librams (1000 → −29000), Solemn Soldier haste (2500 → 2272.73) and
both expertise effects (+10), Serendipity's cost (20 → 19 on Crusader's Brand) and weapon damage (+3%);
`ambiguous_tooltip` for Serendipity on Reckoning (800 → 824: `multiplies` against `adds` 830) and Chivalric
(1500 → 1725: `whole` against `bonus` 1575); alerts for Aggramar's Rage Holy `spell_crit_chance` (2.8592 →
2.8592, expected +6) and Patience on Interdict (spell modifier 1000 → 1000 for both effects; Sacred Restraint, the
mask spell, `measured` 0).
