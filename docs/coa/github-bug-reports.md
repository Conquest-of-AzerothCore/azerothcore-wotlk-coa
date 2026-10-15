# In-game reports to GitHub

The original Ascension Help UI (Help → Bug Report) submits reports to
`jealous-sound/azerothcore-wotlk-coa` through its native bug tracker packet. No client
change is needed.

The local relay forwards reports to `https://coa-bug-report.up.railway.app/v1/reports`.
The GitHub token stays in Railway. The distributed relay includes the separately
configured intake API key, which grants access only to this report endpoint. The key
ships in this public repository (`apps/coa-bugreport/relay.py`), so treat it as public.
The feature is off by default (`CoABugReport.Enable = 0`); deployment must enable it.

## Player experience

Fill in the category, severity, title, description and the category's fields, keep
**Public** ticked (the form's default) and press Submit. Every report becomes a public
GitHub issue, so a report with **Public** cleared is refused with an explanation rather
than published. The form reports success once the server has queued the report; the
number it shows is the server's report id, not a GitHub issue number, and its
ascension.gg link does not apply to this realm.

The client composes the body from the form fields, location, class and client version.
The server adds category and priority ids, class ID, level, map, coordinates and core
Git revision. It does not automatically publish account IDs, character names, IP
addresses, chat logs, credentials or saved settings. The core hash does not describe
uncommitted source changes; retain the deployment receipt when diagnosing a locally
modified build. Text explicitly typed into the form is submitted.

## Components

Server and relay paths below are relative to the repository root:

- `src/server/coa/CoABugReport.cpp`: claims `CMSG_CREATE_BUG_REPORT` (0x0562) from the
  extension opcode dispatcher, queues it by account and answers on the player's update
  with `SMSG_CREATE_BUG_REPORT_SUCCESS` (0x0566, `u32` report id) or
  `SMSG_CREATE_BUG_REPORT_ERROR` (0x0565, `u32` length and text).
- `src/server/coa/CoABugReportService.h`: validation, per-account cooldown and the spool writer.
- `apps/coa-bugreport/relay.py`: a separate Python 3.10+ process using only the standard library.
- `src/server/coa/conf/coa_bugreport.conf.dist`: disabled startup configuration.

The request is `u32` realm field, `u32` category, `u32` priority, `u8` public, then the
title and description, each as a `u32` length followed by its bytes. The server accepts
titles of 3–128 bytes and descriptions up to 4,096 bytes, the client's own limits, and
defaults to one submitted report per 120 seconds per account. Cooldowns survive
relogging but reset on worldserver restart.

The complete report is written to a temporary file, flushed/closed, then renamed to
`<account>-<report id as 16 hex digits>.report`. The relay ignores partial files. These
are private service files: their filenames contain account IDs, which are not included in
GitHub issues. The game server performs no HTTP calls, holds no GitHub credential and
creates no new game database tables. The small amount of local file I/O happens on the
world thread; keep the spool on a local disk, not a network share.

## Activation after an explicitly authorized build

1. Build the matching server sources with the CoA loader entry and C++
   receiver, preserving the other class implementations.
2. Create a private local spool directory outside the source checkout, accessible
   only to the worldserver and relay service identities. Grant those identities
   read/write access; do not expose the directory through a web server or
   distribute it to players.
3. Install `coa_bugreport.conf` from the dist template into the server's module config
   directory. Set `CoABugReport.Enable = 1` and `CoABugReport.SpoolDirectory` to the
   absolute directory above. These settings are read at startup, not on config reload.
4. Deploy the `jealous-sound/coa-bug-report` service on Railway with
   `GITHUB_TOKEN` and `REPORT_API_KEY`. The GitHub credential needs issue creation
   access to the fixed target repository and stays in Railway's environment.
   Set the same intake key in the distributed relay, or override its bundled value
   with `COA_BUGREPORT_API_KEY`. Players do not need GitHub accounts.
   The Railway service needs no persistent volume or database.
5. Start the worker from the repository root, preferably supervised by the
   server service manager. Replace `<absolute-spool-directory>` with the same
   absolute path configured in `CoABugReport.SpoolDirectory`. This command
   enables real issue creation:

   ```powershell
   $bugReportSpool = "<absolute-spool-directory>"
   python -B "apps/coa-bugreport/relay.py" --spool $bugReportSpool --send
   ```

   Without `--send`, the command only validates current `.report` files, then exits;
   it does not read the intake key, contact Railway or write a journal. `--once --send` processes
   one pass, respecting any persisted delay; it does not drain a rate-limited queue.

The repository destination is fixed in the relay. Changing it requires a
coordinated source/configuration review; a player cannot choose an API URL or repository.

The relay sends title/body only to the fixed Railway endpoint: no player-controlled
destination, assignees, labels or issue-management actions. The service neutralizes
`@` mentions before publishing. Both HTTP clients refuse redirects. The intake key
is sent only to Railway; only Railway sends the GitHub credential to GitHub.

## Delivery and recovery

The local relay uses a SQLite journal with committed intent before each POST, atomic
status files and one OS-locked worker per spool. This journal lives on the game server's
existing local disk; it requires no Railway storage. Repeated submissions with the same
request ID return the original queued report or issue.

Railway also filters identical normalized title/body content in memory for up to 24 hours
or 4,096 records. It reserves content while an upload is in flight, so simultaneous clicks
cannot create the same issue twice in that process. It returns HTTP 202 while a matching
request is pending and returns the original issue after completion. It never queries GitHub
to find duplicates. Restarting/redeploying Railway resets this content cache; reports with
different content, including different server context, remain separate reports.

Successful issue creation stores the number before publishing the status file. After
a restart, a missing status file can be rebuilt from the journal without another POST.
Network calls do not block game threads. Rate limits and definite permission failures
pause delivery. The worker spaces requests at least five seconds apart and honors the
service's `Retry-After` header. Known pending requests are retried through the same content
filter. Invalid requests become `failed`; service authentication or definite repository
access failures become `blocked` and can recover after configuration is repaired.

An ambiguous timeout, 5xx response, malformed success response or interrupted `posting`
journal entry becomes `uncertain`. Neither component searches GitHub. The relay does not
automatically resend an uncertain report, because Railway's duplicate cache can reset.
An administrator must check the exact report and repository before repairing its local
journal/receipt. No automatic force-resend command is provided. The journal retains its
legacy opaque marker column for compatibility, but markers are not added to issue bodies
or used for network requests. Detailed API responses and credentials never reach the client.

Keep `.report`, `.status` and `relay.sqlite3` together and back them up. Do not delete the
journal to clear an error: that discards duplicate protection. Completed records are retained;
automatic retention/archival and cross-machine failover are outside this implementation.
Atomic publication covers normal process crashes/restarts; abrupt disk or power failure is
not a claim of transactional durability across the game server, filesystem and GitHub.

## Verification

`python -B tools/verify_all.py --stages harness --harness bugreport` runs the relay tests and
compiles `CoABugReportService.h` into a check of validation, cooldown and the spool file the
relay reads. Read-only checks of the deployed Railway service confirmed health, rejection
without an intake key and authenticated method handling with the configured key; they did
not submit a report. Offline checks do not establish rendered UI, live packet delivery or
successful issue creation.

Live acceptance must exercise the normal Help entry point, all category fields, a normal
player account, the Public refusal, the cooldown and normal relog. Confirm the issue in the
target repository. Deliberate outage tests should use a controlled worker fixture or stopped
worker, and preserve the request/journal for recovery.
