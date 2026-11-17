# 0022. Witchblight forces the struck enemy's next white swing to miss

- Status: accepted
- Date: 2026-11-16

## Context

Witchblight 681220 reads (server Spell.dbc Description): "Each target struck is guaranteed to miss their next instance
of damage within $d." Its aura tooltip reads "Your next instance of damage is guaranteed to miss." Every rank (680494,
681218, 681219, 681220, 681221, 681540) applies Effect[1] aura 333 SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT with
amount -100; the `spell_proc` rows and `aura_ascension_witch_hunter_lifecycle` Check/Proc
(`AscensionWitchHunterDefenses.cpp`) remove the aura on the holder's first damaging attempt, after its outcome is rolled.

The f-n138 fix note (pairs 20261116-215510 / -215905 and 20261116-220541 / -220652, worldserver ee3cfa72c564) measured
the next white swing of an attacker carrying the aura at 58.8% miss (pooled 434 of 738) against 100% stated. Stock
never-consumed probes of aura 54 stopped at the same rate (100% Miss Chance 80646, -99998: 60.4%), while Darken Vision
5514 (-25) moved it linearly: the cause is the stock 0..60% clamp of `Unit::MeleeSpellMissChance` (AzerothCore, 2016),
not the Witch Hunter aura or its consumption. An archived live log (2026-08-11, rank 681540) shows 17 of 17 first white
swings after an application missing, and 8 of 13 first spell or periodic attempts missing.

Mentor D-373 approved option (a) of the fix note: Witch Hunter code only, no SQL, no engine file.

## Options

- (a) Force the miss in the Witch Hunter `OnBeforeRollMeleeOutcomeAgainst` override, which runs after the clamp, for an
  attacker that carries a Witchblight rank aura (chosen).
- (b) As (a), plus melee and ranged special attacks through a spell-hit hook: larger, and the live sample shows spells
  not guaranteed to miss.
- (c) Keep the stock clamp: the tooltip's "guaranteed" stays false.
- Lift the clamp in `Unit::MeleeSpellMissChance`: a shared engine edit for every class.

## Decision

`witch_hunter_scaling::OnBeforeRollMeleeOutcomeAgainst` (`AscensionWitchHunterCompletion.cpp`) sets the miss chance to
10001, above every `urand(0, 10000)` roll of `Unit::RollMeleeOutcomeAgainst` (a miss needs `roll < miss`), when the
attacker carries any Witchblight rank aura, before its hound handling. The hook is reached only by
`Unit::RollMeleeOutcomeAgainst`, the white-swing roll of `Unit::CalculateMeleeDamage`; the existing proc then removes the
aura, so only that one swing is forced. No caster check: the aura comes only from Witch Hunter spells, and the harness
applies it with the attacker as its caster.

## Consequences

- Every enemy struck by Witchblight misses its next white swing within 6 s; in PvP an enemy melee player loses one
  auto attack per Witchblight that struck it (up to 10 targets per cast).
- Spells and melee or ranged special attacks keep the stock rules: by code about 99% miss for a magic spell (the 1%
  hit floor of `Unit::MagicSpellHitResult`) and the 60% cap for a special attack, while the live sample shows 8 missed
  of 13. Unmeasured; an open lead.
- The forced miss holds against every roll: `urand(0, 10000)` is inclusive (`Random.cpp`), so the first value, 10000,
  let a roll of 10000 (1 in 10001) through.
- Hook order: CoA scripts register before module scripts (`AddCoAScripts` in the script loader, `AddModulesScripts`
  after it), and `CALL_ENABLED_HOOKS` runs them in that order. The mod-skinpeelerquest Vaelthara hook, which runs later
  and sets her own miss chance to 0, therefore overrides Witchblight for that one boss. No Witch Hunter code runs after
  it in this roll; the module is not changed (a boss rule outside the class).
- Regressions: `681220 behaviour_taken_outcome 681220 next_miss` and `681220 behaviour_taken_outcome <rank> next_miss_rank_<rank>` for the other ranks, each with a control arm of the same
  attackers without the aura, and `refresh_keeps_aura` (opt-in of the `taken_outcome` kind): the aura is set on each
  attacker that lacks it every 1200 ms and never removed, and the treatment counts start after the first application;
  every attacker carries Silithid Swarm Passive 6590 (+100 hit chance, a precondition
  fixture of both arms) so the control reads 0% and the stated difference is the full 100 points. The second swing
  after an application is not read by any existing kind (design in the 681220 ledger row).
- The three diagnostic `clamp_probe_*` entries of the fix note are removed; their readings stay in the fix note and in
  commit 80df042324. The -47 probe (Eye Peck 4150) read about 61% where a linear model gives about 52%: not
  investigated.

## Amendment (f-sf138b, mentor D-378)

The first pair after the fix (20261116-222031 / -222126, worldserver 12efe803ecb2) read 6 non-misses in 2222 treatment
swings, 5 in one scenario of the second run. No other `OnBeforeRollMeleeOutcomeAgainst` hook changes the miss chance of
the test attackers (creature 36): Felsworn, Necromancer and Venomancer change crit, dodge or parry, mod-coa-challenges
rules key on a player victim, Vaelthara on her own entry. By the harness code the aura was absent at those rolls: the
scenario removed the aura (`stacks 0`) and set it again (`stacks 1`) in two scenario steps, the harness runs one step
per world tick, the world updates maps before scripts (`World::Update`), and the clock gives a polling step 1 ms
(`CoAGameplayClock.cpp`, `MinimumStep`). Each attacker thus spent one 1 ms map update per cycle without the aura, plus
the reads and earlier attackers' steps at the start of the treatment arm, and a swing that fell there rolled at the
control rate (0% with the +100 hit fixture). No per-swing read exists, so this attribution rests on the code path and
on the pair below, not on a swing-level record. The regression now sets the aura without removing it, and the miss
chance is 10001.

## Owner ruling (O-35, 2026-11-17)

The owner validated this change as built (owner ruling O-35, relayed by mentor D-390). It replaces the earlier
"mentor ruling, no owner id" status of this decision.

## Amendment (fu-sfwb, owner ruling O-39, mentor D-408 and D-410)

The owner ruled (O-39, card Q-wh-41 answer (c), mentor D-408) that the text is followed to the letter: any damaging
attempt by a holder of a Witchblight rank aura misses and removes the aura, for spells and special attacks as for white
swings; the 6 s expiry is unchanged. The fu-wb2 pair (20261117-064451 / -064522, worldserver 5e472b02d320) read 99.0%
spell and 57.3% special-attack misses under the aura, with the aura kept after every miss (950/950, 550/550): the stock
1% magic hit floor of `Unit::MagicSpellHitResult`, the 60% clamp of `Unit::MeleeSpellMissChance`, and `spell_proc`
SpellTypeMask 1 rejecting a missed (NODAMAGE) attempt.

Mentor D-410 approved the route: Witch Hunter code only, no SQL, no engine file.
`witch_hunter_casts::OnSpellBeforeEffects` (`AscensionWitchHunterAbilities.cpp`) runs in `Spell::_cast` after the
targets' hit results are rolled and before the launch phase and SMSG_SPELL_GO. For a cast whose original caster (or else
its caster) carries a Witchblight rank aura and whose spell has a damaging effect (school, weapon, normalized or percent
weapon damage, health leech, power burn) or applies a periodic damage, leech or percent damage aura, it sets every
target that is not friendly to that unit (`!Unit::IsFriendlyTo`, mentor D-417) from SPELL_MISS_NONE to SPELL_MISS_MISS
(immune, evade, resist and reflect results stay), and removes every Witchblight rank aura when at least one such target
was present.
`CarriesWitchblight` and the rank list moved to `AscensionWitchHunterCompletion.h` so both hooks share them. This
supersedes the Consequences bullet above that keeps the stock rules for spells and special attacks.

- One cast is one attempt: an area cast misses on all its targets and consumes the aura once; a cast that would apply a
  damage over time misses and applies nothing; a channel whose pulses are triggered spells loses its first damaging
  pulse. Positive spells and spells at friendly targets do not count. In PvP a player holder's next damaging spell or
  special attack misses.
- White swings keep the route above, unchanged.
- Damage shields (`Unit::DealDamageShieldDamage`, not a spell cast) are unchanged: they keep the holder's hit chance and
  never consume the aura. Periodic ticks of a damage over time applied before the holder was struck are not spell casts
  and are not covered; mentor D-410 declined a tick extension.
- Mentor D-417 replaced the first build's hostile test (`Unit::IsHostileTo`) with the not-friendly test, so a holder
  whose reaction to its victim is neutral is covered too: the forced miss applies to a damaging attempt against any
  target that is not friendly to the holder.
- This departs from the archived live behaviour on consumption: in live log 109 (2026-08-11, rank 681540) 18 missed or
  absorbed spell and damage-shield attempts left the aura on (0 of 18), while 4 landed spells and 25 white misses
  removed it. Under this ruling a missed spell or special attack removes it; the departure is the owner's choice.
- Regression (fu-wbreg, mentor D-420 a): the `681220 behaviour_metric_delta spell_miss` (Shadow Bolt 25307) and
  `special_miss` (Sinister Strike 1752) entries use `attacker_attempts` with a +100 hit fixture on the attackers (803393
  for the spell, 6590 for the special attack) so the second attempt and the control land near 100%. Neutral holder
  unmeasured (no neutral-faction fixture): the attackers are hostile, so the pair does not separate `IsFriendlyTo` from
  `IsHostileTo`.

## Amendment (fu-tick, owner ruling O-41, mentor D-413)

The owner ruled (O-41, relayed by mentor D-413) that Witchblight concerns attacks and spells launched after it lands. An
effect already running, such as a damage over time applied before the aura, is not an instance: its ticks neither miss
nor consume the aura. A damage over time cast while holding the aura is a launched spell: it misses and removes the aura
through the spell route above.

Before this change a landed tick of a holder consumed the aura on two paths, both Witch Hunter code:
`witch_hunter_state::OnDamage` removed every aura of the Witchblight family flag (SpellFamilyFlags[1] 16384, which the
server Spell.dbc gives only to the six ranks) from a damaging attacker and set the damage to 0, and the
`aura_ascension_witch_hunter_lifecycle` Check accepted `PROC_FLAG_DONE_PERIODIC`. A tick has no hit roll, so it never
missed, but `AuraEffect::HandlePeriodicDamageAurasTick` sends its combat log before `Unit::DealDamage`: the log showed
the tick while the target lost nothing. Code reading only; no pre-fix run (verification rules).

Decision, Witch Hunter code only, no SQL, no engine file:

- `witch_hunter_state` implements the `DealDamage` unit hook, which `Unit::DealDamage` calls for every unit script just
  before `OnDamage`, to record whether the damage is periodic (`DOT`) from an attacker to another unit; `OnDamage` takes
  that record back (a per-thread stack, so a damage dealt in between keeps its own) and skips the Witchblight removal and
  the zeroing for it. The hook returns the damage unchanged.
- The proc Check no longer accepts `PROC_FLAG_DONE_PERIODIC`.
- Unchanged: white swings, spells and special attacks (the routes above), damage shields (`SPELL_DIRECT_DAMAGE`: a
  landed shield of a holder is still zeroed and consumes the aura in `OnDamage`), and periodic self-damage
  (`DOT` with attacker equal to victim, such as the self-payments of other classes' scripts), which keeps the previous
  behaviour so no other class's path changes.
- The `DOT` damage type also covers periodic leech ticks (`HandlePeriodicHealthLeechAuraTick`); they are running
  effects too and are treated the same way.
- Regression (fu-tick): `681220 behaviour_metric_delta tick_running` (attacker_attempts `running`: Shadow Word: Pain
  10894 cast by each attacker before the aura, one tick under it, aura held, health loss equal to the logged ticks, then
  Shadow Bolt 25307 misses and removes the aura) and `681220 behaviour_metric_delta dot_miss` (attacker_attempts
  `landed: "aura"`: 10894 cast under the aura misses and removes it), each with control arms without the aura.
- Correction to the fu-sfwb amendment: a damage shield does not "never consume" the aura; it never procs it, but a
  landed shield reaches `OnDamage` and consumes it there (code reading, unmeasured).

## Amendment (fu-ondmg, owner ruling O-41, mentor D-425 and D-426)

With the forced miss in place upstream (`witch_hunter_casts::OnSpellBeforeEffects` for spells, the melee roll for
swings), `witch_hunter_state::OnDamage` only ever saw damage the holder did not launch after the aura landed: damage
shields, power-burn ticks and damage dealt by reactive scripts, and, since the fu-tick amendment's marker, a running
effect's damage was the only case it let through. Its zero-and-consume branch therefore turned a non-launched hit
into the "next instance": a running effect's first hit dealt 0 and consumed the aura, a landed damage shield of a
holder dealt 0 and consumed it (the fu-tick correction above), and a holder's damage to itself consumed it as well.

Decision, Witch Hunter code only, no SQL, no engine file:

- `OnDamage` no longer removes the Witchblight family aura (SpellFamilyFlags[1] 16384, only the six ranks in the
  server Spell.dbc) or zeroes the damage. A running effect's first hit now deals its damage and keeps the aura, and
  periodic self-damage of a holder (`DOT` with attacker equal to victim, such as other classes' self-payment scripts)
  no longer consumes it either. The rest of `OnDamage` (802281 removal, the 681173 hounds) is unchanged.
- The fu-tick `DealDamage` hook and its per-thread stack of running-effect records are removed: the only reader was
  the zeroing branch. Same behaviour for running ticks, less code.
- `WitchblightDamaging` counts `SPELL_EFFECT_ENVIRONMENTAL_DAMAGE` (26 spells in the server Spell.dbc, all world or
  creature spells). `SPELL_EFFECT_INSTAKILL` and `SPELL_EFFECT_GAMEOBJECT_DAMAGE` stay out: a holder's instakill and its
  damage to a gameobject are neither forced to miss nor consume the aura (stated limit, D-425).
- D-426 (a): `WitchblightMiss` skips a cast triggered by a periodic aura of an effect already running: a cast whose
  triggering aura effect has ticked (`Spell::GetTriggeredByAuraTickNumber`), or whose triggering aura has a
  `SPELL_AURA_PERIODIC_TRIGGER_SPELL`, `_WITH_VALUE` or `_FROM_CLIENT` effect naming it (`TriggeredByPeriodicAura`,
  `AscensionWitchHunterCompletion.cpp`). The Witchblight proc Check (`aura_ascension_witch_hunter_lifecycle`) skips the
  same casts: the first fu-ondmg run (20261117-084725) showed the tick spell's hit, a
  `PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG` event, removing the aura after every aura-arm window with the fix in
  `WitchblightMiss` alone. Such a tick spell neither misses nor consumes the aura. This supersedes the fu-sfwb statement that a channel whose pulses are triggered spells loses
  its first damaging pulse: its pulses now land and keep the aura. (The limit stated here for a channel or periodic
  trigger cast while holding the aura is removed by the fu-chan amendment below.)
- D-426 (b): a spell with a `SPELL_EFFECT_PERSISTENT_AREA_AURA` effect whose aura is periodic damage, periodic leech or
  periodic damage percent, cast while holding the aura, counts as an attempt even without a unit target: the aura is
  removed and the spell's aura duration is set to 1 ms (`SPELLVALUE_AURA_DURATION`, which `Spell::EffectPersistentAA`
  applies to the area), so the area ends at its first update, before any tick. Stated limits: an area whose aura has
  `SPELL_ATTR5_START_PERIODIC_AT_APPLY` (128 of 2043 such spells in the server Spell.dbc) can still deal one tick at
  that first update; units in range see the area aura applied and removed in that update; a channel built on such an
  area keeps channeling with no area; unit-target auras of the same spell on targets that are not forced to miss
  (friendly ones) also get the 1 ms duration.
- Readers of the touched code, all Witch Hunter keyed: `WitchblightDamaging` and `WitchblightMiss` act only on a caster
  carrying a Witchblight rank (`CarriesWitchblight`); the removed branch acted only on an attacker carrying a
  family-21 SpellFamilyFlags[1] 16384 aura, the six ranks. No other class's spell, script or engine file changes.
- Regressions (fu-ondmg), each with control arms without the aura: `681220 behaviour_metric_delta shield_keeps` (a
  holder's Thorns 43420 shield, struck by the caster, deals its damage and keeps the aura; the next Shadow Bolt 25307
  misses and removes it), `tick_trigger` (Explosive Shot 2150082 cast before the aura: its Explosive Shot 2150083
  ticks deal full damage and keep the aura; the next Shadow Bolt misses and removes it) and `area_miss` (Fire Swoop
  892288 cast under the aura misses and removes it), with `tick_running`, `dot_miss` and every other 681220 label
  re-run. Code reading for the before state; no pre-fix run (verification rules).
- review25 I-3 (D-426 c): the caster's landing in these entries is shown certain by a static reading of its creation
  spells, skill-line spells, the Witch Hunter passives and their trigger closure (no reflect or deflect aura; every
  immunity aura belongs to a spell the caster would have to cast, or is a mechanic immunity), stated in each entry's
  `expected_source`; the false-alert residual of the second attempts is accepted at 0.

## Amendment (fu-chan, owner ruling O-41, mentor D-427, review26 I-1)

The fu-ondmg skip of D-426 (a) applied to every cast triggered by a periodic aura, whenever that aura was applied. A
damage over time whose ticks are triggered spells (aura 23, such as Explosive Shot 2150082) or a channel of pulses
(such as Arcane Missiles 42846) launched while holding the aura therefore neither missed nor consumed it: the launching
spell has no damaging effect, so it is not an attempt, and each tick or pulse was skipped (review26 I-1, code reading;
no pre-fix run). Mentor D-427 (the one exception to the D-426 bound) ruled that such an effect started under the aura
has its first pulse forced to miss and consume the aura, and that the skip applies only when the triggering aura was
applied before the Witchblight aura.

Decision, Witch Hunter code only, no SQL, no engine file:

- `TriggeredByAuraBeforeWitchblight` (`AscensionWitchHunterCompletion.cpp`) replaces `TriggeredByPeriodicAura` at both
  call sites, `WitchblightMiss` (`AscensionWitchHunterAbilities.cpp`) and the Witchblight proc Check
  (`aura_ascension_witch_hunter_lifecycle`, `AscensionWitchHunterDefenses.cpp`). It keeps the D-426 (a) test (the
  triggering aura effect has ticked, or the triggering aura has a periodic trigger effect naming the cast) and adds the
  apply-time rule: the triggering aura is found on the triggered cast's caster or unit target by its spell id and the
  cast's original caster (`Unit::GetAura`; `AuraEffect::HandlePeriodicTriggerSpellAuraTick` sets the aura's owner as
  the unit target and `Unit::CastSpell` takes the aura's caster as original caster), and the cast is skipped only when
  that aura was applied before every Witchblight rank aura the holder carries.
- Apply order: `Aura::GetApplyTime` first. It holds whole seconds (`GameTime::GetGameTime`), so within the same second
  the order comes from the elapsed part of each aura's duration (`GetMaxDuration() - GetDuration()`, milliseconds),
  the larger being the earlier; an aura without a finite duration in that same second, or an equal elapsed time, does
  not count as earlier. A triggering aura that cannot be found does not count as earlier either.
- Effect: a channel of pulses or a periodic-trigger damage over time launched while holding the aura has its first
  damaging pulse forced to miss through the spell route, which removes the aura; its later pulses roll normally. One
  started before the aura keeps every pulse and the aura (unchanged from fu-ondmg).
- Stated limits: within one second, a duration changed after its application (a refresh, a script calling
  `SetDuration`, a haste change of the duration) shifts the elapsed part, so the order can be wrong there; a Witchblight
  refresh keeps its first apply time (`m_applyTime` is set once at construction), so an effect started between the first
  application and a refresh counts as started under it.
- Readers: the helper acts only for a holder carrying a Witchblight rank (`WitchblightMiss` returns before it
  otherwise; the proc Check is registered for the six ranks). `Aura::GetApplyTime`, `GetDuration` and `GetMaxDuration`
  are read, never written. No other class's spell, script or engine file changes.
- Regressions, each with control arms without the aura: `681220 behaviour_metric_delta dot_launched` (Explosive Shot
  2150082 cast under the aura: the first 2150083 tick misses, the aura is gone, the next cast lands at the control rate)
  and `channel_launched` (Arcane Missiles 42846 channelled under the aura: the first 42845 pulse misses, the aura is
  gone, the next channel lands at the control rate), both through the new `landed_tick` field of `attacker_attempts`
  (ADR 0997 amendment); `tick_trigger` (Explosive Shot cast before the aura) must stay ok, and every 681220 label is
  re-run.

## Amendment (fu-chan2, mentor D-429): launch stamps replace the apply-time rule

The fu-chan apply-time rule could not order two auras applied within one unit update: `Aura::GetApplyTime` holds whole
seconds, and the elapsed part of the durations inverted the order for a channel started a few milliseconds after the
aura (fu-chan run 20261117-092101: in the same second the Witchblight aura read 1001 ms elapsed against 1002 ms for the
channel aura, so the first pulse landed). Mentor D-429 chose option (1), class code only: order by launch, not by time.
It supersedes the apply-time bullets of the fu-chan amendment; the rest of that amendment stands.

Decision, Witch Hunter code only, no SQL, no engine file:

- Stamp: `witch_hunter_casts::OnSpellCast` (`AscensionWitchHunterAbilities.cpp`) records the spell id of every cast of
  a unit carrying a Witchblight rank (`StampWitchblightLaunch`, the cast's original caster or else its caster) in that
  unit's `CustomData` (`witch_hunter_witchblight_launches`). The record is cleared when a Witchblight rank is applied
  (`ClearWitchblightLaunches` in `aura_ascension_witch_hunter_lifecycle::Apply`, real application only; a refresh keeps
  it).
- Skip: `PulseOfEffectNotLaunchedUnderWitchblight` (`AscensionWitchHunterCompletion.cpp`) replaces
  `TriggeredByAuraBeforeWitchblight` at both call sites. It keeps the D-426 (a) test and skips the cast only when the
  spell of its triggering aura is not in the holder's record. A pulse of an effect launched under the current aura
  therefore misses and consumes it; a pulse of an effect launched before the latest Witchblight application is skipped.
  No apply time, duration or aura lookup is read.
- Stated limits: the record is per spell id, not per aura instance, so an effect launched before the aura and recast
  under it shares the stamp of the recast; a second rank applied while one is held clears the record of the first.
  Every cast of the holder is stamped, triggered casts included; only the ids of triggering auras are ever looked up.
- Readers: the stamp is written only for a unit carrying a rank and read only by the two call sites (`WitchblightMiss`
  returns before it for a unit without a rank; the proc Check is registered for the six ranks). No other class's spell,
  script or engine file changes.
- Regressions: `channel_launched` (Arcane Missiles 42846) and `dot_launched`, whose fixture is now Seed of Decay
  966245 with its tick 966247: Explosive Shot 2150082 sends no SMSG_SPELL_GO for the harness's triggered cast (SpellVisual
  0, Speed 0), so its go read stayed 0. The dot_launched attackers also carry Demonic Vision 2144709 (aura 333 +100):
  Witchblight's own aura 333 -100 cancels Witch Doctor Minion Hit 803393, and the Seed of Decay launch then missed at
  the base rate under the aura, leaving no tick and the aura kept (8 of 288 windows, fu-chan2 run 20261117-092802; a
  diagnostic build, never committed, showed all such launches under the aura). `tick_trigger` stays ok and every
  681220 label is re-run. No pre-fix run (verification rules).
