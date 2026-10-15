# Witch Doctor reconstruction — 2026-09-09

This source reconstruction addresses the 119 Witch Doctor findings from the
2026-09-07 class audit. It builds on the Guardian, Barbarian and Witch Hunter
implementations, the [Ranger/Witch Hunter follow-up](witch-hunter-ranger-followup.md)
and [Manastorm solo-scaling/cache delivery](manastorm.md). See the
[release history](local-release-state.md) for later integration.

## Evidence and policy

The #88 follow-up connects Jungle Secrets to successful Loa's Brew healing. Each
living owned effigy selects one additional living party/raid ally in its native
heal radius and line of sight, prioritizing the lowest health percentage. The
original Brew recipient is excluded. The helper copies 35% of effective healing,
without another critical roll or healing bonus. `apps/coa-tests/witch_doctor_passives/run.py`
exercises the production hit callback, selection, ownership and helper metadata.

The installed copied-client Spell.dbc and its family-19 helper closure define ranks, masks, descriptions,
base values, durations, coefficients and targeting contracts. Raw client creature/model records supply
missing model rows. Archived official changelog records are supporting evidence, not a measured backend.
In particular, change 70810 keeps a Mojo Madness proc gained during a cast for the next cast;
68978 selects the cauldron model without collision; 69822 removes the old Jungle Thistle threat path
and increases its healing effect by ten percentage points. Current parent area protection is retained.

Where the recovered data has no complete executable rule, the implementation uses the following local
choices. These are explicit reconstruction decisions and require combat/balance acceptance after installation.

- Spirits cap at five. Successful Reclamation/Volley casts, eligible procs and Master of Puppets ticks
  generate the resource. Eclipse spends the captured amount and pulses every 250 ms once per Spirit;
  Frenzy lasts four seconds per Spirit and captures its initial strength before consumption.
- Mojo Beam ticks every 500 ms, grows one branch from each existing branch per pulse, and stops at eight
  distinct allies. Branches require a living, friendly raid member, range and line of sight. Mana cost
  uses the extracted per-second value, current branch count, and an additional 10% of base per elapsed
  pulse. Canceling the channel, losing the owner or insufficient mana stops it. Only Potion, Splash and
  Spirit in a Bottle may be cast instantly during this channel; other channels retain their normal rules.
- Glaive's incomplete Agility cast-time scaling uses `castTime / (1 + Agility / 1000)`.
  War Golem's absorb and health use eight times Intellect, with a 100-health floor for the summon.
  Ordinary stationary wards use at least five health, otherwise ten times owner level.
- Stationary ward fields refresh for 2.2 seconds. Ward, Idol and Effigy slots replace only the same
  owner's matching slot after successful creation. Mimic, War Golem, mass Serpents, Viper and cauldrons
  use separate slots. Serpents prefer the owner's selected hostile target, then an existing combat target.
  Spirit Link preserves the group's total integer health and never rounds a living participant to zero.
- Eclipse splashes hit at most five secondary enemies; Dark Effigy adds two targets. Voodoo Fire hits
  at most three. Unstable Concoction heals up to five allies and triggers on successful Brew/Bottle use,
  including overhealing. Bottle's damage and copied healing use actual effective healing.
- Marionette creates five owned copies, waits for its twenty-stack trigger, then transforms and explodes
  the copies. Fool's Play copies the target's appearance and weapon damage, attacks it, and mirrors native
  pure offensive damage spells. Mixed summon/teleport/utility effects and encounter-script spells are
  excluded; generic replication of arbitrary encounter scripts is not reconstructed.
- Master of Concoctions captures its caster and percentage at cast start. Its next three successful
  offensive casts retain leech for their direct hits and the lifetime of their applied damage aura.
  An unbuffed reapplication replaces that snapshot; misses do not alter an existing aura. Snapshot data
  belongs to the cast/aura instance and is not a permanent unit-wide entry or saved character field.
- Frog Bones Potion uses base + 0.35 Spirit + 0.8 healing power. Splash uses one quarter of its effect:
  0.0875 Spirit + 0.2 healing power. Ingredient/Mojo routing is captured per cast, so changing ingredients
  while a projectile travels cannot change its result. Mojo pairs persist until another ingredient choice.

## Implementation boundaries

Six new C++ units implement metadata/scaling, completed casts/hits, aura lifetimes, proc events, brewing,
and summon AI.
[AscensionWitchDoctorCoefficients.h](../../src/server/coa/AscensionWitchDoctorCoefficients.h)
contains 148 effect slots. Helpers which forward an
already computed damage/healing amount have no second automatic coefficient or critical multiplier.
Threads keep their original expiry while collecting damage; Other Side stacks also do not refresh it.
Beast's direct physical damage debt is paid over five pulses and flushed on removal without losing rounding.

The shared changes add per-cast and per-aura script snapshots, a narrowly scoped channel exception,
and an optional spell-magnet callback. Native magnet selection retains priority and validates the returned
unit's life, map, phase, attack eligibility and line of sight. Ordinary class resources, autoattacks,
channels, and all unrelated script callbacks keep their prior path.

Temporary replacements use the existing native player replacement mechanism. Malefic Arrow follows the
known Wrath rank through a new nine-row Arrow chain. Volley inherits Reclamation modifiers and Umbral
inherits Hex modifiers without becoming its own replacement or masquerading as the persistent Hex aura.
Both original and replacement cast requests are checked against current talent/aura state.

Conditional talents are implemented at their actual event or calculation: Spiritual Devotee on Spirit
gain; Voodoo Mind on Puppets duration/tick interval; Ritual Hexing against the owner's Hex; Soul Feeder
through per-Spirit state; Price of Power through Voice; Hunger in the stalking forms; Residual on natural
Avatar expiry; Vol'jin through active Avatar cooldown pulses; Dark Effigy through target count/damage;
Gift through a living Mimic and Spirit count; True Spirit and Juju Spirits through captured/current Spirits.
Juju's separate bonus against Hexed targets accepts a Hex from any Witch Doctor, as its description says.

Raid critical auras retain native same-type maximum aggregation. The shared damage-percent group gains
the correct first-rank representatives; it does not merge unrelated effects of multi-effect spells.

## Future installation

The [Witch Doctor migration](../../data/sql/updates/pending_db_world/rev_20260909_00_witch_doctor_completion.sql)
uses the normal updater. It contains 23 proc rows, 148 exact bindings,
154 coefficient-suppression rows, 27 missing creature templates and
model bindings, 13 missing model-info rows, two gameobjects, nine Arrow ranks and one ten-member damage
group. The 27 templates comprise 25 summons and two transform lookups. The eight existing model-info
rows are preserved, including the previously installed Witch Hunter model. Applied migrations 05–08
and all earlier SQL remain immutable.

The required external server data package adds rows to three DBCs:
CreatureDisplayInfo (13), CreatureModelData (12) and GameObjectDisplayInfo (1).
Every old row and string byte is preserved. Server Spell.dbc, client archives and
native executable files are unchanged. The selected no-collision cauldron model
comes from client data; rendered asset loading and collision behavior still need
runtime verification.

Before installation, compare every guarded creature/template binding, new model-info row, both
gameobjects, Arrow chain and group 2000184 against the recorded absent-or-exact candidate. A conflicting
live definition must not be overwritten. Verify the three server DBCs against the
baseline used to prepare their additions before installing the coherent set.
Preserve the independent Manastorm migration.

The 69 guarded INSERT statements intentionally do not DELETE missing templates/model rows/gameobjects.
That is the reviewed exception to the repository's mechanical INSERT/DELETE lint rule; it is verified
by scoped SQL composition, idempotence and conflict tests. It is not a clean global historical SQL lint.

There has been no CMake configuration, linked build, updater run, live DBC/client replacement or restart
for this package. The repository requires an explicit build request. Native syntax and isolated
functional tests do not establish in-game targeting, pet AI, group, channel UI or balance acceptance.
