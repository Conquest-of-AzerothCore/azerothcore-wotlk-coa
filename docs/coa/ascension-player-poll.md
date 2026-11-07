# Ascension player polls

Build the server normally; CoA source discovery includes the new C++ file automatically.
Use the supported core database updater for the migrations below, in filename order.
No manual metadata setup or client changes are required. `CoA.PlayerPoll.Enable`
defaults to 1 in `src/server/coa/conf/coa.conf.dist`.

Required migrations by database:

- Characters: `rev_20261107_01_ascension_player_poll.sql`, then
  `rev_20261107_02_ascension_player_poll_native_defaults.sql`.
- World: the same two filenames under `data/sql/updates/pending_db_world/`, then
  `rev_20261107_03_ascension_player_poll_quoted_create.sql`.

The follow-up migrations preserve the first files in case they have already been applied.
They fill missing metadata with recovered client defaults; explicit existing values remain intact.
No auth migration is needed. No sample poll is created automatically.

## Administrator commands

Commands require SEC_ADMINISTRATOR (3), including an internal check if database
permissions are lowered. The core has no separate DEV rank. Console is supported.

```
.poll create 1 1 0 10 "Server feedback" "Which option do you prefer?" "Optional comment" "Community survey"
.poll choice 1 101 First option
.poll choice 1 102 Second option
.poll publish 1 0
.poll list
.poll results 1
.poll close 1
```

Create arguments: ID, type (1-4), allow changes (0/1), minimum level (10-255), then
quoted title and question, then optional quoted feedback prompt and context. Separate
quoted fields with spaces. Omit both optional fields, or use `""` for empty feedback
when supplying context. Example: `.poll create 2 4 0 10 "Feedback" "What should change?"`.
Publish takes an expiry in Unix seconds, or 0 for no expiry. IDs must be nonzero and
unused; choice IDs are stable within a question, not UI indices.

For comment-only questions use type 4 and omit choices. Types 1-3 require a listed choice.
The original addon forces one selection even for type 2; true multi-select is not restored.
Limits: three active questions, ten choices each, 2048 comment bytes.

One answer per account per question in this characters database; alts share it.
Published questions are immutable and cannot be reopened. Closing/expiry retains answers.
Changeable questions accept a different selection/comment, including comment removal;
identical resubmissions are rejected. Comments are available only to administrators.

## Native protocol evidence

Installed `C:/Acension/Extensions.dll`, SHA256
`0f8d847b3adc44a963606f0cd4f7938ad6fcd6f4d87feac3131c7153bdf3bb11`:

- Question constructor 0x102D5FB0 explicitly initializes opaque uint32 fields at
  offsets 04/50/54/A8 to `0xFFFFFFFF / 0 / 0 / 100`.
- Question reader 0x102D6F80, submit serializer 0x102D7420 and result handler
  0x102D8030 establish the 0x745-0x748 variable-length packet layouts.
- Traced poll getters, unanswered-state and submit validation use the actual question,
  choice, feedback, changeable and type fields; the four opaque values are stored/copied.
  The server uses native constructor defaults without assigning invented meanings.

Result labels are server-defined: `PLAYER_POLL_SUBMIT_OK`, `PLAYER_POLL_SUBMIT_REJECTED`,
`PLAYER_POLL_SUBMIT_UNAVAILABLE`. The DLL passes them through; the original addon
recognizes the `_OK` suffix. Success includes the saved question. Login, native
world-entry requests, publication, closure, level changes, expiry and voting refresh lists.

## Manual verification still required

The maintainer compiled the local implementation and reports that polling works in-game
with the original addon. The observed eligibility check also correctly excluded a level-2
character from a level-10 poll. Exact expanded gameplay coverage has not been recorded.
The agent did not run builds, automated tests, SQL or servers for this task.

Before promoting the draft, review admin access, draft invisibility, notification and tab
glow, selection/comment-only submission, alt/relogin persistence, duplicate rejection,
allowed changes, expiry/close refresh and restart persistence. Native metadata defaults
are established statically; original server meanings for these opaque fields remain unnamed.
