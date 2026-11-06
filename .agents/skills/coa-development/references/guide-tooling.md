# Guide tooling: slots, Ghost and the client lab

Optional tooling from lostmind84's [coa-server-guide](https://github.com/lostmind84/coa-server-guide)
(`skills/coa-slot-workflow`, `skills/coa-client-check`, `agents/git-safety.md`). It was written for Linux (Docker,
`/srv/coa`, gamescope, Wine); on another OS adapt it first and tell the user what changed. Commands are documented
in the guide (`docs/tooling/`, `coa-slot help`, `docs/agent-lessons.md`). Use it only when it is installed and the
task needs a proof that `verify_all.py` cannot give: a real session (Ghost) or the rendered client (client lab).
The rules in `.agents/rules/` still apply; gameplay scenarios still run through `verify_all.py` where it works.

## Slots

Up to four isolated Docker stacks ("slots") are managed by `coa-slot`. Each agent uses exactly one slot and never
builds, restarts or queries another slot's server, database or build clone.

1. `coa-slot list`, then `coa-slot claim N "<batch> <note>"` on a free slot; `coa-slot claim-issues N <issue>...`.
   If all are held, stop and tell the user. Never delete another agent's `owner` file.
2. First use: `coa-slot create N` (`--own-data` when the batch changes server DBC files).
3. `coa-slot env N` prints ports, containers, the build clone and the Ghost env file.
4. Deploy only with `coa-slot deploy N <branch>` (2–5 minutes; use a 10-minute timeout or background it). Commit in
   a worktree first; never edit the build clone. Before deploying a branch that lacks SQL another branch applied,
   `coa-slot reset-db N` (slot 1: ask the user).
5. `coa-slot preflight N` before reproducing anything and after every fetch, rebuild, restart, SQL import, client
   patch or DBC install. **A FAIL voids every result taken under it.** Changing shared server DBC data or the
   user's client affects every slot: ask first.
6. Done: `coa-slot stop N` (unless the user wants it up), `coa-slot release N`.

The slot's gameplay-test image bakes its own worldserver binary and `deploy` does not rebuild it: rebuild it after
every C++ change, or scenarios run the previous binary. A result that does not move after a C++ change is an
image-staleness suspicion first.

## Ghost e2e tests

For what a real session receives: packets, authentication, movement, experience, LFG, duels, area triggers, war
mode, chat-visible state, relogs, quest-giver interaction, several actors. Load the slot's env file
(`set -a; . <slots root>/sN/ghost.env; set +a`), never the Ghost repository's own `.env`, and run
`go test -tags=e2e -p 1 ./e2e/<pkg> -count=1 -v` (`-p 1`: parallel packages share the slot's server).

Harness pitfalls: `.aura`/`.cooldown` act on the current selection; high-level training dummies resist low-level
bots and are neutral (faction 7); GM mode stays on after GM commands (`.gm off`); retry missed casts and cast the
owned rank; some triggered spells send no `SMSG_SPELL_GO`, only a damage log; level scaling only runs out of
combat; `ScenarioOpts.Prefix` plus a 10-character suffix must fit 17 characters.

## Client check

For symptoms only the client shows: tooltip text or values, an aura on the wrong unit, icons, models, broken UI.
One issue, one check, one verdict, driven by `coa-client-lab` on a lab copy of the client; the user's own client is
never touched.

1. Claim a slot running the needed revision; `coa-client-lab preflight N` must pass.
2. Write the expectation first in `.agents/plans/<issue>/client/expectation.md`: what is observed, with which
   probe (`probe spell <id>`, `probe auras target`, `probe item <id>`, `probe bagitem <bag> <slot>`,
   `probe errors`), and which result means reproduced. Never soften it afterwards.
3. Build the character with Ghost (race, class, level, spells, items, teleport), not with typed GM commands.
4. Observe, then give exactly one verdict: **reproduced**, **not reproduced**, or **inconclusive** (red preflight,
   client or addon failure, unobservable symptom, vague report). A technical failure is never "not reproduced".
5. After a fix, rerun the same expectation against the fix branch.
6. Clean up: `coa-client-lab stop`, erase throwaway characters, release the slot.

## Obtainability

`coa-obtainable` compares the checkout against captures taken while the live servers ran, calibrating each source
per class before any verdict (`docs/tooling/spell-obtainability.md` in the guide).

## Cleanup

When a worktree's last PR is pushed: `coa-worktree-cleanup <worktree>` (dry run), then with `--yes`. It refuses
unpublished, in-use or leased work; report a refusal, never force it.
