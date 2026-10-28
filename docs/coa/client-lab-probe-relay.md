# Client lab probe relay

The probe relay lets a test harness ask the CoaProbe addon of a running lab client for a read-only UI fact
(tooltip text, frame state, auras) without `/reload`. Lua error text is not captured: on the CoA client the
addon's error handler is replaced after login, so `errors` stays empty, and a Lua error shows only as the client's
own `UI Error` system line in `probe log`. The harness reaches the worldserver over
SOAP; the worldserver whispers the request to the lab character as an addon message and collects the addon's
chunked answer. Code: `src/server/coa/CoAProbeRelay.h`, `CoAProbeRelayCore.cpp` (wire format and reply book) and
`CoAProbeRelay.cpp` (configuration, chat hook, command). Tests: `src/test/server/coa/ProbeRelayTest.cpp`.
The addon side lives in the public guide (`addons/CoaProbe/Relay.lua`).

## Wire format

Every message is a whisper with language `LANG_ADDON` whose text is `CoaProbe\t<body>`, at most 255 bytes in total
(the worldserver drops longer client chat messages).

- Request, server to client: `CoaProbe\tQ:<req>:<line>`. `<req>` is 1-16 ASCII letters or digits; `<line>` is a
  CoaProbe command line whose first word is one of `ping spell item auras spellbook known log state ca frame
  errors`, without tab, newline or NUL.
- Answer, client to server (the addon whispers its own character): `CoaProbe\tR:<req>:<index>:<total>:<data>`,
  `1 <= index <= total <= 64`. The addon cuts its JSON answer into chunks of at most 200 bytes; `<data>` may contain
  `:`. An answer that needs more than 64 chunks is replaced by a short error answer. The answer carries `loadId`
  (changes on every UI load) and the answering `character`.

The relay keeps at most 16 pending requests per character and forgets a request 120 s after it was sent, or when the
character logs out. A chunk for a request that was never sent, a duplicate chunk, or a chunk announcing a different
total than the first one is ignored.

## Command

Both subcommands need `SEC_ADMINISTRATOR` and work from the console and SOAP. The command has no row in the
`command` table, so the worldserver logs a startup warning for it, as for `.crows`.

| Command | Output on success |
|---|---|
| `.labprobe send <character> <req> <line...>` | `sent <req>` |
| `.labprobe result <character> <req>` | `unknown`, `pending <received>/<total>` or `complete <base64 of the JSON answer>` |

A failure returns one message and, over SOAP, a fault: `probe relay disabled`, `<character> is not online`,
`<character> is not a lab account`, `not a read-only probe request`.

## Configuration (`coa.conf`)

| Key | Default | Meaning |
|---|---|---|
| `CoA.ProbeRelay.Enable` | `0` | Accept `.labprobe` and swallow the addon's answer whispers |
| `CoA.ProbeRelay.AccountPrefix` | `"COALAB"` | Only characters of accounts whose name starts with this prefix (case-insensitive) can be probed |

With the relay disabled, the addon's answer whispers reach the client again; the addon ignores `R:` messages.

## Safety

- Off by default; enable it only on a lab slot.
- Admin only, and only lab-prefixed accounts can be probed.
- Read-only allowlist on both ends: the relay refuses any other first word, and the addon refuses to run anything
  outside its own allowlist (`eval`, `pksend`, `pkwatch` and `evwatch` are never reachable over the relay).
- No client memory access, injected code or anti-cheat change: requests and answers are ordinary addon messages.
  Memory diagnostics are a separate, later addition on top of this relay: see
  [client-lab-memory.md](client-lab-memory.md).

## SOAP on a lab slot

The worldserver listens for SOAP when `SOAP.Enabled = 1`. Inside the slot container set `SOAP.IP = "0.0.0.0"`, so
the published port is reachable; `coa-slot` publishes it on the host's `127.0.0.1` only
(`127.0.0.1:(7878 + (N-1)*100)`). SOAP uses HTTP basic authentication with an account of security level 3 and the
`urn:AC` method `executeCommand`. `coa-client-lab relay-setup` in the guide writes these settings for a slot.
