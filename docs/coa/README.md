# CoA server component

CoA is the compatibility layer between AzerothCore and the Ascension 3.3.5a client:
protocol adapters, account-wide collections, character advancement, custom classes
and resources, and class corrections. It is a required server component of this
AzerothCore fork, built by `src/server/coa/CMakeLists.txt` independently of optional
modules and registered by `AddCoAScripts()` during worldserver script initialization.
Class scripts continue to use the normal script APIs.

Sources live in `src/server/coa/`, focused regressions in `apps/coa-tests/`, and
configuration templates in `src/server/coa/conf/`. They install to
`etc/modules/coa.conf` and `etc/modules/coa_bugreport.conf`; runtime configuration is
supplied there, not by committing live local credentials. CoA logs under `coa`,
`coa.gameplay_test` and `coa.highrisk`.

This fork, CoA included, is licensed under the root `LICENSE` (GNU GPL v2), like
AzerothCore. Most CoA source files still carry the short "GNU AGPL v3" notice from
AzerothCore's module template; changing those notices needs the agreement of the
code's contributors. The component's history before the move is reachable with
`git log --follow`; keep its license notices and upstream attribution.

Historical SQL lives in `modules/mod-ascension/data/sql/` (formerly
`modules/mod-ascension-compat/`). The database updater tracks applied migrations
by file name and hash, and both are unchanged. That directory is not a buildable
module. The appearance-template provenance table those migrations create is renamed
to `item_template_coa` by a later pending migration. New migrations belong in
`data/sql/updates/pending_db_*/`.

This is an independent reconstruction; source presence does not establish
complete official gameplay parity. The canceled Retail/native-class experiment
is absent.

Canonical client files, generated candidates, runtime databases and deployment
evidence are kept outside this repository. Preserve applied SQL hashes.
Do not run historical installers or clear client caches to compensate for a
protocol, data or process problem.

## Upgrading a server configured before the move

- Move the settings of `etc/modules/mod_ascension_compat.conf` into `coa.conf`,
  renaming its `AscensionCompat.*` keys to `CoA.*` (for example `CoA.QuestLevelScaling`),
  then delete `mod_ascension_compat.conf`. Installing the server removes the old
  `mod_ascension_compat.conf.dist`; delete it by hand if you install another way, or
  `acore.sh` copies it back to `mod_ascension_compat.conf`.
- Rename environment overrides the same way: `AC_ASCENSION_COMPAT_<KEY>` becomes
  `AC_CO_A_<KEY>` (for example `AC_CO_A_QUEST_LEVEL_SCALING`).
- Add `Logger.coa=4,Console Server` to `worldserver.conf`, and rename any
  `Logger.module.ascension_compat`, `Logger.module.gameplay_test` or
  `Logger.module.highrisk` line to `Logger.coa`, `Logger.coa.gameplay_test` or
  `Logger.coa.highrisk`. Without `Logger.coa`, CoA logs only errors.
- The worldserver logs an error at startup for each of these steps it finds undone,
  and when the old `item_template_ascension_compat` world table is still present.

## Client DBCs

The CoA client's DBC files belong in `env/dist/data/dbc`. The worldserver reads them
from `<DataDir>/dbc`: the Docker setup already uses `env/dist/data`, and for a local
`acore.sh` install set `DataDir` in `worldserver.conf` to that directory (its default
`"."` is the directory the worldserver runs from). Building the server does not need
them; running it and the CoA tests in `apps/coa-tests/` that read client data do. Set
`COA_DBC_DIR` when the tests should read another directory.
[`apps/coa-dbc`](../../apps/coa-dbc/README.md) extracts and checks them.

The models of the Venomancer Beetle, Venomwing and Weaver Forms (CreatureModelData 20612
`custom_nerubianbeetle`, 22063 `custom_flyingnerubian2` and 23813
`maldraxxusmutant_noarmor`) have hand attachment points but lack the `0x10` flag that
native animal forms such as Cat, Bear and Ghost Wolf carry, so the client hangs a drawn
weapon on them in combat (#5128). The Spider and Sea Serpent Form models have no hand
attachments. The weapon's visibility is decided by the client alone. When preparing a
requested client update, run `apps/coa-spells/venomancer_form_weapons.py --input
<CreatureModelData.dbc> --output <candidate-CreatureModelData.dbc>`; it sets the flag on
those three rows in a separate output and never packages or installs a client archive.

## World database installation

Import the [world database package](../../apps/coa-world/README.md) into an empty
world schema before the first worldserver startup. The same guide covers auditing
an existing database and updating the package.

## Equipped gear drops

Rewarded enemy kills can drop one existing wearable item with the same display as the enemy's armor,
weapon or shield. Armor comes from the active `creature_display_preset` or the current model's
`CreatureDisplayInfoExtra` outfit. Weapon entries supply their display and weapon type. Preset slots contain
display IDs, not loot item IDs. Matching also preserves the equipment slot, including robe/chest variants.
Mage-class creatures prefer Intellect gear; shield bearers prefer defenses and Stamina; other creatures
prefer Strength, Agility or attack power. Equal matches prefer the closest eligible level, then quality,
with a stable item-ID tie break. Unknown outfits and appearances without a wearable match produce no drop.

`CoA.EquippedGearLoot` enables the feature; `CoA.EquippedGearLootChance` is a reloadable per-kill percentage,
defaulting to 5. Only unbound or BoE gear through uncommon quality is eligible. Required level must not
exceed the creature's level; items without one use item level minus five, floored at zero. NPC placeholders,
deprecated, conjured, quest, random-affix and requirement-gated items are excluded, as are pets, summons, controlled
creatures, dungeon bosses and disabled loot rewards. Drops are generated once with corpse loot, including
creatures without an ordinary loot table, before native group permissions and quality thresholds. Existing
loot remains, exact item duplicates are skipped, and the loot-window capacity is respected. Native item
scaling can lift the chosen reward while preserving its appearance. Obtaining the
item uses the existing appearance collection path when `CoA.AutoCollectAppearances` is enabled.
Scaled items without a direct wardrobe mapping use their base item's mapping, while collection persistence
retains the obtained item as its source.
Items missing a direct `ItemAppearances` row inherit an existing equipment appearance only when display,
slot, class and subclass match that appearance's captured source item. Direct mappings remain authoritative;
robe/chest and weapon-hand variants share a slot. An item mapping whose source appearance has a different
display cannot supply an alias. Looks absent from the captured wardrobe catalog remain uncollectible.
No appearance record or client DBC row is invented.

The [archived public changelog](https://github.com/hertigservices/ascension-data/blob/main/datasets/research-jeff-fro-coa-changelog-public-73833f29a4c2999b26184e55affe3c769682ccdb4431b2b6e9a4ebb4bbfaf72f.json)
describes immersive gear in entries 62796/62797 (2025-07-28), caster additions in 63297/63298 (2025-08-09),
and increased rogue drop chances in 64953 (2025-10-20). It supplies neither item pools nor exact probabilities.
The rate, quality cap and selection policy here are reconstruction choices. Generic loot rates are unchanged;
the archived generic-loot reductions cannot be reproduced exactly from those notes. The extensions
[appearance API](https://github.com/firstoni-dev/ascension-extensions-reconstruction/blob/main/src/Ascension/AscAppearance.cpp)
maps items to collected appearances; its `GetCreatureDisplayItems` function concerns incarnation appearances,
and supplies no enemy loot table. This feature needs no new client packet or invented item template.

`python -B tools/verify_all.py --stages harness --harness equipped_gear_loot` exercises the production selector,
configuration callbacks and native `Loot::AddItem`/`FillLoot` with bounded APIs. Setting
`COA_EQUIPPED_LOOT_BEFORE=1` selects the `origin/main` loot integration as a failing control;
`COA_EQUIPPED_LOOT_BASE` can pin another pre-feature Git revision. The harness
covers roles, appearance slots, model alternatives, presets, weapons, exclusions, capacity, duplicates,
empty loot tables and group rights. It does not verify client rendering or a player collecting the appearance.
The `equipped-gear-loot` gameplay scenario checks the installed caster/shield equipment and generated item
templates through native loot processing, with ordinary creature fixtures and the default 5% configuration.

## Automatic specialization talents

The talent catalog is read at startup from the client's `CharacterAdvancement.dbc`
with its class type, tab type, `ChrClasses` and `ChrSpecs` tables
(`src/server/coa/AscensionCoATalentData.cpp`). Automatic spec progression requires its level and
spec-tree prerequisites, but does not require purchasing a talent in the shared class
tree, so the loader drops those paid cross-tree requirements. Specialization identity
passives named by `ChrSpecs` are level 10 grants. Paid talents and Barbarian's selectable
free choices remain explicit. The client addon's `CoATalentNodeData.lua` must describe the
same nodes.

Run `python -B apps/coa-tests/test_automatic_talent_dependencies.py --dbc-dir <server-data/dbc>`
with a C++20 compiler available for the server data regressions. Add `--client-addon-dir <Ascension_Collections>`
with `lupa` installed to also exercise the client Lua 5.1 rank calculation and
check that its dependencies match the server. These checks do not build or launch
the server or game client.

The same generator supplies client tab aliases. Primalist's native `MountainKing`
tab must resolve to the builder's `Mountain King` tab for both tree lookup and
automatic passive recognition. The client regressions above cover its 40 nodes,
level gates, and specialization switching. This correction requires the generated
client Lua to be packaged; the server talent catalog already uses spec ID 60.

## Abilities taught by talents

`AscensionTaughtAbilityData.h` lists reviewed teaching promises. The class service
grants these abilities temporarily while the parent, level and confirmed
specialization qualify, preserving independent permanent ownership. This includes
Air Elemental, Eternal Curse, Aeon of Resilience, Herald of the Depths, Dreadnought,
Mixologist's Fish Oil and Ancestor's Call, alongside the existing Tinker and
Primalist grants. Class-specific acquisition scripts remain responsible for their
existing grants. Eternal Curse also grants native Dual Wield temporarily; losing
the talent restores the native ownership check and off-hand equipment rules.

`AscensionTalentReplacementData.h` supplies twelve reviewed transformations for
Stormbringer, Bloodmage, Chronomancer and Reaper. These require both the original
ability and its talent, select the replacement rank by the captured trainer level,
and use native spell replacement packets and cast routing. Refunds and spec changes
restore the original button and remove temporary children. Original ranks share the
highest eligible replacement; this does not implement downranked replacements.

Tooltip links also describe triggered combat effects; they are not a general
spellbook grant list. These acquisition changes do not complete all class mechanics
listed in issue #88 or the older class audits.

Primal Weapons follows this fork's selected reconstruction of the captured level-20
talent. Its existing spell ID 537218 becomes the active selector, casting only the
bonus appropriate to an equipped, unbroken main-hand weapon. The cost is 15% base
mana, matching both captured imbues. Bestial Might grants the player and active pet
their authored Talonfury buffs on physical critical damage (including absorption);
each lasts for at most two successful melee auto-attacks or its native duration.
Primal Might retains native attack power/rage and activates the native Wildclaw
damage modifier. The obsolete helper's Bear's Maw cooldown behavior is not added.
Bonuses are exclusive and are removed on talent/spec loss; a saved eligible imbue
waits for CAD confirmation on login. This is a local restoration, not a claim that
the retired selector exists on the current official realm.

The selector requires the matching client spell data. When preparing a requested
client update, run `apps/coa-spells/primal_weapons.py --input <Spell.dbc> --output
<candidate-Spell.dbc>` against the selected CoA data. It edits one row in a separate
output and never packages or installs a client archive.

The Primalist #88 follow-up also connects Primal Guardian to removal of its three
visible defenses, Earthmother's Blessing to lethal damage after mitigation,
Therazane's Might to Terrasurge against the caster's own Seismic Tremor, and Throat
Clamp to the living owned pet's native dash/interrupt spell. Earthmother's native
cooldown lasts two minutes and is retained on ordinary logout. Primal Guardian
ignores death and the separately removed hidden defense helpers. The crit hook
retains the engine's subsequent target critical modifiers. Throat Clamp checks
pet control, range, phase and line of sight before committing the owner cast.

Run `python -B apps/coa-tests/taught_abilities/run.py` with a
C++20 compiler to check the real service, callbacks and native spell ownership/save
transitions. Add `--spell-dbc <Spell.dbc>` and `--trainer-policy
<LiveClassTrainerPolicy.json>` to verify teaching clauses and replacement ranks.
Run `python -B apps/coa-tests/primal_weapons/run.py` with the same
optional `--spell-dbc` to check the selector, aura callbacks, native charge transitions,
SQL idempotency and matching client edit in memory. These bounded source tests do
not establish full server or in-game combat acceptance.
`apps/coa-tests/primalist_talents/run.py` checks the four additional callbacks, including
lethal boundaries, cooldown expiry, defense removal reasons, owned DoTs and pet
command failures. It accepts the same optional `--spell-dbc` argument.

Runemaster's Primordialism now activates its native critical-chance buff when the
owned Runeshroud ends, excluding death. Stone Petroglyph follows the talent and
all six Earth Tattoo ranks: its existing helper heals 3% maximum health every four
seconds and supplies knockback immunity. The helper also covers destination-based
knockbacks; removing either prerequisite clears it. Reapplying an eligible tattoo
preserves the existing helper's timer. `apps/coa-tests/runemaster_passives/run.py` covers
these transitions and accepts `--spell-dbc` for the native helper contracts.

Manuscription grants Transcribing on a completed cast. The next Thaumaturgy or
Glyphic Ruin consumes it and selects the existing Chapter for the active tattoo
school (Fire; Frost/Water; Nature for Earth/Air; Arcane). If several conflicting
schools are active, Transcribing remains available rather than choosing one.
Chapters retain their native duration, chaining and 20% multiplicative falloff;
their ten saved charges are spent once per completed direct damage cast, including
misses. Triggered children, pure DoTs and channels do not spend extra charges.
The selected helper survives the final charge for delayed hits. The DoT retains
its native chain and gains its described 38% spell-power coefficient per tick.
`apps/coa-tests/manuscription/run.py` covers this lifecycle and the native chain metadata.

Ranger's Light Arrows applies its bonus to the complete Precision Shot damage at
40 yards or farther, measured center to center when the cast launches. Knockout
applies its native incapacitate after the bleed/poison cleanser, with damage break
and the native diminishing-return category. Stonemason's Secret extends owned
Dirty Blades by six seconds when a successful Assault or Skullpiercer uses five
Advantage stacks, including casts whose stacks are preserved by Elven Tactics.
`apps/coa-tests/ranger_passives/run.py` checks these callbacks and the actual spender path;
`--source-ref` accepts an older spender as a negative control, and `--spell-dbc`
verifies the native helpers and all seven Precision Shot ranks.
Snatch retains its native self-disarm cleanser and enemy disarm; its helper now
uses the active button's four-second duration instead of the helper's stale three.

Chronomancer's Shimmering Shard grants the native Shimmer stack for each completed
Aeon activation. Both damage and healing use the displayed 4% per stack, retaining
the three-stack cap and twenty-second duration. Dimensional Divergence swaps live
player positions within one map and phase; transport, vehicle, flight and pending
teleport states are rejected. Friendly swaps grant no speed effect, and an immune
enemy grants no stolen speed. The installed slow/speed helpers specify 80% for
three seconds, matching the active spell's references; the older audit's 20% is
not used. Displacement already contains its native pull and root/snare dispels.
`apps/coa-tests/chronomancer_passives/run.py` checks the actual cast and swap callbacks,
metadata and binding SQL, with optional `--spell-dbc` for these native contracts.

Vampiric Pools emits its native area leech when the owned Liquify ends, excluding
death and removal outside the world. Its damage retains the native level-scaled
base and gains the talent's 100% spell-power coefficient. The current talent only
promises leech; the helper's obsolete fear text has no duration or fear effect.
`apps/coa-tests/bloodmage_passives/run.py` checks the exit callback and scoped coefficient SQL.

Reaper's Harvester uses native damage proc events to heal 15% of the damage event's
amount, including periodic and triggered damage. Its native heal helper preserves
healing-taken adjustments and cannot critically hit. From the Shadows grants the
native crit buff when the owned visible Underwalk ends, excluding death and its
hidden helpers. Soul Splinters follows successful increases in Reaped Souls through
the shared resource service; capped awards, losses and restoration do not trigger
it. A multi-soul award emits the DoT once. Its native tick gains 3.5% Stamina and
5% attack power, retaining duration and refresh behavior. `apps/coa-tests/reaper_passives/run.py`
checks the actual proc, exit callback and resource dispatcher. `--source-ref` runs
an older dispatcher as a negative control; `--spell-dbc` checks the native helpers.

Echo Rune creates an owned stationary marker for the native twenty seconds and
temporarily replaces its button with the existing Echo heal/return spell. Early
reactivation and natural expiry consume the marker, teleport once and heal with
the native level-scaled base plus 150% AP. Cancellation, death, map/phase changes,
logout and ability removal clean up without a return heal. The obsolete automatic
Warpdagger cooldown reset is disabled; Zenith's separate charge system is unchanged.

Warpdagger creates its captured moving marker and temporarily exposes Warp. The
local travel policy uses native run speed with the captured +200% movement aura,
travels up to the described thirty yards along a collision-checked straight line,
and waits at the endpoint for the remainder of the native twenty-second window.
Reactivation uses the marker's current position, with line of sight required, and
deals the native area damage plus 44% SP and 20% AP at that destination. Targeting
uses explicit arrival coordinates while the player awaits teleport acknowledgement.
The passive markers use local neutral template defaults; official NPC durability
and travel timing are unavailable. A destroyed marker cancels the return option.

`apps/coa-tests/runemaster_travel/run.py` executes the actual callbacks and native temporary
button functions with bounded map/movement APIs. It checks cleanup, ownership,
failed summons, spell records and idempotent SQL. It does not test live geometry,
client acknowledgements, rendered models or combat. `apps/coa-spells/runemaster_travel.py`
prepares the two captured display/model pairs and Echo's return-button description
in separate copied DBC files when delivery is requested. Tests transform these bytes
only in memory. The matching client assets and DBCs must be verified during future
packaging; no client or repack patch is produced by this source change.

Cloudburst now triggers its existing knockback helper after the completed player
cast. That helper supplies the captured ten-yard radius and knockback force through
the native effect; the parent's zero-radius dummy never did. Its visual and cooldown
remain native. `apps/coa-tests/stormbringer_passives/run.py` checks the actual callback and
helper data, including class/family guards and preventing triggered recursion.

Wind Gate creates its captured stationary marker for the native one-minute duration.
Learning the parent temporarily teaches Evacuate, whose native two-charge pool
recharges sequentially every sixty seconds and survives ordinary saves. The button
remains learned when a gate expires; using it requires a living owned gate and an
eligible party/raid ally in the same map and phase, within the helper's hundred-yard
range of the gate and its line of sight. Transport, vehicle, flight and pending
teleport targets are rejected. The gate casts the native pull so its destination
is the gate rather than the player. Parent removal clears temporary ownership;
logout, map changes and owner death remove the gate. A failed replacement preserves
the previous gate. `apps/coa-tests/wind_gate/run.py` exercises these callbacks, native charge
state, SQL and in-memory model preparation. `apps/coa-spells/wind_gate.py` supplies
the captured display/model pair for later delivery; marker durability is a local
default. Live movement and rendered appearance remain untested.

Raging Zephyr now creates independent stationary tornados for each charge, with
the captured model and native ten-yard pull every four seconds. Its periodic aura
lasts for the active summon's twelve seconds (including duration modifiers), with
the captured root and school immunity. The stale helper self-kill is disabled.
Native enemy selection and movement remain in use; a scoped guard rejects invalid
owners and targets in transport, vehicles, flight or pending teleports. Parent loss,
owner death, logout and map/phase changes stop pulls and remove the summon.
`apps/coa-tests/raging_zephyr/run.py` checks actual callbacks, independent lifetimes, guards,
SQL and in-memory captured model preparation; live movement/rendering remains
untested. `apps/coa-spells/raging_zephyr.py` prepares copied model tables for later
delivery. The existing native three-charge, thirty-five-second recharge is unchanged.

Air Elemental's missing template now uses its existing white elemental display,
with Windpelt, Breath of Air and Blessing of Air learned through the native pet
spell list. Pet commands and autocast choices remain native. An exact class/entry
hook selects summoned-pet stats; the uncaptured family/stat template uses local
native defaults rather than an unrelated Freepick family. After asynchronous pet
loading, the captured owner-to-pet passive supplies its healing/speed effects and
Invigoration proc. Damage dealt by the active owned elemental triggers the existing
helper chain, including killing blows but excluding misses and fully absorbed
hits. Additional Invigoration stacks preserve the original expiry, including at
the ten-stack cap. Losing the summon ability dismisses the pet. The focused
`apps/coa-tests/air_elemental/run.py` checks actual callbacks, native stacking, SQL and
installed data. Windpelt's wider scaling, other pet talents and in-game behavior
remain separate class-parity work.

Green Dream Flowers now use stationary timed summons and the captured pickup aura:
every 300 ms its native two-yard selector chooses one eligible nearby party/raid
ally, who receives the native 5% maximum-health heal and movement speed buff before
the flower consumes itself. The existing display and pickup visual are retained.
Dream Flowers' damaging-critical proc has a native one-second cooldown; Forest
Herald uses the captured 20% chance on Toxic Dart/Advantage-consumer casts in combat.
Successful green summons grant Highlander stacks only with the talent; three stacks
activate its native free-Falconstrike cost modifier. The next completed Falconstrike
consumes that modifier, retaining a cast-local snapshot for a delayed hit's 40%
healing reduction. The old four-stack debuff cap is reduced to one to match the
active promise. Talent loss clears orphaned stack/ready auras. The focused
`apps/coa-tests/ranger_flowers/run.py` checks actual callbacks, ownership, pickup selection,
failed summons, proc/cast gates, delayed impact and SQL/helper contracts. Flowers
are excluded from pickups so owned flowers cannot consume one another. These
checks do not claim native world movement, healing execution or rendered appearance.

Petalkeeper now spawns independent thirty-second red flowers on Woodland Arrow
casts. Damaging critical hits add Petals to the caster's own living flowers in the
same map/phase; a horn consumes each fully charged flower once, granting the native
twenty-yard Red Dream buff for eight seconds. Its direct-damage healing uses the
active Petals description's `521451s1` reference (currently 10%); the spawner's fixed
20% text is stale. The native 100% movement-speed floor and heal modifiers are
preserved. The short buff can outlive its flower, while invalid owners stop new
petals and bursts. `apps/coa-tests/ranger_petalkeeper/run.py` checks the actual callbacks,
ownership, burst consumption, direct-damage copying, SQL and in-memory model
preparation. `apps/coa-spells/ranger_red_flower.py` supplies captured display/model
records for later delivery. Appearance and full combat execution remain untested.

Falconstrike's talent now prepares the fifth shot after four completed Quick Shots
within the native fifteen-second counter window. Horns prepare it immediately for
the copied ready aura's sixty seconds. The current level selects the temporary
Falconstrike rank and the native replacement packet updates learned Quick Shot
buttons. A completed Falconstrike, expiry, death or talent loss restores Quick Shot;
direct casts require the ready window. Permanent spell ownership and pending
deletions are preserved. The captured higher ranks grant one Advantage, while the
first rank retains its explicit two. `apps/coa-tests/ranger_falconstrike/run.py` exercises
the actual callbacks, native replacement methods and shared resource matcher.
The War Falcon summon and broader Ranger damage parity remain separate audit work.

Pooled Vitality now records actual native health-cost payments and grants one stack
per completed paid cast. At ten owned stacks in Mortal Form, the eight captured
Rage abilities snapshot empowerment before cost and cast-time calculation; cancelled
or invalidated casts keep their stacks. Native spell modifiers implement the free
costs, instant Mend, Crimson Tide radius, Animated Blood count/duration and Transfusion
cooldown. Heartbreak's existing power helpers run only for empowerment, Fleshcraft
adds caster maximum health, and Bloodbolt doubles only its initial target. Mend's
self-heal copies half the effective healing. A completed spend with Vitality For
Later triggers its native capped ally heal, retaining its rank amount and adding
0.5 Spirit before the native 0.25 spell-power coefficient. The focused regression
executes the actual payment and spell-modifier functions plus the CoA callbacks.
This resource work does not establish the wider Bloodmage summon or ability parity.

The remaining tooltip-link audit also connects Spiritual Reflexes, Call of the
Mountain, End of Time and Eternity Warper. Reflexes evaluates the captured 25%
dodge bonus below 35% health at the native dodge roll and releases Soul Harvest
only on an actual dodge. Primal Rush/Quake damage supplies Earth's Rage; crossing
five owned stacks with the talent grants Mountain, replacing the old unconditional
first-stack trigger. Loading or refreshing capped stacks does not award it again.
Clasp's natural expiry releases End of Time only for its talented caster, including
each affected enemy; dispels and cancellations do not release it.

Ripple selects its active Aeon's existing pulse, shield or area-protection helper.
Helpers follow the channel duration and stop protecting when the channel ends.
Renewal/Oblivion retain native half-second pulses, and Protection adds 0.75 healing
power. Resilience defers 30% of direct Physical damage after native absorb bypass;
its remaining debt and tick count live in normal saved aura fields. New debt is
spread across five upcoming one-second ticks without resetting the next tick;
channel cancellation does not erase debt or apply mitigation to it a second time.
The focused fixtures cover these lifecycle and accounting rules, not live combat.

The issue's claimed 69-entry roster is not reproducible from the captured data:
its class counts total 79. Applying its literal dummy-only plus tooltip-link filter
to unique canonical talent spells produces 47 candidates across all classes, 33 in
the classes it names. Those 33 have reviewed acquisition, replacement or combat
handlers; other named examples require combat triggers despite not matching that
filter. Tooltip links remain documentation, not unconditional spellbook grants.
This closes the reviewed acquisition/trigger gaps, not every outstanding mechanic
in the broader class-completion audits.

Templar Scarlet Training turns the next Argent Blade into Scarlet Hammer through the
Scarlet Crusader aura (301172), which the client also uses for the button glow. The
server lends Scarlet Hammer, and Vindication's Divine Fury, only while the swap is
active. The client row still describes the retired Chastise version; when preparing a
requested client update, run `apps/coa-spells/scarlet_crusader_tooltip.py --input
<Spell.dbc> --output <candidate-Spell.dbc>`. It rewrites that row's English texts in a
separate output and never packages or installs a client archive.

## Keeper's Scrolls

A Keeper's Scroll blesses the zone it is used in, not the player: everyone in the
zone gets its buff, players entering later get it for the time left, and a second
scroll of the same kind is refused while one is active. The registry lives in
memory, so a restart clears active blessings.

Keeper's Scroll: Steadfast (91770) ships as an empty dummy; the server rewrites it
into +25% mounted speed with the stacking mount speed aura Crusader Aura uses. Its
client row has no tooltip either. When preparing a requested client update, run
`apps/coa-spells/keepers_scroll_steadfast.py --input <Spell.dbc> --output
<candidate-Spell.dbc>`; it edits one row in a separate output and never packages or
installs a client archive.

## Login and natural regeneration

`Extensions.dll` patches the ping timer at executable address `0x632DE5` from -30000 to
-5000 milliseconds (DLL write at `0x10A689AC`); the reconstructed DLL
(`firstoni-dev/ascension-extensions-reconstruction`) makes the same write.
Stock AzerothCore counts pings less than 27 seconds apart as overspeed; ordinary
accounts are disconnected after exceeding `MaxOverspeedPings`, while GM permission
23 bypasses that check. Local connections with `CoA.Enable = 1` accept
the five-second cadence with a one-second jitter margin. Faster sustained flooding
still reaches the strike limit. Other connections retain the stock limit.

For a realm dedicated to this client, set `CoA.AllowRemoteClients = 1`
and restart worldserver. This also applies the extension opcode range, ping interval,
Ascension spell-modifier packet layout and class-10 character creation mapping to remote
connections. The default is `0`; password proofs, IP bans and packet size validation
remain required.

The server talks to the client interface only through the DLL's native packets; it has
no addon-message or chat-command channel. The reconstructed DLL authenticates with stock
SRP6 and keeps the stock world-header cipher, which is the only header mode the server
supports. Client binaries are maintained outside this repository.

- `SMSG_REALM_INFO` (0x09BC) is sent at `CMSG_CHAR_ENUM`: realm id, ruleset, rates, eight
  realm-kind gates, then the realm data path and the realm name as C strings, then the
  add-ons flag. The data path stays empty: a non-empty one makes the DLL hot-swap client
  data from `Data\<path>\`. The name is the authserver's `realmlist` name.
- The Ascension realm list builds its cards from extra realm-list entries named
  `realm!expansion!gamemode!image!unlocked!page!index!spell` in the last realm category,
  and hides a realm without one. The authserver adds one offline entry per realm; see
  `RealmCards.*` in `authserver.conf.dist`. `RealmCards.Category` must sort after every
  realm's own category.
- Wardrobe outfits: `CMSG_SAVE_APPEARANCE_OUTFIT` (0x069E, name and the category-indexed
  appearance list) and `CMSG_DELETE_APPEARANCE_OUTFIT` (0x06A0) are answered with
  `SAVE_/DELETE_APPEARANCE_OUTFIT_OK` or `_UNKNOWN` (0x069F / 0x06A1) and stored in
  `character_appearance_outfit`; `SMSG_APPEARANCE_OUTFIT_INFO` (0x069D) lists them at login.
  A saved outfit may name only collected appearances; names are 1-64 bytes, 100 per character.
- `SMSG_UPDATE_CONFIGS` (0x058D) is sent once per login with every client setting; see
  [client configuration](client-xp-config.md).
- `SMSG_ACCOUNT_INFO` (0x09BB) is sent at login with the account's GM level and characters.
- Help menu tickets use the ticket packets 0x0701-0x071E and the `.support` GM commands; see
  [player tickets](player-tickets.md).
- Requests the core session handles like stock ones, registered in its opcode table and let
  through the CoA packet filter: the portrait menu's reset all dungeons (`CMSG_RESET_DUNGEONS`,
  0x061F); the ghost frame's return to graveyard (`CMSG_PORT_GRAVEYARD`, 0x0544), which
  moves a released ghost to its closest graveyard; and the flight's early landing request
  (`CMSG_TAXI_REQUEST_EARLY_LANDING`, 0x05F2), which ends the flight at the next discovered
  flight point on its route, so the later legs are neither flown nor paid; and the stable
  window's delete button (`CMSG_STABLE_DELETE_PET`, 0x067C), which deletes a stabled pet and
  answers `SMSG_STABLE_RESULT` 8, after which the client lists the stable again.
- `CMSG_QUERY_INSTANCE_BINDS` (0x06FD), sent at every world entry, is answered with
  `SMSG_QUERY_INSTANCE_BINDS_RESULT` (0x06FE): `QUERY_INSTANCE_BINDS_OK`, then the player's binds
  that can still be reset as instance id, map and difficulty. The portrait menu's Reset Instances
  list shows them, and `CMSG_RESET_INSTANCE` (0x058C: u32 map, u8 difficulty) resets one of them
  like the stock reset: only outside a group or by its leader, and not while players are inside.

The `gtOCTRegenHP`, `gtRegenHPPerSpt` and `gtRegenMPPerSpt` client files each contain
3,200 single-float rows indexed by class and level. Their SQL overlay tables are empty,
so every class reads the client's rows. The DBC loader accepts implicit row IDs for these
game tables while preserving explicit-ID files and SQL overlays.
This lets the existing regeneration formulas reach the supplied custom-class rows;
focus and energy use separate formulas.

Run `python -B apps/coa-tests/client_compat/run.py` with a C++20
compiler available. `--dbc-dir <server-data/dbc>` also compares every installed
regeneration coefficient with the native loader's result. The tests compile the
actual storage/loader and ping/regeneration methods, using isolated session, clock
and database boundaries. They do not launch the server or client. Rebuilding and
deploying the corrected server is required before checking real logins and gameplay.
