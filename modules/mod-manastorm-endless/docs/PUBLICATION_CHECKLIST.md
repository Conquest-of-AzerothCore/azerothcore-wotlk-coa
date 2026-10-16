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
Generate manual post-install review SQL with the documented command. Generated
copies under `.agents/plans` need not be committed and contain no extra secret step.

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

The source merge base is upstream dbb02f53c699f87b12a8b465d9671654ef9ceef6.
The later 9dc61efcd2672c24b4f2a1caf600d4c7af8839e2 refresh was DB-only, not a new
source merge. Publication to a new repository is separate from a future upstream
PR; preserve this distinction in its description. Local build/test reports show
scoped success, not a fully green upstream CI run.
