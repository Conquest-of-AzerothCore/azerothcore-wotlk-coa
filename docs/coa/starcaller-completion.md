# Starcaller reconstruction policy — 2026-09-09

This source package addresses the 164 findings from the Starcaller class audit.
Class 26 uses spell family 32.
The package follows recovered client spell records, helper chains and the archived changelog;
the choices below fill gaps in that evidence. It does not claim official backend parity.

## Resources, stars and Eclipse

Mana remains the primary resource; Mana and Energy are active for restoration and regeneration.
The selected zero-cost or base-mana parents now pay their authored percentage of **maximum** mana.
A default-false `SpellInfo::UsesMaxManaForCost` keeps other spells on the native base-mana path.
All native cost modifiers remain in that path. Refunds and Font of Magic use the amount actually paid.
Moonblade restores fifteen percent missing mana. Celestial Strike/Cleave restore mana on landed
hits, including killing blows, while misses do not generate these class-specific refunds.

Eclipse acquisition starts the four-second Phase driver. Four stacks enable activation and are
reserved at its start; later gains are preserved. One eligible cast reserves the activation's
generation. Silverstream doubles cost and healing; Splash is instant and adds five-percent target
maximum health; Touch refunds its actual mana and grants one Phase. Moonflow resets its cooldown
and consumes owned stars only during Eclipse. Selected charges and temporary replacements have
generation checks so an old cast cannot consume a newly refreshed buff.

Native Lance, Trueshot, Starfire, Umbral and Starsweep consumer chains remain. Each consumption
tick reserves one caster-owned Scattered Star before damage, eight-percent maximum-mana restoration,
cooldown reduction and ten/eight-star counters. Empty or foreign stacks grant no rewards. The legacy
573282 helper's stale Starcall description does not add a new ungranted Starcall-consumption passive.
Goddess healing is enabled only by its aspect. Capacity modifiers remain native; the unadvertised
general critical-chance aura on each star is disabled.

Dancing and Celestial Glaives each multiply consumption effectiveness by 1.5. They multiply one
another; Moonwell separately doubles consumed-star damage and mana. This stacking rule is a local
choice. Goddess healing and each cooldown reduction receive the applicable effectiveness factor.
Trueshot has two charges with eighteen-second recovery, shared by its actual parent ranks.

## Conditional effects, targeting and finite state

Burning means an active harmful periodic-damage or periodic-leech effect whose school includes Fire.
Lunar Splinters guarantees Lance criticals and adds twenty-five-percent critical damage. Tyrande's
Training adds twenty-five critical percentage points and critical damage to Starfire and actual
Trueshot damage helpers. Private raw selectors are disabled for these exact records. Critical chance
worded as a percentage on Lunar Knight, Revelation and Tyrande's Guidance is treated as percentage
points; this is an explicit local interpretation.

Goddess removes the miss component of spells/abilities. Other native outcomes, including immunity,
reflection, avoidance and resistance, remain separate. Copied result helpers do not receive another
coefficient, critical roll or mitigation pass. Warden's three extra hits use actual triggering damage.
Aspect Stars forwards the distinct base amount of each of its three ranks. Starflare haste requires
actual helper damage. Scattering increases only the Warden aspect's proc chance.

Vengeance retains its native owned thirty-percent Astral damage modifier and ten-second mark;
no additional scripted distance multiplier is applied. The next-cast range buff requires successful
mark application. Lunar Charge instead has its own local factor: one percent per yard of straight-line
displacement from Shooting Star's start, capped at fifty yards. The next qualifying attack ends
active forced movement and reserves the charge once; zero distance still allows the base hit.
Every Shooting Star rank receives forced movement and temporary slow immunity.

Lunar Prophecy acts on completed Moon Arrow casts, reducing Prayer by three seconds and Moonflow/
Celestial Form by two. Starcall damage reduces Arrows in the Night by two seconds. Celestial Form
uses at most five enemies within five yards. Precision launches two blades; Pulverize has five uses
and clears its accumulated caster bonus with the parent. Starfire Power opens a five-second
Drawstring replacement. Barrage, Moonblade, free spells and healing/damage bonuses have finite selectors.

## Local numerical and visual choices

| Gap in recovered evidence | Implemented local choice |
| --- | --- |
| Lunar Combatant weapon contribution | 0.20 Arcane spell power added before normal weapon multipliers |
| Asteroid Belt | Each rating: 0.005 current mana; shield block value: 0.02 current mana |
| Starburst unnamed terms | 0.50 shield block value and 0.02 maximum mana |
| Sentinel Glaive unnamed term | 0.03 maximum mana; remove the conflicting native 0.60 SP coefficient |
| Umbral rank text says 0.20 / 0.22 AP | Use 0.20 AP for the shared helper, preserving native forwarded rank base |
| Second Moon's extra 199-point hit | One authored comet amount per affected enemy; no second unexplained damage effect |
| Moonwater's unquantified heal | Ten percent of the last effective granting heal, stored on the owned stack aura |
| Night boundary | Realm-local UTC+3, 18:00–05:59 |
| Missing saber template 912358 | Native riding Frostsaber display 9991, without a global template/model edit |

Avatar keeps native creature-template 22989 (Maiev), whose base template uses display 20628.
It must not use 22989 as a direct display ID: that display is a Lobstrok. Both selected model chains
resolve in the pinned installed DBCs. Rendering, size and animation remain unverified in game.
No client/DBC file changes are included. Existing Necromancer/Templar client dependencies remain.

The coefficient table contains 124 exact spell/effect slots. Original active rank base amounts,
native weapon components and valid chain targeting remain. SQL suppresses duplicate stock coefficients.
Healing-specific recovered formulas use bonus healing; direct damage uses Arcane spell power unless
the native weapon component already supplies its own calculation. The separate coefficient slots,
including current-mana shields and Intellect contributions, are executable-test inputs.

## Stagger and shared proc correction

Shrouded in Night delays thirty percent of direct magical damage. Refreshing the pool preserves its
next tick. Integer remainder is conserved; early aura removal settles the unpaid balance. Normal
logout settles before the native character save, and death clears the remainder. This runtime pool
does not introduce a crash-recovery database journal. It does not delay its own periodic payments.

SQL06 binds Starcaller scripts. Its original raid-group entry was corrected at linked deployment:
SQL09's intermediate group 1038 inferred stat-percent aura 137, so applied SQL10 moves Shrouded Stars
704785 into dedicated damage-taken group 2000185 with Sanctuary 67480 and Vigilance 50720. Native
inference selects aura 87; the largest reduction applies once and the independent stagger is preserved.
The deployed AuraScript registers its periodic callback only when the actual spell has a periodic
dummy aura. SQL09 removes Moonblade's inert aura binding while retaining its native/global handling.

SQL08 updates exactly 64 Felsworn/Knight proc rows from old mask 63 to 9331, adding native
BLOCK, ABSORB and FULL_BLOCK admission. Earlier SQL05/07 remain unchanged. Their earlier proc fixture
tested only six low bits and missed this failure; the new 24,948-case native test supersedes that
admission evidence. Script-level talent, ownership, hit and cooldown filters still decide actual procs.

The [September 9 class follow-up release](local-release-state.md) included a
linked build and matching Necromancer/Templar UI dependencies. Final startup
reported no new unique errors. SQL03–10 were applied and are immutable. Combat,
movement, group behavior and rendered UI acceptance remain separate from build,
native callback tests and startup validation.

## Why an absence means something for this class

The fork is a reconstruction, so its own database cannot settle "could a player acquire this?": a missing
acquisition row is also what lost server data looks like. Each outside source is therefore calibrated against the
spells this class is already known to acquire, with `~/CoaServer/reference/coa-obtainable` (community snapshots,
never the live server). For class 26 the tool reports:

```
class 26 (STARCALLER): shipped table 207; live-client capture covers 207 of 207, extra in capture 0, identical true;
                       calculator covers 192 of 207; class_spell covers 32 of 207
```

The `CharacterAdvancement` set harvested through the live client and the shipped table hold **the same 207
spells, in both directions**. The acquisition table is complete for this class, which is what makes an absence from
it evidence rather than a gap. The displayed specializations are Moon Priest, Sentinel, Warden and Moon Guard
(`ChrSpecs` field 29).

## The reports closed as not obtainable

65 reports describe spells no player can acquire. For every spell below the tool prints
`advancement=none`, `module_grant=False`, `trigger_reachable=False`, `live_capture=False`, `calculator=False`,
`server_class_spell=False` and `server_trainer=False`. Where a skill line lists the spell, it does so with
`acquire = 0`: a client record with no acquisition path. No server change is warranted, since there is nothing to
script for a spell no character can hold or trigger. The ids in the coefficient-clearing list of
`AscensionStockCoefficientData.h` (for example 800363, 800366, 800373, 801139, 801969, 801974) are a coefficient
table, not a grant path.

### No Character Advancement entry

| Issue | Spell | Spell id | Note |
|---|---|---|---|
| #557 | Lunar Conquest | 704791 | skill line Moon Guard, acquire 0 |
| #558 | Moon Priest | 801973 | skill line Moon Priest, acquire 0 |
| #559 | Lunar Blades | 801997 | skill line Moon Guard, acquire 0 |
| #1520 | Tideturner | 300238 | skill line Moon Priest, acquire 0 |
| #1521 | Elemental Extension | 300239 | skill line Moon Priest, acquire 0 |
| #1523 | Rejuvenating Arrows | 300244 | skill line Sentinel, acquire 0 |
| #1524 | Extinguisher | 300245 | skill line Moon Priest, acquire 0 |
| #1525 | Starlight Arrows | 300247 | skill line Sentinel, acquire 0 |
| #1526 | Burdening Starlight | 300248 | skill line Sentinel, acquire 0 |
| #1530 | Astral Knowledge | 300257 | skill line Moon Priest, acquire 0 |
| #1534 | Moon Touch | 300261 | skill line Moon Priest, acquire 0 |
| #1787 | Cosmic Ripple | 300993 | skill line Sentinel, acquire 0 |
| #1864 | Mana-Charged | 500204 | skill line Moon Guard, acquire 0 |
| #2109 | Torn Flesh | 800363 | not on any skill line |
| #2110 | Flow of Water | 800365 | skill line Moon Priest, acquire 0 |
| #2111 | Slipstream | 800366 | skill line Moon Priest, acquire 0 |
| #2113 | Torrent | 800371 | skill line Moon Priest, acquire 0 |
| #2114 | Pond | 800373 | skill line Moon Priest, acquire 0 |
| #2115 | Geyser | 800374 | skill line Moon Priest, acquire 0 |
| #2116 | Aegis of Neptulon | 800375 | skill line Moon Priest, acquire 0 |
| #2117 | Silvercurrent | 800376 | skill line Moon Priest, acquire 0 |
| #2118 | Surge | 800379 | skill line Moon Priest, acquire 0 |
| #2119 | Tide Lash | 800380 | skill line Moon Priest, acquire 0 |
| #2120 | Deluge | 800381 | skill line Moon Priest, acquire 0 |
| #2121 | Moonwater Blessing | 800382 | skill line Moon Priest, acquire 0 |
| #2125 | Astral Flare | 800499 | skill line Sentinel, acquire 0 |
| #2380 | Arrows of Starlight | 704733 | skill line Sentinel, acquire 0 |
| #2380 | Arrows of Starlight | 704734 | skill line Sentinel, acquire 0 |
| #2381 | True Aim | 704735 | skill line Sentinel, acquire 0 |
| #2382 | Wrath of Vashj | 704742 | skill line Moon Priest, acquire 0 |
| #2383 | Bathe | 704744 | skill line Moon Priest, acquire 0 |
| #2384 | Improved Torrent | 704746 | skill line Moon Priest, acquire 0 |
| #2385 | Liquid Space | 704752 | skill line Moon Priest, acquire 0 |
| #2386 | Bubble Blower | 704754 | skill line Moon Priest, acquire 0 |
| #2387 | Effervescence | 704758 | skill line Moon Priest, acquire 0 |
| #2389 | Shark Attack | 704760 | skill line Moon Priest, acquire 0 |
| #2394 | Bright Moon | 704779 | not on any skill line; the obtainable Bright Moon is 801226 (issue 754) |
| #2395 | Starslip | 704780 | skill line Moon Guard, acquire 0 |
| #2396 | Endless Sky | 704782 | skill line Moon Guard, acquire 0 |
| #2402 | Magic Mark | 704797 | skill line Warden, acquire 0 |
| #3039 | Elune's Warding | 706227 | skill line Moon Guard, acquire 0 |
| #3039 | Elune's Warding | 706228 | skill line Moon Guard, acquire 0; triggered only by 706227 |
| #3046 | Moonwell Blessing | 706252 | skill line Moon Priest, acquire 0 |
| #3197 | Guarded by the Moon | 801142 | skill line Moon Guard, acquire 0 |
| #3253 | Celestial Knight (Healing) | 801970 | skill line Moon Guard, acquire 0 |
| #3254 | Lunar Resplendence | 801974 | skill line Moon Priest, acquire 0 |
| #3256 | Moonwell Dipped Arrows | 801991 | skill line Sentinel, acquire 0 |
| #3257 | Cosmic Duality | 801998 | skill line Sentinel, acquire 0 |
| #3372 | Moon Guard | 804287 | skill line Moon Guard, acquire 0 |
| #3380 | Choking Water | 804387 | skill line Moon Priest, acquire 0 |
| #3381 | Starsweeper | 804389 | skill line Moon Guard, acquire 0 |
| #3439 | Siren's Song | 804738 | skill line Moon Priest, acquire 0 |
| #3517 | Starfury | 805435 | skill line Sentinel, acquire 0 |
| #3518 | Starlord's Mandate | 805438 | skill line Moon Guard, acquire 0 |
| #3527 | Alignment | 805507 | skill line Sentinel, acquire 0 |
| #3528 | Celestial Knight | 805521 | skill line Moon Guard, acquire 0 |
| #3529 | Astral Quickness | 805522 | skill line Sentinel, acquire 0 |
| #3531 | Moonsteel Weapons | 805540 | skill line Moon Guard, acquire 0 |
| #3532 | Celestial Armor | 805544 | skill line Moon Guard, acquire 0 |
| #3533 | Cosmic Vengeance | 805545 | skill line Moon Guard, acquire 0 |
| #3535 | Huntress Shot - Mana Cost % | 805553 | skill line Sentinel, acquire 0 |
| #3749 | Starlight | 801131 | skill line Sentinel, acquire 0 |
| #3750 | Lunar Focus | 801139 | skill line Sentinel, acquire 0 |
| #3771 | Vengeance of Elune | 801969 | skill line Moon Guard, acquire 0 |
| #3827 | Halt | 805432 | skill line Warden, acquire 0 |
| #3831 | Rain of Comets | 805520 | skill line Sentinel, acquire 0 |
| #3886 | Bubble Buddy | 704747 | skill line Moon Priest, acquire 0 |

Issue #2017 (Starcrash) also names 704767, which is not acquirable (advancement none, absent from the calibrated
capture, listed only on the Sentinel skill line); its two obtainable ranks, 560721 and 704766, are a different
matter and are not part of this table.

## Boundaries

These snapshots are community captures, not the live server. If a spell above is later shown to be acquirable, by a
trainer, a quest, or a client build carrying a `CharacterAdvancement` row for it, that finding wins over this note
and the report should be reopened. The reverse case, spells the capture offers that this fork's
`CharacterAdvancement.dbc` lacks, is a real gap and belongs in its own report. The chain Vengeance of Elune 801969,
Celestial Knight 805521 and Cosmic Vengeance 805545 cross-reference each other in their tooltips; the whole chain is
unobtainable, not one link.

## Clauses the shipped data does not deliver

Cases where the fix is not in the server. Neither is open server work.

- **#136 Warden talent tree shows no icons** — the server data is complete: `CharacterAdvancement.dbc` holds 40
  entries on tab 89 (Hydromancy, `ChrSpecs` 45) with 43 rank spells, all present in `Spell.dbc` with their
  `SpellIcon` rows. The client Lua table `ASCENSION_LOCAL_COA_TALENT_TAB_ALIASES` (`CoATalentNodeData.lua`, client
  patch only) lacks `Starcaller = { Hydromancy = "Warden" }`, so the frame's tab name matches no dataset key. This
  repository has no reference to that table. Tracked by #424; #1445 is a duplicate.
- **#4007 Aspect buff tooltips overflow the frame** — 574360 Aspect of the Moonwell and 800510 Aspect of the Stars
  carry the client-extension marker `@s:804378:0@` in their description and tooltip, which the client expands into
  the Scattered Stars tooltip block. Tooltip text is client-side `Spell.dbc`; the worldserver sends only aura ids,
  so no server field can reflow the unwrapped block in the buff-frame renderer.
