# Integration installation review

Integration base: feature `e4247ddd63191c51828145583c885f7100a013ec` and upstream
`dbb02f53c699f87b12a8b465d9671654ef9ceef6`. Original exports are preserved byte-for-byte.
No installation or runtime acceptance has been performed by preparing these files.

## Fresh installation sequence

1. Install and finish current upstream world/character/CoA updates BEFORE introducing the
   Manastorm module updater SQL. Pending core and module migrations share a filename-ordered
   pass; enabling everything on an unprepared baseline is not a supported sequence.
2. Provide the matching custom item templates, gear variants and client/server DBC data.
   Cache reconstruction preflights must pass. Do not disable their checks to force installation.
3. Apply mandatory module world SQL and character SQL through the updater. Character files
   run 00 through 05. Module helpers, spell bindings, cache reconstructions and reward rules
   remain necessary: the configured world dump does not include those shared core tables.
   Audit SQL 02 and validation-gated SQL 03 are currently auto-discovered; review their effects.
   The unnumbered helper file still contains plain inserts, so verify duplicate handling before
   applying it to an already configured database. Several legacy migrations explicitly use
   acore_world; a differently named database needs a separate reviewed adaptation.
4. Generate review files with `python -B modules/mod-manastorm-endless/docs/manual-sql-postinstall/prepare_postinstall.py
   --output-dir .agents/plans/manastorm-integration/postinstall` (one command).
5. Review the generated 01 teleport SQL, then 02 world configuration SQL, in that order.
   These are MANUAL inputs, outside updater discovery. They must run only after mandatory SQL.
   The generator never connects to a database. Use a fresh output directory on another run.
6. Only after review and a disposable-database rehearsal should an operator authorize imports.
   Do not import CharactersManastormEXPORT-RunThisInCharacterDB.sql on a fresh server.

The snapshot supplies the final authored segment/teleport/roster configuration; do not manually
recreate segments through the historical encounter migrations. Those migrations remain for
existing installations until a separate consolidation is proven and approved.

## Generated SQL behavior

- No DROP, TRUNCATE, table replacement, foreign-key disabling or hardcoded world-schema target.
- Explicit columns and primary-key upserts preserve source values, including disabled routes,
  boss identities, teleports, stacks, weights, depths, rewards and policy.
- Overlapping teleport IDs deliberately receive authored values. Review every collision first.
- Adds only the three exported message source-metadata columns if absent.
- Finishes by setting RouteCreature and AffixEligible on every ChaoticLinkEligible row.
  The command now uses the same roles for new and already-linked selections.
- Eligibility permits the existing selection policy; it does not force every creature to roll an affix.
- Rows absent from the snapshot are retained, including any additional target-server content.
  Therefore these upserts are not an exact whole-table clone. Compare target-only rows and
  reject/resolve conflicting enabled routes or brackets before deployment.
- Export string literals retain MySQL backslash escapes; NO_BACKSLASH_ESCAPES must not be enabled.
- Existing schema must match mandatory SQL. This is not an arbitrary old-schema migration.
- No player history, loadouts, accounts or character balances are generated.
- Do not replay older foundation/policy SQL after the final snapshot; it can overwrite tuning.

## Existing configured installation

Back up world, characters and updater history, then rehearse on disposable copies. Review only
necessary migrations and configuration differences. Never replace current character history
with the supplied dump. The link-affix repair changes role bits only, including disabled link
rows; it preserves enabled states, other role bits, stacks and all unrelated tuning.

## Acceptance still required

Clean compile; SQL preflight and repeat-application rehearsal; startup prepared statements and
all data loaders; Mode 1 and Mode 2; native config coexistence; queue/loadout/reconnect; concurrent
private maps and cleanup; linked-creature affix selection; rewards/progression; native scripted
bosses, especially Dathrohan transforming to Balnazzar on the same GUID with scaling/links intact.

## Verification in this integration checkout

The Windows RelWithDebInfo worldserver and unit-test executables built successfully. Google Test
requires `gtest_force_shared_crt=ON` to match the server's MSVC runtime; this was set only in the
integration build cache. Compiler-internal parallelism was bounded with `_CL_=/MP4` after the
initial unbounded build exhausted compiler memory. No original build directory was reused.

Eight focused integration tests pass, including a C++ fixture extracted from the production
percentage-damage handlers. It preserves the feature's exact mode-1 and mode-2 overrides while
checking upstream's generic melee/max-health behavior. Export preparation tests preserve all
163 teleport and 135197 world tuples and validate metadata quoting. No SQL was executed.

The broader source check is not all green: the existing module SQL layout triggers the
pending-SQL boundary policy, and upstream's unchanged capture-SQL test assumes POSIX file
permissions on Windows. A future PR needs the documented maintainer SQL exception. These checks
have not been disabled or changed to hide failures. Runtime and database rehearsal remain pending.
