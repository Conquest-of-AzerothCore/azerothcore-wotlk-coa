# Guide tooling: slots, Ghost and the client lab

Optional tooling from lostmind84's [coa-server-guide](https://github.com/lostmind84/coa-server-guide)
(`skills/coa-slot-workflow`, `skills/coa-client-check`, `agents/git-safety.md`). Commands are documented in the
guide (`docs/tooling/`, `coa-slot help`, `docs/agent-lessons.md`). Use it only when the task needs a proof that
`verify_all.py` cannot give: a real session (Ghost) or the rendered client (client check). The rules in
`.agents/rules/` still apply; gameplay scenarios run through `verify_all.py` on every platform.

## Platforms

The guide's scripts were written and tested on Linux: bash driving Docker, `/srv/coa` and `~/CoaServer` paths, a
reflink filesystem, gamescope, xdotool and Wine. Each section below gives the Linux route and the Windows route.

- **Python scripts run natively** on Windows (`py -3 "$env:COA_SERVER_GUIDE\scripts\<script>.py"`):
  `coa-triage-table.py`, `coa_obtainable.py`, `coa-probe-read.py`. `coa-preflight.py` also needs `docker` and
  `mpqcli` on `PATH` and container names from a slot.
- **Bash scripts** (`coa-slot`, `coa-client-lab`, `coa-lab-*`, `coa-worktree-cleanup`, `coa-obtainable`,
  `coa-verify`) need Linux: run them in WSL2 with Docker Desktop's WSL integration, or use the native Windows
  routes below.
- Every adapted command is shown to the user before its first use. Ask before adapting or running anything that
  deletes or overwrites (`coa-worktree-cleanup`, `coa-slot reset-db`/`destroy`/`release`, `coa-client-lab
  destroy`/`erase`, dropping databases, replacing client files). A result that rests on an adaptation that could
  not be tested is reported as **not verified**.
- `scripts/install-agent-tools.sh --check` reports missing prerequisites on Linux and WSL2; on Windows check them
  by hand (`docker version`, `wsl -l -v`, `go version`, `py -3 --version`).

## Servers

### Linux and WSL2: slots

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

In WSL2, keep the guide, the slots root and the build clones on the Linux filesystem (`~/`), not under `/mnt/<drive>`:
the Windows mount is slow and has no reflink support. Docker Desktop's WSL integration must be enabled for the
distribution. The slot's ports are published on Windows' `127.0.0.1`, so a native Windows client can connect.

### Windows native: one local server

Without WSL2, there are no slots. Use one native server built from the checkout:

1. Build the branch under test with `verify_all.py --stages build` (or the user's own build). The binary must come
   from the commit being tested; record that commit.
2. Run `worldserver.exe` and then `authserver.exe` with their own config files and their own `acore_*` databases,
   never the user's production or play databases. Only one agent owns this server and its databases at a time;
   do not start it while another agent's server, build or gameplay stage is running.
3. Preflight by hand, every time the slot workflow would run `coa-slot preflight`: the server reports ready, its
   startup log names the tested commit, pending SQL is applied (no update errors in the log), the server's DBC
   set passes `python apps/coa-dbc/client_dbc.py check <server dbc dir>`, and every DBC the lab client loads is
   byte-identical to the server's copy (`Get-FileHash`). Any failure voids results taken under it.
4. Stop the server when the batch is published or abandoned, unless the user wants it running.

Gameplay scenarios need neither: `verify_all.py --stages build,gameplay` starts its own isolated worldserver with
`coa_test_*` database copies on every platform.

## Ghost e2e tests

For what a real session receives: packets, authentication, movement, experience, LFG, duels, area triggers, war
mode, chat-visible state, relogs, quest-giver interaction, several actors. Always run one package at a time
(`-p 1`): parallel packages share one server and fail spuriously.

- **Linux and WSL2:** load the slot's env file (`set -a; . <slots root>/sN/ghost.env; set +a`), never the Ghost
  repository's own `.env`, and run `go test -tags=e2e -p 1 ./e2e/<pkg> -count=1 -v`.
- **Windows native:** Go runs natively. Write an env file for the local server (auth address `127.0.0.1:3724`,
  world port `8085`, database port, as the Ghost README names the variables), load it into the PowerShell session
  (`Get-Content ghost.env | ForEach-Object { $k, $v = $_ -split '=', 2; Set-Item "env:$k" $v }`), then run the same
  `go test` command. The slot-specific variables (container names) do not apply.

Harness pitfalls: `.aura`/`.cooldown` act on the current selection; high-level training dummies resist low-level
bots and are neutral (faction 7); GM mode stays on after GM commands (`.gm off`); retry missed casts and cast the
owned rank; some triggered spells send no `SMSG_SPELL_GO`, only a damage log; level scaling only runs out of
combat; `ScenarioOpts.Prefix` plus a 10-character suffix must fit 17 characters.

## Client check

For symptoms only the client shows: tooltip text or values, an aura on the wrong unit, icons, models, broken UI.
One issue, one check, one verdict. The user's own client installation is never touched.

1. Run the server revision the check needs and pass its preflight (`coa-client-lab preflight N` on Linux, the manual
   preflight above on Windows).
2. Write the expectation first in `.agents/plans/<issue>/client/expectation.md`: what is observed, with which
   probe (`probe spell <id>`, `probe auras target`, `probe item <id>`, `probe bagitem <bag> <slot>`, `probe log`),
   and which result means reproduced. Never soften it afterwards.
3. Build the character with Ghost (race, class, level, spells, items, teleport), not with typed GM commands.
4. Observe through the lab:
   - **Linux and WSL2:** `coa-client-lab` drives a lab copy of the client under Wine and gamescope.
   - **Windows native:** the client runs natively; no Wine or gamescope is needed. Use a separate copy of the client
     folder as the lab client, with its own `WTF` settings, `realmlist` pointing at the test server, the guide's
     `addons/CoaProbe` addon installed and a throwaway account. Ask the user before creating or replacing that copy.
     Read UI facts through the probe relay (`docs/coa/client-lab-probe-relay.md`): the worldserver forwards a
     probe line to the logged-in lab character and returns the addon's answer over SOAP, which works without
     `coa-client-lab`. Screenshots and input use the platform's own UI automation. `coa-client-lab` itself and
     the `apps/coa-tests/client_lab` harness (which needs its `state/lab.json` descriptor) are unavailable.
5. Give exactly one verdict: **reproduced**, **not reproduced**, or **inconclusive** (red preflight, client or addon
   failure, unobservable symptom, vague report). A technical failure is never "not reproduced"; a verdict reached
   through the Windows adaptation says so.
6. After a fix, rerun the same expectation against the fix branch.
7. Clean up: stop the lab client, erase throwaway characters, release the slot or stop the local server.

## Obtainability

`coa-obtainable` compares the checkout against captures taken while the live servers ran, calibrating each source
per class before any verdict (`docs/tooling/spell-obtainability.md` in the guide). The wrapper is bash and only
forwards its arguments; on Windows run `py -3 scripts/coa_obtainable.py` with the same arguments. Its defaults are the guide's Linux
layout: pass `--repo <checkout>` and `--dbc <server dbc dir>`, and set `COA_REFERENCE_DIR` to the captures
directory (`snapshots/` and `MANIFEST.json`).

## Cleanup

When a worktree's last PR is pushed:

- **Linux and WSL2:** `coa-worktree-cleanup <worktree>` (dry run), then with `--yes`. It refuses unpublished,
  in-use or leased work; report a refusal, never force it.
- **Windows native:** do its checks by hand: `git -C <worktree> status --porcelain` is empty, the branch is pushed
  (`git log fork/<branch>..<branch>` is empty) or its PR is merged, and no process runs from the worktree. Then
  `git worktree remove <worktree>` and `git branch -d <branch>`. Never pass `--force`; report what blocked it.
