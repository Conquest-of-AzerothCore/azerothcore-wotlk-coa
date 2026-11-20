# Realm module patches

These modules are independent, ignored Git repositories. The server repository does not include their files.
The patches preserve the realm's local module fixes alongside the server changes.

| Module | Source | Upstream base | Patch |
| --- | --- | --- | --- |
| Playerbots | https://github.com/Zyth45/mod-playerbots | `3767b6445315a9f1fc60720238296e865212479f` | `mod-playerbots.patch` |
| Dungeon Clear | https://github.com/Zyth45/mod-dungeon-clear | `c97fa2c6fc52483b58b4152c0941ee2a835d8cff` | `mod-dungeon-clear.patch` |

Playerbots refuses non-test database names when gameplay verification is enabled. Dungeon Clear links its test
executable with the CoA components. CTest registration and fixture corrections are now supplied upstream.

On a fresh checkout, clone the modules at the pinned bases and apply the patches from the server repository root:

```bash
git clone https://github.com/Zyth45/mod-playerbots modules/mod-playerbots
git -C modules/mod-playerbots switch -c fix/gameplay-database-guard 3767b6445315a9f1fc60720238296e865212479f
git -C modules/mod-playerbots apply ../../docs/coa/module-patches/mod-playerbots.patch

git clone https://github.com/Zyth45/mod-dungeon-clear modules/mod-dungeon-clear
git -C modules/mod-dungeon-clear switch -c fix/coa-test-linking c97fa2c6fc52483b58b4152c0941ee2a835d8cff
git -C modules/mod-dungeon-clear apply ../../docs/coa/module-patches/mod-dungeon-clear.patch
```

The current installation already has both patches committed; do not apply them again. Updating these modules
is separate from updating the server repository. Review conflicts and run the affected verification when merging
module updates. A later upstream version may already contain an equivalent fix.

Updated on 2026-11-20 to Playerbots 3.1.6 and Dungeon Clear 3.1.4. These patches are plain Git diffs.
After applying them on a fresh checkout, commit the local changes before merging subsequent upstream updates.

Current module merge commits:

- Playerbots: `9640887a00ea5da92b6241ee896da6c868248162`
- Dungeon Clear: `fc6a140e9d9f30273cd5998dd51ed416c2ae6842`

Verification on 2026-11-20: incremental build and both CTest suites passed, as did the source checks and
`gameplay_database_guard` harness. No additional worldserver was started; live gameplay acceptance remains pending.
