# Pyromancer reconstruction policy — 2026-09-09

This source package addresses the 196 original Pyromancer audit findings.
Class 24 uses spell family 30.
Active client descriptions and effect records take precedence over stale helper descriptions.
Archived changelog entries supply context; explicit local choices below cover missing rules.
This is a local reconstruction, not proof of official backend parity.

## Resources and selected casts

Heat retains its remainder when converted to Embers: each complete 100 Heat grants an Ember,
up to five. Bonuses observe actual Ember gains/spends, including the native direct Ember aura,
and do not fire when capacity prevents a gain. Superheated rolls for each gained/spent Ember;
Fire and Brimstone and Lifebinder require their talents. Black Magic observes Heat generation
once per second. Rapid Incineration changes the remaining Lava Shard/Pillar cooldowns by ten
percent per spent Ember. Shazzrah restores maximum-mana percentage; To Ashes/Ashen Skin use
base mana. Existing rank-aware resource requirements and Draconic Invocation's five-Ember
path remain. The native helper's unconditional talent rewards are disabled.

Flamecasting caps at five, or ten with Invocation of Flames. Grants preserve the current expiry,
including direct aura casts and the private five-stack helpers. Ignis consumes a snapshot of
those stacks at channel start; cancellation never releases its final damage/healing. Ignis
Fatalis uses the native duration modifier for its half-second channel reduction, shared with
the client channel-start packet. Natural Flamecasting expiry alone triggers Sizzle.

Aspect's Blessing, next-Blaze, Invoke, Deathwing, Sageweaving and Earthwarder reserve the current
aura generation for a qualifying normal cast. Completing an older cast cannot consume a newly
granted generation. Ragnaros has three native saved charges, consumed by the selected normal
Lava Shard casts; it has no automatic proc row. Failed pre-cast checks and unrelated/triggered
casts do not consume selected buffs. Cast completion, including a later miss, spends a selected
cast bonus. Fired Up's refunds occur when an Ember is actually spent.

Draconic Aspect and level-appropriate Echo ranks are learned temporarily while their passives
are present. Echo replaces known Explode ranks with the highest eligible known Echo. Losing
the passive clears replacements and temporary grants while preserving permanent learned spells.
Residual Power updates Explode cast time from current Embers. Dragon's Edge uses raw spell
critical rating as Intellect, not the level-converted critical percentage.

## Damage, healing and owned state

Burning means the caster's own active family-30 periodic-damage aura. Combustion uses the active
Explode description: fifteen percent more damage per such effect; the passive's dormant five-point
field is not its damage rule. Accelerants, Dragon's Bane and Flames of Execution use their exact
spell/health conditions. Execution adds no undescribed duration bonus.

Aspect of Time copies forty-five percent of actual damage, with at most four extra hits. Each
next copy uses the preceding hit's actual result. Lifebringer heals from those results. Copied
results receive no second coefficient, critical roll, armor, resilience or damage/healing-taken
multiplier. Immunity and new absorption still apply unless the active spell explicitly pierces
them. Dragon's Wrath and Pyroclasm pierce absorb/resistance; Ignis also ignores immunity.

Blaze's next-cast critical chance/critical-bonus snapshots use its existing saved dummy slots,
so consuming the granting buff does not remove the DoT's bonus. Scorched and Soothing Flames
accumulate thirty percent of qualifying actual damage/effective healing. Their integer remainder
and remaining tick count are stored in saved dummy amounts. Pyroclasm consumes only owned
Burning effects, doubles their remaining non-critical damage budget and adds level-scaled
35–37 damage before its new DoT. This new DoT receives PvP mitigation once. Scorched keeps the
installed six-second duration; a later archived twelve-second balance change is not imported.

Stoke adds three seconds per qualifying critical Ignite/Infernus tick, capped at twelve extra
seconds for that application. Its saved extension budget survives normal aura loading; a fresh
application resets it. Spread preserves owner, rank, duration, next tick, amounts, critical
snapshot and accumulated budget. Overwhelming spreads Blaze to one extra enemy within eight
yards; Fiery Passion spreads owned effects to one enemy within five yards per cast. These limits
come from the active helper records. Other extensions retain their described amounts without
an invented twelve-second cap. No crash-recovery journal is introduced.

Wild Magic's damage percentage uses its base amount plus Intellect times 0.125 percentage points;
its mana burn charges the caster, as helper 800957 targets the caster. Binding Flames restores
twenty-five percent of the caster's missing mana when Essence is used on another ally. Essence
itself restores the target's maximum-mana percentage each tick, doubled on self. Lowest-health
heals select living friendly raid/party allies and the caster, in the same phase. Fueling the Fire
retains its base/per-level amount plus Spirit and uses the native twelve-target, thirty-yard limits.

Inferno heals periodically and explodes on natural expiry. Scepter changes this to a five-second
explosion schedule during its extended duration; there is no second expiry explosion. Barrier
retaliation uses the shield caster's Spirit, including on another ally, and admits fully absorbed
direct attacks. Magma Skin retaliates against melee/ranged damage and generates one to three Heat.
Lava-Drenched protects helpful applications cast by the Pyromancer, including allied recipients;
it does not protect harmful applications or alter another class's dispel resistance. Caster aura-317
absorb modifiers are used only for this class's family-30 shields.

## Summons and local choices

The three missing creature templates use guarded new definitions and native model chains:

| Template | Native display | Local scale |
| --- | --- | --- |
| 50359, Roaring Pyre | 1405, Fire Elemental | 0.35 |
| 50258, Phoenix Egg | 20245, egg | 0.60 |
| 52258, Firestorm | 1405, Fire Elemental | 0.80 |

The egg temporarily uses native Phoenix display 17765 during Dive. Spirit of the Phoenix uses
existing creature template 21362, not a display ID as a template. All selected display/model chains
resolve in installed DBCs. Their rendering, size and animation require later gameplay acceptance.
No DBC or client archive is changed by this source package.

Summons retain the exact owner GUID, faction and level. Their local health is half their owner's
maximum health and their armor follows the owner at creation. A new Pyre/Phoenix replaces only
the old owned summon after successful creation. They despawn when their owner is unavailable,
dead, in another phase or over one hundred yards away. Phoenix heals using the native radius;
Kael's Command uses its native ten-target limit and dormant duration. Phoenix death alone triggers
Offering, healing nearby allies for its maximum health; replacement/despawn is not death.

Commands are checked before spending resources: the owned living Phoenix must be in phase and
within sixty yards; Dive also requires a living friendly destination within sixty yards of the
Phoenix and line of sight. Dive shields up to the native ten allies along traversed segments once
per ally. The local path width is three yards, speed twenty-five yards/second and observation
window four seconds. Stationary waiting does not keep shielding newly arriving units.

Firestorm checks entry/re-entry every 200 ms and applies one single-target damage/knockback event
per entrant, avoiding a second area selection for every victim. Flame Step uses the held movement
direction, collision-limited movement and once-per-enemy segment damage. Where the native movement
distance is absent, the local fallback is fifteen yards, speed thirty-five, a two-second observation
window and two-yard damage width. Teleport-sized jumps are excluded from path damage.

Recovered untyped spell-power coefficients use Fire spell power; healing-specific formulas use
bonus healing. The source table contains 152 exact spell/effect coefficient slots and SQL suppresses
duplicate native coefficients. Exact active rank base values and valid native stat modifiers remain.
The legacy missing Overheat ID 802565 is not invented: its obsolete removal link is disabled.
Cataclysm's private effect 178 now applies owned Dazed 1604 for its authored six seconds.
Existing shared raid critical/haste exclusion groups remain unchanged.

## Delivery boundary

SQL11 is new and unapplied. All preceding migrations remain byte-identical. The six guarded
creature/template-model inserts preserve existing rows; installation must reject conflicting
definitions instead of silently keeping an incompatible template. Source and SQL must be installed
together after a separate build request. Source fixtures, native proc/cost tests and real-source
MSVC syntax checks do not replace a linked build, startup registration or in-game acceptance.
