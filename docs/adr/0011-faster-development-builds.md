# 0011. Faster development builds

- Status: accepted
- Date: 2026-11-12

## Context

Contributors and agents verify every change with `tools/verify_all.py`, often from a new worktree. On one Linux
workstation the default build took 830 to 918 s cold and 161.3 s in a second worktree that shared the ccache
directory. The worldserver link alone took about 42 s and the build directory held 20.9 GiB, mostly DWARF.
Profiling showed three reasons the second worktree barely reused the cache:

1. A define carried the checkout path on every compile command.
2. That define also forced every precompiled header to be rebuilt.
3. The unit tests were instrumented for coverage nobody collects.

The measurements are in [build performance](../coa/build-performance.md).

## Considered options

1. Keep the build as it is.
2. Fix only what defeats caching across worktrees: the `_CONF_DIR` define and the coverage flags.
3. Option 2 plus a development profile in verify_all.py's default configure: `-g1`, precompiled headers, unity on
   the inherited `game` library, thin archives and mold when present.
4. Option 3 with unity on `coa`, `modules` and `scripts` too, or with Clang.

## Decision

Option 3:

- `_CONF_DIR` is defined only for `src/common/Configuration/Config.cpp`.
- The coverage flags and the `coverage` target are behind `WITH_TEST_COVERAGE` (off).
- verify_all.py configures new build directories with `-O2 -g1 -DNDEBUG` on macOS and Linux, and on Linux with
  `WITH_GAME_UNITY_BUILD`, thin archives and `-fuse-ld=mold` when `mold` is on `PATH`.
- Windows keeps its previous defaults.

## Consequences

- Measured on the change itself (one run each): a cold build went from 881.7 s to 421.3 s, and a second
  worktree from 153.6 s to 47.0 s. The branch measurements table in
  [build performance](../coa/build-performance.md) has the CPU figures and hit counts.
- Development builds lose types, locals and arguments in gdb. File, line and inlined frames remain. Deployed builds
  set their own flags and are unchanged.
- Existing build directories keep their configuration: verify_all.py does not reconfigure them. Use a new
  `build_directory` or delete `CMakeCache.txt` to get the profile.
- Unity on `coa` and `modules` was rejected: CoA's anonymous-namespace names collide inside a unity batch, and one
  collision already compiles silently against another file's helper. Unity on `scripts` was rejected for its 429
  exclusions in inherited code.
- `game` unity excludes six inherited files:
  - Four of them do not compile in a unity batch.
  - `SmartScript.cpp` and `MovementPacketBuilder.cpp` are excluded because of an audit for silent collisions.
  - The audit used the DWARF of a normal build, a source scan and the compiler's dependency lists, and covered
    every pair of `game` files, not only the current batches. The current batches have no silent case.
  - `SmartScript.cpp` defines a `static CoABossProbeSmartCast` with the same signature as the external one in
    `src/server/coa/CoABossProbe.h`. A later file in the same batch that included that header would silently call
    the static one.
  - `MovementPacketBuilder.cpp` defines an inline `Movement::operator<<(ByteBuffer&, Vector3 const&)` that later
    files of its batch would see.
  - The audit's limits: it does not preprocess conditional code and resolves name lookup by hand for each
    candidate. It also does not cover the order of dynamic initialization across files, which unity changes but
    which the normal build leaves unspecified too.
  - A new upstream file that collides loudly fails the build, and the fix is an entry in the exclusion list. A
    silent collision needs the audit to be run again.
- Linux with GCC older than 12.1 and mold on `PATH` fails at configure; such a setup needs `cmake_args`.
- Development still compiles with GCC while deployment uses Clang. Clang precompiled headers do not hit across
  worktrees with CMake's generated `cmake_pch.hxx` and ccache 4.9.
