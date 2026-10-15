# Build & tests

Out-of-source build is required (in-source is blocked).

```bash
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/azeroth-server -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DSCRIPTS=static -DMODULES=static
make -j$(nproc) && make install
```

C++20 required (`CMAKE_CXX_STANDARD 20`). Useful flags: `BUILD_TESTING=ON` (Google Test), `NOPCH=1` (disable precompiled headers). Full set in `conf/dist/config.cmake`. `compile_commands.json` is exported automatically.

On macOS, `verify_all.py` configures with `-DCMAKE_C_FLAGS_RELWITHDEBINFO` and `-DCMAKE_CXX_FLAGS_RELWITHDEBINFO`
set to `-O2 -g1 -DNDEBUG`; pass the same to a manual configure to get its object sizes and link times.

## Verification

Verify with `python -B tools/verify_all.py` ([guide](../../docs/coa/verification.md)); do not run `ctest`,
`unit_tests`, `apps/coa-tests` harnesses or test scripts directly. Its `build` stage configures a build directory
that has no `CMakeCache.txt` (with `BUILD_TESTING=ON`), turns testing on in an existing one, and builds
everything; its `unit` stage runs the Google Test suite in `src/test/` through `ctest`. It never installs.
Keep the build's worldserver as the gameplay binary so gameplay tests the source just built. The build directory
belongs to one checkout: a separate worktree needs its own build and a `--settings` file
([separate worktrees](../../docs/coa/verification.md#separate-worktrees)).

## Source discovery and runtime checks

- Adding a module `.cpp` can require reconfiguring the existing CMake build to refresh source discovery.
  A successful incremental build does not prove the new file was compiled. Reconfigure when discovery is needed;
  `verify_all.py` does not reconfigure an existing build for this.
- CoA client DBCs belong in `env/dist/data/dbc`; point the worldserver `DataDir` at `env/dist/data` (Docker does).
  CoA tests in `apps/coa-tests/` read the same directory, or `COA_DBC_DIR` when set. The harness stage sets
  `COA_DBC_DIR` to the `dbc_directory` setting, otherwise to the first of an inherited `COA_DBC_DIR`, the
  worldserver config's `DataDir/dbc` and `env/dist/data/dbc` that holds `Spell.dbc`.
- CoA needs the Boost.PropertyTree headers (`boost-property-tree` for component-based vcpkg installs).
- Server readiness does not exercise character loading or gameplay. For lifecycle fixes, use a focused regression
  for the failing callback and relevant map states; report real login and in-game acceptance separately.
