# Sun Cleric reconstruction policy — 2026-09-10

This package addresses the 158 original Sun Cleric audit findings:
157 implementations/extensions and one retained native critical-damage mechanism.
Class 27 uses spell family 33.
These are local source decisions, not evidence of official backend parity or live gameplay.

## Evidence and scope

The active client records and descriptions are the primary contracts. The package pins 1,150
records and the original 158 finding identities. Archived Sun Cleric changelog entries provide
context; an archive entry does not silently replace a conflicting active description. For example,
Daybreak uses 0.595 bonus healing and Heaven's Appraisal uses the active Gavel enhancements.
Corrupt Mind acquisition is outside this package and remains deferred at the user's request.

The initial source baseline contains the pending Pyromancer and Cultist packages. Shared changes
are limited to registration, contract/resource dispatch and native SpellInfo cost/equipment/spellmod
selection. All 78 captured preceding SQL files remain byte-identical. New SQL13 is unapplied.

## Dawn, Vows and finite effects

Solar Power is 0..20; its availability marker follows the actual total. Dawn requires/spends 20
and arms ten qualifying casts. Each qualifying non-triggered cast consumes one charge, including
a miss. A cast can select fulfillment at most once per second. Triggered hand hits and channel
children inherit that cast's selection; they do not consume another charge. One selected cast
dispatches the general fulfillment talents once, while its individual target results carry its
Vow modifier. Incoming spells from another player cannot borrow that player's Dawn selection.
Vow of Light therefore fulfills from a compatible own selected event, such as a self heal.

Generation is blocked while Dawn exists and during its selected result handlers, including the
last charged channel. Dawn's school-choice flag is stored in its effect-0 amount, the proc slot the
contract turns into a dummy, so ordinary aura saves preserve whether Sunrise/Sunset has already been
selected. Effect 1 stays the native Dawnsear cast-time modifier that Solar Conduit raises. Pendant
refreshes charges/duration without rearming that choice. Finite bonuses snapshot aura generations before
effects and consume only those generations; Hot Spot and Learning Light keep two/three charges.
Bulwark consumes only block/full-block events and preserves saved remaining charges on load.

Owned Eclipse ticks accumulate without refreshing duration or the next tick. Healing events feed
the cleric's current hostile victim when available: this is a local targeting choice for an
ambiguous healing-to-damage contract. Copy spells preserve resolved damage/effective healing and
normally suppress recursive procs. Holy Form's extra heal is an explicit exception for eligible
healing procs, but cannot recursively sacrifice mana again.

## Explicit local choices

- Grace with Final Vows uses ten percent remaining cooldown reduction. The active description
  references 807446 effect 2, whose recovered amount is zero; talent 707528 supplies ten. This is
  a reconstruction choice, not recovered official behavior. Grace's mana-cost reduction is 50 percent.
- Sun's Gift contributes 0.25 AP to Horusath Blast; its description does not specify a number.
- Sunflare uses the first recovered rank's 0.25 SP coefficient for all ranks.
- Radiant Cascade reaches the primary plus four additional allies, total five. The native field
  says four while the description calls those additional jumps; native bounce attenuation remains.
- Pious retains native critical-bonus-portion semantics for aura 163. No new total-critical-damage
  multiplier is invented from the ambiguous wording.
- Daytime means realm-local time from 06:00 inclusive to 18:00 exclusive. Conditional helpers update
  every 500 ms. They are not linked to a new client calendar or weather implementation.
- Holy Form follows the archived worked example: at full mana, 2,000 effective healing gives an
  additional 1,000 healing for 250 mana. The form's calculated effect-1 percentage scales the result,
  including Empowered Holy Form. Current mana fraction scales it down; below 30 percent it stops.
- Adjudicator's single-target 50-percent increase applies to its additional echo. Healing uses actual
  echo damage. It does not add a second modifier to the triggering Justicar hit.
- Suncharged follows the active Judgement Day contract, not the stale Suncharge/Sunflare description.
  Owned half-second applications stack up to the native cap; release multiplies the complete amount
  by `1 + 0.25 * stacks` once. The native wildcard aura removal is suppressed at HIT.
- The empty Gateway to Heaven helper is a Hegemony alias. Either enables the same Radiance extension;
  possessing both does not double the grant.

## Healing, defenses and spatial effects

Bless owns self plus one ally per cleric. Replacing that ally removes only the same caster's old
Bless. Blessings validate ownership both before casting and during effect execution. Devotions
are exclusive per recipient and caster. Copies use effective healing; Radiance's heal explicitly
uses SP, while Illumination, Cascade, Daybreak and Sunlight use their named bonus-healing terms.
Hammer of Kings reads Holy power even though its damage school is Holyfire. Justice hand hits
read Fire SP for their flat component while retaining native weapon damage.

The Chosen detects depletion after actual absorption, including native absorb bypass. Only actual
depletion releases Hope, whose damage is split across selected enemies. Divine Retribution saves
raw accumulated damage, divides by four on natural expiry and includes the original target.
Circle of Valor's split link requires the caster's ground aura; damage taking the caster below
ten percent removes the dynamic object. Health-gated and armor/Intellect-derived effects update
from current caster values, with exact plate/shield equipment selectors in SpellInfo.

Sun Gate uses new guarded creature 50331 and existing Shattrath portal display 23719/model 2721.
This native model is a local visual substitute. No DBC/client file changes are required. The gate
stays at the starting point, replaces only its owner's old gate and checks group, distance and
Sunstroke on interaction. Valkyr resolves GUIDs after its delay, starts native movement, and
releases landing damage only after the spline finishes near its destination. No delayed callback
retains a raw Player, Unit or Spell pointer. Rendering and real map movement remain unverified.

## Validation and future installation

Focused tests execute actual callback bodies with bounded dependencies. Separate native tests
execute the complete current cost function and native proc admission. Original prior-class tests
remain unchanged; only two legacy resource fixtures receive dependency declarations in the new
runner. MSVC `/Zs` compiles actual translation units against actual project headers without linking.
Validation included failed phases and reconciliation of the final input hashes;
an earlier passing phase does not establish the final source's validity.

SQL13 has two deliberately non-destructive guarded inserts for the gate/template model. Before
installation, reject conflicting definitions instead of silently reusing them. Install matching
pending Pyromancer, Cultist and Sun Cleric source/SQL together. Preserve the
preceding class implementations when integrating these changes. A linked build,
SQL application, restart and live combat, group, movement, relog and UI acceptance
are separate steps. Client test launches require explicit authorization.


# Sun Cleric second audit round — 2026-09-21

A later, separate wave of 125 open reports against the same class (103 spell-audit reports of the
form `Sun Cleric: "Name" (Spell ID: N) - Spell Script / Aura Handler Not Implemented`, 16 of the
same shape carrying two ranks, and 6 free-form player reports). Its spell identities barely overlap
the 2026-09-10 package above: that package's 158 findings are a different set, and nothing here
supersedes it.

Outcome: 8 fixed, 55 already correct on this core and closed by a new regression
scenario, 53 not obtainable, 9 left open.

## Why an absence means something for this class

`~/CoaServer/reference/coa-obtainable --class 27` reports the strongest calibration shape the tool
has: the live-client `CharacterAdvancement` capture holds every one of the 219 spells this class is
already known to acquire, and 5 more the shipped table lacks. For class 27, and only because of
that calibration, a spell the capture does not hold was not acquirable. The 5 extras are a real gap
in this fork and belong in their own report, not here.

These are local source decisions measured against community captures, not evidence of parity with
the original backend. A later finding that one of the spells below is acquirable should reopen its
report.

## The 53 reports closed against the data, with no source change

| Issue | Spell | Spell ID(s) |
|---|---|---|
| #1559 | Solar Crusader | 300317 |
| #1560 | Path To Glory | 300319 |
| #1566 | Concentrated Light | 300326 |
| #1567 | Blessings - Level 15 Passive | 300330 |
| #1569 | Sintorcher | 300332 |
| #1570 | Beatification | 300333 |
| #1572 | Battle Cleric | 300346 |
| #1575 | Devout Blessing | 300356 |
| #1576 | Luminescent Lances | 300358 |
| #1577 | Ascended Barrage | 300359 |
| #1578 | Piety Sun Cleric Passive Hidden2 | 300362 |
| #1580 | Struck by the Sun | 300372 |
| #1862 | Sunshine | 500142 |
| #2066 | Flash | 500144 |
| #2130 | Warrior's Light | 800610 |
| #2131 | Gleaming Vigil | 800621 |
| #2275 | Bursting Bulwark | 704392 |
| #2311 | Seeker of Sinners | 704567 |
| #2439 | Luminous Light | 704900 |
| #2440 | Vitality | 704901 |
| #2441 | Divine Fire | 704904 |
| #2443 | Placeholder | 704907 |
| #2444 | Guarded By The Light | 704912 |
| #2445 | Solar Incandescence | 704913, 704914 |
| #2447 | Sun Screen | 704918 |
| #2448 | Controlled Fury | 704921 |
| #2449 | Lord Commander | 704923 |
| #2450 | Bulwark of the Sun | 704924 |
| #2451 | Bastion of Vengeance | 704925, 704927 |
| #2453 | Last Wish | 704940 |
| #2454 | Luminary Mendicant | 704943 |
| #2455 | Angelic Touch | 704944 |
| #2456 | Rapid Execution | 704946 |
| #2458 | Wrathful Sun | 704948 |
| #2459 | Solstice | 704949, 704950 |
| #3048 | Wake | 706261 |
| #3199 | Battle Priest | 801180 |
| #3343 | Burning Light | 804030 |
| #3347 | Wind Tunnel | 804050 |
| #3349 | Cyclonean Protection | 804067 |
| #3368 | Guidance: Touch of Light | 804251 |
| #3421 | Scalding Light | 804624 |
| #3536 | Celestial Protection | 805584 |
| #3542 | Blade of The Sun | 805632 |
| #3590 | Ancient Etchings | 806022 |
| #3592 | Sins of the Father | 806061 |
| #3597 | Deliverance | 806114 |
| #3598 | Sunlight Refraction | 806122 |
| #3604 | Freeze Ray | 806160 |
| #3606 | Solar Avenger | 806196 |
| #3644 | Sunfury | 806475 |
| #3854 | Angel's Calling | 805641 |
| #3872 | No Shade | 704902 |

## The 8 real defects

| Issue | Spell | Spell ID(s) |
|---|---|---|
| #756 | March of the Valkyr | 560534 |
| #1574 | Blazing Chariot | 300350 |
| #1818 | Arbiter of Grace | 301313 |
| #1834 | Arbiter of Light | 302914 |
| #1910 | Grace | 504070 |
| #2442 | Champion's Arrival | 704905 |
| #2446 | Harmonious Bells | 704917 |
| #2452 | Vindicator | 704938, 707773 |

## Reports closed by a test rather than a source change

55 reports describe a mechanic the core already delivers natively — through spell modifiers,
stat auras or a generic engine path — so the audit's "no occurrence of the spell ID in the source"
finding was true and irrelevant. Each keeps its tooltip contract pinned by a committed scenario
under `apps/coa-gameplay-test/scenarios/sun-cleric-*.json` rather than by new code.

## Left open

| Issue | Spell | Spell ID(s) |
|---|---|---|
| #171 | Sun Cleric Valkerie Spec - Valkerie Tree |  |
| #323 | SUN CLERIC SULAR POWER |  |
| #1505 | Sun Cleric Dawn -> Radiant Conversion Do |  |
| #1511 | Sun Cleric Vow of Light has no effect |  |
| #3110 | The Chosen King | 707079 |
| #4071 | Vow of Dawn animations (Sun Cleric) |  |

- **#1562 Solar Conduit** was first closed as already correct and the closure was withdrawn when its
  scenario failed on a live worldserver. Dawn's effect 1 is the `SPELLMOD_CASTING_TIME` modifier on
  Dawnsear that Solar Conduit's `SPELLMOD_EFFECT2` raises to -20%, but the contract turned it into a
  dummy and `aura_ascension_sun_cleric_lifecycle::Calculate` pinned its amount to 1 as the
  Sunrise/Sunset school-choice flag. The flag now lives on effect 0 and effect 1 stays native
  (`sun-cleric-solar-conduit-dawnsear`).
- **#323** (Solar Power resource display) and **#171** (empty Valkyrie talent tab) are client-side:
  no server metric exists for either.
- **#3110**, **#1505**, **#1511** and **#4071** each have a tooltip clause with no
  server-side mechanism to carry it; the measurable halves are covered by scenarios.
- **#708 Burn The Heretics** was listed here for its Scorch Marks clause, but Scorch Marks is the
  finite aura 807059 that Radiant Flame consumes in `Finish`. Since 2026-09-27 that consumption grants
  the named buff 560856 to a caster with 560857 (`sun-cleric-burn-the-heretics-scorch-marks`).
- **#733 Blightbreaker** was withdrawn together with #1562, but Mercy chains to nearby allies
  (`sun-cleric-mercy`), so reading the aura without naming its caster could pick up another cleric's
  3000 ms Mercy. With one caster and caster-named reads, Mercy ticks every 1500 ms and costs twice as
  much (`sun-cleric-blightbreaker-mercy`).
