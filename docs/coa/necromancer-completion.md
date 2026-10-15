# Necromancer reconstruction — 2026-09-09

This source reconstruction addresses the 140 Necromancer audit findings. It is
not an official backend implementation or an in-game acceptance result.

Evidence includes 1,363 installed spell records, recovered client creature/model
records and the archived official changelog. Visible current parent descriptions
take precedence over stale hidden helper text. An absent tooltip-only legacy
spell is documented, rather than turned into an invented active ability.

## Army and resources

Life Force is occupancy of living, owned summons, reconstructed from GUIDs. Raising requires sufficient
free capacity; death, unsummon, logout, map/phase loss and the Grave Mages talent update occupancy.
Capacity retains the native cap modifiers on a base of two. Lowering capacity does not kill existing
minions; free capacity is clamped at zero until space becomes available. The visible aura displays free
Life Force, while a separate permanent owner aura dispatches events even when all capacity is occupied.

Combat summons use the existing non-pet Guardian summon properties, including the native controlled list
and owner-to-summon auras. Phylactery, ritual circles and tombstones remain stationary temporary creatures.
The candidate includes 33 creature/transform definitions and the corresponding additive model records.
No minion grants experience, and an owned corpse cannot grant Frozen Bodies to its creator.

Necromancy's exact official stat formula was not recovered. The local policy uses weight
`max(1, Life Force cost)` for each creature, including a unit weight for temporary summons:

* Base Stamina: `(3 × owner level + 0.30 × owner Stamina) × weight`, with native Stamina modifiers.
* Health: `50 × owner level × weight + 10 × resulting Stamina`, then native health modifiers.
* Mana: `30 × owner level + 5 × owner Intellect × weight`, then native power modifiers.
* Attack Power: `0.40 × (owner Intellect + max(Frost SP, Shadow SP)) × weight`.
* Generic spell power: `0.20 × (owner Intellect + max(Frost SP, Shadow SP)) × weight`.
* Armor/resistances: 35%/40% of the owner values; native armor/resistance buffs remain active.
* Hit chance, spell/melee critical chance and cast speed inherit the owner's values. Hit also reduces
  dodge/parry chance for minion attacks. Native minion haste remains a separate multiplier.

Refreshes preserve health and mana fractions. Scoped native Guardian stat paths prevent its ordinary
Strength formula from replacing supplied AP or adding Stamina to health twice. Named command coefficients
are taken explicitly from owner stats, with their native bonus coefficients zeroed to prevent duplication.

Assault, Pacify and Protect are exclusive and control reaction state. Grave March can issue movement and
attack orders during another cast/channel. Individual commands select the appropriate minion roles;
the current general Command spells dispatch the army. Crypt Fiends use the recovered two-target Frost
barbs. Legacy Banshee commands distinguish mana destruction from damage equal to mana destroyed.
Rogue strikes occur after a leap; Colossus attacks wait three seconds and recheck control/Pacify.

The exact autonomous rotation was not recovered: special ranged attacks use a three-second cadence,
ordinary minions retain melee attacks, and idle Assault minions acquire nearby enemies. The local Banshee
basic ranged attack reuses Frost barbs; its mana command has its own bounded calculation. March of the Dead
creates six moving undead that explode on enemy contact. Graveyard tombstones cast their actual ground
damage/summon helper every three seconds; the raised body dies after 0.5 seconds and remains a consumable
corpse for its native temporary lifetime. These are local choices requiring combat/movement acceptance.

## Spells, diseases and procs

The explicit table covers 67 coefficient slots, including current Lichfrost, diseases, commands,
healing helpers, Soulfreeze, Death's Due and separately retained legacy Glacial Impact helpers.
The newer Glacial Impact keeps 1.405 Frost SP; the legacy helpers keep 0.75 Frost SP and 12% falloff
per subsequent target. The current Raise: Warrior parent controls its helper coefficient where the
older standalone command description disagrees. Native rank/base/level terms are preserved.

Crypt Plague stacks without resetting duration or its next tick. Foul Contagion extends only the
caster's Flesh to Worms across all ranks. Rotting Flesh requires its level 30 passive (574138), whose
flat duration modifier supplies the authored five-second refreshable duration; it grants its authored 2%
army damage stacks up to the native ten-stack cap.
Virulency refreshes and copies owned diseases, including amounts, stacks, duration, tick timers and
Permafrost state. Infest remains authorized for ten seconds even if the original enemy dies.
Corpse Explosion claims each eligible corpse before dealing damage, so another cast cannot reuse it.

Owner and minion events use actual damage, distinguish direct/periodic/critical/melee events, and
guard derived damage against recursion. Life Force weights Overwhelming Force chance, not repeated
blind resource refunds. Conditional crit/damage rules have explicit masks, ownership and health/school
predicates. Fetid Mark applies only to the caster's Skeletal Warriors. Putricide's Formula respects
its target cap. Fetid Ward splits its healing among the owner and surviving army.

Permafrost treats the next two ordinary casts as Frozen; generated helpers do not consume charges.
Cast and aura snapshots retain this state after the last charge disappears. Refreshing Chill, Bone King,
Deadly Bond and Ner'zhul's Blessing consume only eligible next casts, with generation checks preventing
a newly refreshed buff from being consumed by the triggering cast. Heartchill's slow/haste reduction
requires an actual successful interrupt by Heartchill itself.

Other local choices where exact behavior is absent:

* Harvest Plague increases linearly with missing target health, from 1× to 2×.
* Resilient Constitution uses 10% baseline PvP damage reduction plus its explicit 20% critical reduction.
  Existing native resilience then applies. Only the existing player-controlled damage path invokes it;
  ordinary NPC damage does not gain a new reduction.
* Life For Power converts 20% of healing remaining after earlier healing absorbs into a ten-second
  accumulating shield. It does not consume its passive as a finite twenty-point absorb.

Lich Form grants Undead creature type and the recovered immunity helper. Phylactery intercepts health
falling below 10%, creates a protected timed Shade, restores 40% health on reaching the owned phylactery,
and kills an unrecovered Shade when its duration ends. Bone Tithe uses actual health sacrificed.
Reliquaries restore 30% of missing health/mana and use the described one-minute item category cooldown.
Runic Harvest drains only living owned Raised minions in range and converts the amount actually drained.
Necromancer can receive mana from spells while retaining Runic Power as its active resource.

## Installation boundary

The [Necromancer migration](../../data/sql/updates/pending_db_world/rev_20260909_01_necromancer_completion.sql)
contains 168 exact bindings, two central proc rows, explicit zero bonus rows,
guarded creature/model definitions, three raid-group memberships and two item
cooldown corrections. Applied SQL and the preceding Witch Doctor migration are
unchanged.

The two server model DBC candidates are composed on the pending Witch Doctor candidates, preserving all
their rows and strings. Install that combined model set with the matching source and SQL. Before any future
installation, require every guarded definition to be absent or exactly match the candidate; never overwrite
a conflicting existing definition. Keep the Witch Doctor GameObject model candidate as a separate dependency.

Validation used actual-source tests and native syntax checks. A linked server
build and manual combat, UI, movement, pet-control and PvP acceptance are separate
checks; syntax checking does not establish those gameplay outcomes. See the
[release history](local-release-state.md) for later integration.
