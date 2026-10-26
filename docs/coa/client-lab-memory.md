# Client lab memory diagnostics

`apps/coa-tests/client_lab/run.py` reads the lab client's own process memory, read only, and checks it against
the probe relay ([client-lab-probe-relay.md](client-lab-probe-relay.md)). Design: ADR
[0007](../adr/0007-client-lab-reads-lab-client-memory.md). Code: `apps/coa-tests/client_lab/lab_memory.py`,
tests `test_lab_memory.py` (the reader against a fake memory image) and `test_lab_memory_checks.py` (the checks
in `run.py` against mocked relay answers and memory reads).

## What it reads

`process_vm_readv` only (no write syscall, no `ptrace` attach, no injected code), resolving from the lab
client's own image:

- the PE TLS directory, to find the thread-local `s_curMgr` slot;
- the 64-bit TEB (the new-WoW64 client runs 32-bit code under a 64-bit TEB whose self pointer sits at `+0x30`)
  and, from it, the 32-bit TEB at `+0x2000`, its TLS array and `s_curMgr`;
- the object manager's flat object list, to find the active player's `CGObject`/`CGUnitData` by GUID;
- `CGUnitData` health and max health;
- the aura array, inline (`TSCGrowableArray`, up to 16 entries) or dynamic (heap-allocated past 16); an aura
  slot counts as active when its spell id is non-zero (a removed aura's slot record keeps spell id 0);
- the player name cache, to read the active player's own name by GUID.

Offsets and guard semantics match the guide's `scripts/coa-lab-mem` (branch `feat/lab-memory-diagnostics`),
validated live there against the lab client; see that tool's own report for the validation evidence. The two
copies must change together when an offset, the guard rule or the client build changes.

## Guards

Refused before any read:

1. the target process maps `Ascension.exe` from under the lab descriptor's `client_dir`;
2. the slot's `worldserver_conf` has `Warden.Enabled = 0`.

Any slot qualifies, slot 1 included: it is a development slot like the others since 2026-10-26.

These two descriptor keys, `client_dir` and `worldserver_conf`, are written by the guide's `coa-client-lab
login ACCOUNT PASSWORD CHARACTER` alongside the existing relay keys. An older descriptor without them makes
`run.py` report one `FAIL: lab descriptor carries the memory diagnostics keys (missing ...)` line and skip the
memory checks; the relay checks (including `probe errors`, below) still run.

## Checks

Run after the existing relay checks, each its own `PASS`/`FAIL` line:

- `memory guards pass for the lab client process`: exactly one process maps `Ascension.exe` under `client_dir`,
  and the two guards above hold.
- `memory active player name equals the descriptor character`: the name read through the player name cache.
- `memory player health and max health equal probe state`: probes `state` over the relay immediately before
  reading memory, and compares both health and max health; one retry (a fresh probe and a fresh read) if they
  do not match, since the two reads are not atomic and health can change between them.
- `memory active aura spell ids include probe auras player`: same one-retry pattern; every aura spell id the Lua
  view lists must be in memory. Memory may hold more: the UI leaves out auras it hides, such as a
  `SPELL_ATTR5_NO_CASTER_AURA_ICON` self aura (Spirit of the Hunt 707763, #7559), so those are reported as
  `memory_only` instead of failing.
- `probe errors answers without error with source ERROR_HANDLER_DATABASE`: the client's own error log, read by
  CoaProbe's `errors` command without an installed handler (ADR 0007 supersedes 0006 on this point: Lua error
  text is readable this way, though an addon's own `seterrorhandler` callback is still dead).

## Limits

- Lab only, one slot at a time, `Warden.Enabled = 0` required; this stays a phase-1, lab-only diagnostic, not a
  general anti-cheat bypass.
- A health or aura mismatch that survives the one retry is a real failure, not a timing artifact; it does not
  by itself say whether the client or the server's accounting is wrong.
- Offsets are specific to the validated client build; a client update can silently break the reader (wrong
  field, not just a crash), which is why every value stays tied to an explicit comparison against the relay
  rather than being reported on trust.
