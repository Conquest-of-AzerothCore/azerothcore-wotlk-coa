# Realm module patches

These modules are independent, ignored Git repositories. The server repository does not include their files.
The patches preserve the realm's local module fixes alongside the server changes.

| Module | Source | Tested base | Patch |
| --- | --- | --- | --- |
| Playerbots | https://github.com/Zyth45/mod-playerbots | `b782fbbbf15281d9a9a499d37304254344dd1646` | `mod-playerbots.patch` |
| Dungeon Clear | https://github.com/Zyth45/mod-dungeon-clear | `69845d51e981f9e6cfdb1ed2c14e6445428f94fa` | `mod-dungeon-clear.patch` |

Playerbots refuses non-test database names when gameplay verification is enabled. Dungeon Clear links its test
executable with the CoA components, registers it with CTest, and updates stale test fixtures.

On a fresh checkout, clone the modules at the tested bases and apply the patches from the server repository root:

```bash
git clone https://github.com/Zyth45/mod-playerbots modules/mod-playerbots
git -C modules/mod-playerbots switch -c fix/gameplay-database-guard b782fbbbf15281d9a9a499d37304254344dd1646
git -C modules/mod-playerbots am ../../docs/coa/module-patches/mod-playerbots.patch

git clone https://github.com/Zyth45/mod-dungeon-clear modules/mod-dungeon-clear
git -C modules/mod-dungeon-clear switch -c fix/coa-test-linking 69845d51e981f9e6cfdb1ed2c14e6445428f94fa
git -C modules/mod-dungeon-clear am ../../docs/coa/module-patches/mod-dungeon-clear.patch
```

The current installation already has both patches committed; do not apply them again. Updating these modules
is separate from updating the server repository. Review conflicts and run the affected verification when merging
module updates. A later upstream version may already contain an equivalent fix.
