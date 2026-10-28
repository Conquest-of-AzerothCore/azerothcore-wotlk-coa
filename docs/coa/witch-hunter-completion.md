# Witch Hunter source completion — 2026-09-08

This package addresses the 125 findings in the Witch Hunter audit. It builds on
the [Guardian](guardian-completion.md) and [Barbarian](barbarian-completion.md)
reconstructions. Source completion does not establish official backend parity or
in-game acceptance.

## Evidence and decisions

The active client descriptions, effective installed Spell.dbc and their rank/helper
records define the starting contract. The installed Spell.dbc hash is
`7651A1FC8C13640268F8E316917379AECB234F8AD5B52CC9801C0A0D68A16FE7`.
The 2026-09-07 audit reviewed 1,104 family-21 spell records and ten referenced
records from other families.

The evidence review also used 1,419 archived Witch Hunter records from the official
[CoA changelog](https://ascension.gg/en/changelog/4), not measured combat output.
Records 60361, 66977, 66979 and 68989 document Noctis scaling and leech changes.
The active 50% leech contract is retained; the later pending-restart 71867/71868
PvE/PvP split and overheal HoT are not imported. For the explicitly conflicting
Tormentor coefficient, record 71856 supplies the selected 29.5% RAP per tick;
native rank bases and the separate 17.5% max(Holy, Shadow) SP initial term remain.
This deliberately differs from the client's older 12.5% RAP text. No client text
or archive has been installed by this task.

These are the explicit reconstruction choices where the recovered contract is incomplete:

| Mechanic | Chosen behavior |
| --- | --- |
| Noctis | Add one damage per parry rating to its rank flat term. Heal 50% of actual damage, capped by the target's pre-hit health. Dusk heals 25% per resolved hand. |
| Damnation | Pay native base cost, then drain the remaining Rage. Every whole additional Rage adds half the player's level to the flat damage term. Fractional raw Rage is drained without an extra damage point. Triggered repeats do not drain again. |
| Night Hunter | Night is 18:00–05:59 Moscow time. Night tracking covers Humanoids, Demons and Undead and adds 100 native stealth-detection points. Day removes those extra tracking bits and detection while preserving other tracking auras. |
| Shadowhound | Permanent pet health is 40% owner max health; lesser hounds use 20%. Their attack range is 90–110% of (owner level + 4% owner RAP), recalculated once per second. Native PetAI remains in charge of permanent-pet commands. |
| Shadow Leap | No separate active Shadow Leap spell record was recovered. Owned hounds use a 20-second AI leap, reduced to 10 seconds by Scent of Magic for that leap. Houndmaster's Call commands two landing hits; native helper base + 35% owner RAP, plus two damage per level with Houndmaster. |
| Lesser hounds | Use the actual summon counts and helper durations: three from Daredevil, one from Houndmaster, one additional Kennel Master hound, and the native Unleash rank count. These helper durations are 15 seconds; Unleash retains its own duration. |
| Shadow Rage | Use the aura's rank base plus 15% owner RAP, shared by its pet and ranged-auto variants. The copied helper gains no second coefficient, critical roll or damage-taken multiplier. Normal hit mitigation still runs. |
| Rolling damage | Interrogator adds 100% of the resolved Dawn hit over its native duration. Destroyer adds its authored percentage per tick. Refreshes carry unpaid owned damage and preserve the tick clock. Integer division can discard less than one point per tick. |
| Misbegotten | A single health aura holds the sum of the last three 15%-of-damage contributions. Expiration resets the history; unrelated casters and bonuses do not contribute. |
| Clinch Fighting | A fatal hit is fully intercepted, health is set to one, then the native 50% heal and Noctis buff apply. This also handles a one-shot from full health. The internal cooldown is 120 seconds. |
| Night's Watch | Defer 25% of NPC physical damage into five one-second payments. Overlapping hits add to the ledger. Removing the stance pays outstanding debt; it cannot erase it. Player-controlled attackers and self-damage are excluded. |
| Smoke | Direct hostile targeting and attacks cannot cross the cloud boundary. Both sides inside, both outside, and ground area damage remain allowed. Native friendly movement and hostile slow fields remain. |
| Vault / Repulse | Vault follows movement flags, defaults forward, and scales a sixteen-yard base travel with run speed plus Parkour. The leap launches the caster along that heading whether or not the caster is moving, with vertical speed 10 over a distance the first collision clamps. The server drives the arc, so control returns the moment the caster lands, and the leap leaves the caster's facing to the client so the camera keeps steering it. Repulse knocks every successfully hit target back with horizontal/vertical speeds 10/5. |
| Field entities | Traps arm after one second and trigger within three yards, with a five-yard effect area. Shadow Trap observes its native target cap. Caltrops use one persistent field with one-second damage/slow pulses. Idol clears the authored control mechanics every 2.5 seconds in its native radius. |
| Pavise | The owned field uses native owner-area deflection and authored visual helper 504854 (SpellVisual 2679). The absent private gameobject 9000119 is suppressed. The actual visual appearance still needs a client check. |
| Fever / flock | Witchblood Fever applies and removes its owned vulnerability/detection helper with the DoT. Five Darkflock victims cause the authored crow DoT around each hit victim; overlapping areas refresh one owned DoT rather than multiplying it without limit. |

## Integration boundaries

[AscensionWitchHunterCompletion.cpp](../../src/server/coa/AscensionWitchHunterCompletion.cpp)
owns scoped runtime metadata and 116 explicit
effect coefficient records. Damage percentages, slows, summon counts and movement
effects do not receive AP/RAP/SP coefficients. Parent-to-child forwarding is counted
once. The new code is split into abilities, events, defenses and summons; the existing
Tonic, Torch, Flourish, Cinder, Stake and conditional-crit implementations remain.

Successful casts own selected one-use buffs, Rage draining and temporary replacements.
Damage events own landed-hit procs. Additional strikes carry their source aura so the
native proc engine can reject self-recursion. A separate exclusion list prevents
generated damage chains from recursively producing new damage chains.

Knight's Seal retains separate eight-second states: consuming the next-Desecrate
heal removes the self Seal readiness, while Dark Oath's damage reduction continues.
Cycle uses the existing native `SPELLMOD_MAX_AURA_STACKS` path, now with activation
and cleanup at 20 stacks. Mail-only Chivalry uses the shared item-armor path already
required by Guardian/Barbarian. Raid groups are supplied by Guardian migration 05.

Shared core changes add movement-aura checks at all three native casting gates and
channel interruption paths, a default-allow hostile-target hook for Smoke, a narrowly
scoped PetAI selection exception for Witch Hunter's permanent Shadowhound, and the
exact Chivalry/periodic-copy exceptions. Other unit and spell families retain their
normal behavior. This changes the server ABI and requires a coherent future build.

## Future installation

The server, SQL and model DBC additions must be installed together. See the
[release history](local-release-state.md) for recorded integrations.

The [Witch Hunter migration](../../data/sql/updates/pending_db_world/rev_20260908_07_witch_hunter_completion.sql)
contains 47 proc definitions, 340 exact script bindings, 108 explicit zero-bonus
rows, nine missing creature
templates/model associations, six model-info definitions and 80 pet levels. Zero
bonus rows prevent generic coefficient inference from double-counting explicit or
forwarded scaling. Applied and previously pending SQL files are unchanged.

The external server data package appends four missing CreatureDisplayInfo rows
and four missing CreatureModelData rows. Every old row and the old string block
are preserved. These two server DBCs are needed alongside the migration and
compiled code; there is no Spell.dbc or client archive replacement in this package.

Before a future install, reject any existing creature template, model association,
model-info or pet-level row that conflicts with the candidate. Guarded INSERTs
preserve conflicts; they do not silently repair them. Preserve Guardian 05's separate
gameobject 9000117 conflict check. Install Guardian, Barbarian and Witch Hunter
coherently with the normal backup/updater workflow.

Combat balance, pet command behavior, group fields, movement acknowledgements,
channel timing, replacement-button presentation, summon visuals, relog and talent
changes require live acceptance after an explicitly requested build/install.

Deployment preparation on 2026-09-08 found native shared display rows 11686 and
16049 already present. Their server radius/reach (0.5/1 and 0.3825/2.5) are retained,
including VerifiedBuild 53788/0. The migration uses those exact rows instead of
inferring shared server collision from mesh geometry. No existing row is overwritten.
