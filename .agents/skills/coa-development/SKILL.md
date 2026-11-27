---
name: coa-development
description: >-
  Development workflow for the Conquest of Azeroth (CoA) AzerothCore fork. Use for any work in this repository:
  features, bug and issue fixes, GitHub issue queues and topic batches ("fix class mechanics issues", "fix
  crashes", issue numbers, triage tables), gameplay scenarios and verify_all runs, PR titles and descriptions,
  CoA Knowledge MCP research and write-back, expected-behavior research for Ascension spells, items and classes,
  and the optional coa-server-guide tooling (server slots, Ghost e2e tests, client lab checks).
---

# CoA development

The single entry point for working on this repository. It routes to the process skill that fits the task and to
the reference that holds this repository's procedure. Creating or editing this skill does not run any workflow.

## Before anything

1. Follow `AGENTS.md` and every file in `.agents/rules/`. They override this skill and every superpowers skill.
2. Pick the process skill from `.agents/rules/workflow.md`: `superpowers:brainstorming` for features and other
   bigger changes, `superpowers:systematic-debugging` for every bug or issue fix,
   `superpowers:verification-before-completion` before any success claim. If superpowers is not installed, say so
   and follow the same phases by hand.
3. Load only the references the task needs.

## Route the task

| Task | Read |
|---|---|
| Feature, behavior change, refactor | brainstorming → `writing-plans` (plan in `.agents/plans/<task>/`), then the relevant `.agents/docs/` guide |
| Raid conversion or rescaling | [coa-raid-rescaling](../coa-raid-rescaling/SKILL.md) |
| Profession conversion or crafted-equipment rescaling | [coa-profession-rescale](../coa-profession-rescale/SKILL.md) |
| Outdoor zone conversion or rescaling | [coa-zone-rescaling](../coa-zone-rescaling/SKILL.md) |
| Five-player dungeon conversion by zone | [coa-dungeon-rescale](../coa-dungeon-rescale/SKILL.md) |
| One reported bug or issue | `.agents/rules/defects.md`, systematic-debugging, then [gameplay-test](references/gameplay-test.md) for its regression |
| Issue queue, topic batch, triage table, resuming a batch | [issue-queue](references/issue-queue.md) and [batch-scheduling](references/batch-scheduling.md) |
| Gameplay scenario design or runtime validation | [gameplay-test](references/gameplay-test.md) |
| Expected behavior, missing values, Ascension facts | [sources](references/sources.md), [knowledge-mcp](references/knowledge-mcp.md) |
| PR title and description | [pr-description](references/pr-description.md) |
| Linux slot servers, Ghost e2e tests, client-visible symptoms | [guide-tooling](references/guide-tooling.md) |

## Seed new worktrees from main

Use `~/tmp` as the base directory for new worktrees. Create each worktree in a
task-specific subdirectory such as `~/tmp/coa-manastorm-leader-depth`.

When creating a worktree, check that the primary checkout's `build-main` is idle, then
copy it to `<worktree>/build-main`. If it is active, ask the user how to proceed before
copying it. Preserve timestamps and include Ninja metadata and object files. On Linux,
`cp -a --reflink=auto -- "$main_checkout/build-main" "$worktree/build-main"` makes an
independent copy when the destination does not exist. Choose a worktree filesystem with
enough space for a full copy when reflinks are unavailable.

Use the seed as the starting point for the worktree's own incremental build. CMake and
Ninja record absolute paths, so check that the build configuration resolves to the new
worktree before invoking it. Reconfigure for the worktree as needed and inspect the planned
work before launching a build. If relocation would trigger a full rebuild, report that
before starting it. Use the [separate worktree settings](../../../docs/coa/verification.md#separate-worktrees)
with the copied build directory.

## Before starting a build

Cap compilation at three parallel jobs. Pass `--jobs 3` to `verify_all.py` when it
runs the build stage, or use a lower job limit.

Check the build host for active builds immediately before each build launch, including a
`verify_all.py` invocation that selects the build stage. Check across worktrees and build
directories. If the shell is sandboxed, use a host-visible process check so builds outside
the sandbox are visible.

If a build is running, tell the user which build and directory you found, where identifiable,
and ask whether to wait, skip the new build, or proceed concurrently. Wait for their answer
before starting another build. Leave the existing build running unless the user asks to stop
it. The build-directory ownership rules in `.agents/rules/git-safety.md` still apply.

Before launching any build, use the build tool's dry run or equivalent to list the C++
source files scheduled for compilation for the selected worktree, build directory and
targets. Include the file count and full paths relative to the worktree. If the list is
long, share it as a file. For unity builds, identify the generated compilation units and
the original source files they include.

Show the list to the user and wait for explicit confirmation before executing that build.
If the planned files or targets change, show the updated list and request confirmation
again. If the plan cannot list the files reliably, explain why and wait for the user's
direction.

## Proof ladder

Choose the cheapest proof that can distinguish the fixed behavior from the reported failure:

1. **Gameplay scenario** (`apps/coa-gameplay-test`, run through `verify_all.py`) — the default. Proves the
   server's own numbers: damage and healing, effect values, modifiers, cast time, power cost, auras, cooldowns,
   talents, pets, loot, quest steps. Cannot see packets, movement, relogs or anything the client renders.
2. **Harness or unit test** (`apps/coa-tests`, `src/test`) through `verify_all.py --stages harness|unit`.
3. **Ghost e2e test** (guide tooling) — what a real session receives: packets, authentication, movement,
   experience, LFG, duels, area triggers, relogs, several actors.
4. **Client check** (guide tooling) — only what is displayed: tooltip text, which unit shows an aura, icons, UI
   errors. A technical failure there is inconclusive, never "not reproduced".
5. **Source and data analysis** with exact manual steps, written in the PR as not automated.

A symptom on both sides is proved on both; a disagreement between server value and client display is itself the
finding. When a needed proof tool is unavailable, report the gap instead of substituting a weaker claim.

## Delegation

For parallel work (`superpowers:dispatching-parallel-agents`, `subagent-driven-development`), the controller keeps
decisions, GitHub writes, commits, pushes, builds and `verify_all.py` runs. Each dispatch prompt names:

- the report file `.agents/plans/<task>/<issue-or-topic>.md` for full findings, and a return cap of 15 lines
  (10 for a reviewer: verdict, counts by severity, one line per important finding);
- the worktree path and branch, and that every other path is forbidden (`.agents/rules/git-safety.md`);
- that investigators never build or run `verify_all.py`;
- that the agent fixes only what the issue reports, and that `Fixes #N` belongs only on a proved commit;
- the issue text and known harness limits, because the agent starts cold.
