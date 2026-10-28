# Chronomancer reconstruction policy — 2026-09-19

This note records what the Chronomancer audit settled without a server change: reports describing spells no
player can acquire, a report whose contract already holds, and clauses the shipped client records do not
deliver. Each can be closed with its evidence instead of being carried as open work. It makes no claim of
parity with the official Ascension backend.

## Why an absence means something for this class

The fork is a reconstruction, so its own database cannot settle "could a player acquire this?": a missing
acquisition row is also what lost server data looks like. The question is settled by calibrating each outside
source against the spells this class is already known to acquire, with `~/CoaServer/reference/coa-obtainable`
(community snapshots, never the live server):

```
class 22 (CHRONOMANCER): ours 169; live-client capture covers 169 of 169, extra in capture 0, identical true;
                         calculator covers 157 of 169; class_spell covers 35 of 169
```

The `CharacterAdvancement` set harvested through the live client's own `GetAllEntries` API and the shipped table
hold **the same 169 spells, in both directions**. The acquisition table is complete for this class, which is what
makes an absence from it evidence rather than a gap.

## The 90 reports

None of the 99 spells below has a `CharacterAdvancement` entry, a module grant, a `class_spell` or trainer row,
or a reachable trigger from another spell, and none appears in the live-client capture or in the CoA Build Hub
calculator. 89 sit on one of the three Chronomancer specialization skill lines (79 Infinite, 80 Artificer,
81 Time) with `acquire = 0` — a client record with no acquisition path, the same shape as the 73 Templar spells
settled this way — and 10 appear on no skill line at all.

No server change is warranted: there is nothing to script for a spell no character can hold or trigger.

| Issue | Spell | Id | Where it appears |
|---|---|---|---|
| #1765 | Timeline Mastery | 300761 | nothing |
| #1766 | Maw of Balance | 300762 | nothing |
| #1854 | Revolving Sands | 500113 | skill line 79 Infinite |
| #2064 | Plaguestorm | 500095 | skill line 80 Artificer |
| #2142 | Time Stretch | 800863 | skill line 81 Time |
| #2289 | Rust Creation | 704479 | skill line 80 Artificer |
| #2290 | Artificer's Amplification | 704483 | skill line 80 Artificer |
| #2293 | Chromatic Shards | 704492 | skill line 79 Infinite |
| #2942 | Reconstruction | 706043 | skill line 79 Infinite |
| #2943 | Elder Tome | 706044 | skill line 79 Infinite |
| #2944 | Black Hole | 706045 | skill line 79 Infinite |
| #2946 | Master of Chaos | 706047 | skill line 79 Infinite |
| #2947 | Master of Duality | 706049 | skill line 79 Infinite |
| #2948 | Master of Order | 706050 | skill line 79 Infinite |
| #2949 | Improved Reverse Wound | 706052 | skill line 79 Infinite |
| #2950 | Wound Removal | 706054 | skill line 79 Infinite |
| #2951 | Slipstream | 706056 | skill line 79 Infinite |
| #2952 | Dark Star | 706062 | skill line 79 Infinite |
| #2953 | Luck or Fate? | 706065 | skill line 80 Artificer |
| #2953 | Luck or Fate? | 706082 | skill line 80 Artificer |
| #2954 | Enchanted Collar | 706066 | skill line 80 Artificer |
| #2955 | Runed Rod | 706067 | skill line 80 Artificer |
| #2955 | Runed Rod | 706068 | skill line 80 Artificer |
| #2956 | Plentiful Orbs | 706069 | skill line 80 Artificer |
| #2956 | Plentiful Orbs | 706070 | skill line 80 Artificer |
| #2958 | Eternity's End | 706072 | skill line 80 Artificer |
| #2959 | Protector Training | 706073 | skill line 80 Artificer |
| #2960 | Discs Upon Discs | 706074 | skill line 80 Artificer |
| #2960 | Discs Upon Discs | 706075 | skill line 80 Artificer |
| #2962 | Ancient Text | 706081 | skill line 80 Artificer |
| #2964 | Vivid Memory | 706086 | skill line 81 Time |
| #2965 | Truly Infinite | 706087 | skill line 81 Time |
| #2966 | Improved Time Stop | 706088 | skill line 81 Time |
| #2966 | Improved Time Stop | 706089 | skill line 81 Time |
| #2967 | Empowered Restoration | 706090 | skill line 81 Time |
| #2968 | Improved Past Self | 706091 | skill line 81 Time |
| #2968 | Improved Past Self | 706092 | skill line 81 Time |
| #2969 | Spatial Distortion | 706094 | skill line 81 Time |
| #2971 | Age of Empires | 706097 | skill line 81 Time |
| #2972 | Carbon Dating | 706101 | skill line 81 Time |
| #2973 | Chrono Herald | 706103 | skill line 81 Time |
| #2973 | Chrono Herald | 706104 | skill line 81 Time |
| #2974 | Wisdom | 706105 | skill line 80 Artificer |
| #2974 | Wisdom | 706106 | skill line 80 Artificer |
| #2975 | Balance of Power | 706108 | skill line 79 Infinite |
| #2976 | Saviour | 706109 | skill line 79 Infinite |
| #2977 | Beam of Time | 706110 | skill line 79 Infinite |
| #2978 | Biting Chaos | 706111 | skill line 79 Infinite |
| #2979 | Unearthed Passage | 706112 | skill line 79 Infinite |
| #2981 | Chrono Sorcery | 706115 | skill line 79 Infinite |
| #2982 | Timemancy | 706118 | skill line 81 Time |
| #2982 | Timemancy | 706119 | skill line 81 Time |
| #2983 | Chromatic Misalignment | 706120 | skill line 81 Time |
| #2985 | Cursed ID - Procs wont work on it | 706123 | skill line 80 Artificer |
| #2986 | Shield of The Keeper | 706124 | skill line 79 Infinite |
| #2987 | Timewarped Shield | 706125 | skill line 79 Infinite |
| #2988 | Wand of Entropy | 706126 | skill line 80 Artificer |
| #2989 | Improved Temporal Focus | 706127 | skill line 81 Time |
| #2991 | Quickcaster | 706132 | skill line 81 Time |
| #2993 | Dimensional Phasing | 706135 | skill line 81 Time |
| #2994 | Future Vision | 706136 | skill line 81 Time |
| #3044 | Accelerated Mending | 706249 | skill line 79 Infinite |
| #3166 | Dazzled | 800050 | skill line 81 Time |
| #3203 | Mass Decomposition | 801283 | skill line 79 Infinite |
| #3204 | Chronicles of History | 801288 | skill line 81 Time |
| #3205 | Time Loop | 801297 | skill line 81 Time |
| #3385 | Artificer's Toughness | 804420 | skill line 80 Artificer |
| #3386 | Artificer's Magic | 804422 | skill line 80 Artificer |
| #3387 | Artificer's Spellplate | 804431 | skill line 80 Artificer |
| #3393 | Shattered | 804447 | skill line 80 Artificer |
| #3394 | Collapse | 804448 | skill line 80 Artificer |
| #3398 | Order Generation Passive | 804485 | nothing |
| #3399 | Chaos Generation Passive | 804486 | nothing |
| #3400 | Echo | 804487 | skill line 80 Artificer |
| #3401 | Incarnation | 804493 | skill line 79 Infinite |
| #3402 | Remake | 804501 | skill line 79 Infinite |
| #3403 | Chronobeam Passive | 804502 | nothing |
| #3404 | Order Baseline Negative | 804516 | nothing |
| #3405 | Chaos Baseline Negative | 804517 | nothing |
| #3423 | Order and Chaos WATCHER | 804659 | nothing |
| #3482 | Stormcloak | 805161 | nothing |
| #3577 | Timeline Guardian | 805845 | skill line 79 Infinite |
| #3578 | Timeline Destroyer | 805846 | skill line 79 Infinite |
| #3579 | Tome of Chaos | 805849 | skill line 79 Infinite |
| #3580 | Celestial Glaives | 805850 | nothing |
| #3609 | Last Wish | 806207 | skill line 80 Artificer |
| #3610 | Disenchant Weapon | 806208 | skill line 80 Artificer |
| #3619 | Sandpage | 806244 | skill line 81 Time |
| #3751 | Epoch | 801275 | skill line 79 Infinite |
| #3752 | Past Self | 801278 | skill line 81 Time |
| #3753 | Buy Time | 801280 | skill line 81 Time |
| #3754 | Discordant Blast | 801290 | skill line 79 Infinite |
| #3755 | Fracture Timeline | 801306 | skill line 81 Time |
| #3793 | Stasis | 804419 | skill line 80 Artificer |
| #3794 | Flow of Infinity | 804497 | skill line 80 Artificer |
| #3843 | Dilation | 806246 | skill line 80 Artificer |
| #3847 | Maw of Chaos | 806316 | skill line 79 Infinite |
| #3849 | Gift of the Timeways | 806332 | skill line 79 Infinite |
| #3883 | Infinite - Level 30 Passive | 706058 | skill line 79 Infinite |

## Boundaries

These snapshots are community captures, not the live server. If a spell below is later shown to be acquirable —
a trainer, a quest, a client build carrying a `CharacterAdvancement` row for it — that finding wins over this
note and the report should be reopened. The reverse case, spells the capture offers that this fork's
`CharacterAdvancement.dbc` lacks, is a real gap and belongs in its own report.

## Reports closed by a test rather than a source change

One report of the audit needed no source change, because the contract it asks about already holds. It is
recorded here because nothing else carries its closure.

| Issue | Spell | Id | What proves it |
|---|---|---|---|
| #1183 | Time Beacon | 574310, 574362 | `apps/coa-gameplay-test/scenarios/chronomancer-time-beacon-durations.json` |

The gameplay scenario carries the closure because the module unit test that previously carried it,
`apps/coa-tests/chronomancer_time/cases.cpp:47-62`, cannot run on Linux: its `run.py` builds through MSVC's `cl.exe`.
That test still covers the same contract on Windows. It loops `{0u, 574310u, 574362u}`, applying one beacon at
a time and removing both between iterations, and asserts Aeon of Renewal's applied duration at 3000 / 7000 /
11000 ms and Aeon of Protection's at that duration plus 5000 ms. The `7000 - 3000 = 4000` and
`11000 - 3000 = 8000` steps are exactly the two ranks' `SPELLMOD_DURATION` amounts (aura 107,
`EffectMiscValue` 1, `EffectSpellClassMask [0,0,32768]`), so both the scenario and the test discriminate the
talent.

## Clauses the shipped data does not deliver

Cases found during the 2026-09-19 Chronomancer audit where a tooltip promises more than the client records
carry, or where a clause resolves to a no-op. None is open work: a clause with no carrier cannot be scripted
without inventing the missing intent, and several need a decision before anything is written. Each line names
the decisive field.

- **#894 Infinite Horizon 560528** — effect 1 is `SPELLMOD_BONUS_MULTIPLIER` +20% masked to Timerend and
  Unmake, but `Unit::SpellDamageBonusDone` applies that op only when the effect's `EffectBonusMultiplier` is
  nonzero. Unmake 503784 carries 0.0624; every Timerend rank carries 0.0, and the one that carried 0.1
  (801291) is zeroed by `AscensionStockCoefficients.cpp`, and the Timerend descriptions state no spell power
  term. The Timerend half is dead. The raid aura and the Unmake bonus work
  (`chronomancer-infinite-horizon-raid-and-unmake-scaling`), and since 2026-09-22 raid damage group 2000184
  enforces "does not stack with similar effects" (`stormbringer-fix-conductor-in-charge`).
- **#786 Black Hole 707557, 707743** — aura 112 `SPELL_AURA_OVERRIDE_CLASS_SCRIPTS`, `EffectMiscValue` 20007,
  `EffectMiscValueB` 26. Every other client record with selector 20007 and state 26 describes "slowed"
  targets (Reckless Assault 804610, The Time Has Come 572879, Shard of True Ice 805425), and Felsworn's
  Reckless Assault already reads it as `SPELL_AURA_MOD_DECREASE_SPEED`. Since 2026-09-27
  `Unit::HasAuraState` computes `ASCENSION_TARGET_SLOWED` (26) that way and both ranks convert to aura 303,
  so Melt Reality and Unmake gain the bonus
  (`chronomancer-black-hole-slowed-damage`). The mask `[0,33554944,0]` still omits Chromatic Shard, which the
  tooltip names; that half has no carrier.
- **#1987 Timeblender 555737** — the crit half works; "gives it an additional charge" has no carrier.
  `SpellCharges.dbc` holds exactly one row for the Fabric of Time family, `(572378, 328)`, and none of the
  obtainable ranks (570177/570178/570179, 572361/572362/572363, 806299) has one.
- **#570 Warpstriker 707556** — effect 0 is aura 235 `SPELL_AURA_MOD_DISPEL_RESIST` 15, which
  `Aura::CalcDispelChance` reads off the unit carrying the dispelled aura and only for an offensive dispel.
  It protects auras on the Chronomancer, not auras the Chronomancer placed elsewhere; the caster-side lever
  (`SPELLMOD_RESIST_DISPEL_CHANCE`, op 28) is absent from the record.
- **#3627 Temporal Anomaly 806315** — aura 69 `SPELL_AURA_SCHOOL_ABSORB`, `EffectBasePoints` 49,
  `EffectMiscValueB` 50, `EffectTriggerSpell` 0. `Unit::CalcAbsorbResist` treats the amount as a flat pool,
  never reads `MiscValueB`, never accumulates and never heals at expiry, so what ships is a ~50-point absorb.
- **#3729 Waves of Time 801277** — effect 1's `EffectTriggerSpell` 65633 is Arcane Cast Visual, a
  `SPELL_EFFECT_DUMMY` with no handler, so the only displacement is the delayed 802600 at t+2 s. The record's
  `AuraDescription` also names a movement-speed slow it has no aura effect for.
- **#3202 Gravity Bomb 801282** — the parent's `$RAP*0.3` term has no carrier: `DmgClass` 1,
  `EquippedItemClass` -1 and no `SPELL_ATTR0_USES_RANGED_SLOT`, so `Unit::SpellDamageBonusDone`'s stat
  selector would read melee attack power, which is not the same stat.
- **#916 Shifting Chaos 706059** — its only effect is `Aura=354`, left `nullptr` in the handler table and
  absent from `isTriggerAura[]`; ~250 Ascension spells across every class use it. The same gap kills #807
  Chaotic Time's "Melt Reality replicates an additional 20%" clause, whose mask resolves to 504727, itself an
  aura-354 record. Since 2026-09-27 706059's effect is a dummy and `chronomancer_secondary_hits` casts its
  payload 801269 at every Chromatic Shard or Anomaly Spike hit for 20% of the damage dealt, as a resolved
  amount over 801269's native 8 yd area around the struck enemy (`chronomancer-shifting-chaos-replication`).
- **#534 Destabilize Time 680971** — effect 0 is aura 42 with `EffectTriggerSpell` **0**, and
  `AuraEffect::HandleProcTriggerSpellAuraProc` returns on a null trigger. Every number in the tooltip lives in
  570761, which nothing casts. Since 2026-09-26 `spell_ascension_destabilize_time` keeps 570761 on the target
  at the debuff's stacks and remaining duration and adds a stack on each enemy cast
  (`chronomancer-destabilize-time-cast-slow`).
- **#3395 Roll Back 804490** — its single `SPELL_EFFECT_SCRIPT_EFFECT` falls through
  `Spell::EffectScriptEffect`, which handles only `SPELLFAMILY_GENERIC` and `SPELLFAMILY_ROGUE`, and no module
  script registers on the id.
- **#1071 Unstable Chronoglass 503836** — `SPELL_EFFECT_SUMMON` with `EffectMiscValue` 506015, and creature
  506015 exists neither in `data/sql/` nor in the repack's world dump. The spell side of the mechanic is
  shipped: 506638 "Unstable Chronoglass" is `SPELL_AURA_SPELL_MAGNET` on `TARGET_UNIT_MASTER` with
  `ProcCharges` 3, the tooltip's "next 3", which `Unit::GetMagicHitRedirectTarget` consumes natively, and
  503870 "[Aura]" (`SPELL_AURA_DUMMY` + `SPELL_AURA_MOD_STUN`, visual 19992) is the glass's own state. Only the
  creature row is missing: its display id, faction, level, `unit_class` and flags are in no readable source.
- **#765 Incarnation of Chaos 570067** — its Description promises resetting Chromatic Shard's cooldown and a
  free next cast; its three effects do none of it. 504723 is the record that does exactly that, and nothing in
  `Spell.dbc` triggers it.
- **#3662 Ideal Time 807210** — `ProcCharges` 0 is repaired to 1 at load, but charges are spent only by
  `Player::RemoveSpellMods` (which needs the spellmod registered on a real cast) or by
  `Aura::PrepareProcToTrigger` (which needs a `spell_proc` row). Until such a row exists the buff still lasts
  its full 10 s instead of one ability.
- **#2164 Null Orbs** — periodic damage cannot crit without `SPELL_AURA_ABILITY_PERIODIC_CRIT`
  (`AuraEffect::CalcPeriodicCritChance` returns 0 otherwise). The only family-28 carrier is the passive
  Impeccable Timing 560949, so the clause is dead for any Chronomancer who has not taken it.
- **#1349 Mass Babify 520855** — the tooltip states an 8 s cap against players. `MECHANIC_POLYMORPH` maps to
  `DIMINISHING_DISORIENT` and `SpellMgr::GetDiminishingReturnsLimitDuration` has no family-28 case, so the cap
  is the default 10 s.
- **#1979 Cheating Time, #3608 Time Is A Circle** — both promise "cannot be extended beyond maximum
  duration", but `Spell::EffectAscensionRefreshAura` raises the cap and `Spell::EffectAscensionModifyAuraDuration`
  never caps at all. 524962 also omits Singularity Core 804438 from the Continuum spells it extends, although
  804438 carries the same word2 `0x8` Continuum tag as the three it names.
- **#1106 The Vast Infinite 706083** — the tooltip splits incoming damage evenly amongst all allies, up to
  100% of their total health, and heals it back at the end. Effect 0 is aura 69 `SPELL_AURA_SCHOOL_ABSORB`
  with `EffectBasePoints` 25 and `EffectMiscValueB` 100, which `Unit::CalcAbsorbResist` reads as a flat ~25
  shield; damage splitting in this core is a different aura, 300 `SPELL_AURA_SHARE_DAMAGE_PCT` in
  `Unit::DealDamage`, and effect 1 is an unscripted `SPELL_AURA_DUMMY`. The payloads do exist: 707600
  "The Vast Infinite [Damage]" ("Share damage.") and 707601 "[Heal]" ("Share heal."), both resolved-value
  helpers. Since 2026-09-27 `spell_ascension_the_vast_infinite` absorbs 25% of each hit up to 100% of the
  holder's maximum health, splits it evenly across the caster's linked group members through 707600 and heals
  each of them through 707601 at expiry for the shared damage it took (`chronomancer-the-vast-infinite-share`).
  The cap is not exercised by that scenario.
- **#3152 Overcorrection 707657** — the tooltip promises a heal-over-time on the caster; the single effect is
  `APPLY_AURA` with `Aura=354`, `EffectBasePoints` 5 and `EffectTriggerSpell` 561231, and aura 354 is
  `nullptr` in the handler table. The HoT 561231 itself is ready (`SPELL_AURA_PERIODIC_HEAL`, 1000 ms
  amplitude, 5000 ms duration).
- **#829 Infinite Keeper 806312** — the tooltip triggers the effect when Unmake hits an enemy affected by
  *your* Timerend. The record has no `spell_proc` row, and the caster half of the clause cannot be expressed
  in data: `conditions` / `CONDITION_AURA` is satisfied by any caster's Timerend. Since 2026-09-27 806312's
  effect is a dummy and `chronomancer_secondary_hits` casts its trigger 806314 when an Unmake rank lands on an
  enemy carrying the same Chronomancer's Timerend, and the vortex 806313 carries its tooltip's 0.12 spell power
  per tick (`chronomancer-infinite-keeper-timerend-vortex`).
- **#449 Buy Time 520188** — the stasis package (520185, 520186 and its delayed 520205) is entirely native and
  correct; only "casting Unmake on a target will remove this effect" has no carrier. No Unmake rank has a
  `spell_linked_spell` or a `spell_script_names` row, no module script touches 520185/520186/520188, and
  `Unit::GetDispellableAuraList` only lets a spell with `SPELL_ATTR0_NO_IMMUNITIES` remove a
  `MECHANIC_BANISH` aura. Since 2026-09-26 every Unmake rank casts the client's own remover 807310
  ("Unmake / Buy Time Remover", `SPELL_EFFECT_REMOVE_AURA` 520186 with `SPELL_ATTR0_NO_IMMUNITIES`) through
  `spell_linked_spell` (`chronomancer-buy-time-unmake-removal`).
- **#1163 Rapid Acceleration 570149** — the tooltip adds 15% bonus-healing scaling to Accelerated Recovery and
  an instant heal for 15% of the total periodic effect. Effect 0 is `SPELL_AURA_ADD_PCT_MODIFIER` with
  `EffectMiscValue` 40 while `MAX_SPELLMOD` is 32, so `AuraEffect::CalculateSpellMod` and
  `Player::AddSpellMod` both discard it; effect 1 is an unscripted `SPELL_AURA_DUMMY`. The client names the
  private index: Weapon Empowerment 92857 "[Spell Power Direct]" uses op 24 and 92858 "[Spell Power DoT]" op 40.
  Since 2026-09-27 effect 0 loads as `SPELLMOD_BONUS_MULTIPLIER`, which scales Accelerated Recovery's periodic
  coefficient in `Unit::SpellHealingBonusDone`, and each application casts the client's Accelerated Recovery
  heal 804500 for 15% of the tick amount times the total ticks (`chronomancer-rapid-acceleration`). Accelerated
  Recovery itself still has no bonus-healing coefficient in the repository (`EffectBonusMultiplier` 0, no
  `spell_bonus_data` row) although its tooltip reads `$bh*0.23` per tick, so the 15% multiplies whatever the
  world database supplies.
- **Singularity Core 804438** (surfaced by #2984, out of its scope) — the tooltip says "Empower your **Wand
  attacks**", but its aura-42 effect has an empty `EffectSpellClassMask`, so the entry
  `SpellMgr::LoadSpellProcs` generates has
  `SpellFamilyName` 0 and fires on any ranged-damage-class hit. Its `ProcFlags 0x4001c0` also contains
  `PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK`, firing off damage the Chronomancer receives.
- **Improved Reverse Wound 706052** — `Effect[1]` is `Aura=4` (`SPELL_AURA_DUMMY`) with `EffectMiscValue` 11
  and `EffectBasePoints` -5001, the shape of a -5 s cooldown modifier written on aura 4 instead of 107, so
  nothing consumes it. #543 names 706053 only.

### Stale client text

Records whose displayed text describes something their own effects do not, with no server consequence:

- **Rippling Power 806300, 807893** — the `AuraDescription` promises the 560401 / 560402 mana-threshold
  bonuses; neither record has an acquisition row or any reference in `src/`, `modules/` or `data/sql/`, and
  both passives carry `SPELL_ATTR0_DO_NOT_DISPLAY`.
- **Procrastination 520854** — the `AuraDescription` names Buy Time, while the class mask reaches Timeguard
  only; Buy Time 520188's family bit (word2 268435456) is not in the mask.
- **Timeless 706131** — the `AuraDescription` says haste; the single effect is `SPELLMOD_EFFECT2` on Endless
  Sands' mana-cost effect.
- **Timeblender 555737** — the `AuraDescription` describes Reverse Wound refreshing Accelerated Recovery; the
  single effect is `SPELLMOD_CRITICAL_CHANCE`.
- **Waves of Time 801277, Shatter Echo 680374** — both carry an `AuraDescription` for an aura effect the
  record does not have; **524944** names "Empower Wand: Artillery" where its `EffectMiscValue` is 804435 Flux
  Emitter.
- **The Bieko Effect 706099** (#1219) — Hasten 801304's `$?s706099` text and 707312's own description name
  Dimensional Divergence, Backtrack and Timeguard, and 712371's names Mend Timeline and Temporal Focus; the
  talent's description and 707312's `EffectMiscValue`s agree on Dimensional Divergence 802790, Temporal Anomaly
  806315 and Temporal Focus 806165, and those are what `spell_ascension_the_bieko_effect` reduces
  (`chronomancer-bieko-effect-cooldowns`).
