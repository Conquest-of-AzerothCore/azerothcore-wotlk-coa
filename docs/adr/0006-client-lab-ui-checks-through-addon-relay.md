# 0006. Check client UI through an addon-message relay on our worldserver

- Status: proposed
- Date: 2026-10-26

## Context

Some CoA defects are visible only in the game client: tooltip text, auras shown on the wrong unit, frames, Lua
errors. The guide's client lab (`coa-client-lab` and the CoaProbe addon in lostmind84/coa-server-guide) drives a lab
copy of the client by keyboard and reads CoaProbe's answers from SavedVariables, which the client writes only on
`/reload` or logout. Every answer therefore costs a UI reload of about ten seconds, and the reload clears the
target and the chat, so two probes never see the same moment.

The in-game testing design (level 3) planned an in-client channel. On 2026-10-25 that route was rescoped: no
injected or proxy DLL, no client memory access, no lifting of protected Lua functions and no anti-cheat or Warden
change, on any slot. The checks must use only what an ordinary addon and our own server can do.

## Considered options

1. Keep SavedVariables plus `/reload` as the only transport.
2. An addon-message relay through our worldserver: a SOAP-reachable admin command whispers a read-only request to
   the lab character as an addon message (`LANG_ADDON`, the pattern `AscensionCrowsCache.cpp` already uses), and the
   addon answers with chunked addon whispers to itself that a `PlayerScript` chat hook swallows and reassembles.
3. As option 2, but with a dedicated `client` stage in `tools/verify_all.py` instead of a harness script.

## Decision

Option 2, exposed to verification as the harness script `apps/coa-tests/client_lab/run.py` with a suppliable
`--client-lab` argument (setting `client_lab`, the lab descriptor path).

Option 1 keeps the reload cost and the lost target. Option 3 adds stage plumbing (selection, report, `unavailable`
rules) for one script, while the harness stage already marks a script `unavailable` when a required argument
cannot be supplied.

## Consequences

- The relay (`src/server/coa/CoAProbeRelay*.{h,cpp}`) is off by default (`CoA.ProbeRelay.Enable = 0`), needs an
  admin account over SOAP, accepts only characters of lab-prefixed accounts (`CoA.ProbeRelay.AccountPrefix`) and
  only read-only CoaProbe commands; the addon applies the same allowlist again.
- A lab slot needs `SOAP.Enabled = 1` with `SOAP.IP = "0.0.0.0"` inside its container (the host side stays bound to
  `127.0.0.1` by `coa-slot`) and `CoA.ProbeRelay.Enable = 1`; `coa-client-lab relay-setup` writes both.
- Without a running lab the script is `unavailable`, never passed. The check verifies the deployed lab slot, not
  the build stage's binary; it prints the slot's deployed commit beside the checkout `HEAD` and does not fail on a
  mismatch.
- The server repository keeps its own small SOAP client (`apps/coa-tests/client_lab/lab_relay.py`) with the same
  contracts as the guide's `scripts/coa-lab-relay`, because verification must not execute scripts from the public
  guide. Both copies must change together when the wire format changes.
- Warden and the anti-cheat path are untouched; requests and answers are ordinary addon whispers.
- Lua error text stays unreadable on this route: the client replaces the addon's error handler after login, and
  only the client's own `UI Error` system line reaches `probe log` (guide `docs/design/client-lab-level3.md`).
