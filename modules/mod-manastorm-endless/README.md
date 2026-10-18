# Manastorm upstream integration

This candidate preserves the SQL-driven shared backend and Mode 1. Mode 2 uses
native Ascension transport; donor gameplay is not registered.

Start with the [installation guide](docs/manual-sql-postinstall/INTEGRATION_INSTALL_REVIEW.md).
Use the [publication checklist](docs/PUBLICATION_CHECKLIST.md) before committing or publishing.
The original manual SQL exports are preserved; the updater applies their generated
non-destructive snapshot updates after the other module SQL. Do not import player history.
The supported world database name is `acore_world`.

The integration includes private restoration of 14 upstream-removed creature spawns,
Chaotic Link affix eligibility, the Ironaya activation correction, trusted native
Manastorm addon support, and all four corrected client files under `client/overlay/`.
See [client packaging instructions](client/Readme.txt). The old two-file MPQ is not
the complete updated package.

Without a client archive, the server can send the same four corrections as interface Lua at
login instead: set `Manastorm.ClientUIFixes` (bitmask, default 0) in
`manastorm-endless.conf`. 1 is the group finder keybind inside a run, 2 the reward divider
anchor, 4 the queue level guards and fallback reward border, 8 hiding an empty loadout flyout;
15 sends all four. It needs `Manastorm.ClientMode = 2`. Clients that already carry the
corrected files can leave it at 0. The sender is `src/server/coa/AscensionClientLua.cpp`; both
delivery routes are described in `docs/coa/client-hot-patch.md`.

## Realm configuration

For CoA: `CoA.ClassModel = "coa"`, `CoA.GameModeMask = 0`.
For Wildcard: `CoA.ClassModel = "hero"`, `CoA.MapClass10ToWarrior = 0`,
`CoA.GameModeMask = 64`, and `CoAChallenges.GameModes.Realm = WildCard`.
Use `Manastorm.Enable = 1` and `Manastorm.ClientMode = 2` for native UI.
The shared authserver supports `RealmCards.Realm.<realm ID>.GameMode` overrides:
CoA card mode is 11 and Wildcard card mode is 6. These are not realm IDs.
Local repack credentials, accounts, configs and databases are not part of source installation.

## Verification status

The integration compiled, both realms initialized the shared backend concurrently,
and focused checks passed. The owner reports successful in-game CoA/Wildcard testing.
This does not certify every encounter, Mode 1 regression, or a new zero-baseline install.
The initial integration source base was upstream `dbb02f53c699f87b12a8b465d9671654ef9ceef6`;
local test SQL was separately refreshed through `9dc61efcd2672c24b4f2a1caf600d4c7af8839e2`.
That DB-only refresh did not merge the nine newer source commits.

# Historical implementation notes

The material below describes earlier restoration stages. Statements about missing
rewards, vendored donor paths, old config transport and pending testing are historical,
not current deployment instructions. Use the installation guide above for deployment.

## Native behavior

- `0x651`, `0x665`, `0x689`: exact payload-size validation, logged-in world-thread
  dispatch, server-side admission and loadout validation.
- `0x660`: depth, SQL segment's native Manastorm ID, normal/endgame type, actual
  cache tuple, in the recovered order. Terminal state explicitly sends depth 0.
- `0x65F`: login snapshot; `0x65D`: GUID-keyed updates, including party members.
  The unchanged SQL backend stores four maxima, not historical lists or a
  normal/endgame split. Each known best is represented as a singleton depth
  list in both corresponding category views. Missing categories are empty.
  This preserves shared entitlement without inventing a history of lower clears.
- Completion commits the existing shared progression transaction for all
  members before `0x65E`; the original client resolves Messages DBC toasts.
- Four loadout slots use `0x688`, `0x689`, `0x68A`, `0x68B`; writes are acknowledged
  only after commit. Range, active run, spell, knowledge, rank and duplicates
  are validated. No unsupported clear-slot request is invented.
- The checked-out shared backend has no cache issuance implementation. Its
  authoritative count/chance/item are zero. No donor cache/pity policy was added.
  `0x6AD` clears the active reward-visibility context: there is no rate-limit policy.
- Login restores progression/loadout and a surviving owned private instance,
  active state and Chaotic Link. Expired instances terminate recovery cleanly.
  Expired empty instances also release run membership without requiring a relog.
  Private instance return positions survive character logout; runs themselves
  remain in memory, so a server restart returns characters outside the run.

## Narrow core/compatibility changes

The compatibility early hook passes shared Manastorm requests through; core
opcode entries admit them as logged-in, world-thread requests. The donor's
map/player/unit/spell/loot/guide/world hooks are not registered. Only its
DB-bound cache-opening item wrapper remains, for already-owned cache items.

Private-instance support has an opt-in database-spawn flag. Shared SQL stages
use ordinary authored creatures, game objects and spawn groups; the donor's
empty-scene default is unchanged. Private instances honor the selected instance
difficulty and can use authored dungeon/raid maps for a party of up to five.
Shared manager transport now supports party membership and reconnects without
ordinary dungeon binds. Old stage instances are released on transition/exit.

## Heart drops and custom effects

Ordinary registered stage creatures have one 75% heart roll per runtime creature,
independent of Chaotic Link membership. Crossing 10% health or a lethal hit can
consume that roll; healing and repeated crossings do not grant another roll.
A lethal hit directly executes the DBC impact summon (991509), avoiding a missile
being interrupted by caster death. Non-lethal hits retain projectile 991507.
Boss non-lethal thresholds at 90/80/.../10% are unchanged. Any living run member
in the same instance can collect a heart; pickup no longer requires the owner.

The deployed Spell.dbc chain was checked: 991507 uses effect 32, 991509 effect 28,
and 991510 effects 10/137. Those core handlers already exist; the module owns
pickup detection and the visual helper. No extra heart aura handler is required.

Compared against the local checkout of Duff-SPP/EunoiaCore-Underworld at
4e30325eb. Its commit named "SpellEffect 173 Fix" (816405a78) implements **174**;
this core already implements 173 (aura refresh). Ported the missing bounded
maximum-health damage handler 174, positive-Amplitude delayed trigger 193, and
negative aura-21 power drain for Mana Bomb spells 93489-93509. Unresolved modes
and zero-delay 193 remain inert, as in the donor. Deferred casts retain GUIDs,
not raw object pointers, and cancel on missing/changed-map casters or targets.
Mana Bomb draining works even at full mana; unrelated regeneration is preserved.

`tests/heart_effect_regressions.py` extracts production methods for compiled
checks of normal-trash lethal/non-lethal drops, once-only success/failure rolls,
boss thresholds, effect-174 mode/overflow handling, and Mana Bomb power drain,
immunity, clamping and normal regeneration. Focused source compilation checks
cover the custom effect/aura and module changes. In-game tests are still needed:
kill non-route trash with a single hit; test failed/repeated threshold rolls;
collect as a non-owner party member; exercise Lightning Rod, delayed affix
triggers and Mana Bomb at full/low mana. No DBC or SQL content was changed.

## Content and bounded limitations

Keep authoring the existing SQL schema. An enabled stage needs a valid map,
supported difficulty, objective creature, teleport, positive weight, depth
bounds and unlock eligibility. In Mode 2 its `segment_id`, `map_id`, `difficulty`
and `dungeon_encounter_id` must match the selected client's Manastorm.dbc row.
The server also needs the matching MapDifficulty support and actual world
creature spawns for that difficulty. Invalid rows are logged and skipped;
empty/partial stage content does not create invented encounters.

Populate the scaling and unlock/grant rows as needed. Segment route authoring
now belongs in `manastorm_segment_spawn`, which records persistent DB spawn GUIDs
once and assigns independent evidence-backed roles: route membership, Chaotic
Link eligibility, future randomization-slot eligibility, and future
creature-pool-source eligibility. Existing `manastorm_chaotic_link_spawn` rows
are legacy input only; `05_manastorm_segment_pool_architecture.sql` copies them
as RouteCreature|ChaoticLinkEligible and deliberately does **not** infer either
randomization role.

Creature-content ownership is stored through `manastorm_creature_pool` and
`manastorm_creature_pool_segment`. Pools source candidate creature entries from
the native occupants of source-segment spawns explicitly marked
CreaturePoolSource. The progression snapshot now consumes CreaturePool grants.
The actual creature replacement algorithm remains disabled because replacement
chance, weighting, archetype matching and depth behavior have not been recovered.
Boss/objective progression continues to use exact Segment grants; the historical
BossPool grant number remains reserved and has no runtime consumer.

Authoring/inspection commands for the recovered roles are additive and do not
enable replacement:

```text
.manastorm link add <segmentId>
    -> RouteCreature + ChaoticLinkEligible

.manastorm spawn randomslot <segmentId> <0|1>
    -> mark/unmark the selected persistent spawn as a future replacement slot

.manastorm spawn poolsource <segmentId> <0|1>
    -> mark/unmark the selected native creature as a future pool source

.manastorm spawn info <segmentId>
.manastorm spawn list <segmentId>
.manastorm pool info <poolId>
```

Creature pools now materialize a distinct list of valid creature-template entries
from their enabled source segments' CreaturePoolSource spawn roles. This is
queryable evidence/readiness only; no creature is transformed by this code.

In native-client mode the full nine-word Manastorm.dbc row is now preserved in
the selected `ManastormSegment` snapshot. Words 0-3 remain the strict native
identity; words 4-8 are retained as native tuning/evidence fields without
changing shared gameplay policy. No stage catalogue, creature-pool membership or
replacement probability is invented by this architecture change.

Stage helpers now adapt the donor's Safety Bubble (93306/93307), Cogsley (80919)
and completion portal visual (12999 with 93338). Positions come from the SQL
entrance teleport and the actual defeated objective, never the donor scene list.
Preparation waits for every member, then ends when a living member leaves the
eight-yard entrance radius or the owner selects Begin from Cogsley. Protection
is cleared on activation, exit and failure. Cogsley respawns at the defeated
objective and offers Continue; this advances through the same validated world
update as the existing five-second automatic continuation. Stale gossip cannot
skip an unfinished stage. Helpers are excluded from enemy scaling/affixes.
The corresponding creature templates and spells must be installed.

Creature levels are committed even when core SelectLevel(false) only regenerates
stats. DB creatures created by instance initialization before the run/map lookup
exists are registered on first arrival, including objective identity, SQL Chaotic
Link stacks and scaling. Zero authored stacks deliberately means no Link aura;
this does not invent route spawns or change the stage's SQL configuration.

Nonzero Messages word3 conditions remain dependent on generic GameEvent state.
No existing serializer was found for the complete `0x9BD` record, whose final
32 bytes are not established by the reports. No guessed bytes are sent.
Ordinary word3=0 toasts use the proven completion path. Reconnecting during an
already-completed stage replays `0x65E` to restore the tracker and can replay its
toasts; no eventless completion opcode is known.

## Real-client acceptance checklist

1. Enable Mode 2 with matching client/DBC files and one eligible authored stage.
   Verify startup identity validation; also try an empty table and a mismatched
   ID/map/difficulty/encounter and verify clear rejection/logging.
2. Log in outside a run: eight progression categories, four slots, inactive
   tracker. Enter depth 1 from the original UI. Capture `0x652` and `0x660`;
   verify depth precedes Manastorm ID, correct type, boss and zero cache policy.
3. Repeat with 2, 3, 4 and 5 players, including endgame characters. Verify the
   same private instance for every member and distinct instances for other runs.
   Check nonleader, offline/distant member, invalid checkpoint, cooldown, combat,
   challenge restriction, malformed/truncated request and invalid group rejection.
4. Verify all members arrive before activation, original SQL creatures spawn,
   HP/melee/spell/DoT scaling, Hearts, resurrection charges, affixes and declining
   native Chaotic Link stacks. Verify the entrance bubble, protection while
   preparing, and activation on leaving the radius or selecting Begin.
   Compare the existing Mode 1 gameplay baseline.
5. Kill the exact objective: verify committed shared progression, one `0x65E`,
   native tracker completion and qualifying word3=0 DBC toast(s), without a custom
   UW toast. Verify `0x65D` reaches self and party and caches remain truthful.
6. Test the completion guide Continue gossip, then separately wait for the five-second continuation. Verify SQL selection, a fresh
   private instance and new depth/ID tracker. Test a one-stage catalogue repeating
   and no eligible next stage failing cleanly.
7. Leave and force failure: native active depth becomes zero, Chaotic Link clears,
   members return to their own entry positions and dead members are resurrected.
   Relog while active, during transfer and during completed-stage delay; then
   test after private-instance expiry and after server restart.
8. Set each loadout slot, relog, and confirm persistence. Reject out-of-range,
   unknown/unlearned spell, lower rank, duplicate family and changes during a run.
   Upgrade a learned gadget in its existing slot; this must succeed.
   Simulate a database failure and verify no success acknowledgement/false clear.
9. Restart in Mode 1 and repeat start, completion/custom toast, next stage, leave,
   failure and reconnect. Verify no native Manastorm presentation is emitted.

## Validation performed

MSVC C++20 syntax checks and a compiled golden-packet test cover the changed
source and recovered serialization. The packet test lives in
`tests/native_protocol.cpp`. The audit fixture generator
`tests/audit_regressions.py` extracts the production loadout/configuration logic
and verifies exclusive donor registration. Its compiled assertions cover
same-slot upgrades, duplicate/rank/knowledge/passive/active-run rejection,
Mode 1/2 startup, invalid-mode fallback and restart-only configuration.
The September 21 UI/helper fixes passed focused MSVC C++20 syntax checks and
const-hook dispatch assertions. The replacement native config packet tests and patched keybinding function
passed; Lua keybinding checks use the available Lua 5.2 runtime with mocked
WoW APIs (the UI code uses Lua 5.1 syntax).
These are not an in-client test.
All seven translation units changed by the earlier ownership audit passed MSVC C++20
syntax checks; the focused C++ and SQL style checks passed.
No full server build, database migration or real
Ascension-client runtime test was performed. The module directory is ignored by
the repository's existing Git rules; preserve/include its files when packaging
these local changes, in addition to the tracked core/compatibility diff.

## Changed files

Shared module: `src/Manastorm.cpp`, `src/ManastormClientBridge.cpp/.h`,
`src/ManastormNativeProtocol.h`, `src/ManastormDataStore.cpp`,
`src/ManastormMgr.cpp/.h`, `src/ManastormProgression.cpp`, `src/ManastormRun.h`,
`conf/manastorm-endless.conf.dist`, `tests/native_protocol.cpp`, and this README.

Compatibility module: `src/AscensionCompat.cpp`, `src/AscensionManastorm.cpp/.h`,
`src/MP_loader.cpp`. Configuration is cached in `src/ManastormModuleConfig.cpp/.h`.
Core: `src/server/game/Entities/Player/Player.h`,
`src/server/game/Grids/GridObjectLoader.cpp`, `src/server/game/Maps/Map.cpp/.h`,
`src/server/game/Maps/MapInstanced.cpp`, `src/server/game/Maps/MapMgr.cpp`,
`src/server/game/Server/Protocol/Opcodes.cpp`.

All changed translation units passed MSVC syntax checks. Focused style checks
passed for the shared module/core and donor Manastorm file. The broader check
also identified existing brace-formatting violations in `AscensionCompat.cpp`
outside the changed routing block; those unrelated lines were left intact.


## Subsequent source synchronization

The source now includes upstream `9021f8b741c0bf5e8744c2a918e2152b1e088cf4`.
The sole Rend conflict was resolved by retaining the custom active-Gyth guard,
state initialization, and upstream summon/completion protections. Manastorm
backend and SQL files were preserved during the merge. The earlier builds and
in-game acceptance apply to the preceding integration revision, not this new
source synchronization. No rebuild, database import or repack deployment was
performed for this merge; a build/runtime check of this revision remains pending.
