# Manastorm installation and integration guide

## Supported target and evidence

Target: AzerothCore CoA with world database `acore_world`, normal auth/character
databases, matching custom item/gear data, and matching Ascension client/server DBCs.
Existing `acore_world` SQL targets are intentional and unchanged.

The integration source merges feature `e4247ddd63191c51828145583c885f7100a013ec`
with upstream `dbb02f53c699f87b12a8b465d9671654ef9ceef6`, plus local fixes intended
for publication. The local test DB was subsequently refreshed through upstream
`9dc61efcd2672c24b4f2a1caf600d4c7af8839e2`; this did not merge those nine code commits.
Do not describe the source as current with that later upstream revision.

The prepared installation compiled, initialized both CoA and Wildcard worldservers,
and passed focused integration checks. The owner reports successful in-game tests
on both realm modes. Original authored exports are preserved. This evidence is for
the prepared installation, not an independently repeated zero-baseline installation
or exhaustive encounter/Mode 1 acceptance.

## Installation on an existing, working upstream PTR

1. Back up the PTR world, character database and update history. Finish upstream's
   supported installation, including the foundation tables owned by its compiled
   modules. Supply the matching custom items, gear variants and DBC/map assets.
   An empty base world with pending updates alone is not the tested prerequisite.
2. Build the integration source and deploy its module config distribution files.
   Use `Manastorm.Enable = 1` and `Manastorm.ClientMode = 2` for the native UI.
   The custom module owns gameplay; no donor gameplay registration is required.
3. Let the normal updater apply outstanding mandatory module world and character
   SQL. World files are in `modules/mod-manastorm-endless/data/sql/db-world/base/`
   and `updates/`; character files are in `data/sql/db-characters/base/`, 00 through
   05. Apply only outstanding migrations; do not manually replay every SQL file.
   Keep helper creatures, shared spell bindings, cache reconstruction and reward
   rules: the authored Manastorm table exports do not replace shared core tables.
   Include `zz_manastorm_private_creature_restoration.sql` and the matching C++
   changes together. It restores 14 definitions only in private Manastorm stages.
4. The same updater run applies the authored snapshot after all other module SQL:
   `zz_manastorm_snapshot_1_game_tele.sql`, then `zz_manastorm_snapshot_2_world.sql`
   in `data/sql/db-world/updates/`. They are generated from the unchanged exports;
   after changing an export, regenerate them from the repository root with
   `python -B modules/mod-manastorm-endless/docs/manual-sql-postinstall/prepare_postinstall.py`
   (`--check` only reports stale files). The generator never connects to a database.
5. The teleport update checks its own IDs: it overwrites only rows carrying the
   authored name or the name the module SQL gave that ID. Any other teleport on those
   IDs is listed as `foreign_teleport_id` and the update stops on
   `manastorm_teleport_ids_free` before changing anything, which stops worldserver
   startup; move that teleport, then restart. The snapshot preserves all 163 authored
   teleport tuples and 135197 world row tuples, and the world update ends by repairing
   link/route/affix eligibility bits. Do not replay older foundation/policy files
   afterward: they can overwrite authored tuning.
6. Install all four corrected client files as described in `client/Readme.txt`.
   Restart with the new worldserver for trusted-addon support. Confirm the log
   reports `Shared Manastorm backend initialized` and no SQL update failure.

Never import `CharactersManastormEXPORT-RunThisInCharacterDB.sql` into a fresh PTR
or over its existing player state. It is preserved historical data, not a required
installation input. Do not import the raw world dump as a table-replacement script;
the snapshot updates above already carry it as explicit-column upserts.

## Recorded prerequisite failure and resolution

The initial test setup attempted pending core updates before all other compiled
modules' foundation tables existed. One recorded failure was missing
`acore_world.coa_boss_flex`; 19 dependent pending migrations subsequently needed
replay. After foundations were present, the updater log confirmed 19 queries
applied successfully. This is not evidence of 19 broken Manastorm migrations.

A maintainer must begin with the working upstream installation in step 1. If an
update fails, stop and resolve its named dependency; do not copy the test setup's
manual update-ledger repair onto the PTR or suppress errors to continue.
Historical module `Creature_template.sql` contains plain inserts, while audit 02
and validation-gated 03 are automatically discoverable. Preserve updater history
and do not manually rerun those already-applied files. Existing cache preflights
must pass; do not disable validation to force installation.

## What the snapshot updates preserve

- No DROP, TRUNCATE, table replacement or foreign-key disabling.
- Explicit columns and primary-key upserts preserve authored enabled states,
  bosses, teleports, links, stacks, weights, depths, rewards and policy.
- Three exported unlock-message source-metadata columns are added only if absent.
- Linked rows gain RouteCreature and AffixEligible without changing other flags
  or enabled states. Eligibility does not force an affix roll on every creature.
- Target-only rows remain. Teleport IDs held by a foreign teleport stop the update
  before any change.
- MySQL backslash string escaping is required; do not use NO_BACKSLASH_ESCAPES.
- No accounts, character history, balances or loadouts are imported.

## Realm settings

CoA uses `CoA.ClassModel = "coa"` and `CoA.GameModeMask = 0`.
Wildcard uses `CoA.ClassModel = "hero"`, `CoA.MapClass10ToWarrior = 0`,
`CoA.GameModeMask = 64`, `CoAChallenges.GameModes.Realm = WildCard`,
`CoA.RealmType = "live seasonal"`, `PlayerStart.CustomSpells = 1`,
`AlwaysMaxSkillForLevel = 1`, and
`CoA.ClientBooleanConfigs = "CONFIG_LEGACY_CHARACTER_ADVANCEMENT_ENABLED=0"`.
Each worldserver needs its own realm ID, world port and character database.
The shared authserver accepts `RealmCards.Realm.<ID>.GameMode`: 11 for CoA and
6 for Wildcard. Card mode values are different from realm IDs and mode mask 64.

## Verification and limits

Existing recorded checks cover builds, export preservation/preparation, private
creature admission/persistence, client anchor and trust wiring, Ironaya activation
in both difficulties, and simultaneous startup of the two test realms. The owner
confirmed in-game CoA/Wildcard operation. Reuse this evidence; no new full build or
database recreation is needed for documentation/client-packaging changes.

Not claimed: all encounter mechanics, exhaustive Mode 1 regression, repeat-install
idempotency of every historical file, or a fresh upstream-only clean-install pass.
The broader source qualification previously reported a module SQL-boundary policy
exception and an upstream POSIX-permission test failing on Windows. These were not
disabled. Resolve the maintainer exception before calling the full PR checks green.
Local reports/repack logs are excluded from publication; this guide captures the
installation-relevant findings without including credentials or database dumps.


## Subsequent source synchronization

The source now includes upstream `9021f8b741c0bf5e8744c2a918e2152b1e088cf4`.
The sole Rend conflict was resolved by retaining the custom active-Gyth guard,
state initialization, and upstream summon/completion protections. Manastorm
backend and SQL files were preserved during the merge. The earlier builds and
in-game acceptance apply to the preceding integration revision, not this new
source synchronization. No rebuild, database import or repack deployment was
performed for this merge; a build/runtime check of this revision remains pending.
