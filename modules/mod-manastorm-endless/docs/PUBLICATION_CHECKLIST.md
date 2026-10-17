# Publication checklist

## Source to include

Publish the integration branch with its existing history and reviewed local fixes.
Do not substitute the original feature checkout, and do not create a history-free
source copy if the later upstream comparison needs the merge ancestry.

The publication diff must include:

- `modules/mod-manastorm-endless/src/ManastormDataStore.cpp`, `.h`, and `ManastormMgr.cpp`:
  private creature restoration and Ironaya activation, preserving the shared backend.
- `src/server/database/Database/Implementation/WorldDatabase.cpp` and `.h`:
  private-creature prepared statement.
- `src/server/game/Entities/Creature/Creature.cpp` and `.h`: guarded private spawn data
  ownership and protection against global persistence.
- `src/server/coa/AscensionCompat.cpp`: trusted native Manastorm addon.
- `src/server/apps/authserver/Server/AuthSession.cpp`: per-realm card mode override.
- `modules/mod-manastorm-endless/data/sql/db-world/updates/zz_manastorm_private_creature_restoration.sql`.
- All four canonical files under `modules/mod-manastorm-endless/client/overlay/Interface/`,
  the updated `build_keybind_patch.py`, and `client/Readme.txt`.
- `tests/test_manastorm_integration.py`, `test_manastorm_interface.py`,
  `test_manastorm_ironaya.py`, and `test_manastorm_dual_realm.py` under the module.
- The module README, installation guide, this checklist and root `.gitignore`.

The original exports and preparation tool are already part of source; retain them.
Commit the two `zz_manastorm_snapshot_*` updates they generate; the integration test
fails when those files no longer match the exports.

## Exclude

Root `.gitignore` excludes `ManastormTestRepack/`, build directories and local
`.agents/plans/`. It also excludes the duplicate client staging folder
`Corrected Addons Needs to get added to patch b/`; publish `client/overlay/` instead.
Do not force-add ignored repack files, configs, passwords, logs, assets or DB dumps.
The local legacy `client/overlay/Interface/FrameXML/StaticPopup.lua` override is
also excluded; it is not one of the four verified client fixes.
The old tracked `client/patch-ZZ.MPQ` is a historical two-file binary, not the full
current package. Use the four loose files or regenerate a new archive as documented.

## Before the separately authorized commit/push

Review `git status --short`, `git diff`, and the eventual staged diff. Include the
new files listed above deliberately; an untracked file is not included by a push.
Check that no repack/local settings or credentials are staged. No commit or push
is performed by following the installation guide or generating review SQL.

The initial source merge base was upstream dbb02f53c699f87b12a8b465d9671654ef9ceef6.
The later 9dc61efcd2672c24b4f2a1caf600d4c7af8839e2 refresh was DB-only, not a new
source merge. Publication to a new repository is separate from a future upstream
PR; preserve this distinction in its description. Local build/test reports show
scoped success, not a fully green upstream CI run.


## Subsequent source synchronization

The source now includes upstream `9021f8b741c0bf5e8744c2a918e2152b1e088cf4`.
The sole Rend conflict was resolved by retaining the custom active-Gyth guard,
state initialization, and upstream summon/completion protections. Manastorm
backend and SQL files were preserved during the merge. The earlier builds and
in-game acceptance apply to the preceding integration revision, not this new
source synchronization. No rebuild, database import or repack deployment was
performed for this merge; a build/runtime check of this revision remains pending.
