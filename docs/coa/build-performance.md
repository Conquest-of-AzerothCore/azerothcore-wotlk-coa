# Build performance

This page records what was measured on the development build that `tools/verify_all.py` configures, what was kept,
what was rejected and why. The decision is [ADR 0011](../adr/0011-faster-development-builds.md). All figures come
from one Linux workstation (32 threads, GCC 13.3, ccache 4.9.1, CMake 3.28.3, Ninja 1.11.1, image
`coa-verify-env:24.04`) on 2026-11-12. They are not guarantees for other machines.

## Method

- Every run used `tools/verify_all.py --stages build,unit` inside `coa-verify-env`, through the guide's
  `coa-verify` wrapper. That wrapper sets `CCACHE_BASEDIR` to the parent of all worktrees,
  `CCACHE_NOHASHDIR=1`, `CCACHE_SLOPPINESS=pch_defines,time_macros,include_file_mtime,include_file_ctime`, and
  ccache as the compiler launcher.
- A cold build starts from an empty ccache directory and an empty build directory.
- A second-worktree build is a different worktree at the same commit, built right after the cold build with the
  same ccache directory. It is what a contributor gets when they open a new worktree.
- CPU is the sum of the compile edges in `.ninja_log`; wall time is the duration of the `verify_all.py` call.
  Wall time varied by 8 to 10 % between identical runs. The baseline measured 847.1, 830.4, 883.4 and 918.3 s.
  CPU is therefore the main comparison and wall time the second one.
- The edit loop appends a comment to one file, then times `ninja worldserver` and the remaining `ninja` (unit
  tests). It runs without ccache, since an edited file is never a hit.
- Every run passed the `build` and `unit` stages. A figure is from one run unless two are listed.
- Linkers, the Clang profile runtime and gdb ran in a throwaway image derived from `coa-verify-env`.

## Baseline

At the time, the guide's `coa-verify` built with `-DNOPCH=1` and verify_all.py's other defaults, at commit
`c072b4e743`:

| Measurement | Value |
|---|---|
| Cold build | 830.4 to 918.3 s (4 runs), CPU 25562 to 27268 s |
| Second worktree | 161.3 s (1 run): 6 of 1816 hits in direct mode |
| worldserver link | 41.9 to 43.5 s (bfd, full `-g`), binary 2.25 GB |
| Build directory | 20.9 GiB, 96 % of it DWARF |

Three causes kept the second worktree slow:

1. `src/cmake/showoptions.cmake` passed `-D_CONF_DIR="<checkout>/env/dist/etc"` to every compile command. The path
   differs per worktree, so ccache's direct mode missed on every file and fell back to the preprocessor.
2. The same define made every precompiled header miss. When ccache compiles a header into a `.gch`, it hashes the
   `-D` arguments, so each worktree rebuilt its `.gch`. Every file that includes a precompiled header then missed
   too, because ccache hashes the `.gch` content.
3. Unit tests were compiled with `-fprofile-arcs -ftest-coverage`. ccache hashes the `.gcda` output path, which
   differs per worktree, so no test file ever hit. Nothing consumes the `.gcda` files: the `coverage` target is
   never invoked, and no active workflow builds or runs lcov.

## Experiments

All at `c072b4e743`; one variable each.

| Experiment | Cold s | CPU s | worldserver link s | Second worktree s | Runs |
|---|---|---|---|---|---|
| Baseline (NOPCH, `-g`) | 830.4 to 918.3 | 25562 to 27268 | 41.9 to 43.5 | 161.3 | 4 cold, 1 warm |
| `-g1` | 632.3 / 708.8 | 19372 / 21784 | 10.7 / 11.6 | not measured | 2 |
| `-g0` | 634.6 | 19563 | 7.5 | not measured | 1 |
| Tests without coverage | 871.7 | 26788 | 42.5 | see `_CONF_DIR` row | 1 |
| Precompiled headers (PCH) | 725.2 | 21984 | 46.0 | 368.5 (41.75 % hits) | 1 |
| `_CONF_DIR` on `Config.cpp` only, NOPCH | 826.5 | 25285 | 42.5 | 92.4 (1816 direct hits) | 1 |
| `_CONF_DIR` fix, PCH | 664.8 | 20133 | 44.5 | 104.8 (94.21 % hits) | 1 |
| `_CONF_DIR` fix, tests without coverage | 847.0 | 26155 | 41.2 | 54.9 (1926 of 1928 hits) | 1 |
| Clang 18, same flags | 620.6 | 19213 | 10.7 | not measured | 1 |
| `-gsplit-dwarf` | 870.9 | 26777 | 11.7 | not measured | 1 |

Unity builds, batch size 8 (one run each). The table gives each target's own CPU:

| Target | Files excluded to compile | Target CPU s, before and after | Cold s |
|---|---|---|---|
| `game` | 4 of 328 (inherited code) | 4708 and 1532 | 759.6 |
| `coa` | 48 of 503 (CoA code) | 8012 and 2516 | 684.2 |
| `modules` | 54 of 178 (CoA code) | 2458 and 1360 | 866.5 |
| `scripts` | 429 of 603 (428 of them upstream) | 8828 and 6790 | 778.0 |

`coa` with batch 16 needed 97 exclusions and took 699.3 s, so batch 16 was no better.

Linkers, worldserver relink only, full `-g`, three runs each:

| Linker | Times s |
|---|---|
| bfd | 18.1 / 17.4 / 17.4 |
| gold | 31.7 / 35.1 / 36.3 |
| lld 18 | 4.6 / 4.8 / 4.0 |
| mold 2.30 | 3.6 / 10.2 / 3.4 |

Thin archives (`ar qcT`) cut rebuilding every static library plus the worldserver link from 36.0 to 37.4 s down to
18.7 to 19.0 s, three runs each. The archives went from 8628 MiB to 21 MiB.

Combinations, measured cold, then in a second worktree with the same cache:

| Combination | Cold s | CPU s | Second worktree s | Runs |
|---|---|---|---|---|
| `_CONF_DIR` fix, no coverage, `-g1`, unity on `coa`, `game` and `modules`, PCH, mold, thin archives | 262.6 / 260.9 | 7799 / 7649 | 53.1 | 2 cold, 1 warm |
| Same, with unity on `game` only (the kept profile) | 412.6 | 12530 | 49.0 | 1 |
| Same as the first row, NOPCH | 389.3 | 11912 | 60.8 | 1 |
| First row with Clang 18, PCH | 166.9 | 4806 | 130.4 (243 of 1150 hits) | 1 |
| First row with Clang 18, NOPCH | 399.2 | 12266 | 68.6 | 1 |

With `-g1`, mold and thin archives, the worldserver link inside a full build took 0.5 to 0.9 s.

Edit loop, from an edited file to a linked worldserver, then the rest of the build (unit tests):

| Edited file | Baseline s | First combination row s | Same without unity on `coa` s |
|---|---|---|---|
| `src/server/coa/AscensionWildcard.cpp` | 38.7 / 38.2, then 8.0 | 11.5 / 11.6, then 0.3 | 11.4 / 18.5, then 1.7 / 1.0 |
| `src/server/scripts/Spells/spell_mage.cpp` | 32.2 / 32.8, then 0.1 | 4.4 / 4.4, then 0.1 | not measured |
| `src/server/coa/AscensionCoATalentData.h` (21 files) | 62.3 / 62.0, then 17.4 / 17.7 | 27.9 / 28.1, then 6.5 | 29.2 / 41.2, then 16.7 / 6.3 |
| `src/server/game/Entities/Player/Player.h` | 574.4, then 41.2 | 179.7, then 22.3 | not measured |

`AscensionCoATalentData.h` is the CoA header most included in the baseline's `ninja -t deps` output. No CoA header
appears among the costly headers of a Clang `-ftime-trace` run. Unity on `coa` did not slow the edit loop. The kept
profile, with unity on `game` only, was not measured in the edit loop.

### Branch measurements

Measured with `tools/verify_all.py --stages build,unit` at the merge base of this change, then on the change
itself. Each figure is from one run:

| Build | Cold s | CPU s | Second worktree s | Second worktree hits |
|---|---|---|---|---|
| Before (`dfc249177c`, guide `coa-verify` NOPCH) | 881.7 | 27115 | 153.6 | 1818/1931 (94.2 %) |
| After (this change, new defaults with mold) | 421.3 | 12874 | 47.0 | 1615/1655 (97.6 %) |

## Kept

- **`_CONF_DIR` only on `Config.cpp`** (`src/common/CMakeLists.txt`). Its only user is
  `ConfigMgr::GetConfigPath()` (`src/common/Configuration/Config.cpp`). The value and the binary are unchanged.
- **Unit-test coverage behind `WITH_TEST_COVERAGE`**, off by default. With it off, the unit tests share the cache
  across worktrees. Turn it on for a coverage report: the `coverage` target exists only then.
- **`-g1` on macOS and Linux.** `-g1` keeps file and line, inlined frames and `.cold` section lines: `addr2line` on
  `Player::Update.cold` gave the same `PlayerUpdates.cpp:341` as `-g`. In gdb it loses types (`ptype Player`: no
  symbol), locals and arguments. This was accepted for development builds; deployed builds configure their own
  flags.
- **Precompiled headers.** verify_all.py's defaults keep them on (`NOPCH` unset). With the `_CONF_DIR` fix, GCC
  precompiled headers hit across worktrees. They cut the cold build most among the options that keep worktree
  caching.
- **Unity build of `game` only** (`WITH_GAME_UNITY_BUILD`, batch 8, six files excluded in
  `src/server/game/CMakeLists.txt`).
  - Four excluded files do not compile in a unity batch: `ScriptedFollowerAI.cpp`, `SpellInfo.cpp`, `SpellMgr.cpp`
    and `WardenMac.cpp`.
  - Two more come from an audit for silent collisions over every pair of `game` files, not only the current
    batches. It took 753 namespace-scope entities first declared in a `game` `.cpp` (244 with internal linkage) from
    the DWARF of a normal full-`-g` build. It cross-checked them with a source scan, and used `g++ -M` dependency
    lists to check headers that a batch makes visible to later files.
  - No silent case exists in the current batches.
  - Two would be silent with another batch layout:
    - `SmartScript.cpp:51` declares `static void CoABossProbeSmartCast(...)`, which `src/server/coa/CoABossProbe.h`
      declares as an external function. A later file in the batch that included that header would call the static
      wrapper instead of the real function.
    - `MovementPacketBuilder.cpp:24` defines an inline `Movement::operator<<(ByteBuffer&, Vector3 const&)`.
    - Both files are excluded.
  - Macros: 16 are defined in a `.cpp` without `#undef`, and none is used by another `game` file.
  - `using` statements: of 7 at namespace scope, none changes a lookup elsewhere.
  - Limits:
    - The scan does not preprocess `#if` branches or macro-generated declarations.
    - Lookup was resolved by hand per candidate.
    - The order of dynamic initialization across files was not audited. Unity changes it, but the normal build
      leaves it unspecified too.
- **Thin archives on Linux.** GNU `ar` supports them, and macOS `ar` does not, so macOS keeps its `libtool -static`
  path.
- **mold when it is on `PATH`, on Linux.** It needs GCC 12.1 or later or Clang: an older GCC rejects
  `-fuse-ld=mold` at configure. Remove mold from `PATH` or set `cmake_args` to avoid it.

## Rejected and why

- **Unity on `coa` and `modules`.** Their exclusions come from colliding names in file-local anonymous namespaces,
  `using` declarations that leak into the next file, and earlier helpers hiding later ones. A collision does not
  always fail to compile:
  - `AscensionRunemasterTalentEffects.cpp` already compiles against `IsRunemaster` from
    `AscensionRunemasterGlyphs.cpp:73` when both share a unity batch. The two bodies are equivalent today.
  - Two more calls resolve to the right function only through overload ranking.
  - Three more would silently switch to another file's helper if the batches were cut differently, which happens
    whenever a file is added or removed.

  An exclusion list cannot stay correct as batch boundaries move. Enabling it safely needs each anonymous
  namespace to become a per-file named namespace (478 `coa` and 116 `modules` files). CMake's
  `UNITY_BUILD_UNIQUE_ID` would help, but needs CMake 3.20, above this project's 3.16 minimum. The module
  instance headers collide at global scope in inherited AzerothCore code as well.
- **Unity on `scripts`.** It needed 429 exclusions out of 603 files, nearly all inherited code. The gain was 2038 s
  of CPU (8828 to 6790 s).
- **`-gsplit-dwarf`.** The link fell to 11.7 s, no better than `-g1`, and cold time stayed in the noise. It is only
  worth it for a profile that keeps full `-g`.
- **gold.** At 31.7 to 36.3 s, it was slower than bfd.
- **lld.** At 4.0 to 4.8 s it was close to mold. mold was kept because it was the faster of the two in two runs out
  of three.
- **Batch 16.** It needed more exclusions and was not faster.
- **Building outside the container.** Not measured.

## Debug information by compiler

gdb 15.1 was run on `Player.cpp.o`, compiled four ways from the same command:

| Object | Size | Inlined entries | Variables and parameters | `ptype Player` | `info scope Player::Create` |
|---|---|---|---|---|---|
| GCC `-g` | 35.5 MB | 40763 | 262867 | yes | locals and arguments |
| GCC `-g1` | 4.9 MB | 25516 | 63 | no | none |
| Clang `-g` | 7.5 MB | 28468 | 91472 | yes | locals and arguments |
| Clang `-g1` | 2.6 MB | 28421 | 0 | no | none |

`info line Player::Create` resolved in all four. Not verified: whether Clang's default `-fno-standalone-debug`
omits, in a full worldserver, types defined in other files.

## GCC in development, Clang in deployment

- The development container's CMake picks `c++`, which is GCC 13.3.
- The repository's `apps/docker/Dockerfile` (used by the guide's `coa-slot deploy`), the guide's release build and
  the server build image all configure Clang.
- No active workflow compiles. The inherited `.github/upstream-workflows` are disabled in this fork; they build with
  clang-18, clang-21 and gcc-15.

So the compiler verify_all.py tests with is not the one that ships. This change keeps GCC for development:

- Clang with precompiled headers built cold in 166.9 s, but hit only 243 of 1150 files in a second worktree.
- For a precompiled header, ccache 4.9 refuses the preprocessor mode ("Not considering cached precompiled header
  in preprocessor mode"), so only a direct-mode hit can help.
- Direct mode fails because CMake's generated `cmake_pch.hxx` includes the header by absolute path.

## Future work

Measured, not done:

- **Rename CoA anonymous namespaces per file**, then enable unity on `coa` and `modules`. The first combination row
  above has it: cold 260.9 to 262.6 s against the kept profile's 412.6 s.
- **Clang with precompiled headers and cross-worktree caching.** Cold 166.9 s, but the second worktree misses until
  the absolute path in `cmake_pch.hxx` or ccache's PCH rule changes. Clang without precompiled headers took
  399.2 s cold and 68.6 s in a second worktree.
- **Build only the targets the selected stages need.** The build stage runs `cmake --build` without `--target`, so
  `--stages build,gameplay` also builds the unit tests: 1434 to 1565 s of CPU cold. Per edit, it adds 8.0 to 41.2 s
  in the baseline and 0.3 to 22.3 s in the first combination row.
- **The guide's `coa-slot deploy`** builds through `apps/docker/Dockerfile` with its own flags. It is not covered
  here.

Observed, not verified: in a second worktree, 44 unity batches still missed. CMake's unity sources include each
file by absolute path, inside the source, where `CCACHE_BASEDIR` does not rewrite it. The preprocessed output
(line markers, `__FILE__` in the `Errors.h` assertions) then names the worktree. `-ffile-prefix-map` could address
it; not measured.
