# 0527. A refused generated character name takes the next name

- Status: accepted
- Date: 2026-11-13

## Context

The gameplay harness names every actor without an explicit `name` from one running index per worldserver run
(`CoAGameplay::NameAllocator`, H + 9 letters). In the Necromancer merged pair (20261113-084238 / -085831) the five
scenarios at sequences 1907-1911 received indices 1960-1964, Hababafuqa to Hababafuqu. The CoA name filter
(`coa_name_filter`, term "fuq") refuses those names at CMSG_CHAR_CREATE; the harness ignored SMSG_CHAR_CREATE and
polled the character cache in the Creating stage until the 90 s scenario timeout. The same scenario timed out with the
explicit name Hababafuqa and passed with Hababafupu (20261113-091812). The mentor approved a test-only harness change
under G-39 on 2026-11-13.

## Decision

- The harness records SMSG_CHAR_CREATE's result byte for each actor. `CoAGameplay::CharacterCreateNext` decides:
  no result or CHAR_CREATE_IN_PROGRESS waits, CHAR_CREATE_SUCCESS continues, any other result retries a generated name
  with the allocator's next name (at most `MaxGeneratedNameRetries` = 8 times) and otherwise fails the setup at once
  with the result code. An explicit `name` is never replaced.
- No filter term is hard-coded: any refusal of a generated name retries. Legacy `Harness<x>` substitutions follow the
  new name.
- Only the harness setup changes; no gameplay path.

## Consequences

- Unit tests (CoAGameplayIsolationTest): waiting, created, retry for four refusal codes, failure at the cap and for a
  fixed name. The pre-change harness is the no-retry mutant: it timed out on the refused names above.
- A run that reaches a filtered index loses no scenario; the next names shift by one per refusal.
