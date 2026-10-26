# 0007. Read the lab client's own process memory for deeper diagnostics

- Status: proposed
- Date: 2026-10-26

## Context

0006 gave the client lab an addon-message relay for read-only UI facts (tooltip text, frames, auras) without the
ten-second `/reload` cost, but two gaps remained open (`.agents/plans/client-lab-memory-diagnostics/design.md`,
use cases 1 and 2):

1. Lua error text. 0006 stated it as unreadable: the CoA client overwrites the global `seterrorhandler` after
   login, so an addon's own handler never runs. Reading `ErrorHandler.lua`'s plain global
   `ERROR_HANDLER_DATABASE.errors.current` instead needs no handler and no protected call; CoaProbe's `errors`
   command does this, so the relay already carries it.
2. Client state of a unit: the object manager, `CGUnitData` (health, max health), the aura array and the active
   player's name, as the client holds them in memory, independent of the Lua API (`UnitHealth`, `UnitAura`)
   that the comparison is meant to check. The addon-message relay cannot see this: it can only ask Lua, which is
   the thing being verified.

Reading process memory from outside needs no client change and no Warden interaction: `kernel.yama.ptrace_scope
= 1` on this machine still allows an ordinary process to `process_vm_readv` another process it owns, without a
`ptrace` attach. The guide's `scripts/coa-lab-mem` (branch `feat/lab-memory-diagnostics`) validated this live
against the lab client (slot 2, character Coalabone): image base, TLS-resolved `s_curMgr`, the object manager's
flat object list, `CGObject`/`CGUnitData` offsets, the inline and dynamic aura array layouts and the player
name cache, each against an independent known value (server DB GUID, `probe state`/`probe auras` health and
aura ids, a `/target` GUID).

## Considered options

1. Addon API only (`UnitAura`, `UnitHealth` through the existing relay). This is the Lua view the memory read
   is meant to check against; it cannot show a mismatch between what the client's engine holds and what Lua
   reports.
2. External read-only memory read via `process_vm_readv`, resolving the object manager, unit data and aura
   array from outside the process. No injection, no write, Warden stays out of the loop.
3. An in-process reader (injected DLL). Rejected: injection was explicitly ruled out on 2026-10-25 (0006's
   context), for every slot.

## Decision

Option 2, phase 1: read only, lab client only, on a slot with `Warden.Enabled = 0`. The server repository keeps
its own small reader, `apps/coa-tests/client_lab/lab_memory.py`, with the same offsets and guard semantics as
the guide's `scripts/coa-lab-mem`, for the same reason 0006 gives for `lab_relay.py`: verification must not
execute scripts from the public guide. `apps/coa-tests/client_lab/run.py` adds memory checks after its existing
relay checks: the active player name and health/max health read from memory must equal the same facts read
through the relay (`probe state`) at the same moment, every aura spell id `probe auras player` lists must be in
the memory aura array (memory also keeps auras the UI hides, reported as `memory_only`), and `probe
errors` must answer through `ERROR_HANDLER_DATABASE` without error.

Guards, refused before any read: the target process maps `Ascension.exe` from under the lab descriptor's
`client_dir`; the slot's `worldserver_conf` has `Warden.Enabled = 0`. The lab
descriptor (`state/lab.json`, written by the guide's `coa-client-lab login`) gained these two keys for this;
an older descriptor without them makes the memory checks report one `FAIL` line naming the missing keys and
skip the memory reads, while the relay checks (including `probe errors`) still run.

## Consequences

- `lab_memory.py` duplicates `coa-lab-mem`'s constants (image base, TLS RVA, object/unit/aura offsets) and
  guard logic. Both copies must change together when an offset, the guard rule or the wire format changes; a
  mismatch would silently compare the wrong fields instead of failing loudly, so a change to one is incomplete
  without the matching change to the other.
- 0006's statement that Lua error text is unreadable is superseded for this scope: the client's own
  `ERROR_HANDLER_DATABASE` is readable through the relay and `probe errors` reports it with `source:
  "ERROR_HANDLER_DATABASE"`; only the overwritten `seterrorhandler` path (an addon's own callback) stays dead.
- Still no write, no `ptrace` attach, no injected code, and no change to the Warden or anti-cheat path: the new
  checks add a read-only `process_vm_readv` client to an already off-by-default, lab-only harness.
- Without a running lab the harness script stays `unavailable`, as before; the new memory checks are reached
  only once the existing preflight and descriptor checks pass.
- The health and aura checks probe the relay immediately before the memory read and allow one retry, since the
  two reads are not atomic and health regenerates or auras expire between them; a reproducible mismatch after
  the retry is reported as a failure, not silently accepted.
